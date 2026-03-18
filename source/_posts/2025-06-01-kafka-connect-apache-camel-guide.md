---
title: 2025-06-01-kafka-connect-apache-camel-guide
excerpt: 2025-06-01-kafka-connect-apache-camel-guide
layout: post
date: 2025-12-15 11:57:54
tags:
categories:
---

# Kafka Connect Apache Camel Guide
在多云环境下，需要一个从AWS SQS到自建数仓的同步方案
```
AWS SQS --> Kafka Connect Apache Camel --> Kafka Topic --> ClickHouse Sink Connector --> ClickHouse --> Data API / BI Tool
```
Apache Camel Kafka Connector 是一个强大的工具，可以帮助我们将数据从各种源（如AWS SQS）传输到Kafka主题，然后再通过ClickHouse Sink Connector将数据写入ClickHouse数据库。以下是一个详细的指南，介绍如何使用Apache Camel Kafka Connector实现这一流程。

## 前提条件
- 已安装并配置Kafka集群。
- 已安装并配置ClickHouse数据库。
- 已安装Kafka Connect，并确保其可以访问Kafka集群和ClickHouse数据库。

- kafka version: 3.4.0+
- JDK version: 11+


## install Apache Camel Kafka Connector
cd  kafka-bin/plugins

wget https://repo.maven.apache.org/maven2/org/apache/camel/kafkaconnector/camel-aws-sqs-source-kafka-connector/4.14.0/camel-aws-sqs-source-kafka-connector-4.14.0-package.tar.gz


参考：
https://camel.apache.org/download/
connect list:
https://camel.apache.org/camel-kafka-connector/next/reference/index.html


## 备注
默认的轮询是500ms,在数据不密集时，可能产生大量的空轮循，浪费资源，可以适当调大轮询间隔时间，比如2000ms
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/2024/202512151401635.png)

```js
    // 距离下次轮询所选流还有多少毫秒, 2s 轮循一次
    "camel.kamelet.aws-sqs-source.delay":2000,
   // 等待时间，单位为秒，表示消费者在没有消息可用时等待的最长时间。
   "camel.kamelet.aws-sqs-source.waitTimeSeconds": "10",
    // 每次最多拉取的消息数量，默认值为 10，最大值为 10。
    "camel.kamelet.aws-sqs-source.maxMessagesPerPoll: "10",
     //如果启用贪婪模式，则如果上一次运行轮询了 1 条或多条消息，则会立即再次进行轮询。
    "camel.kamelet.aws-sqs-source.greedy":"true",
```
参考文档：
https://camel.apache.org/camel-kafka-connector/next/reference/connectors/camel-aws-sqs-source-kafka-source-connector.html

- kakfa connect json  配置参考
```js
{
  "name": "CamelAWSSQSSourceConnector",
  "config": {
    "connector.class": "org.apache.camel.kafkaconnector.CamelSourceConnector",
    "tasks.max": "1",
    "topics": "aws_sqs_topic",

    "camel.source.path.queueName": "your-sqs-queue-name",
    "camel.kamelet.aws-sqs-source.accessKey": "your-aws-access-key",
    "camel.kamelet.aws-sqs-source.secretKey": "your-aws-secret-key",
    "camel.kamelet.aws-sqs-source.region": "us-east-1",

    // 其他配置参数
    "camel.kamelet.aws-sqs-source.delay": "2000",
    "camel.kamelet.aws-sqs-source.waitTimeSeconds": "10",
    "camel.kamelet.aws-sqs-source.maxMessagesPerPoll": "10",
    "camel.kamelet.aws-sqs-source.greedy": "true"
  }
}
```
https://github.com/apache/camel-kafka-connector/blob/camel-kafka-connector-4.11.0/examples/CamelAWSSQSSourceConnector.properties

