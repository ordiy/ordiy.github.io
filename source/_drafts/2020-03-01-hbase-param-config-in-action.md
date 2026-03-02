---
layout: post
title: HBase 一些配置参数的注意事项
categories:
  - tech
tags:
  - blog
date: 2022-03-23 15:25:11
excerpt: HBase 一些配置参数的注意事项
---

# 配置参数

`hbase-site.xml` 配置参数
|:--|:--|:--|:--|
|param name| desc | default value | anttention |
|`hbase.client.keyvalue.maxsize`              |  single HBase table cell.customize the maximum cell size | The minimum cell size is 24 bytes and the default maximum is 10485760 bytes. |  HBase table cells are aggregated into blocks |
|`hbase.mapreduce.hfileoutputformat.blocksize`|  HBase table cells are aggregated into blocks(hdfs) |The default value is 65536 bytes | Administrators may reduce this value for tables with highly random data access patterns to improve query latency. |
|`hbase.hregion.memstore.flush.size` | single memstore size |   which grow to a configurable size, usually between 128 and 256 Mb |  ｜
