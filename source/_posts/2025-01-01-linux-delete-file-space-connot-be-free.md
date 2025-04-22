---
title:  Liunx 文件删除后 Disk 空间未释放
excerpt: Liunx 文件删除后，系统Disk空间未能释放问题排查。Liunx中如果删除一个正在被进程读写的文件时，文件描述符未关闭，导致磁盘空间未释放。
layout: post
date: 2025-04-08 19:05:03
tags:
 - os
 - linux
categories:
 - tech
 - blog
---

# 问题描述
有一个服务器Disk空间告警，删除文件后依然未能释放空间。

![300](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/2024/202504081848213.png)

# 原因排查
 ```shell 
# 删除的 log4j console out 日志文件
# 100G 
rm logs/connectDistributed.out 

```
但是Disk空间并未释放，怀疑是删除的文件未被释放

```shell
sudo lsof | grep deleted

```

![300](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/2024/202504081825764.png)

进程483844的`connectDistributed.out ` 是已经删除，单文件并未被释放。
需要终止进程释放这个文件（进程结束后，空间会自动释放，重启进程服务也可以达到这个目的）

- 其它方案（不终止进程，截断文件）

```shell

sudo truncate -s 0 /data/kafka_2.13-3.8.0/logs/connectDistributed.out

```

# 预防
避免删除进程正在写入的文件，需要清理可采用truncate 清空文件
```shell 

truncate -s 0 /data/kafka_2.13-3.8.0/logs/connectDistributed.out

```

- 删除一个正在读写的文件，文件描述符可能持续大幅波动（文件句柄）
如下图（左侧为删除前，右侧是删除后）
![300](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/2024/202504081920774.png)



