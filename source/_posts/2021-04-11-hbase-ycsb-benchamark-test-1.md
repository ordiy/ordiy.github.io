---
layout: post
title: HBase2 YCSB benchmark test
tags:
  - HBase
  - YCSB
categories:
  - tech
  - BigData
excerpt: 使用 YCSB 对HBase2.1.6进行 benchamark test，测试在不同workload场景下HBase的性能，并进行总结和分析。
date: 2021-05-21 11:09:29
---

# 测试环境说明
------------

机器/网络 环境:

|- | 配置说明|
|:---|:---|
|物理机器配置信息 |CPU32C , 64G Memory , 3T 磁盘 （10个挂载) ,万兆网卡  |
| 虚拟化                       | 无 (物理机器运行) |
|网络                         | 万兆网卡/100G交换机 |
| 机柜/机架情况               |   所有节点在同机架 |
| OS 版本                     | Centos 7.5  |

软件版本:       

|-  | 配置说明|
|:---|:---|
|HBase | 2.1.6-CDH3.1.5 | 
|HDFS | 3.1.1-CDH3.1.5 |
|ambari | 2.7.4-CDH3.1.5 |
|JDK |  1.8_u181 |  
|YCSB | 0.18.0-SNAPHOT |

# 测试方案
----------------

测试说明:

|-  | 说明|
|:---|:---|
| 目的 | 测试HBase在生产环境的下的基准性能 |
|数据量  | 4T（按照生产环境 预估）,1000+ Region .YCSB 一次写入1kb，4T数据约需要43亿行（4 * 1024 * 1024 * 1024 ）| 

## 场景设计

|场景| ycsb workload name |  desc |  分布 |
|:---|:---|:---|:---|
| 读0% / 写100% | workload_g | 单写入场景/SYNC_WAL  | Zipfian：随机选择记录，存在热记录 |
| 读20% / 写80% | workload_h | 读少些多场景         | Zipfian：随机选择记录，存在热记录 |
| 读20%/ 写80% | workload_j | 读多写少场景         | Zipfian：随机选择记录，存在热记录 |
| 读100%/写0% | workload_m | 全读取              | Zipfian：随机选择记录，存在热记录 |
| 补充测试场景-读100%/写0% | workload_m | 全读取              | uniform：全随机选择记录，不存在热记录 |

## 工具准备
YCSB 工具当前的Release版本是1.7，对应的Hbase client 版本是`2.0.0`,最新master分支的代码使用client是`2.3.6`,这里选用master分支上的最新代码自行编译和构建。

```
$ git clone https://github.com/brianfrankcooper/YCSB.git
$ cd YCSB 

# build 
$ mvn -pl site.ycsb:mongodb-binding -am clean package

# jar 包打包位置
$ ll /hbase2/target/ycsb-hbase2-binding-0.18.0-SNAPSHOT.tar.gz

#copy 
$ cp .//hbase2/target/ycsb-hbase2-binding-0.18.0-SNAPSHOT.tar.gz /opt/app
$ cd /opt/app
$ tar -zxvf ycsb-hbase2-binding-0.18.0-SNAPSHOT.tar.gz
$ ln -s ycsb-hbase2-binding-0.18.0-SNAPSHOT ycsb-hbase2

# 配置
export YCSB_HOME=/opt/app/ycsb-hbase2
export PATH=$PATH:$YCSB_HOME/bin

# 配置hbase config
$ mkdir conf 

# 将hbase hase-site.xml文件拷贝到 conf
$ cp /etc/hbase/conf/hbase-site.xml ./conf
```

