---
layout: post
title: NGINX gzip compression fix
categories:
  - tech
tags:
  - blog
  - NGINX
  - web
excerpt: NGINX 代理的的web 加载速度优化.
date: 2023-01-01 00:00:01
---


# 问题描述
NGINX 新部署的web  加载静态资源image速度慢的出奇....
![600](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20231231194146.png)

# 问题解决
web多且>1M, 大图片未压缩，拖慢了web 在浏览器的加载速度

## 服务端处理
- 压缩图片
使用optipng 和 jpegoptim 压缩 png 、 jpg 图片。

```bash
# jpg compression 
find ./ *.jpg -exec jpegoptim --size=500k {} \;


# png compression 
find ./ *.png -exec optipng {} \;

```

- config nginx gzip compression 
在nginx.conf 的 http 模块部分增加gzip compression 相关配置：
```js
http { 
   
   #gzip config
    gzip  on;
    gzip_disable "msie6";
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_buffers 16 8k;
    gzip_http_version 1.1;
    gzip_min_length 256;
    gzip_types
    application/atom+xml
    application/geo+json
    application/javascript
    application/x-javascript
    application/json
    application/ld+json
    application/manifest+json
    application/rdf+xml
    application/rss+xml
    application/xhtml+xml
    application/xml
    font/eot
    font/otf
    font/ttf
    image/svg+xml image/x-icon image/bmp image/png image/gif image/jpeg image/jpg
    text/css
    text/javascript
    text/plain
    text/xml;

}
```

## 其它（可选）
- 升级 NGINX 到 1.22 or new , 增加http2 配置提高网站并行速率

## test
```
curl -H "Accept-Encoding: gzip" -I http://localhost//images/blue_owl_Llanganuco_min.png 
```

```
HTTP/1.1 200 OK
Server: nginx/1.25.3
Date: Sun, 31 Dec 2023 12:00:15 GMT
Content-Type: image/png
Last-Modified: Sun, 31 Dec 2023 11:07:31 GMT
Connection: keep-alive
Vary: Accept-Encoding
ETag: W/"65914b73-4541e2"
Content-Encoding: gzip
```


# 参考
- https://www.digitalocean.com/community/tutorials/how-to-set-up-nginx-with-http-2-support-on-ubuntu-18-04
- https://einverne.github.io/post/2018/06/optimize-and-compress-jpeg-and-png-using-command.html
  