---
layout: post
title: Raspberrypi compile and install nginx 
date: 2018-03-11 11:21:32
categories:
  - tech
  - ARM
tags:
  - blog
  - NGINX
  - Raspberrypi
excerpt: Raspberrypi 4B 编译和安装Ningx 1.19
---

# ARM处理器的集中指令集

| 移殖| 架构 | 简介|
|:---|:---|:---|
| armel | 	EABI ARM |  是arm eabi little endian的缩写。eabi是软浮点二进制接口，这里的e是embeded，是对于嵌入式设备而言。|
| armhf |是arm hard float的缩写。   ARMv7 |
| arm64 | 64-bit ARM ,ARMV8 |
armel和armhf的区别 
它们的区别体现在浮点运算上，它们在进行浮点运算时都会使用fpu，但是armel传参数用普通寄存器，而armhf传参数用的是fpu的寄存器，因此armhf的浮点运算性能更高。
gcc编译的时候，使用-mfloat-abi选项来指定浮点运算使用的是哪种，soft不使用fpu，armel使用fpu，使用普通寄存器，armhf使用fpu，使用fpu的寄存器。


 # ARM compile NGINX 
 下载软件包，以便我们编译nginx：
 ```
 # init 
$ sudo apt-get install -y apt-utils autoconf automake build-essential git libcurl4-openssl-dev libgeoip-dev liblmdb-dev libpcre++-dev libtool libxml2-dev libyajl-dev pkgconf wget zlib1g-dev

 ````

清理ningx config file ：/etc/nginx
 ```
$ sudo apt remove nginx
 ```

 # download 
 ```
 $ wget https://nginx.org/download/nginx-1.19.9.zip
 $ wget https://nginx.org/download/nginx-1.19.9.zip.asc

$ gpg --verify nginx-1.13.11.tar.gz.asc nginx-1.13.11.tar.gz

$ tar -zxvf nginx-1.13.11.tar.gz
$ cd nginx-1.13.11


$ ./configure
    --sbin-path=/usr/local/nginx/nginx
    --conf-path=/usr/local/nginx/nginx.conf
    --pid-path=/usr/local/nginx/nginx.pid
    --with-http_ssl_module

$ make
$ sudo make install
 ```

- test 
```
# nginx test
sudo nginx -t 

nginx version: nginx/1.19.7
built by gcc 8.3.0 (Raspbian 8.3.0-6+rpi1)
configure arguments:

```

```
curl -i -XGET 'http://127.0.0.1'
```

# 总结
ARM 处理器目前有多种CPU架构，编译时需要注意。

# 参考

[ARM Cortex A78](https://developer.arm.com/ip-products/processors/cortex-a/cortex-a78?_ga=2.96347861.810840481.1619338199-1241787852.1619338199)

