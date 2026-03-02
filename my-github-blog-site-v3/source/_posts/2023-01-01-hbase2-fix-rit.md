---
layout: post
title: HBase 超大表修改导致的RIT问题
categories:
  - tech
tags:
  - blog
  - HBase
  - RIT
date: 2023-05-07 14:48:25
excerpt: HBase 2.x Fix RIT。修改一个100T表，导致的RIT问题。
---


# 问题描述
集群需要更新Table Version 
```shell
echo " disable 'xxxx_jdid_new' " | hbase shell -n 
echo " alter 'xxxx_jdid_new', {NAME => 'A', VERSIONS => 730 } " | hbase shell -n 
echo " enable 'xxxx_jdid_new' " | hbase shell -n 
```

但是由于table 数据量非常大(100T+) ， 此操作直接导致table 出现大量RIT


#  tool 
```shell
wget https://dlcdn.apache.org/hbase/hbase-operator-tools-1.2.0/hbase-operator-tools-1.2.0-bin.tar.gz

tar -zxvf hbase-operator-tools-1.2.0-bin.tar.gz 
# 测试
hbase hbck -j ~ s/hbase-operator-tools-1.2.0/hbase-hbck2/hbase-hbck2-1.2.0.jar --help

#可以使用--config 指定配置文件
```


解决 RIT blocking 
![image|700](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20230303165746.png)

HMaster 日志：
```js
2023-03-01 21:04:02,810 WARN  [ProcExecTimeout] assignment.AssignmentManager: STUCK Region-In-Transition rit=OPENING, location=idc-bj-hbase01-node198.hostname.com,16020,1657113851089, table=xxxxx_ip_new, region=83504493dad030dd984351d836f1e038
2023-03-01 21:04:02,810 WARN  [ProcExecTimeout] assignment.AssignmentManager: STUCK Region-In-Transition rit=OPENING, location=idc-bj-hbase01-node222.hostname.com,16020,1657119128640, table=xxxxx_ip_new, region=23e774d40cdbb3c0949b3f331dc78ea1
2023-03-01 21:04:02,810 WARN  [ProcExecTimeout] assignment.AssignmentManager: STUCK Region-In-Transition rit=OPENING, location=idc-bj-hbase01-node192.hostname.com,16020,1657112516084, table=xxxxx_ip_new, region=c62e61fa464ad896d9aa5d2d7a69e1e5
2023-03-01 21:04:02,810 WARN  [ProcExecTimeout] assignment.AssignmentManager: STUCK Region-In-Transition rit=OPENING, location=idc-bj-hbase01-node226.hostname.com,16020,1657120001299, table=xxxxx_ip_new, region=3c7d1f07c62cd9a8762869943ae09f9b
2023-03-01 21:04:02,810 WARN  [ProcExecTimeout] assignment.AssignmentManager: STUCK Region-In-Transition rit=OPENING, location=idc-bj-hbase01-node208.hostname.com,16020,1657116060790, table=xxxxx_ip_new, region=58e92be55ce39cd5ddc82961e540e319
2023-03-01 21:04:02,810 WARN  [ProcExecTimeout] assignment.AssignmentManager: STUCK Region-In-Transition rit=OPENING, location=idc-bj-hbase01-node225.hostname.com,16020,1657119785191, table=xxxxx_ip_new, region=d02c8b7652690cb3fcc1f9f16172faae

```
Region 操作：
```shell
# 对Region 执行 assign 
hbase hbck -j ~ s/hbase-operator-tools-1.2.0/hbase-hbck2/hbase-hbck2-1.2.0.jar assigns -o 23e774d40cdbb3c0949b3f331dc78ea1 
```

Region 恢复正常，可以用canary 或者 Get 测试表，是否完全恢复正常。

