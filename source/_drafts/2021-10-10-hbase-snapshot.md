---
layout: draft
title: 2021-10-10-hbase-snapshot
date: 2021-11-30 20:14:35
categories:
  - tech
tags:
  - blog
excerpt: HBase Snapshot 简介及应用
---

# HBase Snapshot 简介

```bash
#hbase shell 创建表snapshot
snapshot 'table_test', 'snapshot_table_test_20211121'
```

## snapshot文件结构
```
# 以hbase root.dir 为/hbase 为例：
#查看文件大小
$ hdfs dfs -du -h /hbase/.hbase-snapshot
```
输出：
```
0      0      /hbase/.hbase-snapshot/.tmp
2.6 M  7.8 M  /hbase/.hbase-snapshot/snapshot_table_test_20211121
```

查看目录结构：
```
$ hdfs dfs  -ls -R /hbase/.hbase-snapshot
```
输出：
```txt
drwxr-xr-x   - hbase hbase          0 2021-11-30 18:37 /hbase/.hbase-snapshot/.tmp
drwxr-xr-x   - hbase hbase          0 2021-11-30 18:37 /hbase/.hbase-snapshot/snapshot_table_test_20211121
-rw-r--r--   3 hbase hbase         57 2021-11-30 18:35 /hbase/.hbase-snapshot/snapshot_table_test_20211121/.snapshotinfo
-rw-r--r--   3 hbase hbase    2742362 2021-11-30 18:36 /hbase/.hbase-snapshot/snapshot_table_test_20211121/data.manifest
```

这里重点说`.snapshotinfo` 和 `data.manifest` 文件。
- `.snapshotinfo` 文件

- `data.manifest` 文件
  hbase 表的region 信息，包含Region split key


## 源码简述

# HBase Snapshot 用途

## 用于不同HBase集群之间的数据迁移
```

```

## 从HBase集群想Hive集群导数据

