---
title: Analyzing Replica Inconsistency in ClickHouse
excerpt: 在 ClickHouse 多Shard多副本集群中，使用 ReplicatedMergeTree 引擎建表时，如果未显式指定 Zookeeper 路径，系统默认使用包含随机 {uuid} 的路径，可能导致同一 Shard 的不同副本 Zookeeper 路径不一致，进而引发数据不一致的问题。本文分析了该问题的成因，并提出规避建议。 <br> In ClickHouse multi-shard, multi-replica clusters, using ReplicatedMergeTree without explicitly setting the Zookeeper path can lead to inconsistent paths due to randomly generated {uuid} values. This may cause data inconsistency between replicas within the same shard. This post analyzes the root cause and provides mitigation suggestions. 
layout: post
date: 2025-07-10 15:40:38
tags:
 - ClickHouse
 - Debug
categories:
 - tech
---
   
# 环境信息
```
clickhouse version: 24.10.x 
clickhouse 集群： 2 shard 2 replicate 
```

# 问题描述
执行SQL统计时，对历史数据进行统计时发现SQL多次执行的结果不幂等。

```SQL 
-- 定位问题
-- 正常情况 一个唯一ID查询到的行数=副本数
SELECT
    hostName() AS _name,
    unique_id
FROM clusterAllReplicas('my_ch_cluster_name', dev.table_local)
WHERE unique_id = 'Lhq-xxxx'
```
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/2024/202507101631239.png)

### 排查
  分片2的2个副本的数据不一致，说明分片间数据同步有问题。
  一个副本有数据，另一个则没有，可能是其中一个副本节点在fetch Entity环节出现问题了（Clickhouse 提供的最终一致性`Eventual consistency`)
 ```js
  数据写入 --> part Entitiy 
               |    
  注册到 Keeper（ZooKeeper/ClickHouse Keeper）
               |
         其它副本节点拉取
 
```

查看replicate zookeeper path:
```SQL 
SELECT
    hostName() AS _host, table,
    zookeeper_path
FROM clusterAllReplicas(oci_ck_cluster, system.replicas)
WHERE `table` = 'launcher_events_local'
```
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/2024/202507101652777.png)

2个副本的zk path不一致:
`/clickhouse/tables/51724fc0-b8bf-4051-a533-3ad15ba10e23/02`
`/clickhouse/tables/7c6def4c-7868-4b03-b64a-579641798663/02`




### 解决问题

### 方案A-修复副本zk path 
需要-暂停该的所有数据写入的情况下操作

#### 准备工作

