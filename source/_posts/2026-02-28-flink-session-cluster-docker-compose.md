---
layout: post
title: 使用 Docker Compose 快速搭建 Flink Session 集群
excerpt: "提供一份可直接运行的 docker-compose.yml，在本地开发环境快速拉起带 Web UI 的 Flink Session Cluster，方便调试 Flink SQL 和 UDF。"
date: 2026-02-28 15:15:00
tags:
  - Docker
  - Flink
categories:
  - tech
---

每次开发好的 Flink UDF 或是复杂的 Flink SQL 在本地直接打包往往无从下手测试其任务连调表现。自己搭建一个物理或裸虚拟机 Standalone 的集群又非常麻烦。因此，直接在个人开发环境下凭借 `docker-compose` 起一套带有 Web UI 且可进入 SQL 客户端的 Flink Session Cluster 是每个大数据开发的必备技能。

本文提供一份极简可运行的 yaml 配置（以 `1.17.2` 版本为主流）。

<!-- more -->

## 1. 关键的 Compose YAML 文件

创建一个单纯的空文件夹并写入 `docker-compose.yml`，架构极为明晰：即分配出一个 `jobmanager` （调度与 UI 入口中心）挂载出物理端口，并配套两个 `taskmanager` 来作为计算资源分配节点。

```yaml
version: '3.7'

services:
  jobmanager:
    # 搭配 Scala 2.12 和 Java 11
    image: flink:1.17.2-scala_2.12-java11
    hostname: jobmanager
    container_name: jobmanager
    ports:
      # 将 Flink Web 暴露到本机的 18081 用以避免和其它 8081 冲突
      - "18081:8081"  
    environment:
      - JOB_MANAGER_RPC_ADDRESS=jobmanager
    command: jobmanager
    networks:
      - flink-network

  taskmanager:
    image: flink:1.17.2-scala_2.12-java11
    hostname: taskmanager
    container_name: taskmanager
    depends_on:
      - jobmanager
    environment:
      - JOB_MANAGER_RPC_ADDRESS=jobmanager
    command: taskmanager
    networks:
      - flink-network

  taskmanager2:
    image: flink:1.17.2-scala_2.12-java11
    hostname: taskmanager2
    container_name: taskmanager2
    depends_on:
      - jobmanager
    environment:
      - JOB_MANAGER_RPC_ADDRESS=jobmanager
    command: taskmanager
    networks:
      - flink-network

networks:
  flink-network:
    driver: bridge
```

## 2. 启停交互与进入环境操作

通过一条命令拉组并使集群挂入后台运行：
```bash
docker compose -f ./docker-compose.yml up -d
```

### 检测与查看
完成拉起后，本地即可通过浏览器（由于映射被重写了端口）或者单纯的 HTTP 命令试探其存活状态：
```bash
curl http://localhost:18081 
```

### 进入原生的 SQL-Client
要想测试手写的 Flink SQL 各种 `CREATE TABLE` 等建查语态，我们仅需直接穿透到 `jobmanager` 容器里去分配一个客户端工具终端。因为都在一个内部的 bridge network 中，它是直通主服务大脑的。
```bash
docker exec -it jobmanager /opt/flink/bin/sql-client.sh
```

进入后，一个原汁原味的测试向 `Session Cluster` 就诞生在你的个人电脑中了。使用 `docker compose down` 亦可无污染一键终结销毁。

### 补充
如果需要把jar包copy到容器里进行测试，可以先把jar包放在当前目录下，然后执行：
```bash
docker cp your-flink-job.jar jobmanager:/opt/flink/usrlib/
```