# 进行测试
------------
## 准备-测试数据
hbase 创建测试表
```javascript
# 用的机器是HDD的磁盘
# regionNum = RegionServer * 350 
# 我这边有3个Region
# region后续也可以通过split 进行自动调整
hbase(main):001:0> n_splits = 1050 # HBase recommends (10 * number of regionservers)
hbase(main):002:0> create 'user_table2', 'cf', {SPLITS => (1..n_splits).map {|i| "user#{10000+i*(99999-10000)/n_splits}"}}

```
准备写入数据:
```javascript
# 这一步耗时很长，我这边用了24H 多写入了
# 使用2个客户端并行写入 42亿

#insertstart 0 ~ 2100000000
$ nohup  ycsb load hbase2 -P workloads/workloada -jvm-args='-XX:+UseG1GC -Xms10g -Xmx20g' -cp /opt/app/ycsb-0.17.0/hbase20-binding/conf -p table=user_table2 -p columnfamily=cf -p durability=ASYNC_WAL -p insertstart=0 -p recordcount=2100000000 -p operationcount=2100000000 -threads 64 -s  > workloada_load_1.log 2>&1 & 

#insertstart 0 ~ 2100000000 
nohup  ycsb load hbase20 -P workloads/workloada -jvm-args='-XX:+UseG1GC -Xms10g -Xmx20g' -cp /opt/app/ycsb-0.17.0/hbase20-binding/conf -p table=user_table2 -p columnfamily=cf -p durability=ASYNC_WAL -p insertstart=2100000000 -p recordcount=2100000000 -p operationcount=2100000000 -threads 64 -s  > workloada_load_2.log 2>&1 & 
```

## 执行测试场景A `读0%/写100%`
写入数据完成，执行测试场景A：
```javascript
$ cat << EOF > workloads/workloadm
readallfields=true
readproportion=0.00
updateproportion=0
scanproportion=0
insertproportion=1.0
requestdistribution=zipfian
EOF
 
$ nohup ./bin/ycsb run hbase2 -P workloads/workloadm -jvm-args='-XX:+UseG1GC -Xms2g -Xmx20g' -cp /opt/app/ycsb-0.17.0/hbase20-binding/conf -p table=user_table2 -p columnfamily=cf -p recordcount=1000000000 -p operationcount=1000000000 -threads 64 -s > workloada_m.log 2>&1 & 

```

测试结果：
```javascript
#ycsb 测试结果
[OVERALL], RunTime(ms), 54185529
[OVERALL], Throughput(ops/sec), 36910.22376103406
[TOTAL_GCS_G1_Young_Generation], Count, 6289
[TOTAL_GC_TIME_G1_Young_Generation], Time(ms), 87444
[TOTAL_GC_TIME_%_G1_Young_Generation], Time(%), 0.1613788803279931
[TOTAL_GCS_G1_Old_Generation], Count, 0
[TOTAL_GC_TIME_G1_Old_Generation], Time(ms), 0
[TOTAL_GC_TIME_%_G1_Old_Generation], Time(%), 0.0
[TOTAL_GCs], Count, 6289
[TOTAL_GC_TIME], Time(ms), 87444
[TOTAL_GC_TIME_%], Time(%), 0.1613788803279931
[CLEANUP], Operations, 128
[CLEANUP], AverageLatency(us), 43.140625
[CLEANUP], MinLatency(us), 1
[CLEANUP], MaxLatency(us), 3591
[CLEANUP], 95thPercentileLatency(us), 36
[CLEANUP], 99thPercentileLatency(us), 566
[INSERT], Operations, 2000000000
[INSERT], AverageLatency(us), 1730.6711586995
[INSERT], MinLatency(us), 119
[INSERT], MaxLatency(us), 7602175
[INSERT], 95thPercentileLatency(us), 1453
[INSERT], 99thPercentileLatency(us), 4195
[INSERT], Return=OK, 2000000000
```

测试机器负载：
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20210521135955.png)

QPS 监控:
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20210521140105.png)

