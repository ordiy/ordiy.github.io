---
layout: post
title: Apache superset guide
categories:
  - tech
tags:
  - blog
date: 2023-01-01 17:53:05
excerpt: Apache superset 使用笔记
---


# About apache superset 


# Start 
## install apache superset

```shell 


git clone https://github.com/apache/superset.git

cd superset 

docker compose -f docker-compose-non-dev.yml pull
docker compose -f docker-compose-non-dev.yml up

```

## test 

```shell 
curl -i http://localhost:8088
```
log:
```text
HTTP/1.1 302 FOUND
Server: gunicorn
Date: Sun, 10 Dec 2023 10:24:34 GMT
Connection: keep-alive
Content-Type: text/html; charset=utf-8
..........
```

## jinja SQL 