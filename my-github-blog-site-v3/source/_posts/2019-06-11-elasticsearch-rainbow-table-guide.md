---
layout: post
title: 使用ElasticSearch构建彩虹表
categories:
  - tech
tags:
  - blog
  - ElasticSearch
excerpt: 使用ElasticSearch构建彩虹表
date: 2019-01-01 00:00:00
---


### 数据量预估
目前Mobie、Tele、UnionCom和XX运营商已经在使用的号码段共计51个，数据量预估是 4,415,000,000条，存储这些文本信息需要439G。

### ES存储设计
  为支持高QPS,需要对设计支持高QPS

#### nodes和shard
可以参考设备信息的ES进行配置8个节点，20分片
测试环境只有3机器 shard可以分为6分片

### ES存储结构设计(Es 5.3)
shard策略： 将单个shard的大小控制在30G～60G左右
indices(Database)： phn_relations_rainbow
type: rbtype
document 格式
```
{
    "phn": "12345678901", 
    "md5": "5d41402abc4b2a76b9719d911017c592", 
    "sha": "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
}
```
#### 文档索引设计
_Id（docId）使用phn_md5作为docId提升查询速度(docId的查询速度最快)

#### 域映射设计
 term 查找精确值md5值或者sha256值时，需要告诉 Elasticsearch 该字段具有精确值，要将其设置成 ```not_analyzed``` 无需分析的. 之后term 查询不会对其做任何分析，查询会进行精确查找.
 string类型域默认是anlayzed，会被认为包含全文，它们的值在索引前，会通过一个分析器，针对这个域的搜索的搜索也会经过一个分析器(_analzer)。在彩虹表中我们需要的是索引到精确值，所以将md5和sha的index属性设置为not_analyzed.(避免倒排词典的分词后，耗费更多的head空间)
 md5和sha使用了```not_analyzed```即作为一个精确值，对精确值来讲FOO和foo是不同的，所以将MD5和SHA256统一使用大写字符存储在ES中.（ 5.4及以后的版本请用keyword类型）

```
PUT /phn_relations_rainbow 
{
    "mappings": {
        "rbtype": {
            "properties": {
                "md5": {
                    "type": "string", 
                    "index": "not_analyzed"
                }, 
                "sha": {
                    "type": "string", 
                    "index": "not_analyzed"
                }, 
                "phn": {
                    "type": "string", 
                    "index": "not_analyzed"
                }
            }
        }
    }
}
```


