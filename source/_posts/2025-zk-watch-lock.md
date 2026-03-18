---
title: 使用 Apache Curator 实现 ZooKeeper 分布式锁
tags:
  - ZooKeeper
  - Curator
  - distributed-lock
  - Java
  - distributed-systems
excerpt: 使用 Apache ZooKeeper 作为分布式协调服务，结合 Apache Curator 客户端库实现分布式锁，通过 InterProcessMutex 管理锁的获取与释放，并附真实测试日志与主备切换场景分析。
layout: post
status: publish
type: post
date: 2025-01-01 00:00:00
updated: 2025-01-01 00:00:00
categories:
  - 分布式系统
---

# 使用Curator实现分布式锁

# 核心逻辑
使用Apache zookeeper作为分布式协调服务，Apache Curator作为Zookeeper的客户端库来实现分布式锁。通过Curator的InterProcessMutex类，可以轻松地创建和管理分布式锁。

```java
            boolean acquired ==  distLock.acquire(lockAwaitSeconds, TimeUnit.SECONDS)){
                try{
                    if(acquired){
                        log.info("Acquired distributed lock:{} Starting SQS consumers."
                                , distLock.getParticipantNodes());
                                // Start SQS consumers for each mapping
                        for (MyQueueMappingPojo mapping : configMappingPojos) {
                            processQueue(mapping);
                        }
                    }
                // log.info("{} SQS consumer tasks started.", configMappingPojos.size());
                }finally{
                    log.info("Releasing distributed lock.");
                    distLock.release();
                }
                
```

# 分布式锁测试日志：

```js
16:38:29.873 [pool-6-thread-1] INFO  com.qiliangjia.data.rb.rb_point_log_cdc_tool.CuratorDistrLockTest - pool-6-thread-1 hold lock start task,lock status:true ,lock_thread:true,info:[/zktest/_c_79b165f5-37f1-4e4f-be7f-be758a1366fc-lock-0000000064, /zktest/_c_a2559588-1443-44a1-a47b-fe5523ee9dc1-lock-0000000065]...
16:38:34.879 [pool-6-thread-1] INFO  com.qiliangjia.data.rb.rb_point_log_cdc_tool.CuratorDistrLockTest - pool-6-thread-1 release lock
16:38:34.940 [pool-5-thread-1] INFO  com.qiliangjia.data.rb.rb_point_log_cdc_tool.CuratorDistrLockTest - pool-5-thread-1 hold lock start task,lock status:true ,lock_thread:true,info:[/zktest/_c_a2559588-1443-44a1-a47b-fe5523ee9dc1-lock-0000000065]...
16:38:39.945 [pool-5-thread-1] INFO  com.qiliangjia.data.rb.rb_point_log_cdc_tool.CuratorDistrLockTest - pool-5-thread-1 release lock
16:38:59.712 [pool-5-thread-1] INFO  com.qiliangjia.data.rb.rb_point_log_cdc_tool.CuratorDistrLockTest - start scheduledExecutorService ....
16:38:59.714 [pool-6-thread-1] INFO  com.qiliangjia.data.rb.rb_point_log_cdc_tool.CuratorDistrLockTest - start scheduledExecutorService2 ....
16:38:59.787 [pool-5-thread-1] INFO  com.qiliangjia.data.rb.rb_point_log_cdc_tool.CuratorDistrLockTest - pool-5-thread-1 hold lock start task,lock status:true ,lock_thread:true,info:[/zktest/_c_998409fd-9a96-47f5-b120-898d1548eec7-lock-0000000066, /zktest/_c_59869c54-7816-4547-b6ee-5e27d00ddda1-lock-0000000067]...
```


backup节点在leader节点挂掉后，立马变成leader节点
```js
15:03:35.287 [main] INFO  com.qiliangjia.data.rb.rb_point_log_cdc_tool.service.SQSMsgHandlerService - startHandler ...
15:03:35.623 [kafka-producer-network-thread | producer-1] INFO  org.apache.kafka.clients.Metadata - [Producer clientId=producer-1] Cluster ID: abmGtN2qRqCh2YIQ_4W1Tg
15:03:35.624 [kafka-producer-network-thread | producer-1] INFO  org.apache.kafka.clients.producer.internals.TransactionManager - [Producer clientId=producer-1] ProducerId set to 13006 with epoch 0
15:04:35.173 [sqs-leader-lock-thread] INFO  com.qiliangjia.data.rb.rb_point_log_cdc_tool.service.SQSMsgHandlerService - Failed to acquire lock within 60s. Will retry.
15:05:38.245 [sqs-leader-lock-thread] INFO  com.qiliangjia.data.rb.rb_point_log_cdc_tool.service.SQSMsgHandlerService - Failed to acquire lock within 60s. Will retry.
15:06:41.302 [sqs-leader-lock-thread] INFO  com.qiliangjia.data.rb.rb_point_log_cdc_tool.service.SQSMsgHandlerService - Failed to acquire lock within 60s. Will retry.
15:07:44.389 [sqs-leader-lock-thread] INFO  com.qiliangjia.data.rb.rb_point_log_cdc_tool.service.SQSMsgHandlerService - Failed to acquire lock within 60s. Will retry.
15:08:47.430 [sqs-leader-lock-thread] INFO  com.qiliangjia.data.rb.rb_point_log_cdc_tool.service.SQSMsgHandlerService - Failed to acquire lock within 60s. Will retry.
15:09:51.688 [sqs-leader-lock-thread] INFO  com.qiliangjia.data.rb.rb_point_log_cdc_tool.service.SQSMsgHandlerService - Failed to acquire lock within 60s. Will retry.
15:10:57.333 [sqs-leader-lock-thread] INFO  com.qiliangjia.data.rb.rb_point_log_cdc_tool.service.SQSMsgHandlerService - Failed to acquire lock within 60s. Will retry.
15:12:00.381 [sqs-leader-lock-thread] INFO  com.qiliangjia.data.rb.rb_point_log_cdc_tool.service.SQSMsgHandlerService - Failed to acquire lock within 60s. Will retry.
15:12:18.356 [sqs-leader-lock-thread] INFO  com.qiliangjia.data.rb.rb_point_log_cdc_tool.service.SQSMsgHandlerService - Acquired distributed lock. Starting SQS consumers.
15:12:18.356 [sqs-leader-lock-thread] INFO  com.qiliangjia.data.rb.rb_point_log_cdc_tool.service.SQSMsgHandlerService - 1 SQS consumer tasks started.
```
