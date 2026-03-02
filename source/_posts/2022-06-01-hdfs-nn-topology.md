---
layout: post
title: Datanode Initialization failed ——— NetworkTopology error
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


# add New HDFS DataNode 异常

## 环境信息
```bash
Hadoop 版本: 3.1.x-HDP3.1.5  
OS: Centos7.x
部署方式：私有化部署
```
## error 
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
新增Host的的DataNode日志提示是`network topology error` (HDFS ClusterID和NameNodeManager地址无异常),需要重点检查当前`DataNode`节点和`NameNodeManager` 的 `topology_mappings.data`文件。

## 检查新增Datanode机器Rack  
- HDFS printTopology
```javascript
# datanode 172.18.64.64
# show network Topology 
# 可能需要切换user hdfs sudo su - hdfs 
hdfs dfsadmin -printTopology
```
Network Topology信息:
```javascript
Rack: /nj/R304-J02
   172.18.64.15:50010 (gzxy-hbase02-node05.idc01.com)
   172.18.64.16:50010 (gzxy-hbase02-node06.idc01.com)
   172.18.64.17:50010 (gzxy-hbase02-node07.idc01.com)
   172.18.64.18:50010 (gzxy-hbase02-node08.idc01.com)

Rack: /nj/R304-J03
   172.18.64.19:50010 (gzxy-hbase02-node09.idc01.com)
   172.18.64.20:50010 (gzxy-hbase02-node10.idc01.com)

Rack: /nj/R304-J05
   172.18.64.44:50010 (gzxy-hbase02-node16.idc01.com)
   172.18.64.45:50010 (gzxy-hbase02-node17.idc01.com)
   172.18.64.46:50010 (gzxy-hbase02-node18.idc01.com)
   172.18.64.47:50010 (gzxy-hbase02-node19.idc01.com)
....................................
....................................
```
因为新增的`dataNode 172.18.64.64`未启动成功,执行`dfsadmin -printTopology`的结果中找不到该节点.
- 检查 `topology_mappings.data`
```bash 
$  cat /etc/hadoop/conf/topology_mappings.data | grep '172.18.64.64'
172.18.64.64=/NJ/R101-D1-07
```
DataNode的`topology_mappings.data` 已经更新,无异常。

## 检查Namenode Rack信息
新加入的`dataNode 172.18.64.64`并未加入到HDFS集群(DataNode Initialization failed),跳过hdfs report检查,直接检查`topology_mappings.data`.  
```javascript
# 登录到 namenode  检查`topology_mappings.data`文件:
# ssh gzxy-hbase02-node02.idc01.com/172.18.64.12:8020
ssh gzxy-hbase02-node02.idc01.com
cat /etc/hadoop/conf/topology_mappings.data | grep "172.18.64.14"

```
`topology_mappings.data`文件中无`172.18.64.64` 信息.


## 解决问题
### ClouderaManager版本
如果使用ClouderaManager作为集群管理工具，在新增机器并配置Rack后，需要执行`[Deploy Client Configuration]`更新各个节点的配置信息(包括了topology_mappings),操作示意：
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_202209011556718.png)
另外NameNode对`topology_mappings` 有缓存,需要重启`NameNode`才能生效

### HDP Ambari版本
使用Ambari管理集群,需要在`Active NameNode`和`Standby NameNode`分别对`HDFS Client`执行`Refresh Configs`.
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_202209011558955.png)
重启主备`NameNode`才能生效,做了Federation 需要逐个进行操作。

### 社区版本
如果使用hadoop conf `core-site.xml` 文件的 `topology.script.file.name` 配置rack信息, 请更新对应文件,参考[Hadoop3 Rack Awareness](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/RackAwareness.html)
重启主备`NameNode`才能生效.


# 思考
## 导致问题的重要原因是
`topology_mappings.data` 文件在namenode上未能及时同步导致的,过程示意图:
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_202209011925651.png)

## Hadoop network topology
Hadoop network topology 是典型的二层网络架构
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_202209011930720.png)
配置Rack Awareness时候（不考虑跨IDC情况）,可以表示为`/{{IDC_HOST}}/{{RACK_ID}}`. 在实际过程中IDC还会分割为不同的可用区,比如IDC5的B01区L02机柜,所以机柜RACK_ID,可能需要将编码调整为B01-L02,完整的`topology_mappings` 可以表示为 `/IDC5/B01-L02`.



# 参考
- [1]  [DATA NODE was removed from Ambari - Due to Rackwareness topology Error](https://community.cloudera.com/t5/Support-Questions/DATA-NODE-was-removed-from-Ambari-Due-to-Rackwareness/td-p/206917)

