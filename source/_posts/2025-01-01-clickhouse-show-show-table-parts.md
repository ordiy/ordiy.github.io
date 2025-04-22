---
title: Clickhouse system.parts 使用
excerpt: 使用system.parts统计表容量、分区大小和表行数等信息
layout: post
date: 2025-04-15 18:00:45
tags:
 - data
 - clickhouse
categories:
 - blog
---

# 查看 table parts 分布情况
```SQL 

SELECT 
    hostName() AS `storage_host`,
    partition,
    name,
    active,
    rows,
    bytes_on_disk,
    modification_time
FROM clusterAllReplicas(oci_clickhouse_cluster,system.parts)
WHERE  database = 'system'  AND table = 'query_log'
ORDER BY partition;

```
Result:
```SQL 
 ┌─storage_host────────────────────────────────────┬─partition─┬─name──────────────────────┬─active─┬──────rows─┬─bytes_on_disk─┬───modification_time─┐
  1. │ my-data-clickhouse-node-03                 │ 202411    │ 202411_1_8823_103         │      1 │   3944620 │     787341756 │ 2024-11-29 17:54:23 │
  2. │ my-data-clickhouse-node-03                 │ 202411    │ 202411_8824_13570_14      │      1 │   1456371 │     300752047 │ 2024-12-13 15:22:19 │
  3. │ my-data-clickhouse-node-03                 │ 202411    │ 202411_13571_13761_12     │      1 │     44051 │       8967972 │ 2024-12-03 16:07:30 │
  4. │ my-data-clickhouse-node-03                 │ 202411    │ 202411_13762_13762_0      │      1 │        56 │         21546 │ 2024-11-30 03:53:34 │
  5. │ my-data-clickhouse-node-01                 │ 202411    │ 202411_1_9922_85          │      1 │   3166934 │     653398695 │ 2024-11-30 00:56:04 │
  6. │ my-data-clickhouse-node-01                 │ 202411    │ 202411_9923_11350_13      │      1 │    427486 │      88307493 │ 2024-12-08 03:02:45 │
  7. │ my-data-clickhouse-node-01                 │ 202411    │ 202411_11351_11490_11     │      1 │     31462 │       6446748 │ 2024-12-04 18:02:12 │
  8. │ my-data-clickhouse-node-01                 │ 202411    │ 202411_11491_11491_0      │      1 │        44 │         19350 │ 2024-11-30 03:53:35 │
  9. │ my-data-clickhouse-node-02                 │ 202411    │ 202411_1_10194_98         │      1 │   3471461 │     685641265 │ 2024-11-29 20:49:37 │
 10. │ my-data-clickhouse-node-02                 │ 202411    │ 202411_10195_13734_14     │      1 │   1063779 │     218789303 │ 2024-12-21 04:43:55 │
 11. │ my-data-clickhouse-node-04                 │ 202411    │ 202411_1_13205_114        │      1 │   4351929 │     864203789 │ 2024-11-30 02:52:09 │
 12. │ my-data-clickhouse-node-04                 │ 202411    │ 202411_13206_13469_12     │      1 │     79508 │      16367050 │ 2024-11-30 03:04:16 │
 ```

# 按host + partition聚合统计
```SQL 
# 
with my_parts AS (
SELECT 
    hostName() AS `storage_host`,
    partition,
    name,
    active,
    rows,
    bytes_on_disk,
    modification_time
FROM clusterAllReplicas(oci_clickhouse_cluster,system.parts)
WHERE  database = 'system'  AND table = 'processors_profile_log'
)
select   storage_host, partition , sum(rows) AS `total_row`, sum(bytes_on_disk)/1024/1024 AS `store_size_mb` , count(*) AS `total_parts`
from 
my_parts 
group by storage_host, partition 
ORDER BY partition desc 

```

# 按表统计总store size 
```SQL

with my_parts AS (
    SELECT 
        hostName() AS `storage_host`,
        partition,
        name,
        active,
        rows,
        bytes_on_disk,
        modification_time , 
        `table` AS `ck_table` , `database` AS `ck_database` 
    FROM clusterAllReplicas(oci_clickhouse_cluster,system.parts)
 WHERE  database not in ('system')
)
select  ck_database,  ck_table  , sum(rows) AS `total_row`, uniq(`partition`) as partition_count 
  , sum(bytes_on_disk)/1024/1024/1024 AS `store_size_gb` 
from 
my_parts 
group by ck_database, `ck_table` 
ORDER BY store_size_gb desc 

```