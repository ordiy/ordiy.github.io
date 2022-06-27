---
layout: post
title: HBase修复Region Holes和meta问题
indexing: true
categories:
  - tech
  - HBase
tags:
  - blog
  - HBase
  - Meta
date: 2022-03-31 17:19:54
excerpt: HBase RIT 终端导致Region Holes和meta问题，进行修复.
---

# 问题
HBase集群因吞吐量太大，导致IO Limit耗尽，必须进行重启，重启后部分表出RIT问题，手动解决了RIT问题后,对表进行`snapshot`失败，并且发现表存在Region Holes和meta不一致的情况
- `snapshot`失败：
```
hbase(main):006:0> snapshot 'xxx_table','snap_xxx_table'

ERROR: org.apache.hadoop.hbase.snapshot.HBaseSnapshotException: Snapshot { ss=snap_xxx_table table=xxx_table type=FLUSH } had an error.  Procedure snap_xxx_table { waiting=[] done=[xxxx-hbase01-node242.idc01.com,60020,1647068132556, xxxx-hbase01-node240.idc01.com,60020,1647067851041, xxxx-hbase01-node241.idc01.com,60020,1646967561168, xxxx-hbase01-node151.idc01.com,60020,1647070546831, xxxx-hbase01-node77.idc01.com,60020,1645502396304, xxxx-hbase01-node59.idc01.com,60020,1645501475468, xxxx-hbase01-node150.idc01.com,60020,1645502396480, xxxx-hbase01-node52.idc01.com,60020,1647079382281, xxxx-hbase01-node69.idc01.com,60020,1647074328442, xxxx-hbase01-node65.idc01.com,60020,1647077291810, xxxx-hbase01-node67.idc01.com,60020,1647077617774, xxxx-hbase01-node49.idc01.com,60020,1647068745578, xxxx-hbase01-node62.idc01.com,60020,1647075997299, xxxx-hbase01-node61.idc01.com,60020,1647071762915, xxxx-hbase01-node72.idc01.com,60020,1647075869766, xxxx-hbase01-node12.idc01.com,60020,1647070206456, xxxx-hbase01-node76.idc01.com,60020,1647072963065, xxxx-hbase01-node66.idc01.com,60020,1647077055538, xxxx-hbase01-node238.idc01.com,60020,1647074861970, xxxx-hbase01-node56.idc01.com,60020,1645502396748, xxxx-hbase01-node63.idc01.com,60020,1645502397816, xxxx-hbase01-node70.idc01.com,60020,1645502396859, xxxx-hbase01-node68.idc01.com,60020,1647069787140, xxxx-hbase01-node148.idc01.com,60020,1647067131840, xxxx-hbase01-node11.idc01.com,60020,1647066555077, xxxx-hbase01-node149.idc01.com,60020,1647069186054, xxxx-hbase01-node53.idc01.com,60020,1647069998692, xxxx-hbase01-node244.idc01.com,60020,1646797902036, xxxx-hbase01-node71.idc01.com,60020,1647075256801, xxxx-hbase01-node78.idc01.com,60020,1647076192048, xxxx-hbase01-node58.idc01.com,60020,1645502398506, xxxx-hbase01-node60.idc01.com,60020,1647071434665, xxxx-hbase01-node74.idc01.com,60020,1647072760278, xxxx-hbase01-node75.idc01.com,60020,1647076919846, xxxx-hbase01-node55.idc01.com,60020,1647071170284, xxxx-hbase01-node64.idc01.com,60020,1647076141961, xxxx-hbase01-node57.idc01.com,60020,1645502395942, xxxx-hbase01-node239.idc01.com,60020,1647067519317, xxxx-hbase01-node54.idc01.com,60020,1647074700145, xxxx-hbase01-node73.idc01.com,60020,1647076545514, xxxx-hbase01-node51.idc01.com,60020,1647065772433, xxxx-hbase01-node50.idc01.com,60020,1647070897706, xxxx-hbase01-node10.idc01.com,60020,1647069855452] }
	at org.apache.hadoop.hbase.master.snapshot.SnapshotManager.isSnapshotDone(SnapshotManager.java:342)
	at org.apache.hadoop.hbase.master.MasterRpcServices.isSnapshotDone(MasterRpcServices.java:944)
	at org.apache.hadoop.hbase.protobuf.generated.MasterProtos$MasterService$2.callBlockingMethod(MasterProtos.java:44263)
	at org.apache.hadoop.hbase.ipc.RpcServer.call(RpcServer.java:2034)
	at org.apache.hadoop.hbase.ipc.CallRunner.run(CallRunner.java:107)
	at org.apache.hadoop.hbase.ipc.RpcExecutor.consumerLoop(RpcExecutor.java:130)
	at org.apache.hadoop.hbase.ipc.RpcExecutor$1.run(RpcExecutor.java:107)
	at java.lang.Thread.run(Thread.java:745)
Caused by: org.apache.hadoop.hbase.errorhandling.ForeignException$ProxyThrowable via xxxx-hbase01-node151.idc01.com,60020,1647070546831:org.apache.hadoop.hbase.errorhandling.ForeignException$ProxyThrowable: java.io.FileNotFoundException: File does not exist: hdfs://nameservice-hbase1/hbase/data/default/xxx_table/3ba583b9e43fe9efcbcb85d41b62e61d/A/c215951ed4a94c2284b6ea7b4b02fdd2
	at org.apache.hadoop.hbase.errorhandling.ForeignExceptionDispatcher.rethrowException(ForeignExceptionDispatcher.java:83)
	at org.apache.hadoop.hbase.master.snapshot.TakeSnapshotHandler.rethrowExceptionIfFailed(TakeSnapshotHandler.java:313)
	at org.apache.hadoop.hbase.master.snapshot.SnapshotManager.isSnapshotDone(SnapshotManager.java:332)
	... 7 more
Caused by: org.apache.hadoop.hbase.errorhandling.ForeignException$ProxyThrowable: java.io.FileNotFoundException: File does not exist: hdfs://nameservice-hbase1/hbase/data/default/xxx_table/3ba583b9e43fe9efcbcb85d41b62e61d/A/c215951ed4a94c2284b6ea7b4b02fdd2
	at org.apache.hadoop.hbase.regionserver.snapshot.RegionServerSnapshotManager$SnapshotSubprocedurePool.waitForOutstandingTasks(RegionServerSnapshotManager.java:339)
	at org.apache.hadoop.hbase.regionserver.snapshot.FlushSnapshotSubprocedure.flushSnapshot(FlushSnapshotSubprocedure.java:138)
	at org.apache.hadoop.hbase.regionserver.snapshot.FlushSnapshotSubprocedure.insideBarrier(FlushSnapshotSubprocedure.java:157)
	at org.apache.hadoop.hbase.procedure.Subprocedure.call(Subprocedure.java:187)
	at org.apache.hadoop.hbase.procedure.Subprocedure.call(Subprocedure.java:53)
	at java.util.concurrent.FutureTask.run(FutureTask.java:262)
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1145)
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:615)
	... 1 more
  ```

