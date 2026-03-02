---
layout: post
title: HBase Peer状态异常导致的oldWALs目录文件数异常
indexing: true
categories:
  - tech
  - HBase
tags:
  - blog
  - HBase
date: 2022-02-24 17:05:36
excerpt: RegionServer 在设置Replication（Peer)集群后，主集群的WAL会通过同步/异步的方式，拷贝到Peer集群，之后Peer集群重放WAL中的WALEdit(预写日志条目)来完成。当Peer集群异常情况下，主集群会将未能完成复制的WAL放到oldWALs(WAL归档目录)。Peer集群长期异常，会导致oldWALs目录下文件无限膨胀，导致集群存储异常或者宕机。
---

# 背景简述
```text
HBase Version 1.0.0-CDH5.5
集群节点: 50
存储空间：2.2P 
QPS 吞吐: PUT 5K QPS , Read 1K QPS
```
该集群作为主集群，配置了一个Peer集群，但Peer集群下线后已经进行了`disable_peer`。

# 事故异常过程
## HBase RegionServer 突发异常，并出现了宕机

### RegionServer 无法处理流量导致 RPC Read/Write流量异常：
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20220225160713.png)

### 对RegionServer 进行重启失败，出现异常：
```javascript
Feb 22, 12:01:46.497 PM	WARN	org.apache.hadoop.hbase.coordination.SplitLogManagerCoordination	
Could not finish splitting of log file WALs/xxxx-hbase01-node75.xxxxx.com,60020,1626321306698-splitting/xxxx-hbase01-node75.xxxxx.com%2C60020%2C1626321306698.null0.1645492876384
org.apache.hadoop.ipc.RemoteException(org.apache.hadoop.hdfs.protocol.FSLimitException$MaxDirectoryItemsExceededException): The directory item limit of /hbase/oldWALs is exceeded: limit=1048576 items=1048576
	at org.apache.hadoop.hdfs.server.namenode.FSDirectory.verifyMaxDirItems(FSDirectory.java:2060)
	at org.apache.hadoop.hdfs.server.namenode.FSDirectory.verifyFsLimitsForRename(FSDirectory.java:1991)
	at org.apache.hadoop.hdfs.server.namenode.FSDirectory.unprotectedRenameTo(FSDirectory.java:565)
	at org.apache.hadoop.hdfs.server.namenode.FSDirectory.renameTo(FSDirectory.java:477)
	at org.apache.hadoop.hdfs.server.namenode.FSNamesystem.renameToInternal(FSNamesystem.java:3898)
	at org.apache.hadoop.hdfs.server.namenode.FSNamesystem.renameToInt(FSNamesystem.java:3860)
	at org.apache.hadoop.hdfs.server.namenode.FSNamesystem.renameTo(FSNamesystem.java:3825)
	at org.apache.hadoop.hdfs.server.namenode.NameNodeRpcServer.rename(NameNodeRpcServer.java:800)
	at org.apache.hadoop.hdfs.server.namenode.AuthorizationProviderProxyClientProtocol.rename(AuthorizationProviderProxyClientProtocol.java:266)
	at org.apache.hadoop.hdfs.protocolPB.ClientNamenodeProtocolServerSideTranslatorPB.rename(ClientNamenodeProtocolServerSideTranslatorPB.java:566)
	at org.apache.hadoop.hdfs.protocol.proto.ClientNamenodeProtocolProtos$ClientNamenodeProtocol$2.callBlockingMethod(ClientNamenodeProtocolProtos.java)
	at org.apache.hadoop.ipc.ProtobufRpcEngine$Server$ProtoBufRpcInvoker.call(ProtobufRpcEngine.java:617)
	at org.apache.hadoop.ipc.RPC$Server.call(RPC.java:1060)
	at org.apache.hadoop.ipc.Server$Handler$1.run(Server.java:2086)
	at org.apache.hadoop.ipc.Server$Handler$1.run(Server.java:2082)
	at java.security.AccessController.doPrivileged(Native Method)
	at javax.security.auth.Subject.doAs(Subject.java:415)
	at org.apache.hadoop.security.UserGroupInformation.doAs(UserGroupInformation.java:1671)
	at org.apache.hadoop.ipc.Server$Handler.run(Server.java:2080)

	at org.apache.hadoop.ipc.Client.call(Client.java:1472)
	at org.apache.hadoop.ipc.Client.call(Client.java:1403)
	at org.apache.hadoop.ipc.ProtobufRpcEngine$Invoker.invoke(ProtobufRpcEngine.java:230)
	at com.sun.proxy.$Proxy22.rename(Unknown Source)
	at org.apache.hadoop.hdfs.protocolPB.ClientNamenodeProtocolTranslatorPB.rename(ClientNamenodeProtocolTranslatorPB.java:468)
	at sun.reflect.GeneratedMethodAccessor7.invoke(Unknown Source)
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
	at java.lang.reflect.Method.invoke(Method.java:606)
	at org.apache.hadoop.io.retry.RetryInvocationHandler.invokeMethod(RetryInvocationHandler.java:252)
	at org.apache.hadoop.io.retry.RetryInvocationHandler.invoke(RetryInvocationHandler.java:104)
	at com.sun.proxy.$Proxy23.rename(Unknown Source)
	at sun.reflect.GeneratedMethodAccessor7.invoke(Unknown Source)
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
	at java.lang.reflect.Method.invoke(Method.java:606)
	at org.apache.hadoop.hbase.fs.HFileSystem$1.invoke(HFileSystem.java:279)
	at com.sun.proxy.$Proxy24.rename(Unknown Source)
	at sun.reflect.GeneratedMethodAccessor7.invoke(Unknown Source)
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
	at java.lang.reflect.Method.invoke(Method.java:606)
	at org.apache.hadoop.hbase.fs.HFileSystem$1.invoke(HFileSystem.java:279)
	at com.sun.proxy.$Proxy24.rename(Unknown Source)
	at org.apache.hadoop.hdfs.DFSClient.rename(DFSClient.java:1954)
	at org.apache.hadoop.hdfs.DistributedFileSystem.rename(DistributedFileSystem.java:582)
	at org.apache.hadoop.hbase.util.FSUtils.renameAndSetModifyTime(FSUtils.java:1797)
	at org.apache.hadoop.hbase.wal.WALSplitter.archiveLogs(WALSplitter.java:494)
	at org.apache.hadoop.hbase.wal.WALSplitter.finishSplitLogFile(WALSplitter.java:449)
	at org.apache.hadoop.hbase.wal.WALSplitter.finishSplitLogFile(WALSplitter.java:435)
	at org.apache.hadoop.hbase.coordination.ZKSplitLogManagerCoordination$1.finish(ZKSplitLogManagerCoordination.java:117)
	at org.apache.hadoop.hbase.coordination.ZKSplitLogManagerCoordination.getDataSetWatchSuccess(ZKSplitLogManagerCoordination.java:475)
	at org.apache.hadoop.hbase.coordination.ZKSplitLogManagerCoordination.access$700(ZKSplitLogManagerCoordination.java:75)
	at org.apache.hadoop.hbase.coordination.ZKSplitLogManagerCoordination$GetDataAsyncCallback.processResult(ZKSplitLogManagerCoordination.java:1037)
	at org.apache.zookeeper.ClientCnxn$EventThread.processEvent(ClientCnxn.java:561)
	at org.apache.zookeeper.ClientCnxn$EventThread.run(ClientCnxn.java:498)
Feb 22, 12:01:46.498 PM	WARN	org.apache.hadoop.hbase.coordination.SplitLogManagerCoordination	
Error splitting /hbase/splitWAL/WALs%2Fxxxx-hbase01-node75.xxxxx.com%2C60020%2C1626321306698-splitting%2Fxxxx-hbase01-node75.xxxxx.com%252C60020%252C1626321306698.null0.1645492876384

==========
```

