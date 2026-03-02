---
layout: post
title: ClickHouse 分区管理与 System 表空间清理实践
excerpt: "总结在生产 ClickHouse 集群中按分区删除、迁移和归档数据的常用 DDL 操作，以及系统日志表占用空间过大的处理方法。"
date: 2026-02-28 11:15:00
tags:
  - ClickHouse
  - SQL
categories:
  - tech
---

随着生产上 ClickHouse 读写频率的不断增加，日志表与分析表累积的 Partitions 分区经常会迅速堆积并侵占掉机器几十以及上百个 GB 的存储空间。如果不建立监控和清理机制，磁盘报警将会是持久的烦恼。

本文通过常用的聚合 SQL 排查全集群的分区占用情况，以及如何针对业务表与 ClickHouse 自带的庞大 `system` 日志表进行有效的长期空间清理（释放）。

<!-- more -->

## 1. 扫描与定位大容量分区表

磁盘清理的第一步一定是按需分析各个分布式集群下具体由于哪些表吃掉了极高的存储：

```sql
-- 按照存储大小降序，查询集群内每个库、每个表、具体占用的分区以及其 MB 容量
SELECT 
    concat(database,'.',`table`) AS table_name,
    partition,
    sum(bytes_on_disk)/1024/1024 AS `store_size_mb`, 
    count(*) AS `total_parts`
FROM clusterAllReplicas(oci_ck_cluster, system.parts)
WHERE 1 = 1 
-- 比如仅查看 CDN 访问日志等宽表库
AND database = 'cdn_ods'
-- 定位 15 天前较老的分区
AND toDate(partition) < toDate(now() - INTERVAL 15 DAY)
GROUP BY concat(database,'.',`table`), partition 
ORDER BY store_size_mb DESC 
LIMIT 60 ;
```

通过这一条 SQL，立刻能够从全集群层面（`clusterAllReplicas`）汇总出 `cdn_aws_cloudfront_cdn_log_v1_local` 这样超宽厚表具体在哪些按日期命名的 partition 上造成了拥堵。


## 2. 正常业务表的分区快速下线 (Drop Partition)

锁定到冗余过期的数据分区后，最优雅且零 IO 的删除方式是直接 DROP 掉那个分区，而不是执行 `DELETE`（DELETE 是极其消耗服务器计算底层的 Mutation 行动）。

```sql
-- 单分区抛弃例子
ALTER TABLE cdn_ods.cdn_aws_cloudfront_cdn_log_v1_local 
ON CLUSTER oci_ck_cluster 
DROP PARTITION '2025-08-02' ;

ALTER TABLE cdn_ods.cdn_aws_cloudfront_cdn_log_v1_local 
ON CLUSTER oci_ck_cluster 
DROP PARTITION '2025-08-03' ;
```

## 3. System 系统日志表爆炸清理指南

相较于业务数据，很多新手对 ClickHouse 的内部维护库 `system` 放任不管。经常会遭遇 `system.trace_log`、`processors_profile_log` 等表单月积累出几百 GB 的恐怖开销。

我们可以使用针对性的匹配过滤来挖掘：

```sql
SELECT 
    concat(database,'.',`table`) AS table_name,
    partition,
    sum(bytes_on_disk)/1024/1024 AS `store_size_mb` , count(*) AS `total_parts`
FROM clusterAllReplicas(oci_ck_cluster,system.parts)
WHERE database ='system'
AND toInt32(partition) < toYYYYMM(toDate(now())) -- 历史月份分区
GROUP BY concat(database,'.',`table`) , partition 
ORDER BY store_size_mb DESC 
LIMIT 60 ;
```

在排查后，通常类似如下的 10 张引擎溯源和分析追踪日志会名列前茅。清理时需要注意通过参数 `max_partition_size_to_drop = 0` 取消默认的 “不允许直接 drop 容量过大分区” 的安全阈值防护限制：

```sql
-- 强制开启无限制删除模式以清理分析和追踪表
ALTER TABLE system.processors_profile_log ON CLUSTER oci_ck_cluster DROP PARTITION '202501' SETTINGS max_partition_size_to_drop = 0;

ALTER TABLE system.trace_log ON CLUSTER oci_ck_cluster DROP PARTITION '202509' SETTINGS max_partition_size_to_drop = 0;

ALTER TABLE system.metric_log ON CLUSTER oci_ck_cluster DROP PARTITION '202509' SETTINGS max_partition_size_to_drop = 0; 
ALTER TABLE system.asynchronous_metric_log ON CLUSTER oci_ck_cluster DROP PARTITION '202509' SETTINGS max_partition_size_to_drop = 0; 

ALTER TABLE system.query_log ON CLUSTER oci_ck_cluster DROP PARTITION '202509' SETTINGS max_partition_size_to_drop = 0; 
ALTER TABLE system.part_log ON CLUSTER oci_ck_cluster DROP PARTITION '202509' SETTINGS max_partition_size_to_drop = 0;
ALTER TABLE system.text_log ON CLUSTER oci_ck_cluster DROP PARTITION '202509' SETTINGS max_partition_size_to_drop = 0; 
```

一旦以上大内存的分区解除绑定，Linux 底层的空闲磁盘资源将会立即释放，这才是管理 ClickHouse 高级服务器应该具备的最佳实践习惯！