### 查询设计
#### 使用非评分的精确查询
非评分查询constant_score, 不进行评分或相关度的计算，score会返回一个默认评分1.按照[elasticsearch.cn官方](https://elasticsearch.cn/book/elasticsearch_definitive_guide_2.x/_finding_exact_values.html)的说法，非评分查询可以获取到更快的访问。原文
```
Elasticsearch 能够缓存非评分查询从而获取更快的访问，但是它也会不太聪明地缓存一些使用极少的东西。非评分计算因为倒排索引已经足够快了，所以我们只想缓存那些我们知道 在将来会被再次使用的查询，以避免资源的浪费。

为了实现以上设想，Elasticsearch 会为每个索引跟踪保留查询使用的历史状态。如果查询在最近的 256 次查询中会被用到，那么它就会被缓存到内存中。当 bitset 被缓存后，缓存会在那些低于 10,000 个文档（或少于 3% 的总索引数）的段（segment）中被忽略。这些小的段即将会消失，所以为它们分配缓存是一种浪费。
```

term 查询在倒排索引中查找值，然后获取包含term的所有文档。因为查询的是包含关系，但这个与我们的精确查询不符，需要使用组合过滤器-bool过滤器

```
curl -XGET "http://172.16.103.191:19250/alias_phn_relations_rainbow/mitype/_search?routing=12345678901" -d '{
    "query": {
        "constant_score": {
            "filter": {
                "bool": {
                    "must": {
                        "term": {
                            "mac": "12345678901"
                        }
                    }
                }
            }
        }
    }
}'  -w  "time_total:%{time_total}"

```


### ES的监控设计
接入promethesu监控请求耗时和QPS. 主要测试记录

#### getByDocId config routing
1000 QPS 5min  50ms内获得99.76%

```
#原始记录
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.001",} 97577.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.002",} 293417.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.003",} 297628.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.004",} 298078.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.005",} 298257.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.01",} 298578.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.03",} 299277.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.05",} 299708.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.07",} 299874.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.1",} 299937.0

#分组统计
<= 0.003s: 97.8057%
<= 0.005s: 99.3593%
<= 0.010s: 99.4190%
<= 0.030s: 99.5260%
<= 0.050s: 99.7590%
<= 0.100s: 99.9580%
<= 1.00s: 100.0000%
```


5000 QPS 5min
```
#原始数据
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.001",} 507148.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.002",} 1452890.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.003",} 1469155.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.004",} 1473658.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.005",} 1475649.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.01",} 1479310.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.03",} 1486384.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.05",} 1492447.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.07",} 1497304.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.1",} 1499464.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.2",} 1499868.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.3",} 1500000.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.5",} 1500000.0

<= 0.003s: 96.8593%
<= 0.005s: 98.2439%
<= 0.010s: 98.3766%
<= 0.030s: 98.6207%
<= 0.050s: 99.0923%
<= 0.100s: 99.8203%
<= 0.300s: 99.9912%
<= 1.00s: 100.0000%

50ms内获得99.09%
```

10000QPS 压测5min 50ms内完成的保证率96.8%
```
<= 0.003s: 85.0273%
<= 0.005s: 93.5555%
<= 0.010s: 94.5312%
<= 0.030s: 95.8351%
<= 0.050s: 96.8317%
<= 0.100s: 98.2430%
<= 0.300s: 99.0106%
<= 1.00s: 99.0889%
<= 100.00s: 100.0000%
```

phn->md5

1000QPS 压测5min,50ms完成数据查询的保证率是99.54%

```
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.001",} 18608.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.002",} 236088.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.003",} 293617.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.004",} 295297.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.005",} 295717.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.01",} 296435.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.03",} 298607.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.05",} 299254.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.07",} 299767.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.1",} 299874.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.2",} 299964.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.3",} 300000.0

<= 0.003s: 78.6960%
<= 0.005s: 98.4323%
<= 0.010s: 98.5723%
<= 0.030s: 98.8117%
<= 0.050s: 99.5357%
<= 0.100s: 99.9223%
<= 0.300s: 99.9880%
<= 1.00s: 100.0000%
```

5000 QPS  98.49%
```
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.001",} 396370.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.002",} 1361611.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.003",} 1418054.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.004",} 1428237.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.005",} 1433294.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.01",} 1445295.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.03",} 1483337.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.05",} 1491844.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.07",} 1495328.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.1",} 1497847.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.2",} 1499612.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.3",} 1499998.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.5",} 1500000.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="1.0",} 1500000.0

<= 0.003s: 89.8795%
<= 0.005s: 94.6331%
<= 0.010s: 95.0378%
<= 0.030s: 95.9085%
<= 0.050s: 98.4923%
<= 0.100s: 99.4963%
<= 0.300s: 99.9624%
<= 1.00s: 100.0000%

```

10000 QPS 50ms内完成的保证率是 97.03%
```
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.001",} 634865.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.002",} 2409485.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.003",} 2645172.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.004",} 2682787.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.005",} 2702355.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.01",} 2756471.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.03",} 2910921.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.05",} 2964501.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.07",} 2984026.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.1",} 2992563.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.2",} 2996912.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.3",} 2998432.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.5",} 3000000.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="1.0",} 3000000.0


<= 0.003s: 80.3162%
<= 0.005s: 89.4262%
<= 0.010s: 90.0785%
<= 0.030s: 91.8824%
<= 0.050s: 97.0307%
<= 0.100s: 99.4675%
<= 0.300s: 99.8971%
<= 1.00s: 100.0000%
```

phn-> sha 
 1000 QPS

```
<= 0.003s: 85.7930%
<= 0.005s: 98.6920%
<= 0.010s: 98.7637%
<= 0.030s: 98.9577%
<= 0.050s: 99.6313%
<= 0.100s: 99.9657%
<= 0.300s: 99.9967%
<= 1.00s: 100.0000%
==
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.001",} 0.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.002",} 176738.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.003",} 264181.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.004",} 273169.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.005",} 276434.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.01",} 281144.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.03",} 294238.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.05",} 297820.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.07",} 298523.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.1",} 298747.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.2",} 298958.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.3",} 299062.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.5",} 299263.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="1.0",} 299766.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="2.0",} 300000.0
````

ES集群3节点9分片9副本性能测试
2018年04月12日 13:40:12
====================

1000 QPS进行压力测试（系统Iowait大 ES陷入瘫痪)

100 QPS 查询5分钟，50ms内完成查询的保证率是54.2133%
```
<= 0.003s: 1.6500%
<= 0.005s: 3.0767%
<= 0.010s: 3.3467%
<= 0.030s: 9.2067%
<= 0.050s: 54.2133%
<= 0.100s: 71.1700%
<= 0.500s: 75.9567%
<= 1.00s: 76.3367%
<= 1.50s: 77.1800%
<= 5.00s: 80.4633%
<= 10.00s: 85.0067%

micro_service_latency_seconds_bucket{api="get_doc_id",le="0.001",} 60.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.002",} 495.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.003",} 808.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.004",} 923.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.005",} 1004.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.01",} 2762.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.03",} 16264.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.05",} 19874.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.07",} 21351.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.1",} 22230.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.2",} 22681.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.3",} 22787.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.5",} 22901.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="1.0",} 23154.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="2.0",} 23591.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="3.0",} 24139.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="5.0",} 25502.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="10.0",} 28667.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="60.0",} 30000.0


