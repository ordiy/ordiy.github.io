---
layout: post
title: HDFS missing block 问题处理记录
categories:
  - tech
tags:
  - blog
excerpt: IDC 机房出现重大故障，导致Hadoop HDFS missing block 问题的处理过程及记录
date: 2022-12-16 15:01:48
---



# 问题&环境说明 
- 问题
```
IDC机房突然异常断电，导致机器大规模断电重启，并出现IDC内网网络故障
部分物理机无法启动，导致HDFS blokc 丢失
```

- 环境信息
```javascript
Hadoop Version:  2.6.0-cdh5.8.4 
HDFS fediration: 3组 ，分别是：nameservice1 / nfjd-prod-ns3 / nfjd-prod-ns2 
Ranger + Kerberos  进行ACL和身份认证
IDC 自建私有云 , 物理机数量 1000+, 数据总量60P左右

```


# 排查问题
- nanmenode 提示miss block
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_202212161534960.png)

- 获取missing block 列表
```javascript
sudo su - hdfs 

# 检查身份认证信息
 klist 

# 列出缺失的块
hdfs fsck  hdfs://nameservice1/  -list-corruptfileblocks >> 1215-miss-block.txt

hdfs fsck  hdfs://nfjd-prod-ns3/  -list-corruptfileblocks >> 1215-miss-block.txt

hdfs fsck  hdfs://nfjd-prod-ns2/  -list-corruptfileblocks >> 1215-miss-block.txt

```

- 查看内容
`head 1215-miss-block.txt `
```
blk_12885018324	/user/hive/warehouse/....
blk_8321645613	/user/hive/warehouse/....
....
```

 - 统计涉及的表和目录
  提取目录的前7层，涉及的hive库和table
```
cat 1215-miss-block.txt |  awk  '{print $2}' | awk -F'/' '{ print $1"/"$2"/"$3"/"$4"/"$5"/"$6"/"$7 }' | sort | uniq 
```
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_202212161538519.png)


# 后续
对于缺失的块，如何修复：   
```
 机器可以恢复  ---> ，修复机器，并启动datanode
  机器无法恢复，强制删除相关文件（需业务自行评估风险和确认）
```
