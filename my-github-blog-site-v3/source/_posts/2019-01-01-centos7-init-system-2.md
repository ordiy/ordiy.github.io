---
layout: post
title: Centos7 install and config haproxy notes
categories:
  - tech
tags:
  - blog
excerpt: centos7 install openssl/haproxy 支持TLS1.3 以及 HTTP2
date: 2022-01-01 00:00:00
---


# 需求

```
使用haproxy 验证QUICC和gRPC 代理
```
需要使用的组件和用途
```
certbot 获取CA证书
openssl TLS加密解密组件
haproxy  QUICC和gRPC loadbanlance 
nginx  静态html 服务
```


# certbot  获取证书
```

#certbot certonly --webroot -w /var/www/html -d www.mydomain.com -d mydomain.com --email <YOUR_EMAIL_ADDRESS> --agree-tos
#certbot certonly  -d www.isun.app -d isun.app --manual --preferred-challenges --email admin@noxftech.com  dns --server https://acme-v02.api.letsencrypt.org/directory

admin@noxftech.com

# config txt
dig @8.8.8.8 -t txt  _acme-challenge.isun.app


# 设置renew certbot oxy
vim renew.sh


crontab -e
0 3 * * * /root/renew.sh > /dev/null 2>&1
```

# install  openssl haproxy 

## install openssl 1.1.x
```
#https://www.osradar.com/how-to-install-the-latest-version-of-openssl-on-centos-7/
wget --no-check-certificate https://ftp.openssl.org/source/old/1.1.1/openssl-1.1.1q.tar.gz 

tar xvf openssl-1.1.1q.tar.gz 

cd openssl-1.1.1q/
./config --prefix=/usr/openssl-1.1.1q shared
# make 
make CPU=native USE_PCRE2=1 USE_PCRE2_JIT=1 USE_OPENSSL=1 SSL_LIB=/usr/local/openssl-1.1.1/lib SSL_INC=/usr/local/openssl-1.1.1/include USE_ZLIB=1

# make install 
sudo make install

# check version 
openssl version -a

```

## install haproxy 

### make install 
```shell

sudo yum install -y wget 

# gcc make 
yum install gcc openssl-devel readline-devel systemd-devel make pcre-devel
sudo yum install wget -y 


# wget  
wget https://www.haproxy.org/download/2.6/src/haproxy-2.6.6.tar.gz
tar -zxvf haproxy-2.6.6.tar.gz
cd haproxy-2.6.6

# make 
## make TARGET=linux2628 CPU=native USE_PCRE2=1 USE_PCRE2_JIT=1 USE_OPENSSL=1 SSL_LIB=/opt/openssl-1.1.1/lib SSL_INC=/opt/openssl-1.1.1/include USE_ZLIB=1
# make TARGET=linux-glibc USE_QUIC=1 USE_PCRE=1 USE_OPENSSL=1 USE_ZLIB=1 USE_CRYPT_H=1 USE_LIBCRYPT=1 SSL_LIB=/opt/openssl-1.1.1/lib SSL_INC=/opt/openssl-1.1.1/include


# make with opensslv1.1.1 ,support tls1.3 
#sudo make TARGET=linux-glibc  USE_OPENSSL=1 SSL_LIB=/usr/lib SSL_INC=/usr/include USE_ZLIB=1
# make /usr/openssl-1.1.1q 
#make TARGET=linux-glibc USE_OPENSSL=1 SSL_LIB=/usr/openssl-1.1.1q/lib SSL_INC=/usr/openssl-1.1.1q/include USE_ZLIB=1
# make 
make TARGET=linux-glibc USE_OPENSSL=1 SSL_LIB=/usr/openssl-1.1.1q/lib SSL_INC=/usr/openssl-1.1.1q/include USE_ZLIB=1

# 解决 error while loading shared libraries: libssl.so.1.1: cannot open shared object file: No such file or directory
vim ~/.bash_profile
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/openssl-1.1.1q/lib 



# make install 
sudo make install

sudo mkdir -p /etc/haproxy
sudo mkdir -p /var/lib/haproxy 
sudo touch /var/lib/haproxy/stats

# slink 
sudo ln -s /usr/local/sbin/haproxy /usr/sbin/haproxy

# config systemctl 
sudo cp ~/haproxy-2.6.6/examples/haproxy.init /etc/init.d/haproxy
sudo chmod 755 /etc/init.d/haproxy
sudo systemctl daemon-reload

# config systemctl
sudo chkconfig haproxy on
sudo systemctl enable haproxy

sudo useradd -r haproxy
haproxy -v
 
# show all module 
haproxy -vv

# check systemctl status ,default not start 
sudo systemctl  status haproxy 
```



