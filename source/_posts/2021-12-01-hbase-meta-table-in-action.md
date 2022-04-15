---
layout: post
title: HBase Meta使用及故障排查
indexing: true
categories:
  - tech
  - Hadoop
  - HBase
tags:
  - blog
  - HBase
  - SkipList
date: 2022-03-23 15:00:31
excerpt: HBase系统内部设计了一张特殊的表--`hbase:meta`,用于保存Table,Region,RegionServer相关的元数据。
---

# HBase Meta 表

HBas的表由多个`Region`组成， 而`Region`又分布在不同的`RegionServer`上。Client在做任何操作时，都要去人数据在那个`Region`上，然后根据`Region`关联的`RegionServer`信息，确定对应的RegionServer 节点上读取数据，因此HBase系统内部设计了一张特殊的表————`hbase:meta`表（hbase是系统表统一的namespace,meta是表名）。
## 如何定位到`hbase:meta`表
client 需要预先获取到hbase:meta表所在的RegionServer才能，才能获取到hbase:meta中的信息。
`hbase:meta`所在RegionServer会存在放Zookpeer Server中的`${hbase_home}/meta-region-server` path下的ZNode,如下所示：
```shell
$ zookeeper-client
[zk: localhost:2181(CONNECTED) 1] get /hbase/meta-region-server
�master:16000��0��r�
                    PBUF
+
xxxx-hbase02-node20.xxxx.com�}����/
cZxid = 0x50000aaf6
ctime = Thu Aug 19 16:34:29 CST 2021
mZxid = 0xa00033637
mtime = Thu Jan 13 12:04:13 CST 2022
pZxid = 0x50000aaf6
cversion = 0
dataVersion = 17
aclVersion = 0
ephemeralOwner = 0x0
dataLength = 78
numChildren = 0

```
这里表示`hbase:meta`所在的`RegionServer`是`xxxx-hbase02-node20.xxxx.com�}����/` ( 这里显示有一些乱码，是zk client 由于decode不对导致的，实际是没问题的)

# `hbase:meta`表结构
在`hbase:meta`表中一个rowkey对应一个Region，rowkey由TableName(用户创建的表)、StartRow(region split key/ 启始row),Timestamp( Region创建的时间戳)，EncondeName(前面三字字段进行MD5 Hex得到，具体计算方法：md5sum(String.join(",", TableName, StartRow, Timestamp, ，EncondeName)))。 一行数据分为多个列，如下展示：

## 1.x版本`hbase:meta`表结构：
- 1.x版本`hbase:meta`表结构
```shell
$ hbase shell 
hbase(main):001:0> desc 'hbase:meta'
Table hbase:meta is ENABLED
hbase:meta, {TABLE_ATTRIBUTES => {IS_META => 'true', coprocessor$1 => '|org.apache.hadoop.hbase.coprocessor.MultiRowMutationEndpoint|536870911|'}
COLUMN FAMILIES DESCRIPTION
{NAME => 'info', DATA_BLOCK_ENCODING => 'NONE', BLOOMFILTER => 'NONE', REPLICATION_SCOPE => '0', COMPRESSION => 'NONE', VERSIONS => '10', TTL=> 'FOREVER', MIN_VERSIONS => '0', CACHE_DATA_IN_L1 => 'true', KEEP_DELETED_CELLS => 'FALSE', BLOCKSIZE => '8192', IN_MEMORY => 'true', BLOCKCACHE => 'true'}
```