```


phn->sha 使用phnSuffix作路由查询
1000QPS 5分钟,50ms内完成查询的保证率是 95.4333%
```
<= 0.003s: 4.2433%
<= 0.005s: 15.3133%
<= 0.010s: 16.4600%
<= 0.030s: 30.9367%
<= 0.050s: 95.4333%
<= 0.100s: 96.2867%
<= 0.500s: 97.0267%
<= 1.00s: 97.5433%
<= 1.50s: 98.1867%
<= 5.00s: 99.6367%
<= 10.00s: 100.0000%

micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.001",} 5.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.002",} 1273.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.003",} 3849.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.004",} 4594.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.005",} 4938.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.01",} 9281.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.03",} 28630.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.05",} 28852.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.07",} 28886.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.1",} 28937.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.2",} 29024.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.3",} 29108.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.5",} 29263.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="1.0",} 29456.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="2.0",} 29706.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="3.0",} 29891.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="5.0",} 30000.0

```

sha->md5 无路由，无docId
1000QPS 5分钟,50ms内完成查询的保证率是 (大量的Iowait和延时，导致ES集群陷入瘫痪)
```



```

=====
3节点 200分片
```
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.001",} 336.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.002",} 1661.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.003",} 2430.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.004",} 2736.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.005",} 2966.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.01",} 5761.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.03",} 20475.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.05",} 23756.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.07",} 24880.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.1",} 25569.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.2",} 26236.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.3",} 26469.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.5",} 26767.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="1.0",} 27360.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="2.0",} 28287.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="3.0",} 29020.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="5.0",} 29900.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="10.0",} 30000.0
```


========
3节点 3分片 2副本，共计九个节点 100QPS
QPS  docId
```
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.001",} 0.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.002",} 0.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.003",} 0.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.004",} 0.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.005",} 0.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.01",} 0.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.03",} 0.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.05",} 0.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.07",} 0.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.1",} 0.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.2",} 0.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.3",} 1.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.5",} 2.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="1.0",} 5.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="2.0",} 26.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="3.0",} 49.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="5.0",} 92.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="10.0",} 299.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="60.0",} 4279.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="+Inf",} 29564.0
```

phn->sha 
```
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.001",} 0.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.002",} 453.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.003",} 1334.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.004",} 1682.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.005",} 1839.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.01",} 3787.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.03",} 25333.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.05",} 27199.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.07",} 27473.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.1",} 27563.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.2",} 27729.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.3",} 27880.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.5",} 28125.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="1.0",} 28628.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="2.0",} 29390.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="3.0",} 29818.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="5.0",} 30000.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="10.0",} 30000.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="60.0",} 30000.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="+Inf",} 30000.0
```


=========
1分片 2分布

phn->sha 100 QPS 系统iowait扛不住了
```
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.001",} 0.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.002",} 10.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.003",} 40.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.004",} 78.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.005",} 99.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.01",} 110.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.03",} 127.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.05",} 138.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.07",} 162.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.1",} 242.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.2",} 1283.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.3",} 3215.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.5",} 7024.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="1.0",} 10063.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="2.0",} 11130.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="3.0",} 11992.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="5.0",} 13336.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="10.0",} 15688.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="60.0",} 19109.0

