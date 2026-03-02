---
title:  Clickhouse add external disk
excerpt: Clickhouse集群添加S3外部存储
layout: post
date: 2025-04-17 11:40:56
tags:
  - Data
  - clickhouse
  - s3
categories:
 - Data
 - tech
---

# 背景
Clickhouse Disk 存储每周增加5%，预计现有存储资源在2个月内将告急。需要进行存储扩容，综合对比EBS于S3的存储价格，使用S3是EBS存储成本的10%。
<img src="https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/2024/202504171144252.png" width="60%" height="60%">

```js
Clickhouse version： 24.8
部署：2 shard + 2 replicate 

```


# 架构
## 架构设计
引入S3 对象存储，用于存储冷数据(数据不再修改，低频次查询）。 本地Nvme SSD存储热数据、S3 Cache、S3 metadata，或需要高性能的查询数据（比如字典表等）。
<img src="https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/2024/202504161605250.png" width="60%" height="60%">

## S3数据存储安全评估：
 数据的data.bin 需要元数据才能解析到真实存储的数据，单独得到S3上的文件无法从中读取数据，如下：
 `./clickhouse local --query="SELECT * FROM file('/home/joe/ck_test_data_bin.bin',RawBLOB)" | head -10 `
 <img src="https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/2024/202504171343444.png" width="60%" height="60%">
(元数据与数据编码后的内容分开存储， 元数据存储在本地Disk /var/lib/clickhouse/disks/s3/）


**结论：**
  1. 存储在S3上的数据，即使bucket数据被窃取，也无法得到数据内容（元数据未被窃取）
  2. 建议S3 上用于存储 clickhouse 的 bucket 使用单独的access_key, security_key
  3. 对于敏感的数据可以使用Clickhouse 的 encrypt 机制进行加密(账号密码等，且建议本地存储）， 或者配置单独的Disk存储 （ 会牺牲一定的性能 ）

## 参考文献

- https://clickhouse.com/docs/operations/storing-data  
- https://medium.com/datadenys/scaling-clickhouse-using-amazon-s3-as-a-storage-94a9b9f2e6c7  
- https://aws.amazon.com/blogs/storage/clickhouse-cloud-amazon-s3-express-one-zone-making-a-blazing-fast-analytical-database-even-faster/  


# 测试与部署

## 测试S3 数据写入和读取
用于测试直接向S3写入数据是否正常（ 不启动 local cache )
### 配置config.xml
```xml 

</clickhouse> 
    <!-- Path to data directory, with trailing slash. -->
    <path>/var/lib/clickhouse/</path>

   <storage_configuration>
        <disks>
            <default>
                <path>/var/lib/clickhouse/</path>
                <keep_free_space_bytes>0</keep_free_space_bytes>
            </default>

            <s3>
                <type>s3</type>
                <endpoint>https://xxx.s3.us-east-1.amazonaws.com/s3-my-clickhouse/ck-shard1-replica1/</endpoint>
                <access_key_id>xxx</access_key_id>
                <secret_access_key>xxxy</secret_access_key>
                <!-- local s3 store metadata info-->
                <metadata_path>/var/lib/clickhouse/disks/s3/</metadata_path>
                <region>us-east-1</region>
            </s3>
          </disks>

        <policies>
            <!-- 有一个默认的  policy_name:default  -->

            <!-- 添加新的混合存储策略 -->
            <tiered>
                <volumes>
                    <hot>
                        <disk>default</disk>
                    </hot>
                    <cold>
                        <disk>s3</disk> <!-- 或直接使用s3 -->
                    </cold>
                </volumes>
            </tiered>
            <!-- 仅S3存储策略 -->
            <s3_only>
                <volumes>
                    <main>
                        <disk>s3</disk>
                    </main>
                </volumes>
            </s3_only>
        </policies>
  </storage_configuration>

```

- 检查xml格式 
```shell 
xmllint config.xml
```

- 重启服务验证

```shell
  # docker compose 重启
  # docker compose -f ./docker-compose.yaml restart clickhouse-01
  sudo systemctl restart clickhouse-server.servcie

```

### 验证配置
```SQL 
--  disk  check 
-- 确认 当前节点应该 已经注册上了S3 disk
select * FROM  system.disks  ;

```
result：

```SQL 

   ┌─name────┬─path──────────────────────────┬───────────free_space─┬──────────total_space─┬─────unreserved_space─┬─keep_free_space─┬─type──────────┬─object_storage_type─┬─metadata_type─┬─is_encrypted─┬─is_read_only─┬─is_write_once─┬─is_remote─┬─is_broken─┬─cache_path─┐
1. │ default │ /var/lib/clickhouse/          │         415065309184 │         444778545152 │         415065309184 │               0 │ Local         │ None                │ None          │            0 │            0 │             0 │         0 │         0 │            │
2. │ s3      │ /var/lib/clickhouse/disks/s3/ │ 18446744073709551615 │ 18446744073709551615 │ 18446744073709551615 │               0 │ ObjectStorage │ S3                  │ Local         │            0 │            0 │             0 │         1 │         0 │            │
   └─────────┴───────────────────────────────┴──────────────────────┴──────────────────────┴──────────────────────┴─────────────────┴───────────────┴─────────────────────┴───────────────┴──────────────┴──────────────┴───────────────┴───────────┴───────────┴────────────┘
```

```SQL

-- storage policies
-- 是否已经有 配置的policies
SELECT *
FROM system.storage_policies ;


```
result：
```SQL 
   ┌─policy_name─┬─volume_name─┬─volume_priority─┬─disks───────┬─volume_type─┬─max_data_part_size─┬─move_factor─┬─prefer_not_to_merge─┬─perform_ttl_move_on_insert─┬─load_balancing─┐
1. │ default     │ default     │               1 │ ['default'] │ JBOD        │                  0 │           0 │                   0 │                          1 │ ROUND_ROBIN    │
2. │ s3_only     │ main        │               1 │ ['s3_disk'] │ JBOD        │                  0 │           0 │                   0 │                          1 │ ROUND_ROBIN    │
3. │ tiered      │ hot         │               1 │ ['default'] │ JBOD        │                  0 │         0.1 │                   0 │                          1 │ ROUND_ROBIN    │
4. │ tiered      │ cold        │               2 │ ['s3_disk'] │ JBOD        │                  0 │         0.1 │                   0 │                          1 │ ROUND_ROBIN    │
   └─────────────┴─────────────┴─────────────────┴─────────────┴─────────────┴────────────────────┴─────────────┴─────────────────────┴────────────────────────────┴────────────────┘
```

### 数据写入验证 

```SQL 

# create s3 only table 

CREATE TABLE random_table_s3_only_v2_node1
(
    id UInt32,
    id_text String,
    data_time DateTime
)
ENGINE = MergeTree()
partition by toDate(data_time)
ORDER BY id 
SETTINGS storage_policy = 's3_only' ;



-- insert data 
INSERT INTO random_table_s3_only_v2_node1 
SELECT
    rand() AS id,
    generateUUIDv4() AS id_text,
    --toDateTime(rand() % 1000000000 + 1600000000) AS data_time
    now() - INTERVAL 1 DAY   AS data_time 
FROM generateRandom('dummy UInt8', 1, 10, 2)
LIMIT 100000 ;

```

```SQL 
-- 检查数据写入
-- clusterAllReplicas() 集群查询请使用该函数

 SELECT
            hostName() AS storage_host,
            `table` AS ck_table,
            partition,
            name,disk_name ,`path`
            active,
            rows,
            bytes_on_disk,
            modification_time
        FROM system.parts 
        WHERE database = 'dev_test_db' and `table` ='random_table_s3_only_v2_node1';

```
result 

```SQL 
   ┌─storage_host──┬─ck_table──────────────────────┬─partition──┬─name───────────┬─disk_name─┬─active──────────────────────────────────────────────────────────────────────────────────────┬───rows─┬─bytes_on_disk─┬───modification_time─┐
1. │ clickhouse-01 │ random_table_s3_only_v2_node1 │ 2025-04-14 │ 20250414_2_2_0 │ s3_disk   │ /var/lib/clickhouse/disks/s3/store/56e/56e40806-f0dd-40d3-80d7-fe7388b239b9/20250414_2_2_0/ │ 100000 │       4100270 │ 2025-04-15 12:50:56 │
2. │ clickhouse-01 │ random_table_s3_only_v2_node1 │ 2025-04-15 │ 20250415_1_1_0 │ s3_disk   │ /var/lib/clickhouse/disks/s3/store/56e/56e40806-f0dd-40d3-80d7-fe7388b239b9/20250415_1_1_0/ │ 100000 │       4100603 │ 2025-04-15 12:50:12 │
   └───────────────┴───────────────────────────────┴────────────┴────────────────┴───────────┴─────────────────────────────────────────────────────────────────────────────────────────────┴────────┴───────────────┴─────────────────────┘
```

备注：这个`/var/lib/clickhouse/disks/s3/store/56e/56e40806-f0dd-40d3-80d7-fe7388b239b9/20250414_2_2_0/`path 下的 data.bin 指向的是S3 buckect 中的一个文件（该文件在S3上被随机命名了，是一个随机串文件，比如`nwmophhehkmvfkukjjwldgjttcyfr`)



# 生产配置(S3+cache)

## 配置storage
配置映射
```
shard1_replica01 --> s3_endpoint: https://xxxx.s3.us-east-1.amazonaws.com/s3-xxxx-clickhouse/ck-shard1-replica1/
shard1_replica02 --> s3_endpoint: https://xxxx.s3.us-east-1.amazonaws.com/s3-xxxx-clickhouse/ck-shard1-replica2/

shard2_replica01 --> s3_endpoint: https://xxxx.s3.us-east-1.amazonaws.com/s3-xxxx-clickhouse/ck-shard2-replica1/
shard2_replica02 --> s3_endpoint: https://xxxx.s3.us-east-1.amazonaws.com/s3-xxxx-clickhouse/ck-shard2-replica2/

```
在生产配置config.xml:
```xml

<storage_configuration>
        <disks>
	        <default>
                <keep_free_space_bytes>0</keep_free_space_bytes>
            </default>
         <s3_disk>
                    <type>s3</type>
                    <!-- 根据不同 shard replica 配置不同的 endpoint -->
                    <endpoint>https://xxxx.s3.us-east-1.amazonaws.com/s3-xxxx-clickhouse/ck-shard1-replica1/</endpoint>
                    <access_key_id>xxx</access_key_id>
                    <secret_access_key>V/+xxx</secret_access_key>
                    <!-- local s3 store metadata info-->
                    <metadata_path>/var/lib/clickhouse/disks/s3/</metadata_path>
                    <region>us-east-1</region>
          </s3_disk>
         <s3_cache>
              <type>cache</type>
              <disk>s3_disk</disk>
              <path>/var/lib/clickhouse/disks/s3_cache/</path>
              <max_size>30Gi</max_size>
         </s3_cache>
    </disks>
        <policies>
            <!-- 添加新的混合存储策略 -->
            <tiered>
                <volumes>
                    <hot>
                        <disk>default</disk>
                    </hot>
                    <cold>
                        <disk>s3_cache</disk> <!-- 或直接使用s3 -->
                    </cold>
                </volumes>
            </tiered>
            <!-- 仅S3存储策略 -->
            <s3_only>
                <volumes>
                    <main>
                        <disk>s3_cache</disk>
                    </main>
                </volumes>
            </s3_only>
        </policies>
  </storage_configuration>

```

### 配置检查
```SQL 
select * from system.disks ; 

   ┌─name─────┬─path──────────────────────────┬───────────free_space─┬──────────total_space─┬─────unreserved_space─┬─keep_free_space─┬─type──────────┬─object_storage_type─┬─metadata_type─┬─is_encrypted─┬─is_read_only─┬─is_write_once─┬─is_remote─┬─is_broken─┬─cache_path──────────────────────────┐
1. │ default  │ /var/lib/clickhouse/          │        3802866491392 │        6799193366528 │        3802863018600 │               0 │ Local         │ None                │ None          │            0 │            0 │             0 │         0 │         0 │                                     │
2. │ s3_cache │ /var/lib/clickhouse/disks/s3/ │ 18446744073709551615 │ 18446744073709551615 │ 18446744073709551615 │               0 │ ObjectStorage │ S3                  │ Local         │            0 │            0 │             0 │         1 │         0 │ /var/lib/clickhouse/disks/s3_cache/ │
3. │ s3_disk  │ /var/lib/clickhouse/disks/s3/ │ 18446744073709551615 │ 18446744073709551615 │ 18446744073709551615 │               0 │ ObjectStorage │ S3                  │ Local         │            0 │            0 │             0 │         1 │         0 │                                     │
   └──────────┴───────────────────────────────┴──────────────────────┴──────────────────────┴──────────────────────┴─────────────────┴───────────────┴─────────────────────┴───────────────┴──────────────┴──────────────┴───────────────┴───────────┴───────────┴─────────────────────────────────────┘
```

```SQL
SELECT *
FROM system.storage_policies

Query id: 30c178eb-16b7-4eb9-9fe9-0d1273d59333

   ┌─policy_name─┬─volume_name─┬─volume_priority─┬─disks───────┬─volume_type─┬─max_data_part_size─┬─move_factor─┬─prefer_not_to_merge─┬─perform_ttl_move_on_insert─┬─load_balancing─┐
1. │ default     │ default     │               1 │ ['default'] │ JBOD        │                  0 │           0 │                   0 │                          1 │ ROUND_ROBIN    │
2. │ s3_only     │ main        │               1 │ ['s3_disk'] │ JBOD        │                  0 │           0 │                   0 │                          1 │ ROUND_ROBIN    │
3. │ tiered      │ hot         │               1 │ ['default'] │ JBOD        │                  0 │         0.1 │                   0 │                          1 │ ROUND_ROBIN    │
4. │ tiered      │ cold        │               2 │ ['s3_disk'] │ JBOD        │                  0 │         0.1 │                   0 │                          1 │ ROUND_ROBIN    │
   └─────────────┴─────────────┴─────────────────┴─────────────┴─────────────┴────────────────────┴─────────────┴─────────────────────┴────────────────────────────┴────────────────┘

```

### 效果验证
```SQL
-- 查询一个已经在S3 上存储的表，验证cache效果

select * from random_table_s3_only_v2_node1 limit 10

```
配置S3 cache 之后，查询S3上的数据，会临时被缓存到本地（LRU）

 <img src="https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/2024/202504171349220.png" width="60%" height="60%" style="align: left;">
S3 的文件映射到本地Cache:   
`ls /var/lib/clickhouse/disks/s3_cache/*`  
<img src="https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/2024/202504171350837.png" width="60%" height="60%">


- 查询对比
```SQL

--- 从S3 查询数据
--- PS 我这里在Cn mainland 访问的S3 网络比较慢，实际上在US 服务器上速度还是挺快的，不是这么慢
10 rows in set. Elapsed: 2.671 sec. Processed 8.19 thousand rows, 434.18 KB (3.07 thousand rows/s., 162.54 KB/s.)
Peak memory usage: 1.34 MiB.


--- 从 本地cache 查询数据 
← Progress: 8.19 thousand rows, 434.18 KB (1.05 million rows/s., 55.87 MB/s.)  99%
10 rows in set. Elapsed: 0.008 sec. Processed 8.19 thousand rows, 434.18 KB (1.01 million rows/s., 53.46 MB/s.)
Peak memory usage: 1.83 MiB.

```

# 参考
- https://clickhouse.com/docs/integrations/s3#s3-disk
- https://clickhouse.com/docs/operations/backup#backuprestore-using-an-s3-disk