- 字段展示及说明
```
# 结构示例
#scan 'hbase:meta', {LIMIT => 1 }
 xxxx_profile,,1514870140734.685eb1870b1b1c1238e8e90ed3d746fb.                column=info:regioninfo, timestamp=1514870140766, value={ENCODED => 685eb1870b1b1c1238e8e90ed3d746fb, NAME => 'xxxx_profile,,1514870140734.685eb1870b1b1c1238e8e90ed3d746fb.', STARTKEY => '', ENDKEY => ''}
 xxxx_profile,,1514870140734.685eb1870b1b1c1238e8e90ed3d746fb.                column=info:seqnumDuringOpen, timestamp=1647067952077, value=\x00\x00\x00\x00)\x0D\x08\x07
 xxxx_profile,,1514870140734.685eb1870b1b1c1238e8e90ed3d746fb.                column=info:server, timestamp=1647067952077, value=xxxx-hbase01-node240.xxxx.com:60020
 xxxx_profile,,1514870140734.685eb1870b1b1c1238e8e90ed3d746fb.                column=info:serverstartcode, timestamp=1647067952077, value=1647067851041
```
字段信息说明：
|字段 |说明 | value demo  |
|:-----|:----|----|
|`rowkey`               | rowkey由<tableName>,<startKey>,<regionId>,<encodedRegionName> 4部分组成 | xxxx_profile,,</p> 1514870140734.685eb1870b1b1c1238e8e90ed3d746fb |
|`info:regioninfo`      | region信息。EncondeName ,ReginName, Region的startRow,endRow | {ENCODED => 685eb1870b1b1c1238e8e90ed3d746fb, NAME => 'xxxx_profile,,1514870140734.685eb1870b1b1c1238e8e90ed3d746fb.', STARTKEY => '', ENDKEY => ''}   |
|`info:seqnumDuringOpen` |  region打开的序列号（二进制） ， Region open/disable 会改变该sequenceId|   \x00\x00\x00\x00|
|`info:server`           |  region 所在的regionServer <host>:<port> | xxxx-hbase01-node240.xxxx.com:60020  |
|`info:serverstartcode`  |   region启动时的Timestamp, region disable/enable 会更新该时间戳,需要注意的是该时间戳与column的时间戳不一致 | 1616034411621  |


