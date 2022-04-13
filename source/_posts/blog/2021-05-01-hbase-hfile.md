---
layout: post
title:  HBase HFile 基本概念
date: 2021-05-01 18:18:45
tags:
  - HBase
  - GitBook
categories:
  - tech
  - HBase
excerpt: HFile参考BigTable的SSTable和Hadoop的TFile实现,用于MemStore中数据落盘之后会形成一个或者多个文件写入HDFS
---

# HFile 简介
HFile参考BigTable的SSTable和Hadoop的TFile实现,用于MemStore中数据落盘之后会形成一个或者多个文件写入HDFS。HFile JARA [HBASE-61](https://issues.apache.org/jira/browse/HBASE-61)

# HFile 结构
## HFile 逻辑结构
以HFile V2为例，HFile的逻辑结构：
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20220330180033.png)

## HFile 物理结构
以HFile V2为例，HFile的物理结构：
HFile各种不同类型的Block构成，在HBase DDL建表语句中的`BLOCKSIZE => '65536'`，表示Block的大小。
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20220330160731.png)

虽然HFile的Block Type有多种，但是每个Block的数据结构都是一样的（便于存储，遍历？），Block结构：
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20220330163133.png)
又的数据可能会存储在多个HFile Block上。

HFile Block 的BlockType 类型:
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20220330163704.png)

 

* 参考更多：
[HFile v1 & HFile v2](http://devdoc.net/bigdata/hbase-0.98.7-hadoop1/book/hfilev2.html#hfilev2.overview)

## HFile V2 feature
 HFile V2在Boolm Fileter上增加了位数组拆分功能，可以按照Key拆分

## HFile V3 feature

|additional info | desc |
|:----|:----|
|hfile.MAX_TAGS_LEN |The maximum number of bytes needed to store the serialized tags for any single cell in this hfile (int) |
|hfile.TAGS_COMPRESSED | Does the block encoder for this hfile compress tags? (boolean) </br>Should only be present if hfile.MAX_TAGS_LEN is also present. |

HFile V3增加的2个特性，似的可以对Column Famliy中的Key和Value使用不同的压缩方法。（目前还没发现有什么具体的实践）
*注[HFile V3](http://devdoc.net/bigdata/hbase-0.98.7-hadoop1/book/hfilev3.html)

版本逻辑结构对比：
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20220330155918.png)


# HFile 的Block说明
## HFile Trailer Block
Trailer Block 记录HFile的版本信息、各部分的偏移值和寻址值（可以看作是HFile的元数据）。查看Trailer Block  信息：

```bash
hbase hfile -f /hbase/data/default/xxx_table/fff89b301b32e363c5f95788fb44bb6c/A/5c9c11f43b9d4b52a53e62d4ea1dc6b4 -m
```
内容：
```javascript
reader=/hbase/data/default/xxx_table/fff89b301b32e363c5f95788fb44bb6c/A/5c9c11f43b9d4b52a53e62d4ea1dc6b4,
    compression=gz,
    cacheConf=CacheConfig:disabled,
    firstKey=1110000007101565658/A:json_result/1641611263000/Put,
    lastKey=1114996580280422658/A:json_result/1635760526000/Put,
    avgKeyLen=43,
    avgValueLen=435,
    entries=143417796,
    length=4743346317
Trailer:
    fileinfoOffset=4743345372,
    loadOnOpenDataOffset=4743335023,
    dataIndexCount=479,
    metaIndexCount=0,
    totalUncomressedBytes=70255033695,
    entryCount=143417796,
    compressionCodec=GZ,
    uncompressedDataIndexSize=62723887,
    numDataIndexLevels=2,
    firstDataBlockOffset=0,
    lastDataBlockOffset=4743187322,
    comparatorClassName=org.apache.hadoop.hbase.KeyValue$KeyComparator,
    majorVersion=2,
    minorVersion=3
Fileinfo:
    BLOOM_FILTER_TYPE = ROW
    DELETE_FAMILY_COUNT = \x00\x00\x00\x00\x00\x00\x00\x00
    EARLIEST_PUT_TS = \x00\x00\x01;\xF3k>0
    KEY_VALUE_VERSION = \x00\x00\x00\x01
    LAST_BLOOM_KEY = 1114996580280422658
    MAJOR_COMPACTION_KEY = \x00
    MAX_MEMSTORE_TS_KEY = \x00\x00\x00\x00\x00\x00\x01\x5C
    MAX_SEQ_ID_KEY = 348
    TIMERANGE = 1356998590000....9359508000000
    hfile.AVG_KEY_LEN = 43
    hfile.AVG_VALUE_LEN = 435
    hfile.LASTKEY = \x00\x131114996580280422658\x01Ajson_result\x00\x00\x01|\xDA\xEC\xD2\xB0\x04
Mid-key: \x00\x131112514530495714671\x01Ajson_result\x00\x00\x01}\xF9\x00W\xA8\x04\x00\x00\x00\x00\x8D\xA5oq\x00\x00\x09\xAF
Bloom filter:
    BloomSize: 1835008
    No of Keys in bloom: 1517186
    Max Keys for bloom: 1530284
    Percentage filled: 99%
    Number of chunks: 14
    Comparator: RawBytesComparator
Delete Family Bloom filter:
    Not present
```

## Data Block
Data Blocks是存储KeyValue数据，HBase中所有数据都是以KeyValue结构存储在HBase中，内存和磁盘中的Data Block结构：
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20220330164326.png)

