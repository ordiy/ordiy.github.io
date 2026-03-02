---
layout: post
title: Flink清洗Nginx日志
tags:
 - Flink
  - nginx 
  - log
  - ETL
  - TODO
categories:
  - tech
  - Data
excerpt: "FLink 清洗 nginx request log and reponse log"
date: 2025-01-01 00:00:00
---


# 背景和需求
在广告DSP/DMP系统中,需要收集到Nginx Log来排查问题并将日志作为数据分析的数据源.

# 整体架构

```js

ELB --> Nginx HA 
                --->  记录日志 
                   --> filebeat / fluent-bit 收集/转换日志
                     --> kafka MQ 
                       --> Flink Task 
                         ---> Clickhouse数仓存储 / Es 
                            ---> BI / Kibana 


```
组件版本信息:
```js
nginx 1.24

Flink 1.17.2

```


# nginx 输出日志

默认的nginx log 模块只能记录请求信息:

```js
http {
  log_format postdata escape=json '$remote_addr - $remote_user [$time_iso8601] '
	               '$host $cookie_ $content_length '
                       '$request_id "$request" $uri  $request_length  $status [$content_type]  $bytes_sent '
                       '"$http_referer" "$http_user_agent" "$request_body" "$request_headers"';

    server {

    }
}
```
日志:
```js
129.80.59.27 - app_data09 [2025-06-03T03:52:23+00:00] file-upload.data-oci.qiliangjia.com  22 da52888533afb04512bf8c55044a4816 "GET /data_v2/data_v1/ip_geo_info/1.1.1.1 HTTP/1.1" /data_v2/data_v1/ip_geo_info/1.1.1.1  306  200 [application/json]  343 "" "curl/8.5.0" "{\"name\":\"hello_world\"}" ""

```


所以需要nginx lua modle(`libnginx-mod-http-lua`)
```shell
sudo apt install libnginx-mod-http-lua -y 
```
主要使用`body_filter_by_lua_block` 打印
https://github.com/openresty/lua-nginx-module?tab=readme-ov-file#body_filter_by_lua


```js

location /data_v2/ {
	      access_log  /var/log/nginx/postdata.log  postdata;

	      # Capture request headers
            # 将请求信息暂存, 放到最后一起打印
            access_by_lua_block {
            ngx.req.read_body()
            local req_body = ngx.req.get_body_data()
            local req_uri = ngx.var.request_uri
            local req_method = ngx.var.request_method
            if req_body and #req_body > 1024 * 1024 then
                req_body = "Request too large"
            end
            if not req_body then
                req_body = "No request body"
            end
            local headers = ngx.req.get_headers()
            local header_str = ""
            for k, v in pairs(headers) do
                header_str = header_str .. string.format("%s: %s\n", k, v)
            end
            ngx.ctx.req_info = {
                uri = req_uri,
                body = req_body,
                method = req_method,
                headers = header_str
            }
            }

            body_filter_by_lua_block {
            local req_info = ngx.ctx.req_info or {}
                local req_uri = req_info.uri or "Unknown URI"
                local req_body = req_info.body or "Unknown Request Body"
                local req_method = req_info.method or "Unknown Method"
                local req_headers = req_info.headers or "Unknown Headers"
                local resp_headers = ngx.resp.get_headers()
                local resp_header_str = ""
                for k, v in pairs(resp_headers) do
                    resp_header_str = resp_header_str .. string.format("%s: %s\n", k, v)
                end

                if ngx.ctx.buffered_resp_body == nil then
                    ngx.ctx.buffered_resp_body = ""
                    ngx.ctx.buffered_resp_size = 0
                end

                local current_chunk = ngx.arg[1] or ""
                ngx.ctx.buffered_resp_body = ngx.ctx.buffered_resp_body .. current_chunk
                ngx.ctx.buffered_resp_size = ngx.ctx.buffered_resp_size + #current_chunk

                if ngx.ctx.buffered_resp_size > 1024 * 1024 then
                    ngx.ctx.buffered_resp_body = "Response body too large to log"
                end
                if ngx.arg[2] then
                    ngx.log(ngx.ERR, string.format(
                        "Request Method: %s\nRequest URI: %s\nRequest Headers:\n%sRequest Body: %s\nResponse Headers:\n%sResponse Body: %s\n",
                        req_method,
                        req_uri,
                        req_headers,
                        req_body,
                        resp_header_str,
                        ngx.ctx.buffered_resp_body
                    ))
                end
            }


            # Capture response body
	    proxy_pass http://10.21.100.117:18901/;
	    # Enable response buffering
            proxy_buffer_size 128k;
            proxy_buffers 4 256k;

      }

```

log 内容:
```js

2025/06/03 07:51:19 [error] 3300802#3300802: *18163 [lua] file-upload.conf:125):26: Request Method: GET
Request URI: /data_v2/data_v1/ip_geo_info/1.1.1.1
Request Headers:
accept: */*
host: file-upload.data-oci.qiliangjia.com
content-length: 22
authorization: Basic cWxqX2RhdGEwOTpwd2RRTEpEYXRhMDkyMDI0MjliYzJmNmJhZjkw
content-type: application/json
user-agent: curl/8.5.0
cookie: USER_TOKEN=Yes
Request Body: {"name":"hello_world"}
Response Headers:
strict-transport-security: max-age=63072000
connection: keep-alive
content-type: application/json
transfer-encoding: chunked
content-disposition: inline;filename=f.txt
Response Body: {"lat":null,"lon":null,"country_code":null,"city":null,"geo_id":""}
 while sending to client, client: 129.80.59.27, server: file-upload.data-oci.qiliangjia.com, request: "GET /data_v2/data_v1/ip_geo_info/1.1.1.1 HTTP/1.1", upstream: "http://10.21.100.117:18901/data_v1/ip_geo_info/1.1.1.1", host: "file-upload.data-oci.qiliangjia.com"
```

# filebeat 同步数据到MQ
//TODO  filebeat 配置

# Flink 清洗数据
//TODO flink sql 代码

# 参考
- lua-nginx-module
  https://github.com/openresty/lua-nginx-module

- openresty
https://github.com/openresty/openresty 
https://openresty.org/en/download.html

- openresty install
https://openresty.org/cn/installation.html
- nginx 记录完整的 request 及 response
https://www.hujingnb.com/archives/934
https://github.com/hujingnb/docker_composer/blob/master/openresty/nginx/config/test.conf

- access log to Clickhouse
https://clickhouse.com/blog/nginx-logs-to-clickhouse-fluent-bit
