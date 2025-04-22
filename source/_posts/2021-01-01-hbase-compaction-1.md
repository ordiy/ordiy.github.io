---
layout: post
title: HBase Major Compaction 优化
categories:
  - tech
tags:
  - blog
date: 2022-06-30 13:00:34
excerpt: HBase RegionServer Major Compaction Turing
---

# Compaction speed limit 

```xml
<property>
  <name>hbase.regionserver.throughput.controller</name>
  <value>org.apache.hadoop.hbase.regionserver.compactions.PressureAwareCompactionThroughputController</value>
  <description>Compaction speed limit ,use PressureAwareCompactionThroughputController</description>
</property>
<property>
  <name>hbase.hstore.compaction.throughput.higher.bound</name>
  <value>209715200</value>
  <description>In normal hours,! off-peak,The default is 200 MB/sec</description>
</property>
<property>
  <name>hbase.hstore.compaction.throughput.lower.bound</name>
  <value>20971520</value>
  <description>In normal hours,! off-peak,The limit is 20 MB/sec</description>
</property>
<property>
  <name>hbase.hstore.compaction.throughput.offpeak</name>
  <value>9223372036854775807</value>
  <description>The default is Long.MAX_VALUE, which effectively means no limitation</description>
</property>
<property>
  <name>hbase.offpeak.start.hour</name>
  <value>22</value>
  <description>When to begin using off-peak compaction settings, expressed as an integer between 0 and 23.</description>
</property>
<property>
  <name>hbase.offpeak.end.hour</name>
  <value>6</value>
  <description>When to stop using off-peak compaction settings, expressed as an integer between 0 and 23.</description>
</property>
<property>
  <name>hbase.hstore.compaction.throughput.tune.period</name>
  <value>60000</value>
</property>
```

* 参考 [Limiting the Speed of Compactions](https://docs.cloudera.com/documentation/enterprise/6/6.3/topics/admin_hbase_compaction_throughput_configure.html)
