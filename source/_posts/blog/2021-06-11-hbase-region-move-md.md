---
layout: post
title: HBase Region Move 批量操作
date: 2021-06-23 17:15:58
tags:
  - Hadoop
  - HBase
categories:
  - tech
  - BigData
  - Hadoop
  - HBase
excerpt: 对一个PB级的hbase进行RegionServer和DataNode的滚动重启，使用将RegionServer的Region move到一个空闲的RegionServer上，再执行对RegionServer的重启，有效控制在重启过程中对业务的RPC 调用造成影响的问题。
---

# 背景说明
公司的HBase集群部分RegionServer需要进行重启， 每个RegionServer上有1000个左右的RegionServer，单表的容量1T+, 为将RegionServer重启的过程对业务RPC的影响降低最少，需要在重启前将Region移到别的RegionServer上。


# HBase Region 和 Region move 说明
- HBase Region 
HBase 表(Table)根据 rowkey 的范围被水平拆分成若干个 region。每个 region 都包含了这个region 的 start key 和 end key 之间的所有行(row)。Regions 被分配给集群中的某些节点来管理，即 Region Server，由它们来负责处理数据的读写请求。
Region 目录结构：
```
Table                    (HBase table)
    Region               (Regions for the table)
        Store            (Store per ColumnFamily for each Region for the table)
            MemStore     (MemStore for each Store for each Region for the table)
            StoreFile    (StoreFiles for each Store for each Region for the table)
                Block    (Blocks within a StoreFile within a Store for each Region for the table)
```
注：Region是数据表的分片，是RegionServer管理的主要对象。一个Region由一个或多个Store构成（Store数量取决于Column famliy 的个数)。

- region move 过程
Region move 是一个region assign的过程（这里还没找到具体的资料，后续确定了再补充）
![](https://raw.githubusercontent.com/ordiychen/study_notes/master/res/image/node_image/blog_20210623181233.png)

- 使用场景
 主要用于RPC 流量和Region都非常多的HBase集群，避免在RegionServer重启时，部分Region不可用的问题。比如需要迁移/增加ZK节点需要重启RegionServer/DataNode等，但是又要保证业务不受影响。
 Client Scan获取Region信息示意图：
 ![](https://raw.githubusercontent.com/ordiychen/study_notes/master/res/image/node_image/blog_20210623180933.png)


# Region move 操作

## HBase region 信息获取
HBase Region 信息存储在hbase:mata表中，具体可以通过以下方式获取：
```bash 
#hbase2.X 
hbase > scan 'hbase:meta', {  COLUMNS=>['info:sn', 'info:regioninfo']} 
 user_table,user9549,1620813426908.b9130e9b601a0103bac column=info:sn, timestamp=1623903919745, value=sz-hadoop-dev02-9252.xxxxx.com,16020,1623900617214
 ff9d8150f40c0.
 user_table,user9999,1620813426908.6ad01f8a2287220e1db column=info:sn, timestamp=1623903920957, value=sz-hadoop-dev01-9150.xxxxx.com,16020,1623900625182
 d4b7c20db9956.

# hbase1.x 
hbase> scan 'hbase:meta', {  COLUMNS=>['info:regioninfo','info:server'] }
user_table,,1612069265900.fd91d4c9af348e91e8338411992b8860. column=info:regioninfo, timestamp=1612069267443, value={ENCODED => fd91d4c9af348e91e8338411992b8860, NAME => 'user_table,,1612069265900.fd91d4c9af348e91e8338411992b8860.', STARTKEY => '', ENDKEY => '00070K5A9503A5'}
 user_table,,1612069265900.fd91d4c9af348e91e8338411992b8860. column=info:server, timestamp=1619435908083, value=sz-hbase01-node164.xxxxx.com:60020
 user_table,00070K5A9503A5,1612069265900.dc9d6f64b7472a04deb5001c6c5d27bc. column=info:regioninfo, timestamp=1612069267443, value={ENCODED => dc9d6f64b7472a04deb5001c6c5d27bc, NAME => 'user_table,00070K5A9503A5,1612069265900.dc9d6f64b7472a04deb5001c6c5d27bc.', STARTKEY => '00070K5A9503A5', ENDKEY => '00070S5C9A028E4'}

```
*HBase2.x 与HBase1.x 的RegionInfo格式是不一样的，这里需要注意。

## Region blance switch
关闭region的自动均衡策略：
```bash 
hbase>  balance_switch false
```

## HBase region 批量操作
将Node99的Region其全部挪动到指定node235
```bash 
cat << EOF > node99-shell.sh 
#!/bin/shell
node_name="node99"
move_host="hbase01-\${node_name}.xxxxx.com:60020"
#目标RegionServer
target_host="hbase01-node235.xxxxx.com,60020,1624259325292"

echo \$node_name
echo \$move_host
echo \$target_host
echo \$move_hsed
mkdir \$node_name
cd \$node_name 

hbase shell ～/test.txt > "\${node_name}-before-region-info.txt"

#wget convert jar 
#这个jar包只解析了HBase1.x 的Region信息
wget https://github.com/ordiychen/study_notes/blob/master/build-cmd-script.jar

# shell 
/home/xx/jdk1.8.0_181/bin/java -jar build-cmd-script.jar  ～/\$node_name/\${node_name}-before-region-info.txt \$move_host \$target_host 

# test 
echo -n "exit" >>  "\${move_host}-move\${target_host}.txt"
echo "\${move_host}-move\${target_host}.txt"

echo " hbase shell  \${move_host}-move\${target_host}.txt "
echo " ====> "
hbase shell "\${move_host}-move\${target_host}.txt"
echo  "success move ,please use cm restart RegionServer and DataNode"
echo "node is : \${move_host}"
echo " cat \${move_host}-move\${target_host}.txt | sed 's/\${target_host}/"

EOF
```


# 总结
提前移动Region和不移动Region，本地化率变化对比：
![](https://raw.githubusercontent.com/ordiychen/study_notes/master/res/image/node_image/blog_20210730154803.png)
预先move Region，集群的HFile本地化率，更加稳定。
Region 的状态机变换机制复杂，这里只是进行了一个简要的介绍，侧重在于应用层面。

# 参考文献
- 《HBase原理与实践》
- [HBase Book Guide Regions ](https://hbase.apache.org/2.2/book.html#regions.arch)