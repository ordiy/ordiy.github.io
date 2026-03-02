---
title:  Kafka Connect 配置source task and sink task 操作手册
excerpt: 指引配置不同组件的Kakfa Connect sink/source task，以及注意事项
layout: post
date: 2025-04-29 20:17:01
tags: 
 - kafka
 - kafka connect 
 - CDC
categories:
 - tech 
- Data
---

# kafka connect 
 Kafka Connect 是一种工具，用于在 Apache Kafka® 和其他数据系统之间可扩展且可靠地流式传输数据。它使快速定义将大型数据集移入和移出 Kafka 的连接器变得简单。Kafka Connect 可以将整个数据库或所有应用程序服务器的指标收集到 Kafka 主题中，从而使数据可用于低延迟的流处理。导出连接器可以将 Kafka 主题中的数据传输到二级索引（如 Elasticsearch）或批处理系统（如 Hadoop）以进行离线分析。
 - 特点：
  以数据为中心的管道 ：Connect 使用有意义的数据抽象将数据拉取或推送到 Kafka。
  灵活性和可扩展性 ：在单个节点（独立）或扩展到组织范围的服务（分布式）上连接流式和面向批处理的系统。
  可重用性和可扩展性 ：Connect 利用现有连接器或扩展它们以满足您的需求，并缩短生产时间。
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/2024/202507101946194.png)


#  source Connectors

## jdbc source Connectors

config  一个insert + update 的增量数据CDC :

```json
{
    "name": "cdc-jdbc-src-task001-{my_table_name}-t250526-01",
    "config": {
       "connector.class": "io.confluent.connect.jdbc.JdbcSourceConnector",
       "tasks.max": "1",

       "connection.url": "jdbc:mysql://xxxxx:3306/xxx",
       "connection.user": "xxx",
       "connection.password": "xxxx",

        "mode": "timestamp+incrementing",
        "incrementing.column.name": "id",
        "timestamp.column.name": "updated_at",
        "timestamp.initial": "1",

        "topic.prefix": "cdc-rds-oic-",
        "poll.interval.ms": "60000",

        "validate.non.null": "false",

        "table.whitelist": "my_table_name",
        "transforms":"createKey,extractInt",
        "transforms.createKey.type":"org.apache.kafka.connect.transforms.ValueToKey",
        "transforms.createKey.fields":"id",
        "transforms.extractInt.type":"org.apache.kafka.connect.transforms.ExtractField$Key",
        "transforms.extractInt.field":"id",

        "topic.creation.default.partitions":3,
        "topic.creation.default.replication.factor":2,
        "topic.creation.default.compression.type":"zstd",
        "topic.creation.default.cleanup.policy": "compact",

        "value.converter": "org.apache.kafka.connect.json.JsonConverter",
        "value.converter.schemas.enable": "false"
    }
}
```


# sink Connectors

## clickhouse sink Connectors

config sink 
```json
{
      "transforms": "InsertTimestamp,keyToValue,TimestampConverterEnd,InsertDefault,TimestampConverterDeleted",
      "transforms.InsertTimestamp.type": "org.apache.kafka.connect.transforms.InsertField$Value",
      "transforms.InsertTimestamp.timestamp.field": "msg_event_time",
      "transforms.keyToValue.type": "com.clickhouse.kafka.connect.transforms.KeyToValue",
      "transforms.keyToValue.field": "id",

        "transforms.TimestampConverterEnd.type":"org.apache.kafka.connect.transforms.TimestampConverter$Value",
        "transforms.TimestampConverterEnd.field":"created_at",
        "transforms.TimestampConverterEnd.format":"yyyy-MM-dd'T'HH:mm:ss.SSSX",
        "transforms.TimestampConverterEnd.target.type":"unix",

    # deleted_at 可能为空, 替换为默认值
    "transforms.InsertDefault.type": "org.apache.kafka.connect.transforms.InsertField$Value",
    "transforms.InsertDefault.static.field": "device_first_seen_at",
    "transforms.InsertDefault.static.value": "1970-01-01T00:00:00.000Z",
   "transforms.InsertDefault.skip.if.exists": false,

       
    #  字符串转换为 long timestamp 
    "transforms.TimestampConverterDeleted.field": "device_first_seen_at",
    "transforms.TimestampConverterDeleted.format": "yyyy-MM-dd'T'HH:mm:ss.SSSX",
    "transforms.TimestampConverterDeleted.target.type": "unix",
    "transforms.TimestampConverterDeleted.type": "org.apache.kafka.connect.transforms.TimestampConverter$Value"
}
```