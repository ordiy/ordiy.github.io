---
title: Clickhouse show slow query log 
excerpt: Clickhouse 定位慢查询 
layout: post
date: 2025-03-28 20:31:44
tags:
categories:
---


# rank top slow query 

```SQL 
-- query SQL 维度的数据
with query_tmp AS (
    SELECT
        user,
        query_duration_ms,
        normalized_query_hash,
        tables,
        read_rows,
        memory_usage,
        event_time 
    FROM clusterAllReplicas(xxxx, system.query_log)
    PREWHERE 
     (event_time >= (now() - toIntervalHour(6))) 
     AND 
      hasAny(databases, ['xxx', 'xxx']) 
       AND query_duration_ms > 20000 
    ORDER BY query_duration_ms DESC
    LIMIT 200 
) 
select toStartOfInterval(event_time, INTERVAL 1 HOUR)  AS data_day , 
  normalized_query_hash,tables, count(*) query_total, avg(query_duration_ms)  avg_duration_ms
  from 
  query_tmp 
group by 
data_day ,
normalized_query_hash , tables 
order by query_total desc , avg_duration_ms desc  

```


normalized_query_hash  SQL 语句的Hash编码，同一个SQL（不带参数）得到的编码是一样的，可以用该字段快速定位到是否位同一个SQL
query_duration_ms SQL 执行的时间长度（单位ms)

#  展示及报表
由于`system.query_log`属于系统表，不便于BI展示，也未缩小数据查询规模，每隔1H统计一次，将数据写入到一个新表：

```SQL

with query_tmp AS (
    SELECT
        user,
        query_duration_ms,
        normalized_query_hash,
        tables,
        read_rows,
        memory_usage,
        event_time 
    FROM clusterAllReplicas(xxx, system.query_log)
    PREWHERE 
      (event_time >= (now() - toIntervalHour(1))) 
     AND 
      hasAny(databases, ['xxx', 'xxx']) 
      AND query_duration_ms > 20000 
    ORDER BY query_duration_ms DESC
    LIMIT 200 
) 
INSERT INTO data_mock_dev.clickhouse_query_log_metrics_count(data_day,normalized_query_hash, 
tables , query_total ,avg_duration_ms) 
select toStartOfInterval(event_time, INTERVAL 1 HOUR)  AS data_day , 
  normalized_query_hash,tables, count(*) query_total, avg(query_duration_ms)  avg_duration_ms
  from 
  query_tmp 
group by 
data_day ,
normalized_query_hash , tables 
order by query_total desc , avg_duration_ms desc  

```
- 配置定时任务
```shell
  crontab -e 

# 每小时执行一次 

0 * * * * clickhouse-client -h 10.21.100.156 --port 9000 -u zzzz  --password  xxxx --queries-file  /data/schedule-task/count_query_log.sql 

```

- 效果展示

![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/2024/202503282031457.png)


- 参考
https://clickhouse.com/docs/operations/system-tables/query_log
