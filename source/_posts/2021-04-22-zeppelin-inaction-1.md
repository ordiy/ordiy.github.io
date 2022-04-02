---
layout: post
title: Zeppelin In Action
tags:
  - blog
  - ApacheZeppelin
categories:
  - tech
  - BigData
excerpt: Zeppelin Install and config，并使用Zeppelin 对MySQL数据进行可视化分析。
date: 2021-04-22 14:06:36
---


# About Zeppelin
基于Web的笔记本，可通过SQL，Scala等实现数据驱动的交互式数据分析和协作文档。
> Web-based notebook that enables data-driven, 
> interactive data analytics and collaborative documents with SQL, Scala and more.

Architecture
![](http://zeppelin.apache.org/docs/0.9.0-preview1/assets/themes/zeppelin/img/docs-img/submarine-architecture.png)
*图片@apache zeppelin*

![](http://zeppelin.apache.org/docs/0.9.0-preview1/assets/themes/zeppelin/img/docs-img/submarine-interpreter.png)
*图片@apache zeppelin*


# Install and config 

```
环境：
Centos 7.5
JDK1.8
zeppelin-0.9.0
网络：局域网使用

```

install 过程：

```
wget https://mirrors.bfsu.edu.cn/apache/zeppelin/zeppelin-0.9.0/zeppelin-0.9.0-bin-all.tgz 
# https://mirrors.tuna.tsinghua.edu.cn/apache/zeppelin/zeppelin-0.9.0/zeppelin-0.9.0-bin-all.tgz 

tar zxvf zeppelin-0.9.0-bin-all.tgz

#软链
ln -s zeppelin-0.9.0-bin-all zeppeline

# 
cd zeppline 

# 修改配置
cat<< EOF> conf/zeppelin-site.xml
<property>
  <name>zeppelin.server.addr</name>
  <value>0.0.0.0</value>
  <description>Server binding address</description>
</property>

<property>
  <name>zeppelin.server.port</name>
  <value>8089</value>
  <description>Server port.</description>
</property>
EOF


# start zeppline 
./bin/zeppelin-daemon.sh start 


```


# 配置一个interpreter
备注：建议增加一个内网的maven 私服 repostory 地址，便于jar依赖下载



interperter增加 interpreter
![](https://raw.githubusercontent.com/ordiychen/study_notes/master/res/image/node_image/blog_20210425115420.png)

```
default.url: 	jdbc:mysql://172.17.8.85:3306/
default.user	root	
default.password	***	 
default.driver	com.mysql.jdbc.Driver


Dependencies:
mysql:mysql-connector-java:5.1.49	
```

![](https://raw.githubusercontent.com/ordiychen/study_notes/master/res/image/node_image/blog_20210425120338.png)


- interpreter 命令

```
#nstall all community managed interpreters
./bin/install-interpreter.sh --all


# You can get full list of community managed interpreters by running
./bin/install-interpreter.sh --list

# add 第三方 interpreter 
#rd party interpreters
#http://zeppelin.apache.org/docs/0.9.0/usage/interpreter/installation.html#3rd-party-interpreters
   
```


# zeppline 进行数据可视化分析

```
%mysql 
select tab2.user_name,count(*) as auth_obj_num from  tb_dp_hero_auth_info as tab1 left join tb_dp_hero_user_info tab2 on tab1.user_id = tab2.id  group by tab1.user_id ;

```
分析用户的授权对象个数：
![](https://raw.githubusercontent.com/ordiychen/study_notes/master/res/image/node_image/blog_20210425143319.png)


# 参考文章

[zeppelin interpreter](http://zeppelin.apache.org/docs/0.9.0/usage/interpreter/installation.html)
[zeppelin architecture](http://zeppelin.apache.org/docs/0.9.0-preview1/interpreter/submarine.html#architecture)
