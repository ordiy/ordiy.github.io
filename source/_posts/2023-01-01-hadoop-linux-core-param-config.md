---
layout: post
title: Hadoop 服务器内核参数设置
categories:
  - tech
tags:
  - blog
excerpt: >-
  Hadoop
  集群安装前应该对服务器的内核参数进行设置，以提高性能（网络/CPU)。同时对磁盘、NTP、DNS等进行检查，推荐使用ansible进行批量操作。
date: 2023-01-01 00:00:10
---


# 查看服务器默认参数
```shell 
# debain 为例
sudo /sbin/sysctl -a 
```

# 设置参数

## 内核参数：
```
fs.file-mx=6815744
fs.aio-max-n=1048576
net.core.rmem default=262144
net.core. wmem default=262144
net.core.rmem max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_ rmem=4096 262144 16777216
net.ipv4.tcp_ Wmem=4096 262144 16777216
```
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20231212122036.png)

## 文件数限制和进程数
```shell
#ulimit
# HDP 推荐10000, 大服务器可以设置到更多

sudo vim /etc/security/limits.conf

soft nofile 65535
hard nofile 65535

# 进程数量
soft nproc 32768
hard nproc 32768
```
生效：
```shell
systctl -p

systctl -a

```

## 其它检查项目
```shell
# 磁盘 I/O 速度 (read ) 70MB/S  以上
hdparm -t /dev/sda1 


#  NTP 同步时间很重要

# DNS  hosts 配置正反向DNS
# 大集群启动linux nscd 服务
通过编辑/etc/nscd.conf文件，在其中增加如下一行可以开启本地DNS cache：
enable-cache hosts yes


# 禁止 swap ( datanode )
# 防止内存满后使用 swap ，将swappiness 设置为1, 加速机器内存用满后立即退出程序
swappiness=1


# 磁盘整理是否要禁止，还没实际测试过，但是 Cloudrea 公司建议禁用

```