RegionServer 出现 HFile异常:
```shell
2023-03-01 20:13:46,242 WARN  [region-location-2] balancer.RegionLocationFinder: IOException during HDFSBlocksDistribution computation. for region = e6f6b7e51ece844ebb25346ee1d3e424
java.io.FileNotFoundException: File does not exist: hdfs://backup-hbase-hdp/hbase/data/default/app_id_v2/537ec7199e5b188c9e49948c769cf1ef/A/8b0869da8f4b4f7b8828a9c03d059396_SeqId_61_
	at org.apache.hadoop.hdfs.DistributedFileSystem$29.doCall(DistributedFileSystem.java:1581)
	at org.apache.hadoop.hdfs.DistributedFileSystem$29.doCall(DistributedFileSystem.java:1574)
	at org.apache.hadoop.fs.FileSystemLinkResolver.resolve(FileSystemLinkResolver.java:81)
	at org.apache.hadoop.hdfs.DistributedFileSystem.getFileStatus(DistributedFileSystem.java:1589)
	at org.apache.hadoop.hbase.regionserver.StoreFileInfo.getReferencedFileStatus(StoreFileInfo.java:352)
	at org.apache.hadoop.hbase.regionserver.StoreFileInfo.computeHDFSBlocksDistributionInternal(StoreFileInfo.java:321)
	at org.apache.hadoop.hbase.regionserver.StoreFileInfo.computeHDFSBlocksDistribution(StoreFileInfo.java:315)
	at org.apache.hadoop.hbase.regionserver.HRegion.computeHDFSBlocksDistribution(HRegion.java:1238)
	at org.apache.hadoop.hbase.regionserver.HRegion.computeHDFSBlocksDistribution(HRegion.java:1206)
	at org.apache.hadoop.hbase.master.balancer.RegionLocationFinder.internalGetTopBlockLocation(RegionLocationFinder.java:198)
	at org.apache.hadoop.hbase.master.balancer.RegionLocationFinder$1$1.call(RegionLocationFinder.java:81)
	at org.apache.hadoop.hbase.master.balancer.RegionLocationFinder$1$1.call(RegionLocationFinder.java:78)
	at org.apache.hbase.thirdparty.com.google.common.util.concurrent.TrustedListenableFutureTask$TrustedFutureInterruptibleTask.runInterruptibly(TrustedListenableFutureTask.java:125)
	at org.apache.hbase.thirdparty.com.google.common.util.concurrent.InterruptibleTask.run(InterruptibleTask.java:69)
	at org.apache.hbase.thirdparty.com.google.common.util.concurrent.TrustedListenableFutureTask.run(TrustedListenableFutureTask.java:78)
	at java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:511)
	at java.util.concurrent.FutureTask.run(FutureTask.java:266)
	at java.util.concurrent.ScheduledThreadPoolExecutor$ScheduledFutureTask.access$201(ScheduledThreadPoolExecutor.java:180)
	at java.util.concurrent.ScheduledThreadPoolExecutor$ScheduledFutureTask.run(ScheduledThreadPoolExecutor.java:293)
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
	at java.lang.Thread.run(Thread.java:748)
2023-03-01 20:13:46,270 WARN  [region-location-3] balancer.RegionLocationFinder: IOException during HDFSBlocksDistribution computation. for region = 902fae4b2bf19cf834fac4a199c9f598
java.io.FileNotFoundException: File does not exist: hdfs://backup-hbase-hdp/hbase/data/default/app_id_v2/a59bbc3938aea4fb2c0d0256f30cf472/A/0bb927da6e874cad81e79175f39896dc_SeqId_68_
	at org.apache.hadoop.hdfs.DistributedFileSystem$29.doCall(DistributedFileSystem.java:1581)
	at org.apache.hadoop.hdfs.DistributedFileSystem$29.doCall(DistributedFileSystem.java:1574)
	at org.apache.hadoop.fs.FileSystemLinkResolver.resolve(FileSystemLinkResolver.java:81)
	at org.apache.hadoop.hdfs.DistributedFileSystem.getFileStatus(DistributedFileSystem.java:1589)
	at org.apache.hadoop.hbase.regionserver.StoreFileInfo.getReferencedFileStatus(StoreFileInfo.java:352)
	at org.apache.hadoop.hbase.regionserver.StoreFileInfo.computeHDFSBlocksDistributionInternal(StoreFileInfo.java:321)
	at org.apache.hadoop.hbase.regionserver.StoreFileInfo.computeHDFSBlocksDistribution(StoreFileInfo.java:315)
	at org.apache.hadoop.hbase.regionserver.HRegion.computeHDFSBlocksDistribution(HRegion.java:1238)
	at org.apache.hadoop.hbase.regionserver.HRegion.computeHDFSBlocksDistribution(HRegion.java:1206)
	at org.apache.hadoop.hbase.master.balancer.RegionLocationFinder.internalGetTopBlockLocation(RegionLocationFinder.java:198)
	at org.apache.hadoop.hbase.master.balancer.RegionLocationFinder$1$1.call(RegionLocationFinder.java:81)
	at org.apache.hadoop.hbase.master.balancer.RegionLocationFinder$1$1.call(RegionLocationFinder.java:78)
	at org.apache.hbase.thirdparty.com.google.common.util.concurrent.TrustedListenableFutureTask$TrustedFutureInterruptibleTask.runInterruptibly(TrustedListenableFutureTask.java:125)
	at org.apache.hbase.thirdparty.com.google.common.util.concurrent.InterruptibleTask.run(InterruptibleTask.java:69)
	at org.apache.hbase.thirdparty.com.google.common.util.concurrent.TrustedListenableFutureTask.run(TrustedListenableFutureTask.java:78)
	at java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:511)
	at java.util.concurrent.FutureTask.run(FutureTask.java:266)
	at java.util.concurrent.ScheduledThreadPoolExecutor$ScheduledFutureTask.access$201(ScheduledThreadPoolExecutor.java:180)
	at java.util.concurrent.ScheduledThreadPoolExecutor$ScheduledFutureTask.run(ScheduledThreadPoolExecutor.java:293)
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
	at java.lang.Thread.run(Thread.java:748)
2023-03-01 20:13:46,270 WARN  [region-location-1] balancer.RegionLocationFinder: IOException during HDFSBlocksDistribution computation. for region = 2e4e230ae474011ee5707eb7fec8d1a5
java.io.FileNotFoundException: File does not exist: hdfs://backup-hbase-hdp/hbase/data/default/app_id_v2/e17415c07f5efdbe3d4ff41b457205a7/A/aaa6fcd4cfda4f1a9e1454d1c95d41fe_SeqId_73_
	at org.apache.hadoop.hdfs.DistributedFileSystem$29.doCall(DistributedFileSystem.java:1581)
	at org.apache.hadoop.hdfs.DistributedFileSystem$29.doCall(DistributedFileSystem.java:1574)
	at org.apache.hadoop.fs.FileSystemLinkResolver.resolve(FileSystemLinkResolver.java:81)
	at org.apache.hadoop.hdfs.DistributedFileSystem.getFileStatus(DistributedFileSystem.java:1589)
	at org.apache.hadoop.hbase.regionserver.StoreFileInfo.getReferencedFileStatus(StoreFileInfo.java:352)
	at org.apache.hadoop.hbase.regionserver.StoreFileInfo.computeHDFSBlocksDistributionInternal(StoreFileInfo.java:321)
	at org.apache.hadoop.hbase.regionserver.StoreFileInfo.computeHDFSBlocksDistribution(StoreFileInfo.java:315)
	at org.apache.hadoop.hbase.regionserver.HRegion.computeHDFSBlocksDistribution(HRegion.java:1238)
	at org.apache.hadoop.hbase.regionserver.HRegion.computeHDFSBlocksDistribution(HRegion.java:1206)
	at org.apache.hadoop.hbase.master.balancer.RegionLocationFinder.internalGetTopBlockLocation(RegionLocationFinder.java:198)
	at org.apache.hadoop.hbase.master.balancer.RegionLocationFinder$1$1.call(RegionLocationFinder.java:81)
	at org.apache.hadoop.hbase.master.balancer.RegionLocationFinder$1$1.call(RegionLocationFinder.java:78)
	at org.apache.hbase.thirdparty.com.google.common.util.concurrent.TrustedListenableFutureTask$TrustedFutureInterruptibleTask.runInterruptibly(TrustedListenableFutureTask.java:125)
	at org.apache.hbase.thirdparty.com.google.common.util.concurrent.InterruptibleTask.run(InterruptibleTask.java:69)
	at org.apache.hbase.thirdparty.com.google.common.util.concurrent.TrustedListenableFutureTask.run(TrustedListenableFutureTask.java:78)
	at java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:511)
	at java.util.concurrent.FutureTask.run(FutureTask.java:266)
	at java.util.concurrent.ScheduledThreadPoolExecutor$ScheduledFutureTask.access$201(ScheduledThreadPoolExecutor.java:180)
	at java.util.concurrent.ScheduledThreadPoolExecutor$ScheduledFutureTask.run(ScheduledThreadPoolExecutor.java:293)
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
	at java.lang.Thread.run(Thread.java:748)
```

