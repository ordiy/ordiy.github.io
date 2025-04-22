---
layout: post
title: Hadoop disctp -- kerberos cluster to nosecure cluster
categories:
  - Haddop
  - HDFS
tags:
  - blog
  - distcp
  - hdfs
date: 2022-11-03 17:58:41
excerpt: HDFS 跨集群拷贝注意点：kerberos集群和非kerberos集群间的拷贝
---


# HDFS distcp 从安全集群到非安全集群

## 问题
```shell
hadoop --config /etc/hadoop/conf --debug distcp -update -delete hdfs://namedoe-xxx/tmp/data.tar.gz hdfs://cluster-2-no-secure:9000/tmp/ods-load
```


```javascript
/2022103116/verify_info.172.16.105.254.flume-verify-info-5dfddbf759-x4c92.0.1667203200002.snappy hdfs://namedoe-xxx/tmp/ods
2022-11-03 17:40:05,030 ERROR tools.DistCp: Invalid arguments:
java.io.IOException: DestHost:destPort namedoe-xxx , LocalHost:localPort ali-zjk-dp-ods-1205.host-xxx/10.55.1.205:0. Failed on local exception: java.io.IOException: Server asks us to fall back to SIMPLE auth, but this client is configured to only allow secure connections.
	at sun.reflect.NativeConstructorAccessorImpl.newInstance0(Native Method)
	at sun.reflect.NativeConstructorAccessorImpl.newInstance(NativeConstructorAccessorImpl.java:62)
	at sun.reflect.DelegatingConstructorAccessorImpl.newInstance(DelegatingConstructorAccessorImpl.java:45)
	at java.lang.reflect.Constructor.newInstance(Constructor.java:423)
	at org.apache.hadoop.net.NetUtils.wrapWithMessage(NetUtils.java:833)
	at org.apache.hadoop.net.NetUtils.wrapException(NetUtils.java:808)
	at org.apache.hadoop.ipc.Client.getRpcResponse(Client.java:1549)
	at org.apache.hadoop.ipc.Client.call(Client.java:1491)
	at org.apache.hadoop.ipc.Client.call(Client.java:1388)
	at org.apache.hadoop.ipc.ProtobufRpcEngine$Invoker.invoke(ProtobufRpcEngine.java:233)
	at org.apache.hadoop.ipc.ProtobufRpcEngine$Invoker.invoke(ProtobufRpcEngine.java:118)
	at com.sun.proxy.$Proxy9.getFileInfo(Unknown Source)
	at org.apache.hadoop.hdfs.protocolPB.ClientNamenodeProtocolTranslatorPB.getFileInfo(ClientNamenodeProtocolTranslatorPB.java:907)
	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
	at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
	at java.lang.reflect.Method.invoke(Method.java:498)
	at org.apache.hadoop.io.retry.RetryInvocationHandler.invokeMethod(RetryInvocationHandler.java:431)
	at org.apache.hadoop.io.retry.RetryInvocationHandler$Call.invokeMethod(RetryInvocationHandler.java:166)
	at org.apache.hadoop.io.retry.RetryInvocationHandler$Call.invoke(RetryInvocationHandler.java:158)
	at org.apache.hadoop.io.retry.RetryInvocationHandler$Call.invokeOnce(RetryInvocationHandler.java:96)
	at org.apache.hadoop.io.retry.RetryInvocationHandler.invoke(RetryInvocationHandler.java:362)
	at com.sun.proxy.$Proxy10.getFileInfo(Unknown Source)
	at org.apache.hadoop.hdfs.DFSClient.getFileInfo(DFSClient.java:1666)
	at org.apache.hadoop.hdfs.DistributedFileSystem$29.doCall(DistributedFileSystem.java:1576)
	at org.apache.hadoop.hdfs.DistributedFileSystem$29.doCall(DistributedFileSystem.java:1573)
	at org.apache.hadoop.fs.FileSystemLinkResolver.resolve(FileSystemLinkResolver.java:81)
	at org.apache.hadoop.hdfs.DistributedFileSystem.getFileStatus(DistributedFileSystem.java:1588)
	at org.apache.hadoop.fs.FileSystem.exists(FileSystem.java:1683)
	at org.apache.hadoop.tools.DistCp.setTargetPathExists(DistCp.java:241)
	at org.apache.hadoop.tools.DistCp.run(DistCp.java:143)
	at org.apache.hadoop.util.ToolRunner.run(ToolRunner.java:76)
	at org.apache.hadoop.tools.DistCp.main(DistCp.java:441)
Caused by: java.io.IOException: Server asks us to fall back to SIMPLE auth, but this client is configured to only allow secure connections.
	at org.apache.hadoop.ipc.Client$Connection.setupIOstreams(Client.java:843)
	at org.apache.hadoop.ipc.Client$Connection.access$3800(Client.java:421)
	at org.apache.hadoop.ipc.Client.getConnection(Client.java:1606)
	at org.apache.hadoop.ipc.Client.call(Client.java:1435)
	... 25 more
```

## 解决方案1
允许集群client认证fallback

cp /etc/hadoop/conf ~/conf

vim ~/core-site.xml
```javascript
     <!-- auth allow fallback -->
   <property>
        <name>ipc.client.fallback-to-simple-auth-allowed</name>
        <value>true</value>
   </property>

```
执行正常：
```javascript
hadoop --config /etc/hadoop/conf --debug distcp -update -delete hdfs://namedoe-xxx/tmp/data.tar.gz hdfs://cluster-2-no-secure:9000/tmp/ods-load 
```
注意：这里必须只允许在特定节点使用，全局配置"ipc.client.fallback-to-simple-auth-allowed" 存在安全风险 ？ 
特点： distcp 效率高

## 解决方案2
使用非RPC 链接方式:
```javascript
webhdfs 
hftp
```


# 参考
https://henning.kropponline.de/2015/10/04/distcp-between-kerberized-and-none-kerberized-cluster/
