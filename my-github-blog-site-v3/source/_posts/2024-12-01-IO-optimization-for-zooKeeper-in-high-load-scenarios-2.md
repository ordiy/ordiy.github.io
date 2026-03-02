---
layout: post
title: Optimization for ZooKeeper in High Load Scenarios
tags:
  - zookeeper
  - io
  - performence
  - optimization
categories:
  - tech
 - Data
excerpt: Zookeeper transcation log file and snapshot file 过多导致Disk IO 出现性能问题
date: 2025-03-26 18:08:00
---


# Zookeeper 架构
Zookeeper为公司Kafka集群和Clickhouse集群提供分布式协调(Distributed Coordination), 一致性保证以及故障恢复功能。平均每个节点需要处理的Transcation在3000次/Sencond以上。
集群信息：
```js
Zookeeper version: 3.8.4
node: 3 
Disk IO: 10K IPOS

```

- 遇到的问题
 Zookeeper节点的Disk I/O Utilization 一直在升高，已经接近80%, 需要进行优化
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/2024/202503261736315.png)

- 事务snapshot log file 


```js
-rw-r--r-- 1 ubuntu ubuntu  88M Mar 26 09:00 snapshot.120bededf4
-rw-r--r-- 1 ubuntu ubuntu  88M Mar 26 09:00 snapshot.120bef485e
-rw-r--r-- 1 ubuntu ubuntu  88M Mar 26 09:01 snapshot.120bf015a4
-rw-r--r-- 1 ubuntu ubuntu  87M Mar 26 09:01 snapshot.120bf10f1f
-rw-r--r-- 1 ubuntu ubuntu  87M Mar 26 09:02 snapshot.120bf27122
-rw-r--r-- 1 ubuntu ubuntu  87M Mar 26 09:03 snapshot.120bf33b07
-rw-r--r-- 1 ubuntu ubuntu  86M Mar 26 09:03 snapshot.120bf43603
-rw-r--r-- 1 ubuntu ubuntu  86M Mar 26 09:04 snapshot.120bf57674
-rw-r--r-- 1 ubuntu ubuntu  85M Mar 26 09:05 snapshot.120bf6bfe5
-rw-r--r-- 1 ubuntu ubuntu  85M Mar 26 09:05 snapshot.120bf7ae1f
-rw-r--r-- 1 ubuntu ubuntu  85M Mar 26 09:06 snapshot.120bf8b730
-rw-r--r-- 1 ubuntu ubuntu  84M Mar 26 09:06 snapshot.120bf9bd2c
-rw-r--r-- 1 ubuntu ubuntu  84M Mar 26 09:07 snapshot.120bfa8115
-rw-r--r-- 1 ubuntu ubuntu  83M Mar 26 09:07 snapshot.120bfb9874
-rw-r--r-- 1 ubuntu ubuntu  84M Mar 26 09:08 snapshot.120bfcceeb
-rw-r--r-- 1 ubuntu ubuntu  85M Mar 26 09:09 snapshot.120bfe27d0
-rw-r--r-- 1 ubuntu ubuntu  86M Mar 26 09:09 snapshot.120bff5e88
-rw-r--r-- 1 ubuntu ubuntu  85M Mar 26 09:10 snapshot.120c00bed2
```

计算单个node事务数/Second:
```
  17 * 100000 / 10 / 60 = 2,833.3 次/S
```


# 优化方案
 增加Node的Disk挂载，将snapshot file 和 transcation log file写入到不同的盘中，同时优化snapshot file 和 transcation log file的落盘策略

## 增加 Disk挂载
配置zoo.cfg

```js

#dataLogDir： trancation log 
dataDir=/data0/zookeeper-data/

#snapshot log 
dataLogDir=/data1/zookeeper-data/txnlog/
```
关于dataDir与dataLogDir，官方文档的说明
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/2024/202503261814361.png)

https://zookeeper.apache.org/doc/r3.1.2/zookeeperAdmin.html

##  优化snapshot file 和 transcation log file的持久化存储策略
```js

#before 
# 1kb log
preAllocSize=1024

# snap transaction log auto clean , keep 5 ,delete 1h/times
autopurge.snapRetainCount=3
autopurge.purgeInterval=8
snapCount=1000000

```

## 操作
```
sudo systemctl daemon-reload
sudo systemctl stop zookeeper.service

```

迁移trancation log file 到指定 

```
#备份
cp -r /data0/zookeeper-data/ /data0/zookeeper-data-back-0327 
mkdir -p /data1/zookeeper-data/txnlog/version-2/
mv /data0/zookeeper-data/version-2/log.* /data1/zookeeper-data/txnlog/version-2/

```

```
sudo systemctl start zookeeper.service && tail -f /data/zookeeper-bin/logs/zookeeper.log 

```
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/2024/202503261936833.png)