KeyValue由：Key Length, Value Length, Key和Value。其中Key是一个复合结构，由多个部分构成：Rowkey、Column Family、Column Qualifier、TimeStamp以及KeyType。所以，任意的KeyValue都包含Rowkey、Column Family、Column Qualifier（TimeStamp（long类型 8byte/KeyType(枚举）是定长的，占用空间较小），因此这种存储方式比直接存储Value占用更多的存储空间。也是HBase表结构设计时经常强调Rowkey、Column Family以及Column Qualifier尽可能设置短的根本原因。


## Bloom Block 以及 Bloom Index Block结构
布隆过滤器（Bloom）对HBase的数据读取性能至关重要。（原因：LSM树对写入非常友好，对读取并不十分友好(遍历)，使用布隆过滤器（Bloom）可以进行相应优化，可以直接判断HFile是否存在待检索Key，同时使用了多层Bloom数位组)
- Bloom Block
在HFile V2中Bloom Filer位数组进行了拆分，可以拆分为多个位数组，每个位数组就对应一个Bloom Block。

- Bloom Index Block
在存在多个Bloom Filter位数组时候，为了提高效率使用Bloom Index Block来定位不同的位数组。Bloom Index Block内存和逻辑结构：
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20220330182201.png)
`Bloom Index Block`的`Bloom Index Entry`的`BlockOffset`是一个指向`Bloom Block`在HFile中的偏移量。
在实现上由`CompoundBloomFilterBase.java`进行数位组的查找和定位：
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20220330184840.png)  
使用一个二维数组表示多个BloomFilter的多个数位组，以及关联的Block的position：
```java
  public static int binarySearch(byte[][] arr, byte[] key, int offset, int length) {
    int low = 0;
    int high = arr.length - 1;

    while (low <= high) {
      int mid = (low + high) >>> 1;
      // we have to compare in this order, because the comparator order
      // has special logic when the 'left side' is a special key.
      int cmp = Bytes.BYTES_RAWCOMPARATOR
          .compare(key, offset, length, arr[mid], 0, arr[mid].length);
      // key lives above the midpoint
      if (cmp > 0)
        low = mid + 1;
      // key lives below the midpoint
      else if (cmp < 0)
        high = mid - 1;
      // BAM. how often does this really happen?
      else
        return mid;
    }
    return -(low + 1);
  }
```

所以： Get请求根据Bloom Filter进行过滤查找，可分为三步： Key 在BloomIndexBlock 所有BlckKey二分查找到，定位到Bloom Index Entity  > 使用Bloom Index Entity加载对应的位数组 ---> 对key进行Hash Mapping ,对数位组进行查找（! All 1 == 存在）


# HFile 基本命令
```bash
$ hbase hfile

usage: HFile [-a] [-b] [-e] [-f <arg> | -r <arg>] [-h] [-i] [-k] [-m] [-p]
       [-s] [-v] [-w <arg>]
 -a,--checkfamily         Enable family check
 -b,--printblocks         Print block index meta data
 -e,--printkey            Print keys
 -f,--file <arg>          File to scan. Pass full-path; e.g.
                          hdfs://a:9000/hbase/hbase:meta/12/34
 -h,--printblockheaders   Print block headers for each block.
 -i,--checkMobIntegrity   Print all cells whose mob files are missing
 -k,--checkrow            Enable row order check; looks for out-of-order
                          keys
 -m,--printmeta           Print meta data of file
 -p,--printkv             Print key/value pairs
 -r,--region <arg>        Region to scan. Pass region name; e.g.
                          'hbase:meta,,1'
 -s,--stats               Print statistics
 -v,--verbose             Verbose output; emits file and meta data
                          delimiters
 -w,--seekToRow <arg>     Seek to this row and print all the kvs for this
                          row only

```


# 参考
- 胡争,范欣欣. HBase原理与实践 (Chinese Edition) (p. 150). Kindle 版本. 