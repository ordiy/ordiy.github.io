---
layout: post
title: 搭建HTTP内网文件服务器-以NGINX为例
date: 2021-02-01 14:14:55
categories:
  - tech
  - net
tags:
  - blog
  - Nginx
  - Net
excerpt: 基于HTTP协议搭建一个简单的内网文件服务器，方便公司的办公和开发测试,减少办公时间段大文件下载对WLAN带宽的消耗，并引入了NGINX AIO用以提升性能,增加对浏览器预览PDF/TXT等文件的支持。
---

# 需求

在内网建一个文件服务器，需要示意图如下：    
![](https://raw.githubusercontent.com/ordiychen/study_notes/master/res/image/node_image/blog_20210329185845.png)


实现需求，可行的组件:
```
apache http
tomcat/jetty
nginx 
.....

```
为方续架构扩展（如做反向代理等）、扩展功能的丰富性和个人对组件的熟悉程度，最终选择了Nginx.


# nginx 搭建文件服务
这里需要使用到Nginx的`autoindex` 特性（`ngx_http_autoindex_module`  模块），以及其它几个module。由于本文涉及到Nginx的多个版本的不同feature ，建议nginx安装版本为： 1.18.0 +  ,详情参照[Nginx Changes](http://nginx.org/en/CHANGES)

##  nginx install
```
wget http://nginx.org/packages/rhel/7/x86_64/RPMS/nginx-1.18.0-2.el7.ngx.x86_64.rpm

sudo yum install nginx-1.18.0-2.el7.ngx.x86_64.rpm -y

nginx -V

```

## 修改配置
```
vim /etc/nginx/conf.d/default.conf
server {
    listen       80;
    server_name  localhost;

    #charset koi8-r;
    #access_log  /var/log/nginx/host.access.log  main;


    #location / {
    #    root   /usr/share/nginx/html;
    #    index  index.html index.htm;
    #}

    # file index
    location / {
        root /opt/data/hdp_dir/;
        charset utf-8;

        autoindex on;
        autoindex_exact_size off;
        autoindex_format html;
        autoindex_localtime on;
     }
}
```

## 配置文件目录权限
 设置文件目录权限
```
chown -R nginx:users  /opt/data/hdp_dir/
chmow -R 775 /opt/data/hdp_dir/

```

- nginx 重启
```
#开机启动
systemctl enable nginx

# 启动
systemctl restart nginx

```

- 测试
```
curl -XGET "http://127.0.0.1:80'

```
文件服务搭建完毕。如下图：   
![](https://raw.githubusercontent.com/ordiychen/study_notes/master/res/image/node_image/blog_20210329191803.png)


## 提升IO性能
由于大并发的大文件下载，磁盘IO会最先成为瓶颈。所以这里对IO进行优化，增加`aio` 和 `sendfile` `tcp_nopush` `tcp_nodelay` 用以提升IO性能，全部配置如下：
```
user  nginx;
worker_processes  2;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;

thread_pool default threads=8 max_queue=5096;

events {
    worker_connections  1024;
}


http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    #tcp_nopush     on;
    #tcp_nodelay    on;
    sendfile_max_chunk 512k;

    #keep connection keep alive
    keepalive_timeout  300s;

    gzip  on;

      server {
        listen       80;
        server_name  localhost;

        access_log  /var/log/nginx/host.access.log  main;

        # file index
        autoindex on;
        location / {
            sendfile       on;
            aio            threads=default;

            root /home/chenpx/hdp_dir/;
            #index index.html;
            charset utf-8;

            autoindex on;
            autoindex_exact_size off;
            autoindex_format html;
            autoindex_localtime on;
        }

        #error_page  404              /404.html;

        # redirect server error pages to the static page /50x.html
        #
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   /usr/share/nginx/html;
        }
      }
}
```
以下载一个10G文件为例子，从实际测试效果对比看，磁盘的IO压力的下降了很多，如下图：
![](https://raw.githubusercontent.com/ordiychen/study_notes/master/res/image/node_image/blog_20210330180829.png)

按照官网的[Thread Pools in NGINX Boost Performance 9x!](https://www.nginx.com/blog/thread-pools-boost-performance-9x/),性能可以提升9倍。
AIO配置说明，参照 [nginx aio ](http://nginx.org/en/docs/http/ngx_http_core_module.html#aio).

## 增加文件预览
实现对配置允许的文件格式后缀，文件可以打开，可以下载。

```  
        location / {
            charset utf-8;
            autoindex on;
            autoindex_exact_size off;
            autoindex_format html;
            autoindex_localtime on;

            #file  shows   
            if ($request_filename ~* ^.*?\.(txt|doc|pdf|rar|gz|zip|docx|exe|xlsx|ppt|pptx)$){
                add_header Content-Disposition: 'p_w_upload;';
            }
        }
```


# 总结

- index.html文件冲突
Nginx `autoindex` 可能会遇到目录下有 index.html 文件，出现401` Error Object `问题，可以采用下面的方法解决：
```
# 对目录下的 index.html文件进行重命名
find ./ -type f -name "index.html" -exec  mv {} {}-bak \;
```
修改完成后可能需要nginx 服务。

- 权限控制
如果需要设置权限控制，可以使用[`ngx_http_access_module`](http://nginx.org/en/docs/http/ngx_http_access_module.html), 需要用户鉴权还可用设置[`HTTP Basic Authentication`](https://docs.nginx.com/nginx/admin-guide/security-controls/configuring-http-basic-authentication/). 对于需要多租户的场景，可以配置 Basic HTTP authentication，参考[nginx用户认证配置（ Basic HTTP authentication](http://www.ttlsa.com/nginx/nginx-basic-http-authentication/)

- 文件搜索
对于需要使用搜索功能，可以使用 [`ngx-fancyindex)`](https://github.com/aperezdc/ngx-fancyindex) 插件，实现效果如下图：
![](https://perso.crans.org/besson/publis/Nginx-Fancyindex-Theme/Nginx-Fancyindex-Theme__example1.png)

- 传输安全
如果涉及敏感数据传输，建议增加TLS1.2+协议进行加密传输

- 为什么不用FTP实现
FTP不是一项安全的协议，并且具有许多安全漏洞。比如存在暴力破解、FTP反弹攻击。在加上FTP使用的端口是21，一般会被防火墙屏蔽。（yum 等repository 仓库默认使用的都是HTTP协议）



# 参考
- [Module ngx_http_autoindex_module](http://nginx.org/en/docs/http/ngx_http_autoindex_module.html#example)
- [Nginx系列之nginx静态文件服务](https://aiopsclub.com/nginx/nginx_static_file/)
- [Nginx目录列表(autoindex)配置相关以及页面美化](https://blog8.flyky.org/20191128/nginx-autoindex-conf/)
- [Nginx install](https://www.nginx.com/resources/wiki/start/topics/tutorials/install/)
- [nginx优化——包括https、keepalive等](https://lanjingling.github.io/2016/06/11/nginx-https-keepalived-youhua/)