## 执行测试B-读20%写80%
```javascript
$ cat << EOF > workloads/workloadg
readallfields=true
readproportion=0.20
updateproportion=0
scanproportion=0
insertproportion=0.80
requestdistribution=zipfian
EOF
 
$ $ nohup ./bin/ycsb load hbase2 -P workloads/workloadg -jvm-args='-XX:+UseG1GC -Xms2g -Xmx20g' -cp /opt/dp/ycsb-0.17.0/hbase20-binding/conf -p table=user_table2 -p columnfamily=cf -p recordcount=1000000000 -p operationcount=1000000000 -threads 64 -s > workloada_g.log 2>&1 & 

```
YCSB 测试结果：
```javascript
[OVERALL], RunTime(ms), 8444494
[OVERALL], Throughput(ops/sec), 11842.035769105882
[TOTAL_GCS_G1_Young_Generation], Count, 316
[TOTAL_GC_TIME_G1_Young_Generation], Time(ms), 4594
[TOTAL_GC_TIME_%_G1_Young_Generation], Time(%), 0.05440231232327242
[TOTAL_GCS_G1_Old_Generation], Count, 0
[TOTAL_GC_TIME_G1_Old_Generation], Time(ms), 0
[TOTAL_GC_TIME_%_G1_Old_Generation], Time(%), 0.0
[TOTAL_GCs], Count, 316
[TOTAL_GC_TIME], Time(ms), 4594
[TOTAL_GC_TIME_%], Time(%), 0.05440231232327242
[READ], Operations, 19995388
[READ], AverageLatency(us), 23096.382339317446
[READ], MinLatency(us), 138
[READ], MaxLatency(us), 41287679
[READ], 95thPercentileLatency(us), 66879
[READ], 99thPercentileLatency(us), 218239
[READ], Return=OK, 19995388
[CLEANUP], Operations, 168
[CLEANUP], AverageLatency(us), 28.136904761904763
[CLEANUP], MinLatency(us), 0
[CLEANUP], MaxLatency(us), 2683
[CLEANUP], 95thPercentileLatency(us), 24
[CLEANUP], 99thPercentileLatency(us), 51
[INSERT], Operations, 80004612
[INSERT], AverageLatency(us), 3044.945812198927
[INSERT], MinLatency(us), 240
[INSERT], MaxLatency(us), 40861695
[INSERT], 95thPercentileLatency(us), 736
[INSERT], 99thPercentileLatency(us), 2967
[INSERT], Return=OK, 80004612
```

## 执行测试C-读80%写20%  
```javascript
$ cat << EOF > workloads/workloadh
recordcount=100000000
operationcount=100000000
workload=site.ycsb.workloads.CoreWorkload
readallfields=true
readproportion=0.8
updateproportion=0
scanproportion=0
insertproportion=0.20
requestdistribution=zipfian
EOF

$ nohup ./bin/ycsb run hbase2 -P workloads/workloadh -jvm-args='-XX:+UseG1GC -Xms10g -Xmx10g ' -cp /opt/dp/ycsb-hbase2/conf -p table=user_table2 -p columnfamily=cf -p recordcount=100000000 -p operationcount=100000000 -threads 84 -s > workload_h_log.log 2>&1 
 
```
测试结果：
```javascript
[OVERALL], RunTime(ms), 1622208
[OVERALL], Throughput(ops/sec), 6164.437606028327
[TOTAL_GCS_G1_Young_Generation], Count, 34
[TOTAL_GC_TIME_G1_Young_Generation], Time(ms), 582
[TOTAL_GC_TIME_%_G1_Young_Generation], Time(%), 0.03587702686708486
[TOTAL_GCS_G1_Old_Generation], Count, 0
[TOTAL_GC_TIME_G1_Old_Generation], Time(ms), 0
[TOTAL_GC_TIME_%_G1_Old_Generation], Time(%), 0.0
[TOTAL_GCs], Count, 34
[TOTAL_GC_TIME], Time(ms), 582
[TOTAL_GC_TIME_%], Time(%), 0.03587702686708486
[READ], Operations, 7999801
[READ], AverageLatency(us), 16489.358773674496
[READ], MinLatency(us), 120
[READ], MaxLatency(us), 18448383
[READ], 95thPercentileLatency(us), 61855
[READ], 99thPercentileLatency(us), 222207
[READ], Return=OK, 7999801
[CLEANUP], Operations, 168
[CLEANUP], AverageLatency(us), 22.125
[CLEANUP], MinLatency(us), 1
[CLEANUP], MaxLatency(us), 2257
[CLEANUP], 95thPercentileLatency(us), 12
[CLEANUP], 99thPercentileLatency(us), 71
[INSERT], Operations, 2000199
[INSERT], AverageLatency(us), 1431.605406762027
[INSERT], MinLatency(us), 241
[INSERT], MaxLatency(us), 18120703
[INSERT], 95thPercentileLatency(us), 542
[INSERT], 99thPercentileLatency(us), 4099
[INSERT], Return=OK, 2000199
```


