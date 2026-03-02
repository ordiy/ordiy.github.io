---
title:  clickhouse optimize turn off insert query logs
excerpt: 默认的情况下Clickhouse system.query_log表会记录insert log，在数据流量非常大的情况下，会增加Disk IO 压力，也浪费存储空间。
date: 2025-03-28 16:11:23
tags:
 - clickhouse
 - optimize
categories:
- Data
layout: post
---

# 现状 

Clickhouse system.query_log 表占用的空间异常。(Clickhouse system.query_log表 使用的是MergeTree Engine , 实际存储容量= clickhose_node数量 * 203G)占用了800G左右的Disk容量：
![300](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/2024/202503281624629.png)

- 导致问题的原因：
 insert log 被写入了该表

# 关闭 insert 类型用户的 query_log 

## 关闭用户 query_log 
- user.xml 配置的用户（建议通过此方式配置）
```xml 
<clickhouse replace="true">
  <profiles>
    <!-- default config -->
    <default>
      <max_memory_usage>10000000000</max_memory_usage>
      <use_uncompressed_cache>0</use_uncompressed_cache>
      <load_balancing>round_robin</load_balancing>
      <log_queries>0</log_queries> <!-- 设置为0 关闭query_log -->
      <distributed_product_mode>global</distributed_product_mode>
      <max_partitions_per_insert_block>5000</max_partitions_per_insert_block>
      <optimize_read_in_order>1</optimize_read_in_order>
    </default>
    </profiles>

</clickhouse>
```

- 使用 clickhouse client 关闭
```shell

#只在当前会话中有效
SET log_queries = 0;

## -- We do not recommend to turn off logging because information in this table is important for solving issues.
# 官方不建议关闭
```


## query_log的配置说明
config.xml 中关于`system.query_log`的配置说明：

```xml
<query_log>
        <!-- What table to insert data. If table is not exist, it will be created.
             When query log structure is changed after system update,
              then old table will be renamed and new table will be created automatically.
        -->
        <database>system</database>
        <table>query_log</table>
        <!--
            PARTITION BY expr: https://clickhouse.com/docs/en/table_engines/mergetree-family/custom_partitioning_key/
            Example:
                event_date
                toMonday(event_date)
                toYYYYMM(event_date)
                toStartOfHour(event_time)
        -->
        <partition_by>toYYYYMM(event_date)</partition_by>
        <!--
            Table TTL specification: https://clickhouse.com/docs/en/engines/table-engines/mergetree-family/mergetree/#mergetree-table-ttl
            Example:
                event_date + INTERVAL 1 WEEK
                event_date + INTERVAL 7 DAY DELETE
                event_date + INTERVAL 2 WEEK TO DISK 'bbb'

        <ttl>event_date + INTERVAL 30 DAY DELETE</ttl>
        -->

        <!--
            ORDER BY expr: https://clickhouse.com/docs/en/engines/table-engines/mergetree-family/mergetree#order_by
            Example:
                event_date, event_time
                event_date, type, query_id
                event_date, event_time, initial_query_id

        <order_by>event_date, event_time, initial_query_id</order_by>
        -->

        <!-- Instead of partition_by, you can provide full engine expression (starting with ENGINE = ) with parameters,
             Example: <engine>ENGINE = MergeTree PARTITION BY toYYYYMM(event_date) ORDER BY (event_date, event_time) SETTINGS index_granularity = 1024</engine>
          -->

        <!-- Interval of flushing data. -->
        <flush_interval_milliseconds>7500</flush_interval_milliseconds>
        <!-- Maximal size in lines for the logs. When non-flushed logs amount reaches max_size, logs dumped to the disk. -->
        <max_size_rows>1048576</max_size_rows>
        <!-- Pre-allocated size in lines for the logs. -->
        <reserved_size_rows>8192</reserved_size_rows>
        <!-- Lines amount threshold, reaching it launches flushing logs to the disk in background. -->
        <buffer_size_rows_flush_threshold>524288</buffer_size_rows_flush_threshold>
        <!-- Indication whether logs should be dumped to the disk in case of a crash -->
        <flush_on_crash>false</flush_on_crash>

        <!-- example of using a different storage policy for a system table -->
        <!-- storage_policy>local_ssd</storage_policy -->
    </query_log>

```

# 验证效果
insert log  关闭
```shell
#检查效果

SELECT
    user,
    query_id,
    query_start_time,
    query_duration_ms,
    initial_query_id,
    --query,
    tables,
    read_rows,
    memory_usage
FROM clusterAllReplicas(xxx, system.query_log) 
WHERE 
 hasAny(databases, ['xxx', 'xxx']) 
 AND (event_time >= (now() - toIntervalMinute(3))) 
 AND user = 'ck_sink_user' 
 ORDER BY query_duration_ms DESC
limit 10  ;


```

- 效果
```SQL 
ALTER USER insert_user SETTINGS log_queries = 0

-- 等待1分钟

SELECT
    user,
    query_id,
    query_start_time,
    query_duration_ms,
    initial_query_id,
    --query,
    tables,
    read_rows,
    memory_usage
FROM clusterAllReplicas(oci_clickhouse_cluster, system.query_log) 
WHERE 
 (event_time >= (now() - toIntervalMinute(3))) 
 AND user = 'admin_sink_user' 
 ORDER BY query_duration_ms DESC
limit 10  ;

```
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/2024/202503281604405.png)


# 参考
https://clickhouse.com/docs/operations/system-tables/query_log