使用 filesystem --fix 修复以上问题
```shell
hbase hbck -j ~ s/hbase-operator-tools-1.2.0/hbase-hbck2/hbase-hbck2-1.2.0.jar filesystem --fix app_id_v2
```

执行后问题若还是无法修复，可以将对应Region 下的引用文件进行强制删除：
```shell
# 假设 geo_ip_new 表， Region: ba3a916a55749216a59a923816819058 出现问题
# 找到引用文件
hdfs dfs -ls -l /hbase/data/default/geo_ip_new/ba3a916a55749216a59a923816819058/A | grep "\." | awk '{ print $NF }' 

# 执行删除
hdfs dfs -rm  /hbase/data/default/geo_ip_new/ba3a916a55749216a59a923816819058/A/1583fcee58894c4a829046b371a8fc15.b00fa72df6519151cf98a569c3f482fd 
```

之后再对Region 执行 assign 操作
```shell
hbase hbck -j ~ s/hbase-operator-tools-1.2.0/hbase-hbck2/hbase-hbck2-1.2.0.jar assign  -o ba3a916a55749216a59a923816819058
```


canary 遇到region  not online问题，也可以使用assign 工具解决
```shell
ERROR: org.apache.hadoop.hbase.NotServingRegionException: app_ip_new,0562439629376612551|2020022513,1654594690934.513c23e655b4fb5ff72049f79f8d0a13. is not online on idc01-hbase01-node188.hostname.com,16020,1657111672521
	at org.apache.hadoop.hbase.regionserver.HRegionServer.getRegionByEncodedName(HRegionServer.java:3341)
	at org.apache.hadoop.hbase.regionserver.HRegionServer.getRegion(HRegionServer.java:3318)
	at org.apache.hadoop.hbase.regionserver.RSRpcServices.getRegion(RSRpcServices.java:1428)
	at org.apache.hadoop.hbase.regionserver.RSRpcServices.get(RSRpcServices.java:2464)
	at org.apache.hadoop.hbase.shaded.protobuf.generated.ClientProtos$ClientService$2.callBlockingMethod(ClientProtos.java:42186)
	at org.apache.hadoop.hbase.ipc.RpcServer.call(RpcServer.java:413)
	at org.apache.hadoop.hbase.ipc.CallRunner.run(CallRunner.java:132)
	at org.apache.hadoop.hbase.ipc.RpcExecutor$Handler.run(RpcExecutor.java:324)
	at org.apache.hadoop.hbase.ipc.RpcExecutor$Handler.run(RpcExecutor.java:304)
```