```SQL
--备份数据
-- 优化目标：只扫描一次表，并使用聚合过滤唯一 unique_id
-- 确认修复 node05 节点的zk path , 将该节点上存在但另一个副本不存在的数据进行备份

-- step 1 数据规模
WITH raw_data AS (
        SELECT hostName() AS _name, unique_id
        FROM clusterAllReplicas(oci_ck_cluster, common_shared_db_ods.launcher_events_local)
    ),
    unique_once AS (
        SELECT unique_id
        FROM raw_data
        GROUP BY unique_id
        HAVING count(*) = 1
    )
SELECT _name, count(*) AS line_nums
FROM raw_data
WHERE unique_id IN (SELECT unique_id FROM unique_once)
GROUP BY _name;

-- 备份数据到一个临时表

CREATE TABLE common_shared_db_ods.launcher_events_local_node05_tmp
(
    `id` UInt64,
    `unique_id` String DEFAULT '' COMMENT '事件唯一标识符',
    `url` String DEFAULT '' COMMENT 'URL',
    `event` String DEFAULT '' COMMENT '事件名称',
    `ua` String DEFAULT '' COMMENT 'user agent',
    `ip` String DEFAULT '' COMMENT 'IP',
    `ts` UInt64 DEFAULT toUnixTimestamp(now()) COMMENT '事件发生的Unix时间戳(秒)',
    `properties` String DEFAULT '' COMMENT 'JSON格式字符串的事件属性和元数据' CODEC(LZ4),
    `is_reported` UInt8 DEFAULT 0 COMMENT '是否已上报到第三方平台(0=未上报，1=已上报)',
    `report_ts` UInt64 DEFAULT 0 COMMENT '上报到第三方平台的时间戳(秒)',
    `report_response` String DEFAULT '' COMMENT '第三方平台上报的响应内容' CODEC(LZ4),
    `channel_id` UInt8 DEFAULT 0 COMMENT '渠道ID，标识流量来源',
    `clickid` String DEFAULT '' COMMENT '点击ID，用于跟踪广告点击转化',
    `device_id` String DEFAULT '' COMMENT '设备唯一标识符',
    `created_at` DateTime64(3) DEFAULT now64(3) COMMENT '事件创建时间(精确到毫秒)',
    `device_first_seen_at` DateTime64(3) DEFAULT toDateTime64(0, 3) COMMENT '设备首次出现的时间(精确到毫秒)',
    `msg_event_time` DateTime64(3, 'UTC') DEFAULT now(),
    INDEX idx_bf_unique_id unique_id TYPE bloom_filter(0.01) GRANULARITY 1,
    INDEX idx_bf_device_id device_id TYPE bloom_filter(0.01) GRANULARITY 1,
    INDEX idx_bf_clickid clickid TYPE bloom_filter(0.01) GRANULARITY 1
)
ENGINE = MergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')
PARTITION BY toYYYYMMDD(created_at)
PRIMARY KEY (toStartOfDay(created_at), event, channel_id)
ORDER BY (toStartOfDay(created_at), event, channel_id)
SETTINGS index_granularity = 8192
COMMENT 'launcher事件表' ;


-- 创建一个在node 05 节点的 MergeTree table 
CREATE TABLE IF NOT EXISTS common_shared_db_ods.launcher_events_local_node05_local_backup_tmp
AS common_shared_db_ods.launcher_events_local 
ENGINE = MergeTree()

-- 迁移未同步的数据到  (只在node05节点上存在的数据)
--common_shared_db_ods.launcher_events_local_node05_local_backup_tmp
WITH raw_data AS (
    SELECT hostName() AS _name, unique_id
    FROM clusterAllReplicas(oci_ck_cluster, common_shared_db_ods.launcher_events_local)
),
uniq_hosts AS (
    SELECT unique_id, groupUniqArray(_name) AS hosts
    FROM raw_data
    GROUP BY unique_id
    HAVING length(hosts) = 1 AND hosts[1] = 'oci-data-clickhouse-node-05.oci-us-internal.com'
)
insert into common_shared_db_ods.launcher_events_local_node05_local_backup_tmp
select * from common_shared_db_ods.launcher_events_local 
where unique_id in (
    SELECT unique_id FROM uniq_hosts
)



```

#### 修复副本 zk path 

