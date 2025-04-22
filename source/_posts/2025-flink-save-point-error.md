---
layout: post
title: Flink Save point error 
tags:
  - flink
categories:
  - tech
  - data
excerpt: Flink run指定save point时，任务启动失败 
date: 2025-01-01 00:00:00
---

# flink run use save point error
Flink run指定save point时，任务启动失败，日志如下：

```javascript

Caused by: java.util.concurrent.CompletionException: java.lang.IllegalStateException: Failed to rollback to checkpoint/savepoint file:/data/task-jar-file/tmp/savepoint-5320bf-9ef9c8b06c9b. Cannot map checkpoint/savepoint state for operator 62ceb6347fdaf6baff74befbfe9a14bf to the new program, because the operator is not available in the new program. If you want to allow to skip this, you can set the --allowNonRestoredState option on the CLI.
	at java.util.concurrent.CompletableFuture.encodeThrowable(CompletableFuture.java:273)
	at java.util.concurrent.CompletableFuture.completeThrowable(CompletableFuture.java:280)
	at java.util.concurrent.CompletableFuture$AsyncSupply.run(CompletableFuture.java:1606)
	... 3 more
Caused by: java.lang.IllegalStateException: Failed to rollback to checkpoint/savepoint file:/data/task-jar-file/tmp/savepoint-5320bf-9ef9c8b06c9b. Cannot map checkpoint/savepoint state for operator 62ceb6347fdaf6baff74befbfe9a14bf to the new program, because the operator is not available in the new program. If you want to allow to skip this, you can set the --allowNonRestoredState option on the CLI.
	at org.apache.flink.runtime.checkpoint.Checkpoints.throwNonRestoredStateException(Checkpoints.java:238)
	at org.apache.flink.runtime.checkpoint.Checkpoints.loadAndValidateCheckpoint(Checkpoints.java:203)
	at org.apache.flink.runtime.checkpoint.CheckpointCoordinator.restoreSavepoint(CheckpointCoordinator.java:1849)
	at org.apache.flink.runtime.scheduler.DefaultExecutionGraphFactory.tryRestoreExecutionGraphFromSavepoint(DefaultExecutionGraphFactory.java:223)
	at org.apache.flink.runtime.scheduler.DefaultExecutionGraphFactory.createAndRestoreExecutionGraph(DefaultExecutionGraphFactory.java:198)
	at org.apache.flink.runtime.scheduler.SchedulerBase.createAndRestoreExecutionGraph(SchedulerBase.java:365)
	at org.apache.flink.runtime.scheduler.SchedulerBase.<init>(SchedulerBase.java:210)
	at org.apache.flink.runtime.scheduler.DefaultScheduler.<init>(DefaultScheduler.java:136)
	at org.apache.flink.runtime.scheduler.DefaultSchedulerFactory.createInstance(DefaultSchedulerFactory.java:152)
	at org.apache.flink.runtime.jobmaster.DefaultSlotPoolServiceSchedulerFactory.createScheduler(DefaultSlotPoolServiceSchedulerFactory.java:119)
	at org.apache.flink.runtime.jobmaster.JobMaster.createScheduler(JobMaster.java:371)
	at org.apache.flink.runtime.jobmaster.JobMaster.<init>(JobMaster.java:348)
	at org.apache.flink.runtime.jobmaster.factories.DefaultJobMasterServiceFactory.internalCreateJobMasterService(DefaultJobMasterServiceFactory.java:123)
	at org.apache.flink.runtime.jobmaster.factories.DefaultJobMasterServiceFactory.lambda$createJobMasterService$0(DefaultJobMasterServiceFactory.java:95)
	at org.apache.flink.util.function.FunctionUtils.lambda$uncheckedSupplier$4(FunctionUtils.java:112)
	at java.util.concurrent.CompletableFuture$AsyncSupply.run(CompletableFuture.java:1604)
	... 3 more

```

Flink task jar 任务中有算子调整，导致`flink run -s xxxx ` 启动失败, 配置 `flink run -s xxx --allowNonRestoredState ` 解决以上问题

