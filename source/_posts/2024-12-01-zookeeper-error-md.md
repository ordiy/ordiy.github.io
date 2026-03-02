---
title: Zookeeper遇到网络异常log
date: 2024-12-10 17:51:37
categories:
 - Data
tags:
  - zookeeper
layout: post
excerpt: Zookeeper遇到网络异常出现的log
---

# log 
```js

2025-02-10 21:46:21,422 [myid:2] - WARN  [LeaderConnector-/10.21.100.211:2888:o.a.z.s.q.Learner$LeaderConnector@448] - Unexpected exception, tries=0, remaining init limit=464551, connecting t
o /10.21.100.211:2888
java.net.ConnectException: Connection timed out
        at java.base/sun.nio.ch.Net.pollConnect(Native Method)
        at java.base/sun.nio.ch.Net.pollConnectNow(Net.java:672)
        at java.base/sun.nio.ch.NioSocketImpl.timedFinishConnect(NioSocketImpl.java:554)
        at java.base/sun.nio.ch.NioSocketImpl.connect(NioSocketImpl.java:602)
        at java.base/java.net.SocksSocketImpl.connect(SocksSocketImpl.java:327)
        at java.base/java.net.Socket.connect(Socket.java:633)
        at org.apache.zookeeper.server.quorum.Learner.sockConnect(Learner.java:305)
        at org.apache.zookeeper.server.quorum.Learner$LeaderConnector.connectToLeader(Learner.java:422)
        at org.apache.zookeeper.server.quorum.Learner$LeaderConnector.run(Learner.java:380)
        at java.base/java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:539)
        at java.base/java.util.concurrent.FutureTask.run(FutureTask.java:264)
        at java.base/java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1136)
        at java.base/java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:635)
        at java.base/java.lang.Thread.run(Thread.java:840)
2025-02-10 21:46:21,524 [myid:2] - INFO  [LeaderConnector-/10.21.100.211:2888:o.a.z.s.q.Learner$LeaderConnector@384] - Successfully connected to leader, using address: /10.21.100.211:2888
2025-02-10 21:46:21,527 [myid:2] - INFO  [QuorumPeer[myid=2](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):o.a.z.s.q.QuorumPeer@917] - Peer state changed: following - synchronization
2025-02-10 21:46:22,055 [myid:2] - INFO  [QuorumPeer[myid=2](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):o.a.z.s.q.Learner@565] - Getting a diff from the leader 0x11133d3b9f
2025-02-10 21:46:22,055 [myid:2] - INFO  [QuorumPeer[myid=2](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):o.a.z.s.q.QuorumPeer@922] - Peer state changed: following - synchronization - diff
2025-02-10 21:46:22,056 [myid:2] - WARN  [QuorumPeer[myid=2](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):o.a.z.s.q.Learner@637] - Got zxid 0x11133bc361 expected 0x1
2025-02-10 21:46:22,393 [myid:2] - INFO  [QuorumPeer[myid=2](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):o.a.z.s.q.Learner@737] - Learner received NEWLEADER message
2025-02-10 21:46:22,393 [myid:2] - INFO  [QuorumPeer[myid=2](plain=[0:0:0:0:0:0:0:0]:2181)(secure=disabled):o.a.z.s.q.QuorumPeer@1892] - Dynamic reconfig is disabled, we don't store the last
seen config.


```
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/2024202502111454023.png)


# desc 
Zookeeper遇到这种问题，节点会进入孤立模式（尝试将自己变为Leader，但是会失败, 这里是因为`standaloneEnabled`配置错误， 3node情况下应该配置`standaloneEnabled=false`）

