---
layout: post
title: HDFS DataNode Initialization failed - NetworkTopology error 
categories:
  - tech
  - BigData
tags:
  - blog
  - Hadoop
  - HDFS
date: 2022-06-08 17:53:48
excerpt: <p> HDFS DataNode Initialization failed - You cannot have a rack and a non-rack node at the same level of the network topology. </p>
---


# add HDFS DataNode 异常

对集群添加新Host, Add DataNode Role,启动出现异常:
```javascript
 12:16:48,935 INFO  datanode.DataNode (BPServiceActor.java:register(764)) - Block pool BP-1657279700-172.18.64.12-1628675383465 (Datanode Uuid d5249f23-d5e6-4d0c-a00c-7cf60f4be2fd) service to gzxy-hbase02-node02.idc01.com/172.18.64.12:8020 beginning handshake with NN
 12:16:48,952 ERROR datanode.DataNode (BPServiceActor.java:run(824)) - Initialization failed for Block pool BP-1657279700-172.18.64.12-1628675383465 (Datanode Uuid d5249f23-d5e6-4d0c-a00c-7cf60f4be2fd) service to gzxy-hbase02-node02.idc01.com/172.18.64.12:8020 Failed to add /default-rack/172.18.64.64:50010: You cannot have a rack and a non-rack node at the same level of the network topology.
	at org.apache.hadoop.net.NetworkTopology.add(NetworkTopology.java:134)
	at org.apache.hadoop.hdfs.server.blockmanagement.DatanodeManager.registerDatanode(DatanodeManager.java:1135)
	at org.apache.hadoop.hdfs.server.blockmanagement.BlockManager.registerDatanode(BlockManager.java:2358)
	at org.apache.hadoop.hdfs.server.namenode.FSNamesystem.registerDatanode(FSNamesystem.java:3830)
	at org.apache.hadoop.hdfs.server.namenode.NameNodeRpcServer.registerDatanode(NameNodeRpcServer.java:1490)
	at org.apache.hadoop.hdfs.protocolPB.DatanodeProtocolServerSideTranslatorPB.registerDatanode(DatanodeProtocolServerSideTranslatorPB.java:101)
	at org.apache.hadoop.hdfs.protocol.proto.DatanodeProtocolProtos$DatanodeProtocolService$2.callBlockingMethod(DatanodeProtocolProtos.java:31658)
	at org.apache.hadoop.ipc.ProtobufRpcEngine$Server$ProtoBufRpcInvoker.call(ProtobufRpcEngine.java:524)
	at org.apache.hadoop.ipc.RPC$Server.call(RPC.java:1025)
	at org.apache.hadoop.ipc.Server$RpcCall.run(Server.java:876)
	at org.apache.hadoop.ipc.Server$RpcCall.run(Server.java:822)
	at java.security.AccessController.doPrivileged(Native Method)
	at javax.security.auth.Subject.doAs(Subject.java:422)
	at org.apache.hadoop.security.UserGroupInformation.doAs(UserGroupInformation.java:1730)
	at org.apache.hadoop.ipc.Server$Handler.run(Server.java:2682)

 12:16:49,309 INFO  datanode.DataNode (BPServiceActor.java:register(764)) - Block pool BP-1657279700-172.18.64.12-1628675383465 (Datanode Uuid d5249f23-d5e6-4d0c-a00c-7cf60f4be2fd) service to gzxy-hbase02-node04.idc01.com/172.18.64.14:8020 beginning handshake with NN
 12:16:49,337 ERROR datanode.DataNode (BPServiceActor.java:run(824)) - Initialization failed for Block pool BP-1657279700-172.18.64.12-1628675383465 (Datanode Uuid d5249f23-d5e6-4d0c-a00c-7cf60f4be2fd) service to gzxy-hbase02-node04.idc01.com/172.18.64.14:8020 Failed to add /default-rack/172.18.64.64:50010: You cannot have a rack and a non-rack node at the same level of the network topology.
	at org.apache.hadoop.net.NetworkTopology.add(NetworkTopology.java:134)
	at org.apache.hadoop.hdfs.server.blockmanagement.DatanodeManager.registerDatanode(DatanodeManager.java:1135)
	at org.apache.hadoop.hdfs.server.blockmanagement.BlockManager.registerDatanode(BlockManager.java:2358)
	at org.apache.hadoop.hdfs.server.namenode.FSNamesystem.registerDatanode(FSNamesystem.java:3830)
	at org.apache.hadoop.hdfs.server.namenode.NameNodeRpcServer.registerDatanode(NameNodeRpcServer.java:1490)
	at org.apache.hadoop.hdfs.protocolPB.DatanodeProtocolServerSideTranslatorPB.registerDatanode(DatanodeProtocolServerSideTranslatorPB.java:101)
	at org.apache.hadoop.hdfs.protocol.proto.DatanodeProtocolProtos$DatanodeProtocolService$2.callBlockingMethod(DatanodeProtocolProtos.java:31658)
	at org.apache.hadoop.ipc.ProtobufRpcEngine$Server$ProtoBufRpcInvoker.call(ProtobufRpcEngine.java:524)
	at org.apache.hadoop.ipc.RPC$Server.call(RPC.java:1025)
	at org.apache.hadoop.ipc.Server$RpcCall.run(Server.java:876)
	at org.apache.hadoop.ipc.Server$RpcCall.run(Server.java:822)
	at java.security.AccessController.doPrivileged(Native Method)
	at javax.security.auth.Subject.doAs(Subject.java:422)
	at org.apache.hadoop.security.UserGroupInformation.doAs(UserGroupInformation.java:1730)
	at org.apache.hadoop.ipc.Server$Handler.run(Server.java:2682)
```

