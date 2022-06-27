---
layout: post
title: 2022-04-09-regionserver-hot-point
categories:
  - tech
tags:
  - blog
date: 2022-06-06 14:05:31
excerpt: HBase RegionServer 
---

# Hot Region
RPC请求集中在某个RegionServer上,导致集群负载不均:
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20220621114219.png)

