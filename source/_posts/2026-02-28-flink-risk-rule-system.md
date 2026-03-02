---
layout: post
title: 基于 Flink 构建生产级广告过滤风控流系统实践
excerpt: "记录在生产环境部署一个基于 Kafka + Redis 的 Flink 风控过滤作业，包括实机参数配置、多条优化规则的设计思路与业务部署实践。"
date: 2026-02-28 15:45:00
tags:
  - Flink
  - Kafka
  - Redis
categories:
  - tech
---

广告业务中由于爬虫、测试或者是无效终端的发起，每秒常常产生数以万计的脏数据访问。依靠传统离线跑批去清理已经跟不上广告系统的时效结算周期要求了。

本文汇总了我们在生产机上发布一个代号为 `flink-etl-point-link-job` 的底层强力过滤风控流项目的实际发布情况和业务要求。

<!-- more -->

## 1. 生产环境部署参数透视
在实机进行拉起这种强规则拦截作业时，需要极强的网络稳定保障并与 Kafka 、强大的多核心 Redis 集群构成网状闭环。我们在生产执行的经典提交模式如下：

```bash
/data/flink-1.17.2/bin/flink run \
  -m flink-jobmanager-host:8081 -d \
  -c com.example.data.flink.RiskRuleStreamJob \
  /data/jars/flink-etl-job.jar \
  --src_kafka_broker kafka-broker-1:9092,kafka-broker-2:9092,kafka-broker-3:9092 \
  --src_topic_name cdc-src-jdbc-pwa_event_point_log_2412 \
  --src_consumer_group flink-risk-rule-cgroup-04 \
  --sink_kafka_broker kafka-broker-1:9092,kafka-broker-2:9092,kafka-broker-3:9092 \
  --sink_topic sink-risk-rule-filter-point-log-dev-03 \
  --parallelism 12 \
  --redis_nodes redis-node-1:6379,redis-node-2:6379,redis-node-3:6379,redis-node-4:6379,redis-node-5:6379,redis-node-6:6379,redis-node-7:6379,redis-node-8:6379 \
  --job_name flink-etl-dev-1226-p06 
```
这个作业赋予了至少 `12` 的并发度去直接消耗庞大的入口流数据（源于 MySQL Debezium 的数据泵出），而通过参数注入的 `redis_nodes` 一共有 8 个分片，承接起了所有规则维表中超高速的缓存键值查阅。

## 2. 核心业务要求与规则引擎抽象
在这个数据过滤与判定系统中，并不是简单的流流去重，我们为系统指定了一个带时间窗口（比如 10 分钟边界）和多条件的防御阀门。

我们摘取其中的几个生产黄金控制规则：
1. **因果倒置判定策略**：对于埋点号代表末端的事件（比如付款等 21003 事件），必须要依赖此用户的上游 UUID 是否有先产生前端展示或初次访问（21001事件）。如果它在 Redis / 内部状态里搜不到前置产生链记录，直接阻断下流并将此 21003 数据行打上 `DIRTY_A` 的废弃或伪造标签拦截。
2. **频率熔断策略（防刷）**：同一个设备或者用户的 UUID 如果在设定的短时内发生多次相同的重要末向操作（21003等），则首次落库而后续行为直接认定为不入库作废。这能过滤掉机器人无意义地狂刷按键或者自动化 UI 测试脚本的脏乱。
3. **参数规整隔离**：专门针对 Facebook 的 `fbclid`、Google 的 `gclid` 等进行去重和打平合并提取。
4. **地域/爬虫包排查封锁**：明确阻隔所有 `language=ZH-CN`（基于只开展海外业务的特征屏蔽），或者基于 `ua_browser` 解析判定是微信、百度搜索引擎蜘蛛以及国内应用自带 WebView 的套壳访问，将其拒在主库门外。

这种依托 Flink 本身带有的大状态窗口配合着 Redis 外部辅助表的验证方案，将原本被各种无效包塞爆和污染的下游指标库（如 ClickHouse）清理得非常通透纯净。使得下游 BI 及分析师无需在书写极度耗时的复杂 SQL 过滤逻辑！