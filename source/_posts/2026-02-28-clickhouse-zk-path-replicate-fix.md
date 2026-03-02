---
layout: post
title: ClickHouse ReplicatedMergeTree 副本数据不一致与 ZK Path 修复实践
excerpt: "在 ClickHouse 集群中，ReplicatedMergeTree 表的 Zookeeper 路径异常会导致副本数据不一致。本文演示从排查数据偏差、隔离差异数据，到重建表结构、回写数据的完整修复方案。"
date: 2026-02-28 10:00:00
tags:
  - ClickHouse
  - Debug
categories:
  - tech
---

在日常运维 ClickHouse 集群阶段，由于操作不当或者节点硬件故障，可能会引发 `ReplicatedMergeTree` 表在 Zookeeper 中的路径（zk_path）记录异常。进而导致了各副本（Replica）间的数据无法正常同步，出现严重的数据不一致问题。

本文将演示如何从排查数据偏差开始，利用本地节点临时表隔离差异数据，最终重建并修复受损表数据的一整套实战方案。

<!-- more -->

## 1. 异常发现与问题排查

通常在集群中发现各节点同一张表的数据量出现较大差异时，我们首先要排查 `system.replicas` 表，查看具体表的 `zookeeper_path` 配置是否正确，以及同步状态是否正常。

```sql
-- 查看特定表在各节点的 ZK path 状态
SELECT
    hostName() AS _host, 
    table,
    zookeeper_path
FROM clusterAllReplicas(oci_ck_cluster, system.replicas)
WHERE `table` = 'shortlink_request_log_local'
```

### 统计未同步的数据规模
为了确认存在多少差异数据（且只存在于特定单节点上），我们可以通过对比查询，将仅出现一次的 `id` 数量按节点进行分布统计。这里利用 `GROUP BY ... HAVING count(*) = 1` 找到未同步的孤儿数据：

```sql
WITH raw_data AS (
    SELECT hostName() AS _name, id
    FROM clusterAllReplicas(oci_ck_cluster, common_shared_db_ods.shortlink_request_log_local)
),
unique_once AS (
    SELECT id
    FROM raw_data
    GROUP BY id
    HAVING count(*) = 1
)
SELECT _name, count(*) AS line_nums
FROM raw_data
WHERE id IN (SELECT id FROM unique_once)
GROUP BY _name;
```

## 2. 修复步骤实战

一旦我们确定了出现问题的表（例如 `common_shared_db_ods.shortlink_request_log_local` ）以及承载了未同步数据的异常节点（在这个例子中是 `node05` ），可以通过以下操作无损修复：分离差异数据、重建表结构、补回数据。

### 2.1 隔离与备份异常节点数据
首先，在包含未同步数据的节点（如 `node05`）上手动建一个本地的 `MergeTree` 作为临时表，并将仅仅存在于本节点的特有孤儿数据刷录进去：

```sql
-- 1. 创建 node05 的临时表用于备份
CREATE TABLE IF NOT EXISTS common_shared_db_ods.shortlink_request_log_local_node05_tmp
AS common_shared_db_ods.shortlink_request_log_local 
ENGINE = MergeTree();

-- 2. 仅抓取存在于 node05 上而其他节点没有的数据
WITH raw_data AS (
    SELECT hostName() AS _name, id
    FROM clusterAllReplicas(oci_ck_cluster, common_shared_db_ods.shortlink_request_log_local)
),
uniq_hosts AS (
    SELECT id, groupUniqArray(_name) AS hosts
    FROM raw_data
    GROUP BY id
    HAVING length(hosts) = 1 AND hosts[1] = 'ck-node-05.internal'
)
INSERT INTO common_shared_db_ods.shortlink_request_log_local_node05_tmp
SELECT * FROM common_shared_db_ods.shortlink_request_log_local 
WHERE id IN (
    SELECT id FROM uniq_hosts
);
```

### 2.2 重建正确 ZK 路径的 ReplicatedMergeTree 表
分离出备份数据后，我们可以直接通过 `REPLACE TABLE` 命令将错误的表替换。在执行时，必须确保新的 `ENGINE` 参数中采用的是绝对正确的、未受损的 zk path。

```sql
REPLACE TABLE common_shared_db_ods.shortlink_request_log_local
(
    `id` UInt64 DEFAULT generateSnowflakeID(hostname()),
    `account_code` String DEFAULT '' COMMENT '账户code',
    `cookie` String DEFAULT '' COMMENT '用户cookie标识',
    `request_time` DateTime64(3, 'UTC') DEFAULT now64() COMMENT '请求发生时间，精确到毫秒',
    -- ... (省略其他字段，保持与原表完全一致) ...
    `insert_time` DateTime64(3, 'UTC') DEFAULT now64() COMMENT '数据入库时间'
)
ENGINE = ReplicatedMergeTree('/clickhouse/tables/8b685b92-6cd4-44ec-8919-5dc1fed89abc/02', '{replica}')
PARTITION BY toYYYYMMDD(request_time)
PRIMARY KEY (short_code, toDate(request_time))
ORDER BY (short_code, toDate(request_time), id)
SETTINGS index_granularity = 8192
COMMENT '短链请求记录表';
```

### 2.3 回写数据与清理
最后，表结构和同步路径配置好后，将之前隔离提取的孤儿数据重新插回到修复后的高可用表中，ClickHouse 将基于此正确的路径向各个副本（Replica）发起自动同步。

```sql
-- 1. 回写备份数据至高可用表
INSERT INTO common_shared_db_ods.shortlink_request_log_local
SELECT * FROM shortlink_request_log_local_node05_tmp;

-- 2. 通过分布查询确认数据已经同步到其它节点
SELECT * FROM common_shared_db_ods.shortlink_request_log_local 
WHERE id = 7340940974655205377;

-- 3. 一切无误后，删除临时备份表
DROP TABLE shortlink_request_log_local_node05_tmp;
```

## 结语
遇到 ClickHouse 集群 Replica 一致性问题，不要急于直接 `DROP`。通过 `clusterAllReplicas` 多节点联查找出差异集合，并在单节点将孤立数据以常规 `MergeTree` 表妥善备份（暂存），再以 `REPLACE TABLE` 纠正结构元数据并回刷数据，是一种非常安全和优雅的设计思路。