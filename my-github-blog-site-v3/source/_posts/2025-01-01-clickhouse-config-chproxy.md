---
title: Clickhouse config Chproxy 
tags:
  - clickhouse
categories:
  - tech
 - Data
excerpt: Clickhouse config Chproxy 便于测试环境进行使用和配置
date: 2025-01-01 10:00:00
layout: post
---

# Clickhouse Chproxy 

## config.yml 

`vim config.yml`
配置yml config:
```yml

hack_me_please: true

server:
  http:
    listen_addr: '0.0.0.0:16464'

users:
  - name: "stg_test_admin"
    password: "TRpz1I2p1KlMOIvFxxx"
    to_cluster: 'cluster_2S_2R'
    to_user: 'default'
    max_concurrent_queries: 1024
    max_execution_time: 300s
    requests_per_minute: 600000
    allow_cors: true

clusters:
  - name: 'cluster_2S_2R'
    nodes:
      [
        '10.20.6.147:8123',
        '10.20.6.147:8124',
        '10.20.6.147:8125',
        '10.20.6.147:8126',
      ]
    users:
      - name: 'default'
```

## start test 
```shell 
./chproxy -config ./config.yml 

```


##  配置`clickhouse-chproxy.service`

`sudo vim /etc/systemd/system/clickhouse-chproxy.service `

```js

[Unit]
Description=ClickHouse Proxy (chproxy) Service
After=network.target

[Service]
Type=simple
ExecStart=/data/clickhouse-node01/proxy-chproxy/chproxy -config /data/clickhouse-node01/proxy-chproxy/config.yml
StandardOutput=file:/data/clickhouse-node01/proxy-chproxy/logs/chproxy.log
StandardError=file:/data/clickhouse-node01/proxy-chproxy/logs/chproxy_error.log
Restart=on-failure
User=ubuntu
Group=ubuntu
WorkingDirectory=/data/clickhouse-node01/proxy-chproxy

[Install]
WantedBy=multi-user.target

```

```shell 
sudo systemctl daemon-reload
sudo systemctl start clickhouse-chproxy.service
sudo systemctl status clickhouse-chproxy.service
```
log out:
```shell
● clickhouse-chproxy.service - ClickHouse Proxy (chproxy) Service
     Loaded: loaded (/etc/systemd/system/clickhouse-chproxy.service; disabled; preset: enabled)
     Active: active (running) since Thu 2025-03-27 10:52:08 UTC; 9s ago
   Main PID: 395749 (chproxy)
      Tasks: 11 (limit: 38349)
     Memory: 3.9M (peak: 4.7M)
        CPU: 13ms
     CGroup: /system.slice/clickhouse-chproxy.service
             └─395749 /data/clickhouse-node01/proxy-chproxy/chproxy -config /data/clickhouse-node01/proxy-chproxy/config.yml

```


# client 验证
```

curl -i http://127.0.0.1:8580 
```
输出
```js
HTTP/1.1 401 Unauthorized
Date: Thu, 27 Mar 2025 11:04:53 GMT
Content-Length: 78
Content-Type: text/plain; charset=utf-8

"127.0.0.1:37436": invalid username or password for user "default"; query: ""
```


# 参考

https://github.com/ContentSquare/chproxy/releases
