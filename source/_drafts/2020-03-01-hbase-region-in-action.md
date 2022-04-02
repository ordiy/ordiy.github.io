---
layout: post
title: 2020-03-01-hbase-region-in-action
categories:
  - tech
tags:
  - blog
date: 2022-03-23 15:21:14
excerpt: hbase-region-in-action
---

# HBase Region 


# Region 实践

## RegionServer合适的Region数量
`memstore_size``RegionServer`的最大区`Region`，一个计算公式（`formula`）：
```javascript
 number of Regions for a region server =
        (regionserver_memory_size) * (memstore_fraction) / ((memstore_size) * (num_column_families))
```
* 参考[cloudera HDP](https://docs.cloudera.com/HDPDocuments/HDP2/HDP-2.1.3/bk_system-admin-guide/content/ch_hbase_cluster_region_count_size_increase_memstore.html)

其中，部分参数可以看作是常数：
Memstore fraction =  0.4  (常量)
column family = 1  （Table通常只有一个column Family)
regionserver_memory_size = 62G/128G （ 机器的内存一般比较固定，可以视为常数）

所以在内存等确定的情况下，`RegionServer`的`Region`个数与`memstore_size`的大小成反比

```javascript
几个计算的例子：

# memstore_size =128Mb ,128G 机器
(128*1024*0.4)/(128*1) =409.6

# memstore_size =64Mb ,128G 机器
(128*1024*0.4)/(64*1) = 819.2
```


## Region 大小
`hbase.hregion.max.filesize`