# 排查问题

## 分析  
新增Host的的DataNode日志提示是`network topology` 有问题(HDFS ClusterID和NameNodeManager地址无异常),需要重点检查当前`DataNode`节点和`Active。NameNodeManager` 的 `topology_mappings.data`文件。

## 检查 Host Rack  
```javascript
# show network Topology 
hdfs dfsadmin -printTopology
```
Network Topology信息:
```javascript
Rack: /304/J02
   172.18.64.15:50010 (gzxy-hbase02-node05.idc01.com)
   172.18.64.16:50010 (gzxy-hbase02-node06.idc01.com)
   172.18.64.17:50010 (gzxy-hbase02-node07.idc01.com)
   172.18.64.18:50010 (gzxy-hbase02-node08.idc01.com)

Rack: /304/J03
   172.18.64.19:50010 (gzxy-hbase02-node09.idc01.com)
   172.18.64.20:50010 (gzxy-hbase02-node10.idc01.com)

Rack: /304/J05
   172.18.64.44:50010 (gzxy-hbase02-node16.idc01.com)
   172.18.64.45:50010 (gzxy-hbase02-node17.idc01.com)
   172.18.64.46:50010 (gzxy-hbase02-node18.idc01.com)
   172.18.64.47:50010 (gzxy-hbase02-node19.idc01.com)
....................................
....................................
....................................
```
新加入的Node22并未加入到`dfsAdmin`信息中(DataNode Initialization failed)

```javascript
# 查看 HDFS的基本统计信息，重点看注册上的节点
hdfs dfsAdmin -report 
```
report信息:
```javascript
Name: 172.18.64.72:50010 (gzxy-hbase02-node30.jpushoa.com)
Hostname: gzxy-hbase02-node30.jpushoa.com
Rack: /304/J08
Decommission Status : Normal
Configured Capacity: 11093557831680 (10.09 TB)
DFS Used: 2921948365247 (2.66 TB)
Non DFS Used: 0 (0 B)
DFS Remaining: 8170798108176 (7.43 TB)
DFS Used%: 26.34%
DFS Remaining%: 73.65%
Configured Cache Capacity: 0 (0 B)
Cache Used: 0 (0 B)
Cache Remaining: 0 (0 B)
Cache Used%: 100.00%
Cache Remaining%: 0.00%
Xceivers: 38
Last contact: Wed Jun 08 17:18:35 CST 2022
Last Block Report: Wed Jun 08 15:01:53 CST 2022
Num of Blocks: 22926
....................................
....................................
....................................
```

检查`topology_mappings.data`文件:
```javascript
ssh node22.idc01.com
cat /etc/hadoop/conf/topology_mappings.data
```
`topology_mappings.data`文件内容:

```javascript
gzxy-hbase02-node26.jpushoa.com=/304/J08
172.18.64.68=/304/J08
gzxy-hbase02-node22.jpushoa.com=/default-rack
172.18.64.64=/default-rack
```
新增Node22未正确设置Rock导致的异常？

## 解决问题
DataNode启动时候会向NameNode进行注册




# 参考
- []  [DATA NODE was removed from Ambari - Due to Rackwareness topology Error](https://community.cloudera.com/t5/Support-Questions/DATA-NODE-was-removed-from-Ambari-Due-to-Rackwareness/td-p/206917)

