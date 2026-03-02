---
title: FlinkSQL Error — OffsetOutOfRangeException
excerpt: "本文记录了一次 FlinkSQL 消费 Kafka 时遇到的 OffsetOutOfRangeException 错误。该错误是由于 Flink 作业尝试从一个已不存在的 Kafka offset 开始消费数据导致的。根本原因是 Kafka topic 的数据已根据保留策略被清理，而 Flink consumer group 却被重置到了一个过旧的时间点，其对应的 offset 已经失效。"
layout: post
date: 2025-07-15 14:57:43
tags:
 - FlinkSQL
 - Data
 - debug 
categories:
 - tech
---

# error cause
出现`OffsetOutOfRangeException`错误，日志如下：
```js
025-07-14 12:00:32,165 INFO  org.apache.kafka.clients.consumer.internals.Fetcher          [] - [Consumer clientId=fink-xxx-xxx-xxx-prod-2, groupId=fink-xxx-xxx-xxx-prod] Fetch position FetchPosition{offset=447013888, offsetEpoch=Optional.empty, currentLeader=LeaderAndEpoch{leader=Optional[xx.xx.100.75:9092 (id: 2 rack: null)], epoch=14}} is out of range for partition flink-src-topic-data-prod-3, raising error to the application since no reset policy is configured
2025-07-14 12:00:32,165 ERROR org.apache.flink.connector.base.source.reader.fetcher.SplitFetcherManager [] - Received uncaught exception.
java.lang.RuntimeException: SplitFetcher thread 0 received unexpected exception while polling the records
	at org.apache.flink.connector.base.source.reader.fetcher.SplitFetcher.runOnce(SplitFetcher.java:165) ~[flink-connector-base-1.17.2.jar:1.17.2]
	at org.apache.flink.connector.base.source.reader.fetcher.SplitFetcher.run(SplitFetcher.java:114) [flink-connector-base-1.17.2.jar:1.17.2]
	at java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:515) [?:?]
	at java.util.concurrent.FutureTask.run(FutureTask.java:264) [?:?]
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1128) [?:?]
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:628) [?:?]
	at java.lang.Thread.run(Thread.java:829) [?:?]
Caused by: org.apache.kafka.clients.consumer.OffsetOutOfRangeException: Fetch position FetchPosition{offset=447013888, offsetEpoch=Optional.empty, currentLeader=LeaderAndEpoch{leader=Optional[xx.xx.100.75:9092 (id: 2 rack: null)], epoch=14}} is out of range for partition flink-src-topic-data-prod-3
	at org.apache.kafka.clients.consumer.internals.Fetcher.handleOffsetOutOfRange(Fetcher.java:1405) ~[kafka-clients-3.2.3.jar:?]
	at org.apache.kafka.clients.consumer.internals.Fetcher.initializeCompletedFetch(Fetcher.java:1357) ~[kafka-clients-3.2.3.jar:?]
	at org.apache.kafka.clients.consumer.internals.Fetcher.collectFetch(Fetcher.java:658) ~[kafka-clients-3.2.3.jar:?]
	at org.apache.kafka.clients.consumer.KafkaConsumer.pollForFetches(KafkaConsumer.java:1286) ~[kafka-clients-3.2.3.jar:?]
	at org.apache.kafka.clients.consumer.KafkaConsumer.poll(KafkaConsumer.java:1242) ~[kafka-clients-3.2.3.jar:?]
	at org.apache.kafka.clients.consumer.KafkaConsumer.poll(KafkaConsumer.java:1215) ~[kafka-clients-3.2.3.jar:?]
	at org.apache.flink.connector.kafka.source.reader.KafkaPartitionSplitReader.fetch(KafkaPartitionSplitReader.java:101) ~[flink-connector-kafka-1.17.2.jar:1.17.2]
	at org.apache.flink.connector.base.source.reader.fetcher.FetchTask.run(FetchTask.java:58) ~[flink-connector-base-1.17.2.jar:1.17.2]
	at org.apache.flink.connector.base.source.reader.fetcher.SplitFetcher.runOnce(SplitFetcher.java:162) ~[flink-connector-base-1.17.2.jar:1.17.2]
	... 6 more
2025-07-14 12:00:32,165 INFO  org.apache.kafka.clients.consumer.internals.ConsumerCoordinator [] - [Consumer clientId=fink-xxx-xxx-xxx-prod-2, groupId=fink-xxx-xxx-xxx-prod] Resetting generation and member id due to: consumer pro-actively leaving the group
2025-07-14 12:00:32,165 INFO  org.apache.kafka.clients.consumer.internals.ConsumerCoordinator [] - [Consumer clientId=fink-xxx-xxx-xxx-prod-2, groupId=fink-xxx-xxx-xxx-prod] Request joining group due to: consumer pro-actively leaving the group
2025-07-14 12:00:32,165 INFO  org.apache.kafka.common.metrics.Metrics                      [] - Metrics scheduler closed
2025-07-14 12:00:32,165 INFO  org.apache.kafka.common.metrics.Metrics                      [] - Closing reporter org.apache.kafka.common.metrics.JmxReporter
2025-07-14 12:00:32,165 INFO  org.apache.kafka.common.metrics.Metrics                      [] - Metrics reporters closed
2025-07-14 12:00:32,166 INFO  org.apache.kafka.common.utils.AppInfoParser                  [] - App info kafka.consumer for fink-xxx-xxx-xxx-prod-2 unregistered
2025-07-14 12:00:32,166 INFO  org.apache.flink.connector.base.source.reader.fetcher.SplitFetcher [] - Split fetcher 0 exited.
2025-07-14 12:00:32,173 INFO  org.apache.flink.connector.base.source.reader.SourceReaderBase [] - Closing Source Reader.
2025-07-14 12:00:32,174 WARN  org.apache.flink.runtime.taskmanager.Task                    [] - Source: src_event_point_source_v2[1] -> Calc[2] (3/3)#140 (b4261ffe742ad92556738fcad2166ca0_cbc357ccb763df2852fee8c4fc7d55f2_2_140) switched from RUNNING to FAILED with failure cause:
java.lang.RuntimeException: One or more fetchers have encountered exception
	at org.apache.flink.connector.base.source.reader.fetcher.SplitFetcherManager.checkErrors(SplitFetcherManager.java:261) ~[flink-connector-base-1.17.2.jar:1.17.2]
	at org.apache.flink.connector.base.source.reader.SourceReaderBase.getNextFetch(SourceReaderBase.java:169) ~[flink-connector-base-1.17.2.jar:1.17.2]
	at org.apache.flink.connector.base.source.reader.SourceReaderBase.pollNext(SourceReaderBase.java:131) ~[flink-connector-base-1.17.2.jar:1.17.2]
	at org.apache.flink.connector.base.source.reader.SourceReaderBase.pollNext(SourceReaderBase.java:157) ~[flink-connector-base-1.17.2.jar:1.17.2]
	at org.apache.flink.streaming.api.operators.SourceOperator.emitNext(SourceOperator.java:419) ~[flink-dist-1.17.2.jar:1.17.2]
	at org.apache.flink.streaming.runtime.io.StreamTaskSourceInput.emitNext(StreamTaskSourceInput.java:68) ~[flink-dist-1.17.2.jar:1.17.2]
	at org.apache.flink.streaming.runtime.io.StreamOneInputProcessor.processInput(StreamOneInputProcessor.java:65) ~[flink-dist-1.17.2.jar:1.17.2]
	at org.apache.flink.streaming.runtime.tasks.StreamTask.processInput(StreamTask.java:550) ~[flink-dist-1.17.2.jar:1.17.2]
	at org.apache.flink.streaming.runtime.tasks.mailbox.MailboxProcessor.runMailboxLoop(MailboxProcessor.java:231) ~[flink-dist-1.17.2.jar:1.17.2]
	at org.apache.flink.streaming.runtime.tasks.StreamTask.runMailboxLoop(StreamTask.java:839) ~[flink-dist-1.17.2.jar:1.17.2]
	at org.apache.flink.streaming.runtime.tasks.StreamTask.invoke(StreamTask.java:788) ~[flink-dist-1.17.2.jar:1.17.2]
	at org.apache.flink.runtime.taskmanager.Task.runWithSystemExitMonitoring(Task.java:952) ~[flink-dist-1.17.2.jar:1.17.2]
	at org.apache.flink.runtime.taskmanager.Task.restoreAndInvoke(Task.java:931) [flink-dist-1.17.2.jar:1.17.2]
	at org.apache.flink.runtime.taskmanager.Task.doRun(Task.java:745) [flink-dist-1.17.2.jar:1.17.2]
	at org.apache.flink.runtime.taskmanager.Task.run(Task.java:562) [flink-dist-1.17.2.jar:1.17.2]
	at java.lang.Thread.run(Thread.java:829) [?:?]
Caused by: java.lang.RuntimeException: SplitFetcher thread 0 received unexpected exception while polling the records
	at org.apache.flink.connector.base.source.reader.fetcher.SplitFetcher.runOnce(SplitFetcher.java:165) ~[flink-connector-base-1.17.2.jar:1.17.2]
	at org.apache.flink.connector.base.source.reader.fetcher.SplitFetcher.run(SplitFetcher.java:114) ~[flink-connector-base-1.17.2.jar:1.17.2]
	at java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:515) ~[?:?]
	at java.util.concurrent.FutureTask.run(FutureTask.java:264) ~[?:?]
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1128) ~[?:?]
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:628) ~[?:?]
	... 1 more
Caused by: org.apache.kafka.clients.consumer.OffsetOutOfRangeException: Fetch position FetchPosition{offset=447013888, offsetEpoch=Optional.empty, currentLeader=LeaderAndEpoch{leader=Optional[xx.xx.100.75:9092 (id: 2 rack: null)], epoch=14}} is out of range for partition flink-src-topic-data-prod-3
	at org.apache.kafka.clients.consumer.internals.Fetcher.handleOffsetOutOfRange(Fetcher.java:1405) ~[kafka-clients-3.2.3.jar:?]
	at org.apache.kafka.clients.consumer.internals.Fetcher.initializeCompletedFetch(Fetcher.java:1357) ~[kafka-clients-3.2.3.jar:?]
	at org.apache.kafka.clients.consumer.internals.Fetcher.collectFetch(Fetcher.java:658) ~[kafka-clients-3.2.3.jar:?]
	at org.apache.kafka.clients.consumer.KafkaConsumer.pollForFetches(KafkaConsumer.java:1286) ~[kafka-clients-3.2.3.jar:?]
	at org.apache.kafka.clients.consumer.KafkaConsumer.poll(KafkaConsumer.java:1242) ~[kafka-clients-3.2.3.jar:?]
	at org.apache.kafka.clients.consumer.KafkaConsumer.poll(KafkaConsumer.java:1215) ~[kafka-clients-3.2.3.jar:?]
	at org.apache.flink.connector.kafka.source.reader.KafkaPartitionSplitReader.fetch(KafkaPartitionSplitReader.java:101) ~[flink-connector-kafka-1.17.2.jar:1.17.2]
	at org.apache.flink.connector.base.source.reader.fetcher.FetchTask.run(FetchTask.java:58) ~[flink-connector-base-1.17.2.jar:1.17.2]
	at org.apache.flink.connector.base.source.reader.fetcher.SplitFetcher.runOnce(SplitFetcher.java:162) ~[flink-connector-base-1.17.2.jar:1.17.2]
	at org.apache.flink.connector.base.source.reader.fetcher.SplitFetcher.run(SplitFetcher.java:114) ~[flink-connector-base-1.17.2.jar:1.17.2]
	at java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:515) ~[?:?]
	at java.util.concurrent.FutureTask.run(FutureTask.java:264) ~[?:?]
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1128) ~[?:?]
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:628) ~[?:?]
	... 1 more
2025-07-14 12:00:32,174 INFO  org.apache.flink.runtime.taskmanager.Task                    [] - Freeing task resources for Source: src_event_point_source_v2[1] -> Calc[2] (3/3)#140 (b4261ffe742ad92556738fcad2166ca0_cbc357ccb763df2852fee8c4fc7d55f2_2_140).
2025-07-14 12:00:32,175 INFO  org.apache.flink.runtime.taskexecutor.TaskExecutor           [] - Un-registering task and sending final execution state FAILED to JobManager for task Source: src_event_point_source_v2[1] -> Calc[2] (3/3)#140 

```