##  测试场景D - 读100% / 写0%

```javacript

$ cat >> EOF > workloads/workloadj
recordcount=100000000
operationcount=100000000
workload=site.ycsb.workloads.CoreWorkload
readallfields=true
readproportion=1.0
updateproportion=0.0
scanproportion=0.0
insertproportion=0.0
requestdistribution=zipfian

EOF
 
$ nohup ./bin/ycsb run hbase2 -P workloads/workloadj -jvm-args='-XX:+UseG1GC -Xms10g -Xmx10g '  -cp /opt/dp/ycsb-hbase2/conf -p table=user_table2 -p columnfamily=cf  -p recordcount=100000000 -p operationcount=100000000 -threads 84 -s > workload_j.log 2>&1 &

```
测试结果：
```javascript
[OVERALL], RunTime(ms), 31251027
[OVERALL], Throughput(ops/sec), 3199.8948386560223
[TOTAL_GCS_G1_Young_Generation], Count, 307
[TOTAL_GC_TIME_G1_Young_Generation], Time(ms), 4354
[TOTAL_GC_TIME_%_G1_Young_Generation], Time(%), 0.013932342127508322
[TOTAL_GCS_G1_Old_Generation], Count, 0
[TOTAL_GC_TIME_G1_Old_Generation], Time(ms), 0
[TOTAL_GC_TIME_%_G1_Old_Generation], Time(%), 0.0
[TOTAL_GCs], Count, 307
[TOTAL_GC_TIME], Time(ms), 4354
[TOTAL_GC_TIME_%], Time(%), 0.013932342127508322
[READ], Operations, 100000000
[READ], AverageLatency(us), 26169.73705328
[READ], MinLatency(us), 105
[READ], MaxLatency(us), 46170111
[READ], 95thPercentileLatency(us), 55967
[READ], 99thPercentileLatency(us), 208895
[READ], Return=OK, 100000000
[CLEANUP], Operations, 168
[CLEANUP], AverageLatency(us), 22.458333333333332
[CLEANUP], MinLatency(us), 1
[CLEANUP], MaxLatency(us), 2121
[CLEANUP], 95thPercentileLatency(us), 16
[CLEANUP], 99thPercentileLatency(us), 57
```

### 测试场景E-uniform 读100%/写0%

```
$ cat << EOF > workloads/workloadj_uniform
recordcount=100000000
operationcount=100000000
workload=site.ycsb.workloads.CoreWorkload
readallfields=true
readproportion=1.0
updateproportion=0.0
scanproportion=0.0
insertproportion=0.0
requestdistribution=uniform
EOF 

$ nohup ./bin/ycsb run hbase2 -P workloads/workloadj_uniform -jvm-args='-XX:+UseG1GC -Xms10g -Xmx10g '  -cp /opt/dp/ycsb-hbase2/conf -p table=user_table2 -p columnfamily=cf  -p recordcount=10000000 -p operationcount=10000000 -threads 84 -s > workload_uniform.log 2>&1 &

```

