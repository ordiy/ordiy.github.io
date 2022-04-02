---
layout: post
title: HBase写入数据的过程
categories:
  - tech
  - HBase
tags:
  - blog
  - HBase
  - BigTable
  - BigData
date: 2021-02-05 00:00:00
excerpt:  HBase是一款分布式KV数据库系统，在互联网和传统IT行业都有大量应用，也是大数据领域经常使用的一个组件，本文以HBase写入数据的过程为切入点，说明HBase的数据模型。
---

## 简介
  今天在Tencent面试遇到一个面试问题：请说一下HBase写入数据的过程。
没答到关键点上 -_- 。 做个整理，按照Data从Client写入到HBase Server的整个过程，进行说明。

## HBase写数据过程
  以`HBase-Client` 、`HBase-Server` 、`RegionServer`三个重要组件为重点，分析HBase写入数据的整个过程。
- `HBase-Client` 构建和发送RPC请求
HBase-Client写入数据的Code Demo:
```javascript
   public static void main(String[] args) throws IOException {
        //1.1 build put object
        Put put = new Put(Bytes.toBytes("testrow"));
        // family name,  qualifier column qualifier , value column value
        put.addColumn(Bytes.toBytes("fam-1"), Bytes.toBytes("qual-1"), Bytes.toBytes("hbase-value-hello-world-1"));
        put.addColumn(Bytes.toBytes("fam-1"), Bytes.toBytes("qual-2"), Bytes.toBytes("hbase-value-hello-world-02"));
        put.addColumn(Bytes.toBytes("fam-2"), Bytes.toBytes("qual-3"), Bytes.toBytes("hbase-value-hello-world-003"));
    
        //put rpc  CellScanner iterator
        CellScanner scanner = put.cellScanner();
        while (scanner.advance()) {
          Cell cell = scanner.current();
        }
    
        //1.2 send put rpc data
        String tableName = "test-hbase-wr";
        Connection connection = helper.getConnection();
        Table table = connection.getTable(TableName.valueOf(tableName));
        table.put(put);
  }
```
  这里重点关注`org.apache.hadoop.hbase.client.Put` 对象的数据结构：
![](https://raw.githubusercontent.com/ordiychen/study_notes/master/res/image/node_image/blog_20210309171923.png)
`Put`对象的row、列簇、列名、value都被转换为了一个`KeyValue`对象（`KeyValue`对象内是一个由row、列簇、列名、value等拼接成的`byte`类型的数组),`Put`会使用 `protobuf`序列化框架转换为一个的RPC，发送到`HBase-Server`。

- HBase-Server 接收数据的过程
  将写入数据过程抽象为以下阶段：ZK获取metadata, 根据metadata连接到RegionServer获取到此次写入数据的目标RegionServer,向目标RegionServer写数据，目标RegionServer执行IO请求。（这里省略了HBase内部的数据存储过程）。
  ![](https://raw.githubusercontent.com/ordiychen/study_notes/master/res/image/node_image/blog_20210315113739.jpg)


- RegionServer执行IO请求
  RegionServer主要作用是用来响应用户的IO请求，是HBase的核心模块，有WAL(HLog)、BlokCache以及多个Region组成。
  HBase写入数据并非直接写入到HFlie数据文件，而是先写入缓存，再异步刷行落盘。为了防止缓存数据丢失，数据写入缓存之前需要先写入到HLog,这样缓存即使丢失，仍然可以通过HLog日志恢复；另外HBase集群实现集群间的主  复制，通过回放主集群推送过来的HLog日志实现主从复制。


## HBase基本知识
  补充一些关于HBase数据模型的基本知识，以便于更好的理解这个过程。
- HBase 逻辑试图
![](https://raw.githubusercontent.com/ordiychen/study_notes/master/res/image/node_image/blog_20210308113835.jpeg)

- 多维稀疏排序Map
  BigTable论文中称BigTable为"spares,distributed,persistent,multidimensional sort map"。BigTable本质是一个Map结构数据库，HBase亦然，也是一系列KV构成.
HBase的Map的Key是一个复合键，由rowkey,column,family,qualifiter,type以及timestamp组成，value即为cell的值。
例如：
```javascript
{"com.cnn.www","anthor","cnsi.com","put",153212121} -> "CNN"
```

- HBase 物理视图
  HBase中数据是按照列簇存储的，即将数据按照列簇分别存储在不通目录中。
![](https://raw.githubusercontent.com/ordiychen/study_notes/master/res/image/node_image/blog_20210308115402.jpeg)


- HBase 体系结构
![](https://raw.githubusercontent.com/ordiychen/study_notes/master/res/image/node_image/blog_20210318165242.png)





## 参考文献
- HBase原理与实践.机械工业出版社
- [apache hbase book](https://hbase.apache.org/book.html#_configuring_the_rest_server_and_client)
- [Understanding HBase and BigTable](https://dzone.com/articles/understanding-hbase-and-bigtab)