# kafka topic properties 
```js
cleanup.policy=delete
compression.gzip.level=-1
compression.lz4.level=9
compression.type=zstd
compression.zstd.level=3
delete.retention.ms=3456000000
file.delete.delay.ms=60000
flush.messages=9223372036854775807
flush.ms=9223372036854775807
follower.replication.throttled.replicas=
index.interval.bytes=4096
leader.replication.throttled.replicas=
local.retention.bytes=-2
local.retention.ms=-2
max.compaction.lag.ms=9223372036854775807
max.message.bytes=1048588
message.downconversion.enable=true
message.format.version=3.0-IV1
message.timestamp.after.max.ms=9223372036854775807
message.timestamp.before.max.ms=9223372036854775807
message.timestamp.difference.max.ms=9223372036854775807
message.timestamp.type=CreateTime
min.cleanable.dirty.ratio=0.7
min.compaction.lag.ms=60000
min.insync.replicas=1
preallocate=false
remote.storage.enable=false
retention.bytes=-1
retention.ms=3456000000
segment.bytes=1073741824
segment.index.bytes=10485760
segment.jitter.ms=0
segment.ms=604800000
unclean.leader.election.enable=false
```

# 操作offset命令
```shell
 /data/kafka-bin/bin/kafka-consumer-groups.sh  --bootstrap-server xx.xx.100.21:9092,xx.xx.100.75:9092,xx.xx.100.232:9092  --group fink-xxx-xxx-xxx-prod   --describe
/data/kafka-bin/bin/kafka-consumer-groups.sh  --bootstrap-server xx.xx.100.21:9092,xx.xx.100.75:9092,xx.xx.100.232:9092  --group fink-xxx-xxx-xxx-prod   --describe

Consumer group 'fink-xxx-xxx-xxx-prod' has no active members.

GROUP                                      TOPIC                                PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID     HOST            CLIENT-ID
fink-xxx-xxx-xxx-prod flink-src-topic-data-prod 1          559298895       625483460       66184565        -               -               -
fink-xxx-xxx-xxx-prod flink-src-topic-data-prod 2          559358558       625545458       66186900        -               -               -
fink-xxx-xxx-xxx-prod flink-src-topic-data-prod 0          559357644       625537537       66179893        -               -               -
fink-xxx-xxx-xxx-prod flink-src-topic-data-prod 5          559348549       625522842       66174293        -               -               -
fink-xxx-xxx-xxx-prod flink-src-topic-data-prod 3          559359386       625540063       66180677        -               -               -
fink-xxx-xxx-xxx-prod flink-src-topic-data-prod 4          559353695       625535243       66181548        -               -               -
```

# 原因
我使用了 reset offset 到 指定日期
```shell

/data/kafka-bin/bin/kafka-consumer-groups.sh \
 --bootstrap-server xx.xx.100.21:9092,xx.xx.100.75:9092,xx.xx.100.232:9092 \
        --topic flink-src-topic-data-prod \
        --group fink-xxx-xxx-xxx-prod \
        --reset-offsets \
        --to-datetime "2025-06-20T00:00:00.000" \
```

这个日期的数据已经被清理了,导致读取offset失败

## 总结
根据错误信息和 Kafka 的保留策略，推测出以下原因：
1. Flink 作业被重置到了一个过旧的时间点，导致其对应的 offset 已经失效。
2. Kafka topic 的数据已根据保留策略被清理，导致无法找到对应的 offset。
3. 不建议手动操作offset，尤其是重置到一个较早的时间点，这可能会导致消费失败或数据丢失`（选择latest 或 earliest 相对安全一些）`