测试结果：
```javascript
[OVERALL], RunTime(ms), 10907660
[OVERALL], Throughput(ops/sec), 916.7869185508166
[TOTAL_GCS_G1_Young_Generation], Count, 34
[TOTAL_GC_TIME_G1_Young_Generation], Time(ms), 577
[TOTAL_GC_TIME_%_G1_Young_Generation], Time(%), 0.005289860520038212
[TOTAL_GCS_G1_Old_Generation], Count, 0
[TOTAL_GC_TIME_G1_Old_Generation], Time(ms), 0
[TOTAL_GC_TIME_%_G1_Old_Generation], Time(%), 0.0
[TOTAL_GCs], Count, 34
[TOTAL_GC_TIME], Time(ms), 577
[TOTAL_GC_TIME_%], Time(%), 0.005289860520038212
[READ], Operations, 10000000
[READ], AverageLatency(us), 91175.9869907
[READ], MinLatency(us), 160
[READ], MaxLatency(us), 18235391
[READ], 95thPercentileLatency(us), 138495
[READ], 99thPercentileLatency(us), 560127
[READ], Return=OK, 10000000
[CLEANUP], Operations, 168
[CLEANUP], AverageLatency(us), 22.44047619047619
[CLEANUP], MinLatency(us), 1
[CLEANUP], MaxLatency(us), 2099
[CLEANUP], 95thPercentileLatency(us), 20
[CLEANUP], 99thPercentileLatency(us), 69
```

# 测试数据汇总
---------

 测试结果-汇总表：
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20210521140743.png)

\
 图表表示(不包含 uniform分布)：
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20210521140842.png)


## 测试总结
- 从上图可以看出 HBase的GET 读操作是主要的性能瓶颈，主要是收到`BlockCache Hit `Ratio和`Disk IOPS` 的影响：

RegionServer Hit Ratio :
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20210521142441.png)
一个机器的最大内存是64G，分配给RegionServer 的BlockCache L1 总量是12G，集群RegionServer L1 Cache总共35G(12G * 3节点), 能够缓存的数据量有限。
测试中 GET RPC 的BlockCache Hit Ratio 一直在50%左右（和生产环境接近)，还有50% 的 RPC 请求需要到HDFS存储中访问数据(需要读磁盘），导致latency较大，成为限制QPS提升的瓶颈。

关于Disk IO ，磁盘最大OPS：`1K OPS`左右,如图：
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20210521145029.png)
机器最大IOPS： 机器有10个挂载，单个HDD盘的读写 `150IOPS`左右，所以` 10挂载 * 150 IOPS = 1.5K OPS `,从监控看磁盘OPS基本已经达到上限。

- 相对与zipfian分布的测试，uniform分布下，Hbase 读取性能还要下降2/3 。 
这是由于zipfian分布下存在热数据,`YCSB paper` 中zipfian与uniform对比见:
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20210521144127.png)
*注意：图片涞源,https://labs.yahoo.com/news/yahoo-cloud-serving-benchmark/

# 总结
在机器环境不变的情况下，通过提前表的StoreFileSize,可以有效提高表的吞吐量：

![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20210521144838.png)
*图片涞源：Surbhi Kochhar,https://blog.cloudera.com/hbase-performance-testing-using-ycsb/
这个图展示了：缓存命中率接近99％(40G数据，cache 命中率100%），并且大多数工作负载数据在缓存中可用，因此延迟要低得多。相比之下，对于1TB数据集，由于必须从HDFS存储访问HFile数据，因此缓存命中率约为85％。


# 参考文献
-----

- YCSB project 
https://labs.yahoo.com/news/yahoo-cloud-serving-benchmark/

- hbase-performance-testing-using-ycsb
https://blog.cloudera.com/hbase-performance-testing-using-ycsb/

- HBase测试|HBase 2.2.1随机读写性能测试
https://mp.weixin.qq.com/s/V53IHclunWsEMjgxYrbQdQ

- Hbase SSD 
https://blogs.apache.org/hbase/?page=1

