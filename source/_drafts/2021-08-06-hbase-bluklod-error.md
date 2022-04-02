---
layout: post
title: 2021-08-06-hbase-bluklod-error
categories:
  - tech
tags:
  - blog
date: 2021-08-10 10:54:25
excerpt: HBase Bluckload Action
---


# 问题描述
HFile BulkLoad 时候遇到 Region分裂，导致HFile导入速率极速下降
```
2021-08-10 00:35:30,669 INFO  [LoadIncrementalHFiles-3] tool.LoadIncrementalHFiles: HFile at hdfs://psd-hbase/tmp/ods/hfiles/psd-202108/jdid_cell_20210720_A_617/N1WKRCTERHZ/A/5e66f4289e41469c996fbe7f978bf4f8 no longer fits inside a single region. Splitting...
2021-08-10 00:35:30,669 INFO  [LoadIncrementalHFiles-17] tool.LoadIncrementalHFiles: HFile at hdfs://psd-hbase/tmp/ods/hfiles/psd-202108/jdid_cell_20210720_A_617/N1WKRCTERHZ/A/f88ae58558f34ff4af38a900882bf963 no longer fits inside a single region. Splitting...
2021-08-10 00:35:30,669 INFO  [LoadIncrementalHFiles-1] tool.LoadIncrementalHFiles: HFile at hdfs://psd-hbase/tmp/ods/hfiles/psd-202108/jdid_cell_20210720_A_617/N1WKRCTERHZ/A/2d7e66df369a4d29b33ee670f5a0f153 no longer fits inside a single region. Splitting...
```