### config haproxy.cfg file example 
haproxy.cfg 普通配置案例：
```javascript 
#vim  /etc/haproxy/haproxy.cfg

global
    log         127.0.0.1 local3 info
    chroot      /var/lib/haproxy
    maxconn     512
    user        haproxy
    group       haproxy
    daemon
    pidfile     /var/run/haproxy.pid
   # do not keep old processes longer than that after a reload
   hard-stop-after 5m
   # The command-line-interface (CLI) used by the admin, by provisionning
   # tools, and to transfer sockets during reloads
   stats socket /var/run/haproxy-svc1.sock level admin mode 600 user haproxy expose-fd listeners
   stats timeout 1h
   # intermediate security for SSL, from https://ssl-config.mozilla.org/
   ssl-default-bind-ciphers TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
   ssl-default-bind-options prefer-client-ciphers no-sslv3 no-tlsv10 no-tlsv11  no-tls-tickets


defaults
    maxconn 150
    log global
    mode tcp
    option dontlognull
    timeout connect 30s
    timeout client 900s
    timeout server 900s
    timeout tunnel  600s
    option srvtcpka #tcp mode, server side send  keep alived
    option tcpka   #tcp keep alved
    timeout http-request 5s #slow request
    http-reuse aggressive

frontend www
   mode http
   maxconn 10
   bind *:80,[::]:80 v6only
   http-request redirect scheme https unless { ssl_fc }

frontend tls-inbound
    bind *:443,[::]:443 v6only ssl crt /etc/letsencrypt/live/www.isun.app/www_isun_app_crt.pem
    mode http
    maxconn 10
    http-after-response set-header Strict-Transport-Security "max-age=31536000"
    # silently ignore connect probes and pre-connect without request
    #option http-ignore-probes
    # pass client's IP address to the server and prevent against attempts
    # to inject bad contents
    #http-request del-header x-forwarded-for
    option forwardfor
    #enable HTTP compression of text contents
    compression algo deflate gzip
    compression type text/ application/javascript application/xhtml+xml image/x-icon
    # enable HTTP caching of any cacheable content
    tcp-request inspect-delay 10s
    tcp-request content accept if HTTP
    default_backend web-site

frontend admin_stats
    mode http
    bind *:8085 ssl crt /etc/letsencrypt/live/www.isun.app/www_isun_app_crt.pem  alpn h2,http/1.1
    option httpclose
    option forwardfor
    option httplog
    maxconn 10
    default_backend stats_web

backend stats_web
   mode http
   stats enable
   stats refresh 30s
   stats uri /admin
   stats auth admin:123123_pwdLogin
   stats admin if TRUE


backend web-site
   mode http
   server s1 127.0.0.1:8085 check inter 12000

```
启动服务
```javascript
sudo systemctl start haproxy
sudo systemctl status haproxy
```
测试服务
```
curl -i -XGET 'https://127.0.0.1/admin
```

