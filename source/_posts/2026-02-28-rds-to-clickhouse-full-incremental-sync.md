---
layout: post
title: RDS 到 ClickHouse 全量快照 + 增量 CDC 一体化同步架构实践
excerpt: "展示如何利用 AWS RDS S3 快照作为全量基线再配合 Debezium Binlog CDC 完成增量结合，通过 ReplicatedReplacingMergeTree 入库，实现大表零干扰迁移。"
date: 2026-02-28 15:30:00
tags:
  - AWS RDS
  - Kafka
  - ClickHouse
categories:
  - tech
---

在实施 MySQL (AWS RDS) 向实时数仓环境进行大表搬迁和增量同频时，最稳固和避免数据库锁库风险的办法便是：**走底层 S3 快照导出拉取全量 + 走 Binlog CDC 承接增量**，随后使用同一个 ClickHouse 表进行归口合并入库！

本文提供在实际架构迁移中：自 `pwa_webpush_subscription` 发起的、经由自编工具读取 Parquet 、再经 Kafka Sink 入 CH 的整体脉络指南。

<!-- more -->

## 1. 搬取 AWS S3 快照作为全量历史

很多运维工具在配置全量兜底时不仅非常慢，而且还对在线 RDS 直接查询发起抢占式 IO。
在这里我们首先利用原生能力从 S3 Bucket 拖拽一份纯后台制作（不影响主库性能）的格式化快照。

```bash
# 依据 RDS 自动/手动 Snapshot 到 S3 中产生的目录，进行整个库内文件的剥离
mkdir ./rds-your-table-snapshot

aws s3 cp \
  s3://your-s3-backup-bucket/xxxx-prod-db-your-table-snapshot/ \
  ./rds-your-table-snapshot \
  --recursive
```

## 2. 解析 Parquet 并压入 Kafka 历史消息管道
此时我们获得了海量的 `.parquet` 列式小碎片，接下来利用我们封装开发的自研 Java 小应用，把解析出来的行重新回包打入到给定的用于承担全量迁移的 Kafka Topic。

```properties
# app-config.properties 配置文件指定了处理模式和推送终点
kafka.bootstrap=kafka-broker-1:9092,kafka-broker-2:9092,kafka-broker-3:9092
kafka.topic=rds-snapshot-data-pwa-webpush-subscription-history-all-0526

# 指定本地拖拉下来的文件夹路径（也可以改造直接读 S3 IO）
rds.parquet.path=/data/app-aws-rds-parquest-file-s3-to-kafka/rds-pwa-pwa-webpush-subscription-250526/
rds.parquet.table=pwa-webpush-subscription

# 用主键占位规避顺序以及哈希倾斜错误
rds-table-filed-map-as-topic-msg-key=id
```

```bash
# 执行推送任务到 Kafka
nohup java -Xms2g -Xmx2g -XX:MaxMetaspaceSize=512m \
 -Dconfig.file.path=./app-config.properties \
 -Dlog4j2.level=INFO \
 -jar app-rds-parquet-to-kafka-mq-tool.jar > out-log-$(date +%Y%m%d).log 2>&1 &
```

## 3. 在 ClickHouse 中构建支持等幂更新的存储底座表
针对可能由于增量和全量的交点问题带来冗余甚至重复数据的隐患。我们在底座的设计一定要借助具备更新迭代与收纳版本（根据 `updated_at` 覆盖的）家族：`ReplicatedReplacingMergeTree`。同时外贴分布式表进行分发和散列。

```sql
CREATE TABLE roi_ods.pwa_webpush_subscription_v2_local
on cluster oci_ck_cluster  
(
    `id` UInt32 COMMENT '自增ID',
    -- ......
    `status` UInt8 DEFAULT 1 COMMENT '订阅状态：1-已订阅，2-已退订',
    `msg_event_time` DateTime64(3, 'UTC') DEFAULT now()
)
-- [重要属性] 使用更新时间取代版本号的 MergeTree
ENGINE = ReplicatedReplacingMergeTree(updated_at)
ORDER BY (status, created_at, project_id, link_id, id)
SETTINGS index_granularity = 8192 ;

CREATE TABLE roi_ods.pwa_webpush_subscription_v2
on cluster oci_ck_cluster 
AS roi_ods.pwa_webpush_subscription_v2_local
-- 基于 project_id 将全量数据通过分布式引擎 Hash 分发给各个分片
ENGINE = Distributed('oci_ck_cluster', 'roi_ods', 'pwa_webpush_subscription_v2_local', cityHash64(project_id)) ;
```

## 4. 连接器挂载（Kafka Connect to ClickHouse）
此时远端管道中蓄势待发的所有消息，统一由一个原生的 Sink 配置发起抓取接盘（同时增量的源 CDC 后续也如此这般写入，引擎层面的 `ReplacingMergeTree` 会自动做版本融合）：

```json
// sink-ck-pwa-webpush-subscription-v2-t250515-03.json
{
    "name": "sink-ck-pwa-webpush-subscription-v2-t250515-03",
    "config": {
      "connector.class": "com.clickhouse.kafka.connect.ClickHouseSinkConnector",
      "topics": "rds-snapshot-data-pwa-webpush-subscription-history-all-0526",
      "topic2TableMap": "rds-snapshot-data-pwa-webpush-subscription-history-all-0526=pwa_webpush_subscription_v2",
      "tasks.max": "1",

      "hostname": "ck-host",
      "database": "roi_ods",
      // ... 帐号密码鉴权及 keeper 集群等

      "value.converter": "org.apache.kafka.connect.json.JsonConverter",
      "value.converter.schemas.enable": "false",
       
      // 使用 transform 组件抓取入库物理时间并塞入附加字段 msg_event_time 中监控延迟
      "transforms": "InsertTimestamp",
      "transforms.InsertTimestamp.type": "org.apache.kafka.connect.transforms.InsertField$Value",
      "transforms.InsertTimestamp.timestamp.field": "msg_event_time"
    }
}
```

投递到 ClickHouse Sink 后，等待日志表与集群同步片刻，完美的融合与快照对撞就已经大功告成了！