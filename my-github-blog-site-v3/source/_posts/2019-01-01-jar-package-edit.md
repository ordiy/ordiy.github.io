---
layout: post
title: Jar Package 编辑技巧
categories:
  - tech
  - Java
tags:
  - blog
  - Java
  - Jar
date: 2019-01-01 00:00:00
excerpt: Edit Jar package 
---

# Jar编辑
- jar 查看
```bash
jar -tf xxx.jar 
```
- jar 解压
```bash
jar -xvf xxx.jar 
```

- jar 更新文件
```
jar -uvf xxx.jar com.xx.AppLaunch.class
```

- jar 包删除指定文件
```
zip -d xxx.jar log4j2.xml 
```

# jar 其它操作
- 查看class file版本
```shell
javap -v xxx.class
```
查看得到的信息中，major version属性的内容，如下：
```bash
major version: 52    //主版本号
minor version: 0     //小版本号
```
说明这个.class文件是由JDK1.8编译得到的。
major version,主版本号对照表.
```bash
J2SE 8.0 = 52(0x33 hex)
J2SE 7.0 = 51(0x32 hex)
J2SE 6.0 = 50 (0x32 hex)
J2SE 5.0 = 49 (0x31 hex)
JDK 1.4 = 48 (0x30 hex)
JDK 1.3 = 47 (0x2F hex)
JDK 1.2 = 46 (0x2E hex)
JDK 1.1 = 45 (0x2D hex)
```
　　注：一个.jar包中可能有多个.class文件，每个.class的JDK版本可能会不一样（编译器多个项目设置不同） 


# Jar execute
- cp指定classpath
```
java -cp ${CLASSPATH}:.:./test.jar com.test.Demo 
```

- cmf 指定main方法：
```
jar cmf Manifest.txt testapp1.jar org
```

- maven 编译插件：
https://www.cnblogs.com/zhangwuji/p/10040834.html