## 高级用法

对处于CLOSED状态的Region 进行批量 assigin 
```shell
echo " scan 'hbase:meta', { COLUMN => 'info:state'}" | hbase shell  > tmp_txt_p7.txt \
cat tmp_txt_p6.txt  | grep "CLOSED"

```


## lock 
lock 解决
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20230506213532.png)

```shell
hbase --config ../data-sync-dispatcher-nj-ods-2-tx-emr/config/emr-ssd-hbase  hbck -j ~/hbase-operator-tools-1.2.0/hbase-hbck2/hbase-hbck2-1.2.0.jar bypass -r  2277

# RIT region 
# 解决 assgin region 
hbase --config ../data-sync-dispatcher-nj-ods-2-tx-emr/config/emr-ssd-hbase  hbck -j ~/hbase-operator-tools-1.2.0/hbase-hbck2/hbase-hbck2-1.2.0.jar  assigns -o 0d20f76480111a18d34083951386eb19

```

# 总结
 大表进行DDL修改是个灾难。

# 参考
- [hbck2 ].  https://github.com/apache/hbase-operator-tools/tree/master/hbase-hbck2
-  [ admin tool hbck2 ]. https://docs.cloudera.com/documentation/enterprise/6/6.3/topics/admin_hbase_hbck.html
- [hbck and hck2 ]. https://bbs.huaweicloud.com/blogs/329387
- https://cloud.tencent.com/developer/article/1786386