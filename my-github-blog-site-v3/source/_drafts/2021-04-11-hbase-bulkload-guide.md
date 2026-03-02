---
layout: post
title: 2021-04-11-hbase-bulkload-guide
categories:
  - tech
tags:
  - blog
date: 2022-11-16 11:46:19
excerpt: hbase bulkload guide config 
---


# config 



```xml

 <property>
    <name>hbase.regionserver.thread.compaction.large</name>
    <value>15</value>
  </property>
  <property>
    <name>hbase.regionserver.thread.compaction.small</name>
    <value>15</value>
  </property>
  <property>
    <name>hbase.hstore.compaction.min</name>
    <value>6</value>
  </property>
  <property>
    <name>hbase.hstore.compaction.max</name>
    <value>50</value>
  </property>
  <property>
    <name>hbase.hstore.compaction.max.size</name>
    <value>10737418240</value>
  </property>


```

<property>
	<name>hbase.regionserver.throughput.controller</name>
	<value>org.apache.hadoop.hbase.regionserver.compactions.PressureAwareCompactionThroughputController</value>
	<description>限制compaction速度：限速的controller类</description>
</property>
<property>
	<name>hbase.hstore.compaction.throughput.offpeak</name>
	<value>9223372036854775807</value>
	<description>限制compaction速度：Cluster非高峰时期不限制速度</description>
</property>
<property>
	<name>hbase.hstore.compaction.throughput.lower.bound</name>
	<value>10485760</value>
	<description>限制compaction速度：高峰时期compaction限速下线10M/s</description>
</property>
<property>
	<name>hbase.hstore.compaction.throughput.higher.bound</name>
	<value>83886080</value>
	<description>限制compaction速度：高峰时期compaction限速上线80M/s</description>
</property>
<property>
	<name>hbase.offpeak.start.hour</name>
	<value>22</value>
	<description>限制compaction速度：业务非高峰时期晚上20点开始</description>
</property>
<property>
	<name>hbase.offpeak.end.hour</name>
	<value>6</value>
	<description>限制compaction速度：业务非高峰时期早上6点结束</description>
</property>
<property>
  <name>hbase.hstore.compaction.throughput.tune.period</name>
  <value>60000</value>
</property>

<property>
	<name>hbase.ipc.warn.response.time</name>
	<value>2000</value>
	<description>慢查询阈值：查询处理时间超过2s记录</description>
</property>
<property>
	<name>hbase.regionserver.thread.compaction.large</name>
	<value>10</value>
	<description>增加compaction线程：大的compaction线程增加到10个</description>
</property>
<property>
	<name>hbase.regionserver.region.split.policy</name>
        <value>org.apache.hadoop.hbase.regionserver.ConstantSizeRegionSplitPolicy</value>
</property>
<property>
	<name>hbase.storescanner.parallel.seek.enable</name>
        <value>true</value>
</property>
<property>
	<name>dfs.client.cache.readahead</name>
        <value>0</value>
</property>
<property>
	<name>hbase.storescanner.parallel.seek.threads</name>
        <value>32</value>
</property>
<property>
	<name>hbase.regionserver.compaction.private.readers</name>
        <value>true</value>
	<description>compaction使用单独的reader</description>
</property>
<property>
   <name>ipc.client.connect.max.retries.on.timeouts</name>
   <value>2</value>
</property>
<property>
   <name>dfs.client.socket-timeout</name>
   <value>10000</value>
</property>
<!--  关于compact的参数 -->
<property>
    <name>hbase.hstore.compactionThreshold</name>
    <value>3</value>
</property>
<property>
    <name>hbase.hstore.compaction.max</name>
    <value>100</value>
</property>

<property>
    <name>hbase.regionserver.thread.compaction.small</name>
    <value>10</value>
</property>


===> 
<property>
    <name>hbase.hregion.max.filesize</name>
    <value>100G</value>
</property>

<property>
    <name>hbase.hstore.compactionThreshold</name>
    <value>100</value>
</property>
```