- hbck table 
```bash
hbase hbck xxx_table
```
```
ERROR: Region { meta => xxx_table,9025001908395714571,1646715649569.020eddd9bc17a4e84a2ca14a2c1eba58., hdfs => hdfs://nameservice-hbase1/hbase/data/default/xxx_table/020eddd9bc17a4e84a2ca14a2c1eba58, deployed => , replicaId => 0 } not deployed on any region server.
ERROR: Region { meta => xxx_table,649,1647077867939.02d349f43cc84a186d66933aad7598a4., hdfs => hdfs://nameservice-hbase1/hbase/data/default/xxx_table/02d349f43cc84a186d66933aad7598a4, deployed => , replicaId => 0 } not deployed on any region server.
ERROR: Region { meta => xxx_table,062,1647077866823.03b69057055b7ff936720635a2079f20., hdfs => hdfs://nameservice-hbase1/hbase/data/default/xxx_table/03b69057055b7ff936720635a2079f20, deployed => , replicaId => 0 } not deployed on any region server.
....
ERROR: There is a hole in the region chain between 001 and 0015000377495714571.  You need to create a new .regioninfo and region dir in hdfs to plug the hole.
ERROR: There is a hole in the region chain between 009 and 0095009610695714571.  You need to create a new .regioninfo and region dir in hdfs to plug the hole.
ERROR: There is a hole in the region chain between 010 and 0104992836495714571.  You need to create a new .regioninfo and region dir in hdfs to plug the hole.
ERROR: There is a hole in the region chain between 0145001196765771651 and 015.  You need to create a new .regioninfo and region dir in hdfs to plug the hole.
ERROR: There is a hole in the region chain between 016 and 0165015829595714571.  You need to create a new .regioninfo and region dir in hdfs to plug the hole.
ERROR: There is a hole in the region chain between 017 and 018.  You need to create a new .regioninfo and region dir in hdfs to plug the hole.
.....
Status: INCONSISTENT
```

- 问题分析
 对于`not deployed on any region server` 问题，是由于Region元数据信息在HDFS和hbase:meta中都存在，但是没有部署到任何RegionServer上，需要进行`assign`到RegionServer上。
 对于`You need to create a new .regioninfo and region dir in hdfs to plug the hole`问题，是由于Region Holes（空洞问题导致的）。可以使用` -fixHdfsHoles`选项问题进行修复，这个命令会在空洞形成的地方填充一个空Region（注意：` -fixHdfsHoles` 通常要与`-fixAssignments -fixMeta` 一起使用。

# 解决
```
# 执行修复
hbase hbck -fixAssignments -fixMeta -fixHdfsHoles xxx_table
```
检查结果：
```
# 
hbase hbck xxx_table -details
```


## 参考
- [1] [Hbase修复工具Hbck](https://developer.aliyun.com/article/899875)
- [2]  [HBase原理与实践]



