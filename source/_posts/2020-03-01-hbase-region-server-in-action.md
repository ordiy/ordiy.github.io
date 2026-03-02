---
layout: post
title: HBase RIT 问题记录
categories:
  - tech
tags:
  - blog
date: 2022-03-23 16:19:33
excerpt: HBase RIT 异常问题记录
---

# RegionServer 


## HLog

### WAL
- WAL格式：
```javascript
#读取文件WAL文件格式
hbase wal /hbase/WALs/xxxx-hbase01-node46.xxxx.com,16020,1636530458538/xxxx-hbase01-node46.xxxx.com%2C16020%2C1636530458538.1648027649457 
```
文件格式内容：
```javascript
[Writer Classes: ProtobufLogWriter AsyncProtobufLogWriter
Cell Codec Class: org.apache.hadoop.hbase.regionserver.wal.IndexedWALEditCodec
{"sequence":2156243,"region":"b39a3c45778cda4d4e1b5486f9b237b1","actions":[{"vlen":414,"row":"34609239191","family":"A","qualifier":"lbs","timestamp":1648027627000,"total_size_sum":504},{"vlen":374,"row":"34642592779","family":"A","qualifier":"lbs","timestamp":1648027603000,"total_size_sum":464}],"table":{"name":"bGJzX2lvcw==","nameAsString":"lbs_ios","namespace":"ZGVmYXVsdA==","namespaceAsString":"default","qualifier":"bGJzX2lvcw==","qualifierAsString":"lbs_ios","systemTable":false,"nameWithNamespaceInclAsString":"default:lbs_ios"}}
edit heap size: 1008
position: 1044
```
`hbase wal`在hbase1.x 版本是`hbase hlog`（考虑到HLog支持`MultiWAL`,使用`WAL`表述更加合理）。同时该命令还支持region、row、sequence过滤`WAL`文件。

### 生命周期




# RegionServer 实践

## 使用`MultiWAL` 增加`throughput`
HBase中系统故障恢复以及主从辅助都基于`HLog`实现。默认情况下，所有（PUT、GET/MultiGet、Delete)的数据都以追加方式写`HLog`.`RegionServer`必须串行写入WAL，因为 HDFS 文件必须是顺序的。 这导致 WAL 成为性能瓶颈。
HBase 1.0增加了[MultiWal](https://issues.apache.org/jira/browse/HBASE-5699)`MultiWAL` 允许 RegionServer 通过在底层 HDFS 实例中使用多个管道并行写入多个 WAL 流，这增加了写入期间的总吞吐量。 这种并行化是通过按区域划分传入编辑来完成的。 因此，当前的实现无助于增加单个区域的吞吐量。
-Configure MultiWAL：
```
<!-- hbase-site.xml-->
<property>
  <name>hbase.wal.provider</name>
  <value>multiwal</value>
</property>

```
*注：重启RegionServer后生效