```SQL
# on node-05 
CREATE TABLE  common_shared_db_ods.launcher_events_local  
(
    `id` UInt64,
    `unique_id` String DEFAULT '' COMMENT '事件唯一标识符',
    `url` String DEFAULT '' COMMENT 'URL',
    `event` String DEFAULT '' COMMENT '事件名称',
    `ua` String DEFAULT '' COMMENT 'user agent',
    `ip` String DEFAULT '' COMMENT 'IP',
    `ts` UInt64 DEFAULT toUnixTimestamp(now()) COMMENT '事件发生的Unix时间戳(秒)',
    `properties` String DEFAULT '' COMMENT 'JSON格式字符串的事件属性和元数据' CODEC(LZ4),
    `is_reported` UInt8 DEFAULT 0 COMMENT '是否已上报到第三方平台(0=未上报，1=已上报)',
    `report_ts` UInt64 DEFAULT 0 COMMENT '上报到第三方平台的时间戳(秒)',
    `report_response` String DEFAULT '' COMMENT '第三方平台上报的响应内容' CODEC(LZ4),
    `channel_id` UInt8 DEFAULT 0 COMMENT '渠道ID，标识流量来源',
    `clickid` String DEFAULT '' COMMENT '点击ID，用于跟踪广告点击转化',
    `device_id` String DEFAULT '' COMMENT '设备唯一标识符',
    `created_at` DateTime64(3) DEFAULT now64(3) COMMENT '事件创建时间(精确到毫秒)',
    `device_first_seen_at` DateTime64(3) DEFAULT toDateTime64(0, 3) COMMENT '设备首次出现的时间(精确到毫秒)',
    `msg_event_time` DateTime64(3, 'UTC') DEFAULT now(),
    INDEX idx_bf_unique_id unique_id TYPE bloom_filter(0.01) GRANULARITY 1,
    INDEX idx_bf_device_id device_id TYPE bloom_filter(0.01) GRANULARITY 1,
    INDEX idx_bf_clickid clickid TYPE bloom_filter(0.01) GRANULARITY 1
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/7c6def4c-7868-4b03-b64a-579641798663/02', '{replica}')
PARTITION BY toYYYYMMDD(created_at)
PRIMARY KEY (toStartOfDay(created_at), event, channel_id)
ORDER BY (toStartOfDay(created_at), event, channel_id)
SETTINGS index_granularity = 8192
COMMENT 'launcher事件表';
```
重建表后，数据会自动同步
```SQL
-- 检验数据同步状态
WITH raw_data AS (
        SELECT hostName() AS _name, unique_id
        FROM clusterAllReplicas(oci_ck_cluster, common_shared_db_ods.launcher_events_local)
    ),
    unique_once AS (
        SELECT unique_id
        FROM raw_data
        GROUP BY unique_id
        HAVING count(*) = 1
    )
SELECT _name, count(*) AS line_nums
FROM raw_data
WHERE unique_id IN (SELECT unique_id FROM unique_once)
GROUP BY _name;
```

#### 将备份表回写
```SQL
-- node 05 执行
insert into common_shared_db_ods.launcher_events_local  
select * from 
launcher_events_local_node05_local_backup_tmp ;
```

- 检查数据同步状态
```SQL
--检查同步状态，没有查询到结果说明数据已经同步
WITH raw_data AS (
        SELECT hostName() AS _name, unique_id
        FROM clusterAllReplicas(oci_ck_cluster, common_shared_db_ods.launcher_events_local)
    ),
    unique_once AS (
        SELECT unique_id
        FROM raw_data
        GROUP BY unique_id
        HAVING count(*) = 1
    )
SELECT _name, count(*) AS line_nums
FROM raw_data
WHERE unique_id IN (SELECT unique_id FROM unique_once)
GROUP BY _name;
```

#### 修复后验证之前的问题
```SQL
select  hostName() AS _name ,`unique_id` 
FROM clusterAllReplicas(oci_ck_cluster, common_shared_db_ods.launcher_events_local)
WHERE unique_id ='Lhq-kyL-FMp9MPQz8wd8j' ;
```
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/2024/202507101752694.png)



#### 重建表
暂停表的数据写入，开始备份数据
适用场景：表数据规模较小的情况（比如 10G 以内）


# 导致问题的原因
```SQL
-- CREATE  table 
CREATE TABLE test_db.test_table_v1
(
    `id` Int32,
    `customer_id` Int32,
    `street` String,
    `city` String,
    `state` String,
    `zip` String,
    `type` Enum8('SHIPPING' = 1, 'BILLING' = 2, 'LIVING' = 3)
)
ENGINE = ReplicatedMergeTree()
PRIMARY KEY id
ORDER BY id ;

```
默认的`ReplicatedMergeTree`会转换为`ReplicatedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}') `。
每次DDL执行`uuid`都是不一样，这导致同一个在多个节点上多次执行 zk path 完全不一样。

- 建议使用data_base + table_name 命名zk path 
 * 使用 `ENGINE = ReplicatedMergeTree('/clickhouse/tables/{shard}/{your_database_name}/{your_table_name}', '{replica}')·`
 * `CREATE table` 前需要 `CREATE table IF NOT EXISTS xxx`

# 参考

- Clickhouse Data replication 
 https://clickhouse.com/docs/academic_overview#3-6-data-replication