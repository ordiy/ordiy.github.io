---
title: Flink使用经验总结-1
excerpt: Flink遇到问题处理，以及部分场景的工具使用经验总结。
layout: post
date: 2025-07-09 10:38:33
tags:
 - Flink
 - FlinkSQL
 - Data
 - Debug
categories:
 - tech
---

# 经验总结

## flink kafka connect 需要注意的问题

### lib 目录jar 不要同时存在多个`connector-kafka`
`$FLINK_HOME/lib/`不要同时存在`flink-sql-connector-kafka-1.17.2.jar`和`flink-connector-kafka-1.17.2.jar`

- `ERROR`
使用`sql-client.sh`时或者TableAPI时候会遇到ERROR:

```js
[ERROR] Could not execute SQL statement. Reason:
java.lang.ClassNotFoundException: org.apache.kafka.clients.consumer.OffsetResetStrategy
```
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/2024/202507091045492.png)


## flink run 时引入多个jar package 

这里通过 `--classpath` 引入一个第三方 jar ,解决依赖问题
多个jar`--classpath file:///path_to_jar1:file:///path_to_jar2`
```shell
$FLINK_HOME/bin/flink run -p 4 \
      	-c com.xxx.xxx.xxx.FlinkSQLCmmExecuteByFileJob \
      	--classpath file:///data/application-flink-job-task-dir/lib/flink-sql-connector-kafka-1.17.2.jar \
     	/data/application-flink-job-task-dir/lib/flink-table-sql-app-data-commons-start-application-1.0.3-0708-sql-shard.jar \
     	--job_name "flink-sql-cloudflare-worker-log" \
      	--execute_sql_file_path sql-dir/flink-sql-cloudflare-woker-log-transform.sql
```

## flink sql-client.sh 引入jar or mutil jar 

```shell
# 单个jar 直接指向 , 可以多次指定
$FLINK_HOME/bin/sql-client.sh --jar ./lib/xxxx.jar 

#  多个jar 执行jar 所在的parent dir 
$FLINK_HOME/bin/sql-client.sh -l ./lib-extent-dir 
```

### 场景1 执行SQL
```shell
#指定依赖 执行SQL
# 适用于 指定自定义UDF jar等场景

/data/flink-bin/bin/sql-client.sh embedded \
--file ./sql-user-tags-v2/flink-sql-user-tags-v2-user-init-first-exposure.sql \
--jar /data/application-flink-job-task-dir/lib/flink-sql-connector-kafka-1.17.2.jar

```

### 场景2  自定义init file 
```shell
# init sql + execute sql 

# init sql 
vim  sql-client-init-sql.sql 


SET 'parallelism.default' = '3';
SET 'pipeline.name' = 'SqlJob';
SET 'sql-client.execution.result-mode' = 'TABLEAU';


# sql file 
vim  sql-client-test-sql-01.sql

SELECT
  name,
  COUNT(*) AS cnt
FROM
  (VALUES ('Bob'), ('Alice'), ('Greg'), ('Bob')) AS NameTable(name)
GROUP BY name;


# 执行文件SQL
 $FLINK_HOME/bin/sql-client.sh embedded \
 --init ./tmp_sql/sql-client-init-sql.sql \
  --file ./sql-client-test-sql-01.sql 

```