## 定位问题
从日志提示看是由于`/hbase/oldWALs` 目录下的文件数超过了`HDFS`最大文件限制数`10485761`，检查该目录:
```javascript
hdfs -dfs -du -s  /hbase/oldWALs
```
这个文件达到了100T, 已经无法统计出该目录下的子文件。目录`/hbase/oldWALs`的作用是WAL的归档目录，一旦一个WAL文件中记录的所有KV数据确认已经从MemStore持久化到HFile，那么该WAL文件就会被移到该目录。 开启了Peer后，若未复制成功的WAL也会存放在该目录。

## 解决问题
清理`/hbase/oldWALs`
```javascript
today=`date +'%s'`
hdfs dfs -ls /hbase/oldWALs | grep "^d" | while read line ; do
dir_date=$(echo ${line} | awk '{print $6}')
difference=$(( ( ${today} - $(date -d ${dir_date} +%s) ) / ( 24*60*60 ) ))
filePath=$(echo ${line} | awk '{print $8}')

if [ ${difference} -gt 10 ]; then
    #hdfs dfs -rm -r $filePath
   echo "===> $filePath"
fi
done
``` 

## 数据


## 原因
HLog文件是有生命周期的,HLog生命周期：
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20220328095759.png)

默认情况下HBase Master(Active节点)会后台启动一个线程，以`hbase.master.cleaner.interval`(默认1分钟，HDP3 改为了1h间隔)为间隔检查`oldWALs`下所有失效的日志问题，确定是否可以删除。
确认删除需要达成2个条件：
1. HLog 文件是否还在参与主从复制，以及该文件是否还在用于主从复制`ReplicationHFileCleaner.getDeletableFiles`逻辑
2. HLog 文件在oldWALs文件中存在的时间 > `hbase.master.logcleaner.ttl`(默认值10minutes)
```javascript
[zk: localhost:2181(CONNECTED) 6] ls /hbase/replication/peers
[]
[zk: localhost:2181(CONNECTED) 7] ls /hbase/replication/rs
[xxxx-hbase01-node244.xxxx.com,60020,1645515180740, xxxx-hbase01-node238.xxxx.com,60020,1645502396855, xxxx-hbase01-node12.xxxx.com,60020,1645502395651, xxxx-hbase01-node68.xxxx.com,60020,1645502396574, xxxx-hbase01-node56.xxxx.com,60020,1645502396748, xxxx-hbase01-node57.xxxx.com,60020,1645502395942, xxxx-hbase01-node66.xxxx.com,60020,1645502396692, xxxx-hbase01-node11.xxxx.com,60020,1645502396175, xxxx-hbase01-node149.xxxx.com,60020,1645502556596, xxxx-hbase01-node64.xxxx.com,60020,1645502398389, xxxx-hbase01-node62.xxxx.com,60020,1645502396268, xxxx-hbase01-node59.xxxx.com,60020,1645501475468, xxxx-hbase01-node240.xxxx.com,60020,1645502396736, xxxx-hbase01-node75.xxxx.com,60020,1645502396501, xxxx-hbase01-node10.xxxx.com,60020,1645502395833, xxxx-hbase01-node63.xxxx.com,60020,1645502397816, xxxx-hbase01-node150.xxxx.com,60020,1645502396480, xxxx-hbase01-node71.xxxx.com,60020,1645502396275, xxxx-hbase01-node49.xxxx.com,60020,1645502396541, xxxx-hbase01-node65.xxxx.com,60020,1645502398568, xxxx-hbase01-node77.xxxx.com,60020,1645502396304, xxxx-hbase01-node54.xxxx.com,60020,1645502395830, xxxx-hbase01-node78.xxxx.com,60020,1645502396183, xxxx-hbase01-node55.xxxx.com,60020,1645502396742, xxxx-hbase01-node50.xxxx.com,60020,1645502396573, xxxx-hbase01-node70.xxxx.com,60020,1645502396859, xxxx-hbase01-node72.xxxx.com,60020,1645502395894, xxxx-hbase01-node242.xxxx.com,60020,1645502396166, xxxx-hbase01-node53.xxxx.com,60020,1645502395834, xxxx-hbase01-node61.xxxx.com,60020,1645502396141, xxxx-hbase01-node51.xxxx.com,60020,1645502396211, xxxx-hbase01-node148.xxxx.com,60020,1645502396044, xxxx-hbase01-node67.xxxx.com,60020,1645502396172, xxxx-hbase01-node58.xxxx.com,60020,1645502398506, xxxx-hbase01-node76.xxxx.com,60020,1645502397094, xxxx-hbase01-node52.xxxx.com,60020,1645502395760, xxxx-hbase01-node73.xxxx.com,60020,1645502396696, xxxx-hbase01-node60.xxxx.com,60020,1645502396503, xxxx-hbase01-node241.xxxx.com,60020,1645502396087, xxxx-hbase01-node69.xxxx.com,60020,1645502396658, xxxx-hbase01-node151.xxxx.com,60020,1645502396097, xxxx-hbase01-node239.xxxx.com,60020,1645502396421, xxxx-hbase01-node74.xxxx.com,60020,1645502396215, xxxx-hbase01-node61.xxxx.com,60020,1626235982224]
[zk: localhost:2181(CONNECTED) 8] rmr /hbase/replication/rs

```

   
  
# 参考：
- [1].https://community.cloudera.com/t5/Support-Questions/java-io-IOException-Packet-len73388953-is-out-of-range/td-p/327482