## HBase 2.2 `hbase:meta`表结构及字段
-  2.2 版本`hbase:meta`表结构
```bash
$ hbase shell 

hbase(main):001:0> desc 'hbase:meta'
Table hbase:meta is ENABLED
hbase:meta, {TABLE_ATTRIBUTES => {IS_META => 'true', REGION_REPLICATION => '1', coprocessor$1 => '|org.apache.hadoop.hbase.coprocessor.MultiRowMutationEndpoint|536870911|'}
COLUMN FAMILIES DESCRIPTION
{NAME => 'info', VERSIONS => '3', EVICT_BLOCKS_ON_CLOSE => 'false', NEW_VERSION_BEHAVIOR => 'false', KEEP_DELETED_CELLS => 'FALSE', CACHE_DATA_ON_WRITE => 'false', DATA_BLOCK_ENCODING => 'NONE', TTL => 'FOREVER',MIN_VERSIONS => '0', REPLICATION_SCOPE => '0', BLOOMFILTER => 'NONE', CACHE_INDEX_ON_WRITE => 'false', IN_MEMORY => 'true', CACHE_BLOOMS_ON_WRITE => 'false', PREFETCH_BLOCKS_ON_OPEN => 'false', COMPRESSION => 'NONE', BLOCKCACHE => 'true', BLOCKSIZE => '8192'}
{NAME => 'rep_barrier', VERSIONS => '2147483647', EVICT_BLOCKS_ON_CLOSE => 'false', NEW_VERSION_BEHAVIOR => 'false', KEEP_DELETED_CELLS => 'FALSE', CACHE_DATA_ON_WRITE => 'false', DATA_BLOCK_ENCODING => 'NONE', TTL => 'FOREVER', MIN_VERSIONS => '0', REPLICATION_SCOPE => '0', BLOOMFILTER => 'NONE', CACHE_INDEX_ON_WRITE => 'false', IN_MEMORY => 'true', CACHE_BLOOMS_ON_WRITE => 'false', PREFETCH_BLOCKS_ON_OPEN => 'false', COMPRESSION => 'NONE', BLOCKCACHE => 'true', BLOCKSIZE => '65536'}
{NAME => 'table', VERSIONS => '3', EVICT_BLOCKS_ON_CLOSE => 'false', NEW_VERSION_BEHAVIOR => 'false', KEEP_DELETED_CELLS => 'FALSE', CACHE_DATA_ON_WRITE => 'false', DATA_BLOCK_ENCODING => 'NONE', TTL => 'FOREVER', MIN_VERSIONS => '0', REPLICATION_SCOPE => '0', BLOOMFILTER => 'NONE', CACHE_INDEX_ON_WRITE => 'false', IN_MEMORY => 'true', CACHE_BLOOMS_ON_WRITE => 'false', PREFETCH_BLOCKS_ON_OPEN => 'false', COMPRESSION => 'NONE', BLOCKCACHE => 'true', BLOCKSIZE => '8192'}
```
- `hbase:meta`表字段
```bash
hbase shell
hbase(main):008:0>scan 'hbase:meta', { STARTROW => 'fraud:test_fraud,,9999999999999', REVERSED => true, VERSIONS=> 3, LIMIT => 1}

ROW                                                                                                         COLUMN+CELL
 fraud:test_fraud,,1641866861822.1834b75053cfb05edb359493313b1d86.                               column=info:regioninfo, timestamp=1642046677391, value={ENCODED => 1834b75053cfb05edb359493313b1d86, NAME => 'fraud:test_fraud,,1641866861822.1834b75053cfb05edb359493313b1d86.', STARTKEY => '', ENDKEY => '007ff1a547c07e27999d6d60d720b47e'}
 fraud:test_fraud,,1641866861822.1834b75053cfb05edb359493313b1d86.                               column=info:regioninfo, timestamp=1642046676303, value={ENCODED => 1834b75053cfb05edb359493313b1d86, NAME => 'fraud:test_fraud,,1641866861822.1834b75053cfb05edb359493313b1d86.', STARTKEY => '', ENDKEY => '007ff1a547c07e27999d6d60d720b47e'}
 fraud:test_fraud,,1641866861822.1834b75053cfb05edb359493313b1d86.                               column=info:regioninfo, timestamp=1641866862584, value={ENCODED => 1834b75053cfb05edb359493313b1d86, NAME => 'fraud:test_fraud,,1641866861822.1834b75053cfb05edb359493313b1d86.', STARTKEY => '', ENDKEY => '007ff1a547c07e27999d6d60d720b47e'}
 fraud:test_fraud,,1641866861822.1834b75053cfb05edb359493313b1d86.                               column=info:seqnumDuringOpen, timestamp=1642046677391, value=\x00\x00\x00\x00\x00\x00\x00\x1C
 fraud:test_fraud,,1641866861822.1834b75053cfb05edb359493313b1d86.                               column=info:seqnumDuringOpen, timestamp=1641866862584, value=\x00\x00\x00\x00\x00\x00\x00\x13
 fraud:test_fraud,,1641866861822.1834b75053cfb05edb359493313b1d86.                               column=info:seqnumDuringOpen, timestamp=1641866862204, value=\x00\x00\x00\x00\x00\x00\x00\x01
 fraud:test_fraud,,1641866861822.1834b75053cfb05edb359493313b1d86.                               column=info:server, timestamp=1642046677391, value=xxxx-hbase02-node13.xxxx.com:16020
 fraud:test_fraud,,1641866861822.1834b75053cfb05edb359493313b1d86.                               column=info:server, timestamp=1641866862584, value=xxxx-hbase02-node13.xxxx.com:16020
 fraud:test_fraud,,1641866861822.1834b75053cfb05edb359493313b1d86.                               column=info:serverstartcode, timestamp=1642046677391, value=1642046652302
 fraud:test_fraud,,1641866861822.1834b75053cfb05edb359493313b1d86.                               column=info:serverstartcode, timestamp=1641866862584, value=1639400425190
 fraud:test_fraud,,1641866861822.1834b75053cfb05edb359493313b1d86.                               column=info:sn, timestamp=1642046676303, value=xxxx-hbase02-node13.xxxx.com,16020,1642046652302
 fraud:test_fraud,,1641866861822.1834b75053cfb05edb359493313b1d86.                               column=info:sn, timestamp=1641866862368, value=xxxx-hbase02-node13.xxxx.com,16020,1639400425190
 fraud:test_fraud,,1641866861822.1834b75053cfb05edb359493313b1d86.                               column=info:state, timestamp=1642046677391, value=OPEN
 fraud:test_fraud,,1641866861822.1834b75053cfb05edb359493313b1d86.                               column=info:state, timestamp=1642046676303, value=OPENING
 fraud:test_fraud,,1641866861822.1834b75053cfb05edb359493313b1d86.                               column=info:state, timestamp=1641866862584, value=OPEN
```

# `hbase:meta` 更新逻辑

## client `MetaCache`
在hbase-client(以2.0.0为例）,tableName 于对应的region使用了一个`ConcurrentMap<TableName, ConcurrentNavigableMap<byte[], RegionLocations>>`的数据结构进行存储，值得注意的是`NavigableMap`是继承于SortedMap的接口,可以"获取大于/等于某对象的键值对"、“获取小于/等于某对象的键值对”,很适合用于使用`Row`查询对应的`RegionLocations`。`NavigableMap`使用的数据结构-跳跃表（SkipList)，SkipList示意图：
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20220323150645.png)
* 图片来源[wiki]()


# HBase meta 常见问题
## Region 的`Overlaps'和`Holes`及`Orphans`,对于RIT或者`block`丢失导致的问题可以使用`hbck`解决：
```
hbase hbck -fixAssignments -fixMeta -fixHdfsHoles xxx_table
```

# 参考
- [] 胡争,范欣欣. HBase原理与实践 (Chinese Edition). Kindle 版本. 


