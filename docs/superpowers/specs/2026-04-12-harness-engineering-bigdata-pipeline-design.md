---
name: Harness Engineering 大数据管道落地实践博文设计
description: 博文规格文档 - 将 Harness Engineering 方法论应用于 S3/SQS→Kafka→Flink→ClickHouse 数据管道
type: spec
date: 2026-04-12
---

# Spec: Harness Engineering 在大数据管道的落地实践

## 目标

写一篇面向大数据工程师的中文技术博文，以「问题驱动」叙事方式，将 Harness Engineering 的
Guides（前馈）/ Sensors（反馈）方法论映射到 `S3/SQS → Kafka → Flink → ClickHouse` 管道的
每个节点，给出具体的工程设计要点。

## 受众

大数据工程师：熟悉 Flink/Kafka/ClickHouse，需要「为什么要这样设计」+ 关键配置点。

## 文章元数据

- 标题：`Harness Engineering 在大数据管道的落地实践：从凌晨3点的报警说起`
- 文件名：`2026-04-12-harness-engineering-bigdata-pipeline.md`
- Tags: [Harness Engineering, Flink, Kafka, ClickHouse, S3, SQS, 大数据, 数据工程]
- Category: tech

## 结构

### 引言
场景：凌晨3点 ClickHouse 告警，数据条数少了17万，问题节点不明。
引出：Pipeline = Data + Harness，Harness 是让数据异常「前可预防、后可自愈」的控制体系。

### 节点1：S3/SQS — "消息幽灵"
- 痛点：重复消费 or 丢失
- Guides: Schema Contract、SQS 幂等键、S3 文件命名规范
- Sensors: DLQ 深度告警、消费位移追踪、入 Kafka 条数对账

### 节点2：Kafka — "Lag 雪崩"
- 痛点：消费者 Lag 突然积压到百万
- Guides: 分区数规范、Consumer Group 隔离、消息 TTL 策略
- Sensors: consumer_lag 告警、热分区检测、Broker 磁盘水位

### 节点3：Flink — "Checkpoint 黑洞"
- 痛点：OOM 重启后窗口数据重复计算
- Guides: 算子拓扑模板、状态 TTL、RocksDB+MiniBatch 标准参数
- Sensors: Checkpoint 时长/失败率、背压率、GC 停顿、算子吞吐比

### 节点4：ClickHouse Sink — "写入成功≠正确"
- 痛点：Sink 显示成功但数据缺失/重复
- Guides: 分区键+排序键约束、async_insert 幂等重试、表引擎选型规范
- Sensors: system.query_log 慢写检测、写入失败率、副本延迟、Parts 数量

### 节点5：端到端对账 — "数字消失了"
- 痛点：报表数据每天都比预期少，不知道哪个节点丢失
- 设计: 每节点埋水印计数器，pipeline_audit_log 表 + 定时对账 SQL

### 结尾
- 回到凌晨3点场景：Harness 就位后告警链路
- 速查表：每节点最关键的1个 Guide + 1个 Sensor
- 结论：Harness Engineering 在大数据的本质——把「数据可信」从人工巡检变成系统自证

## 视觉元素
- 全链路 Mermaid 总览图（引言后）
- 每节点 Mermaid 流程图（Guides+Sensors 闭环）
- 结尾速查表（Markdown 表格）

## 不包含
- 具体的 Prometheus/Grafana 配置细节（篇幅控制）
- Kafka Connect 配置（已有独立文章）
- Flink MiniBatch 详细参数（已有独立文章，交叉引用即可）
