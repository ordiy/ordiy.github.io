---
layout: post
title: ClickHouse 数据外发：使用 Kafka Engine 表将数据回写消息队列
excerpt: "展示如何在 ClickHouse 中创建 Kafka Engine 外挂表，通过 INSERT INTO ... SELECT 将已清洗的报表数据写入指定 Kafka Topic。"
date: 2026-02-28 14:45:00
tags:
  - ClickHouse
  - Kafka
categories:
  - tech
---

大家都知道利用 Kafka 作为 Sink 通过 `Kafka Engine` 直接落盘 ClickHouse（简称 CH）是非常主流的做法。但若是业务产生了回旋——需要将洗好、加工好的 CH 数据大表再“原路吐回”给 Kafka 提供给其它的服务（比如机器学习的预测管道），应该如何设计呢？

ClickHouse 借助其巧妙引擎库也可同时兼纳“发送消息的源”这一角色。本文揭示通过建立外部表（外挂表）将过滤好的 ClickHouse 报表“发射”给 Kafka 队伍。

<!-- more -->

## 1. 原理核心
在 CH 内建立一张指定 `ENGINE = Kafka` 的表，这张表并不是用于持久化存数据（它在 CH 的节点磁盘内并不占用实体 block 文件夹）。当你通过 `INSERT INTO this_kafka_table SELECT ...` 语句向其塞入数据时，CH 节点会自动扮演 Producer 的身份，将每行数据序列化（比如依照 JSON 格式）吐到挂载的远端 Topic 里面去。

## 2. 操作实战步骤

### 创建连接通道外挂表

假设我们要将数仓中 `roi_ods.pwa_event_point_log` 某日的事件日志推出去：

```sql
CREATE TABLE data_dev_stg.pwa_event_point_log_clickhouse_to_kafka_queue
ON CLUSTER cluster_2S_2R_auth 
(
    `id` UInt64 COMMENT '主键ID',
    `project_id` String  COMMENT '项目ID',
    `channel_id` Int32  COMMENT '渠道',
    `event_code` Int32  COMMENT '事件值',
    -- ... 后续庞大字段略过...
    `ts_time` DateTime('UTC')  COMMENT 'ts 时间戳时间',
    `msg_event_time` DateTime64(3, 'UTC') 
) 
ENGINE = Kafka 
SETTINGS
    -- 指定消息队列 brokers 的连接池
    kafka_broker_list = 'kafka-broker-1:9092,kafka-broker-2:9092,kafka-broker-3:9092',
    -- 准备被写入的目标话题
    kafka_topic_list = 'stg-event-point-history-data-queue',
    -- Group Name，虽然发数据这里更多是结构强校验，顺应协议仍需带上
    kafka_group_name = 'clickhouse_push_group',
    -- [关键]格式刷序列器，使得接受端拿到的全部为标准 JSON。
    kafka_format = 'JSONEachRow'; 
```

### 发起投递

这步如同最平常的 `INSERT INTO ... SELECT` 操作一样。ClickHouse 以列式的查询极速执行了下推，而后并发式地转化为发送消息任务：

```sql
-- 将 2025-07-16 全天的埋点清洗数据重新投递回消息汇流排：
INSERT INTO data_dev_stg.pwa_event_point_log_clickhouse_to_kafka_queue 
SELECT * FROM roi_ods.pwa_event_point_log 
WHERE toDate(ts) = toDate('2025-07-16') ;
```

## 经验避坑雷区
* **流量冲击**：这种强塞操作可能会带来高达数 GB 的内网带宽挤兑，如果在下班/深夜执行，建议注意做好业务应用的限流配置或者关注 Kafka 网络网卡的负载能力，否则非常容易把弱底子的 Kafka 节点打挂。
* **数据流向闭环**：特别要注意不能存在双引擎循环订阅的成环可能。即推出去的 Kafka 消费端不要再二次清洗写回同名的 CH 表去，会引起严重的数据海啸效应。