### haprox 软重启
aproxy 支持一种软重载，避免TCP长连接在更改配置时断开（ 意味着更好的性能）
```
# 配置
global
   log         127.0.0.1 local2
   chroot      /var/lib/haproxy
   pidfile     /var/run/haproxy.pid
   maxconn     4096
   #user        haproxy
   #group       haproxy
   daemon
   stats socket /var/lib/haproxy/stats mode 600 expose-fd listeners level user
   #debug
```
使用：
```
#/var/run/haproxy.pid
#sudo time haproxy -f /etc/haproxy/haproxy.cfg -p /var/run/haproxy.pid -sf $(cat /var/run/haproxy.pid) -x /var/lib/haproxy/stats
sudo time haproxy -f /etc/haproxy/haproxy.cfg -p /var/run/haproxy.pid -sf $(cat /var/run/haproxy.pid) 
```
参考 [hitless-reloads-with-haproxy-howto](https://www.haproxy.com/blog/hitless-reloads-with-haproxy-howto/)



### h2c 使用(noTLS) 
Enable HTTP/2 over HTTP (h2c)To enable HTTP/2 between clients and HAProxy without using TLS, use the proto parameter to announce support for it. This method does not allow you to support multiple versions of HTTP simultaneously.
gRPC 使用HTTP2作为通信协议，可使用HTTP/2 或者  HTTP (h2c) ,可以使用此方法实现 haproxy proxy gRPC。
```javascript
global
    # haproxy multiThread config 
    nbproc 4
    cpu-map 1 0
    cpu-map 2 1
    cpu-map 3 2
    cpu-map 4 3

defaults
    mode  http

frontend ods
    bind *:9093 proto h2
    default_backend ods_gw_servies

backend ods_gw_servies
   balance static-rr
   option tcp-check
   server server2 172.16.116.206:9093 check  proto h2
   server server3 172.16.116.95:9093 check  proto h2

# monitor 
frontend stats
    mode http
    bind *:8084
    use_backend demo if HTTP

backend demo
   mode http
   stats enable
   stats uri /stats
   stats auth admin:pwd@helloWorld
```


## QUICC配置
```javascript
# 待补充 TODO 
One front that made impressive progress over the last few months is QUIC. While a few months ago we were counting the number of red boxes on the interop tests at https://interop.seemann.io/ to figure what to work on as a top priority, now we're rather counting the number of tests that report a full-green state, and haproxy is now on par with other servers in these tests. Thus the idea emerged, in order to continue to make progress on this front, to start to deploy QUIC on haproxy.org so that interoperability issues with browsers and real-world traffic can be spotted. A few attempts were made and already revealed issues so for now it's disabled again. Be prepared to possibly observe a few occasional hiccups when visiting the site (and if so, please do complain to us). The range of possible issues would likely be frozen transfers and truncated responses, but these should not happen.
From a technical point, the way it's done is by having a separate haproxy process listening to QUIC on UDP port 1443, and forwarding HTTP requests to the existing process. The main process constantly checks the QUIC one, and when it's seen as operational, it appends an Alt-Svc header that indicates the client that an HTTP/3 implementation is available on port 1443, and that this announce is valid for a short time (we'll leave it to one minute only so that issues can resolve quickly, but for now it's only 10s so that quick tests cause no harm):

    http-response add-header alt-svc 'h3=":1443"; ma=60' if { var(txn.host) -m end haproxy.org } { nbsrv(quic) gt 0 }
As such, compatible browsers are free to try to connect there or not. Other tools (such as git clone) will not use it. For those impatient to test it, the QUIC process' status is reported at the bottom of the stats page here: http://stats.haproxy.org/. The "quic" socket in the frontend at the top reports the total traffic received from the QUIC process, so if you're seeing it increase while you reload the page it's likely that you're using QUIC to read it. In Firefox I'm having this little plugin loaded: https://addons.mozilla.org/en-US/firefox/addon/http2-indicator/. It displays a small flash on the URL bar with different colors depending on the protocol used to load the page (H1/SPDY/H2/H3). When that works it's green (H3), otherwise it's blue (H2). For Chrome there is HTTP Indicator which does the same but displays an orange symbol when using H3. Chrome only accepts H3 on port 443 (which we enabled as well for it). Note that H2 and H3 are only served when the site is browsed in HTTPS at https://haproxy.org/.

At this point I'd still say "do not reproduce these experiments at home". Amaury and Fred are still watching the process' traces very closely to spot bugs and stop it as soon as a problem is detected. But it's still too early for being operated by non-developers. The hope is that by 2.6 we'll reach the point where enthousiasts can deploy a few instances on not-too-sensitive sites with sufficient confidence and a little dose of monitoring.

```



###  配置syslog 
haproxy 使用配置syslog 记录binlog 日志：
```javascript
# 配置 syslog 
vim /etc/rsyslog.conf

# Provides UDP syslog reception
$ModLoad imudp
$UDPServerRun 514
local3.* /var/log/haproxy.log 
  
# 重启syslog 
sudo systemctl restart rsyslog

```
### 配置 prometheus 监控
```javascript
TODO 待补充

```

## nginx 
nginx 配置静态文件服务：
```javascript
sudo yum install  nginx  -y 
sudo systemctl daemon-reload
sudo systemctl enable haproxy

#
sudo systemctl restart nginx
```


# 参考
https://upcloud.com/resources/tutorials/haproxy-load-balancer-centos  
https://blog.51cto.com/yanconggod/2062213   
https://docs.haproxy.org/2.6/intro.html   
https://www.osradar.com/how-to-install-the-latest-version-of-openssl-on-centos-7/   