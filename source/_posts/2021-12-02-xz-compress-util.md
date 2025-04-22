---
layout: post
title: xz compress util
categories:
  - tech
tags:
  - blog
  - util
date: 2021-12-02 11:59:13
excerpt:  XZ Utils are the successor to LZMA(Lempel–Ziv–Markov chain algorithm) Utils.XZ Utils create 30 % smaller output than gzip and 15 % smaller output than bzip2.
---

# XZ Utils
## tar.xz文件压缩与解压
- compress
```
# 制作tar.xz文件
$ tar -zvf vedio_study_big_data.tar ./vedio_study_big_data 

#多线程打包 提高效率,xz version >= 5.2
$ xz -z --threads=10 vedio_study_big_data.tar
```
- decompress
```
xz -d vedio_study_big_data.tar.xz 
tar -xvf vedio_study_big_data.tar
```



## XZ 特点
压缩率非常高(号称压缩率之王)，但压缩时间较长,在5.2版本引入了LZMA2支持多线程机制，支持多CPU Core并行进行.


# 参考
 - [1] [XZ web](https://tukaani.org/xz/)