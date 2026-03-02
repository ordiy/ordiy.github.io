---
layout: post
title: Kafka Connect Task UNKNOWN 状态修复与 Flink Savepoint 恢复指南
excerpt: "记录 Kafka Connect 任务进入 UNKNOWN 卡死状态时的 REST API 复位操作，以及 Flink 任务基于 S3 Savepoint 的快速停启命令。"
date: 2026-02-28 10:30:00
tags:
  - Kafka
  - Flink
  - Ops
categories:
  - tech
---

大数据基础平台在线上奔跑时，难免会遇到 Connector 组件罢工、以及流计算任务因底层环境突变需要快速恢复的情况。这篇简短的笔记记录并梳理了 **Kafka Connect 任务处在 UNKNOWN (卡死) 状态时的恢复操作手段**，以及 **Flink 挂载 S3 Savepoint 快速启停的操作命令**。

<!-- more -->

## 1. Kafka Connect: Task UNKNOWN 状态异常修复排查

在通过 Kafka Connect (如 Debezium CDC) 同步外部数据源时，如果在查状态时发现 Task 变为了未知 / 失败异常，可以采用如下 REST API 组合拳操作对其进行复位启停。

通常情况下，Kafka Connect Worker 被绑定在某个主机的指定端口（例如 `kafka-connect-host:8083`）：

### 查看当前详细状态与 Tasks
遇到异常首先通过 `status` 以及 `tasks` 服务路径看清任务的全貌：
```bash
KC_HOST="kafka-connect-host:8083"
CONNECTOR="your-connector-name"

# 查看 Connector 状态
curl -X GET "http://${KC_HOST}/connectors/${CONNECTOR}/status"

# 查看该连接器具体的下属 tasks
curl -X GET "http://${KC_HOST}/connectors/${CONNECTOR}/tasks"
```

### 硬干预复位（Stop & Resume/Restart）
处于 UNKNOWN 的 Task 可能陷入挂起僵局，单纯重启未必生效，往往需要强制 Stop 收回资源后重新 Resume。

```bash
# 1. 强制终止任务
curl -X PUT "http://${KC_HOST}/connectors/${CONNECTOR}/stop"

# (此时再次查状态应该变为 STOPPED 及 tasks 列表为空)

# 2. 重新拉起整个 job 以及其 tasks
curl -X PUT "http://${KC_HOST}/connectors/${CONNECTOR}/resume"

# (或者选择软重启)
curl -X POST "http://${KC_HOST}/connectors/${CONNECTOR}/restart?includeTasks=true"
```
当配置和连接没有硬伤时，操作 `Resume` 后查询 status，Connector 与 Tasks 的状态应当均回归到 `"RUNNING"`。

---

## 2. Flink CLI: 任务启停与基于 S3 的 Savepoint 恢复

流处理任务随时有着升级和回放的需要。妥善使用 Savepoint 进行任务“快照”和无缝恢复，是 Flink 操作中的基石。在具备高可用且挂载了 S3 集群的场景下，可以随时触发或者打着标记停机。

### 触发与携带 Savepoint 停机

```bash
# 查询获取任务的 Job ID
/data/flink-bin/bin/flink list

# 对运行中的任务【手工】触发一个 Savepoint 到 S3 对象存储（任务不停止）
/data/flink-bin/bin/flink savepoint b64d43cf15694468fd1a048c4cc22231 \
    s3://data-flink-job-manager-ha-file-store-us-east01/pro-oci-flink-cluster/savepoints/

# 如果需要进行代码升级或配置变更，可以直接使用带有 Savepoint 的方式关掉任务
# 注: 更高版本推荐使用 stop 命令代替 cancel
/data/flink-bin/bin/flink cancel --withSavepoint \
    s3p://data-flink-job-manager-ha-file-store-us-east01/pro-oci-flink-cluster/savepoints/ \
    b64d43cf15694468fd1a048c4cc22231
```
成功 `cancel` 后会输出带有类似 `savepoint-b64d43-b3ad0f2ba0a6` 为后缀的文件确切路径。

### 基于 Savepoint 恢复流处理任务

在新版本的包（或者调优了代码的 Jar 包）进行回滚/重启时，用 `-s` 参数指定上述已生成的 Checkpoint / Savepoint 路径，配合 Adaptive Scheduler 配置让集群自己接管并行度下限：

```bash
export FLINK_HOME=/data/flink-bin

/data/flink-bin/bin/flink run \
    -s s3p://data-flink-job-manager-ha-file-store-us-east01/pro-oci-flink-cluster/savepoints/savepoint-b64d43-b3ad0f2ba0a6 \
    -Djobmanager.scheduler=adaptive \
    -Djobmanager.adaptive-scheduler.min-parallelism=1 \
    -Djobmanager.adaptive-scheduler.max-parallelism=60 \
    -c io.github.streamingwithflink.chapter1.AverageSensorReadings \
    /data/data-examples/examples-scala.jar
```
*提示：S3 协议如果在 Flink 内预设了 Presto 也可以使用 `s3p://` 作为 Schema。*