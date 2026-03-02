---
layout: post
title: Nginx SSL + Basic Auth 保护内网大数据 Web 管理界面
excerpt: "利用 Nginx 反向代理 + Let's Encrypt SSL + auth_basic 对 Flink UI 、Airflow 等内网 Web 管理界面进行认证防护。"
date: 2026-02-28 14:15:00
tags:
  - Nginx
  - Security
categories:
  - tech
---

在大数据平台开发环境中，像 Flink Web UI、Airflow、还有 Superset 这样的组件通常提供开放且弱管控的 HTTP 访问入口。这在公有云或者跨区域组网的架构中是非常危险的，容易成为挖矿程序的提权后门。

本文分享了一种利用 Nginx 的代理结合 `Let's Encrypt` SSL，并挂载 `auth_basic` Http 用户强校验的防护封堵手段。

<!-- more -->

## 1. 准备 Basic Auth 验证文件

首先我们需要在服务器上利用 `htpasswd` 工具生成账户名和密码记录档。

```bash
# 生成 .htpasswd 文件并添加一个基础账户
sudo htpasswd -c /etc/nginx/.htpasswd my_data_user
# 键入高强度密码...
```

## 2. 撰写 Nginx 代理配置文件

通常这批大数据的界面服务是跑在多端口（如 Flink 的 8081、Airflow 的 8080 等）。我们可以撰写不同模块的代理配置文件。通过拦截 443（HTTPS）并强加认证，最后以 `proxy_pass` 转入目标服务的原生内网端口。

以下为示例配置 Flink Web Manager 代理：

```nginx
# /etc/nginx/conf.d/flink-web.conf

server {
    listen 0.0.0.0:443 ssl ;
    server_name flink-manager.example.internal;

    # >>> 引用预先刷好的 TLS SSL / HTTPS 鉴权证书 <<<
    ssl_certificate /etc/letsencrypt/live/example.internal/fullchain.pem ;
    ssl_certificate_key  /etc/letsencrypt/live/example.internal/privkey.pem ;
    ssl_session_timeout 1d;
    ssl_session_cache shared:MozSSL:10m;  
    ssl_session_tickets off;

    # modern configuration - 强迫放弃落后加密加密套件
    ssl_protocols TLSv1.3 TLSv1.2;
    ssl_prefer_server_ciphers off;
    ssl_ciphers "TLS_CHACHA20_POLY1305_SHA256+AES128+AES256:EECDH+AES128:EECDH+AES256:EDH+AES128:EDH+AES256:EECDH+CHACHA20:EDH+CHACHA20";

    # HSTS (ngx_http_headers_module is required) 
    add_header Strict-Transport-Security "max-age=63072000" always;

    # OCSP stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    keepalive_timeout 10m;

    location / {
        # 【核心保护动作】：挂载 Basic Auth
        auth_basic "Restricted Area|内部受限访问站点 请输入Data用户名及密码";    
        auth_basic_user_file /etc/nginx/.htpasswd;    
        
        # 将完成认证的流量转发到无密 Flink 服务器上
        proxy_pass http://flink-host:8081;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

同理，我们在处理类似 Airflow 的 8080 组件上或者 Metadata 等管理页也都可以用此模板套用。

**总结：** 仅对外网或者跨机房暴露基于 Nginx 的 HTTPS 端口，所有底层的 Web Manger (Airflow/Flink) 端口在安全组和系统层被切断，只能本地环回访问，由 Nginx 的 Basic Auth 全权镇守，是非常轻量和牢靠的大数据安全管控手法！