```

https://www.elastic.co/guide/en/elasticsearch/reference/5.2/tune-for-indexing-speed.html

=====
调整索引策略  将每个索引的大小控制在30G左右

3节点 2shard 2份副本

phn->sha routing  100QPS 5min

```
<= 0.003s: 43.0667%
<= 0.005s: 93.5100%
<= 0.010s: 94.5500%
<= 0.030s: 96.0333%
<= 0.050s: 99.5133%
<= 0.100s: 99.8367%

micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.001",} 529.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.002",} 12920.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.003",} 26713.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.004",} 28053.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.005",} 28365.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.01",} 28810.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.03",} 29854.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.05",} 29942.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.07",} 29951.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.1",} 29964.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.2",} 29990.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.3",} 30000.0

```

phn->sha routing  1000QPS 5min

```
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.001",} 25208.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.002",} 198962.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.003",} 275536.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.004",} 285326.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.005",} 288791.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.01",} 294614.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.03",} 297922.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.05",} 298695.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.07",} 298936.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.1",} 299258.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.2",} 299748.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.3",} 299889.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.5",} 300000.0

<= 0.001s: 8.4027%
<= 0.003s: 91.8453%
<= 0.005s: 96.2637%
<= 0.010s: 98.2047%
<= 0.030s: 99.3073%
<= 0.050s: 99.5650%
<= 0.100s: 99.7527%
<= 0.500s: 100.0000%


<= 0.001s: 8.9920%
<= 0.003s: 88.6590%
<= 0.005s: 93.2140%
<= 0.010s: 95.5363%
<= 0.030s: 97.4300%
<= 0.050s: 97.7613%
<= 0.100s: 98.1437%
<= 0.500s: 99.2203%
<= 1.00s: 99.8280%
<= 2.00s: 100.0000%

```

phn->sha routing 10K QPS  5min

```
<= 0.003s: 61.3570%
<= 0.005s: 84.0936%
<= 0.010s: 86.6701%
<= 0.030s: 90.4551%
<= 0.050s: 95.5499%
<= 0.100s: 98.9746%
<= 0.500s: 99.6846%
<= 1.00s: 99.7707%
<= 1.50s: 99.9340%
<= 5.00s: 100.0000%

micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.001",} 437013.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.002",} 1840710.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.003",} 2352389.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.004",} 2522807.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.005",} 2600103.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.01",} 2713654.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.03",} 2866497.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.05",} 2941196.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.07",} 2969239.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.1",} 2981318.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.2",} 2987595.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.3",} 2990537.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.5",} 2993121.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="1.0",} 2998019.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="2.0",} 3000000.0
```

===
phn->md5 docId 100QPS 5min
```
<= 0.003s: 30.1567%
<= 0.005s: 91.5900%
<= 0.010s: 94.0267%
<= 0.030s: 96.9433%
<= 0.050s: 98.4400%
<= 0.100s: 98.6033%
<= 0.500s: 98.9400%
<= 1.00s: 99.0800%
<= 1.50s: 99.2833%
<= 2.00s: 100.0000%
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.001",} 135.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.002",} 10460.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.003",} 27368.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.004",} 29207.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.005",} 29553.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.01",} 29806.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.03",} 29913.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.05",} 29967.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.07",} 29977.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.1",} 29988.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.2",} 29996.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.3",} 30000.0

```

phn->md5 docId 1K QPS 5min
```

<= 0.001s: 8.5163%
<= 0.003s: 93.1640%
<= 0.005s: 97.6767%
<= 0.010s: 98.6833%
<= 0.030s: 99.2490%
<= 0.050s: 99.4887%
<= 0.100s: 99.6923%
<= 0.500s: 100.0000%

micro_service_latency_seconds_bucket{api="get_doc_id",le="0.001",} 25549.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.002",} 206372.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.003",} 279492.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.004",} 290066.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.005",} 293030.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.01",} 296050.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.03",} 297747.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.05",} 298466.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.07",} 298774.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.1",} 299077.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.2",} 299706.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.3",} 299960.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.5",} 300000.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="1.0",} 300000.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="2.0",} 300000.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="3.0",} 300000.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="5.0",} 300000.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="10.0",} 300000.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="60.0",} 300000.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="+Inf",} 300000.0
```

10k QPS phn docId
```
<= 0.001s: 15.5621%
<= 0.003s: 79.7102%
<= 0.005s: 88.3068%
<= 0.010s: 92.2587%
<= 0.030s: 96.4028%
<= 0.050s: 98.4555%
<= 0.100s: 99.5161%
<= 0.500s: 99.9964%
<= 1.00s: 100.0000%

micro_service_latency_seconds_bucket{api="get_doc_id",le="0.001",} 466862.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.002",} 1895290.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.003",} 2391306.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.004",} 2566861.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.005",} 2649203.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.01",} 2767761.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.03",} 2892083.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.05",} 2953664.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.07",} 2976181.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.1",} 2985482.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.2",} 2992554.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.3",} 2996161.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="0.5",} 2999892.0
micro_service_latency_seconds_bucket{api="get_doc_id",le="1.0",} 3000000.0

```

sha->md5 无docId 和routing  100QPS 5min
```
<= 0.001s: 0.0000%
<= 0.003s: 24.5905%
<= 0.005s: 67.0432%
<= 0.010s: 82.6737%
<= 0.030s: 92.0674%
<= 0.050s: 92.3850%
<= 0.100s: 92.6032%
<= 0.500s: 93.4981%
<= 1.00s: 93.7108%
<= 2.00s: 94.0809%
<= 5.00s: 95.0753%
<= 10.00s: 96.6413%
<= 60.00s: 100.0000%

micro_service_latency_seconds_bucket{api="get_filed_sha",le="0.001",} 0.0
micro_service_latency_seconds_bucket{api="get_filed_sha",le="0.002",} 331.0
micro_service_latency_seconds_bucket{api="get_filed_sha",le="0.003",} 8875.0
micro_service_latency_seconds_bucket{api="get_filed_sha",le="0.004",} 19181.0
micro_service_latency_seconds_bucket{api="get_filed_sha",le="0.005",} 24040.0
micro_service_latency_seconds_bucket{api="get_filed_sha",le="0.01",} 28495.0
micro_service_latency_seconds_bucket{api="get_filed_sha",le="0.03",} 29623.0
micro_service_latency_seconds_bucket{api="get_filed_sha",le="0.05",} 29706.0
micro_service_latency_seconds_bucket{api="get_filed_sha",le="0.07",} 29730.0
micro_service_latency_seconds_bucket{api="get_filed_sha",le="0.1",} 29770.0
micro_service_latency_seconds_bucket{api="get_filed_sha",le="0.2",} 29885.0
micro_service_latency_seconds_bucket{api="get_filed_sha",le="0.3",} 29960.0
micro_service_latency_seconds_bucket{api="get_filed_sha",le="0.5",} 30000.0

<= 0.001s: 0.0000%
<= 0.003s: 29.5833%
<= 0.005s: 80.1333%
<= 0.010s: 94.9833%
<= 0.030s: 98.7433%
<= 0.050s: 99.0200%
<= 0.100s: 99.2333%
<= 0.500s: 100.0000%


```

sha->md5 1000 QPS
```
micro_service_latency_seconds_bucket{api="get_filed_sha",le="0.001",} 0.0
micro_service_latency_seconds_bucket{api="get_filed_sha",le="0.002",} 37866.0
micro_service_latency_seconds_bucket{api="get_filed_sha",le="0.003",} 131994.0
micro_service_latency_seconds_bucket{api="get_filed_sha",le="0.004",} 190104.0
micro_service_latency_seconds_bucket{api="get_filed_sha",le="0.005",} 215932.0
micro_service_latency_seconds_bucket{api="get_filed_sha",le="0.01",} 255075.0
micro_service_latency_seconds_bucket{api="get_filed_sha",le="0.03",} 277297.0
micro_service_latency_seconds_bucket{api="get_filed_sha",le="0.05",} 282983.0
micro_service_latency_seconds_bucket{api="get_filed_sha",le="0.07",} 286445.0
micro_service_latency_seconds_bucket{api="get_filed_sha",le="0.1",} 290133.0
micro_service_latency_seconds_bucket{api="get_filed_sha",le="0.2",} 296199.0
micro_service_latency_seconds_bucket{api="get_filed_sha",le="0.3",} 298368.0
micro_service_latency_seconds_bucket{api="get_filed_sha",le="0.5",} 299830.0
micro_service_latency_seconds_bucket{api="get_filed_sha",le="1.0",} 300000.0

300000.0
<= 0.001s: 0.0000%
<= 0.003s: 43.9980%
<= 0.005s: 71.9773%
<= 0.010s: 85.0250%
<= 0.030s: 92.4323%
<= 0.050s: 94.3277%
<= 0.100s: 96.7110%
<= 0.500s: 99.9433%
<= 1.00s: 100.0000%
```

=====
phn-> md5 routing  5min 1K QPS，50ms保证率99.7887%
2018年04月17日 17:53:25
```
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.001",} 31914.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.002",} 227564.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.003",} 285241.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.004",} 292444.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.005",} 294729.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.01",} 296807.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.03",} 298454.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.05",} 299366.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.07",} 299721.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.1",} 299863.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.2",} 299998.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.3",} 300000.0

300000.0
<= 0.001s: 10.6380%
<= 0.003s: 95.0803%
<= 0.005s: 98.2430%
<= 0.010s: 98.9357%
<= 0.030s: 99.4847%
<= 0.050s: 99.7887%
<= 0.100s: 99.9543%
<= 0.500s: 100.0000%
```

10K QPS
```
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.001",} 461119.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.002",} 1977262.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.003",} 2475505.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.004",} 2619217.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.005",} 2679664.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.01",} 2766618.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.03",} 2890699.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.05",} 2954801.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.07",} 2977103.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.1",} 2987720.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.2",} 2995430.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.3",} 2998140.0
micro_service_latency_seconds_bucket{api="get_filed_phn",le="0.5",} 3000000.0

<= 0.001s: 15.3706%
<= 0.003s: 82.5168%
<= 0.005s: 89.3221%
<= 0.010s: 92.2206%
<= 0.030s: 96.3566%
<= 0.050s: 98.4934%
<= 0.100s: 99.5907%
<= 0.500s: 100.0000%
```