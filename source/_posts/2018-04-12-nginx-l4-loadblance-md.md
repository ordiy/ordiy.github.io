---
layout: post
title: Nginx Stream L4 负载均衡
date: 2018-04-12 00:00:00
tags:
  - blog
  - Nginx
  - Nginx Stream
categories:
  - tech
  - nginx stream
excerpt:  总结Nginx Stream进行反向代理实现负载均衡，以及配置集群的高可用、A/B测试、SSL/TLS加密和日志排查等场景，总结了使用过程中遇到的一些问题，及改进方面。
---


## 需求
使用Nginx Stream实现反向代理（通信协议：TCP），并结合DNS、keepalived 和VIP ，实现Nginx Stream的多活和高可用。
![](https://raw.githubusercontent.com/ordiychen/study_notes/master/res/image/node_image/blog_20200814175544.png)

## 实现与配置
### Nginx Stream 安装
Nginx Stream 编译安装，参照本文 [附录一 Nignx Stream 安装](./)
注意: 在centos7 OS上通过yum安装的nginx-all-modules 已经包含Nginx Stream module,可以直接使用[cenots/RHEL yum install nginx](http://nginx.org/en/linux_packages.html#RHEL-CentOS)

### Nginx Stream L4 负载基本配置
#### Nginx Stream 配置
Nginx Stream 使用过程中可能还会遇到需要进行负载均衡方式调整、A/B测试、流量镜像、使用TLS加密、记录日志和配置多活等。

#### 负载均衡方法
在upstream 的几种负载均衡方法：
```bash
 upstream backend_ods {
      hash $remote_addr$remote_port consistent;
      server 10.224.17.246:10091;
      server 10.224.17.246:10092;
      server 10.224.17.246:10093;
   }
```
| load blance | desc |
|:---|:---|
| `hash $remote_addr consistent`  | 按client ip(ipv4/ipv6) addrees进行hash和取模（计算可以表示为： mod(hash($remote_addr),upstream_size)), 同一个client的所有会被分发给一个后端节点。问题：单个cleint的并发很高时，会造后端服务节点的负载不均衡。好处：方便跟踪日志和抓包 |
| `hash $remote_addr$remote_port  consistent`| 按client ip(ipv4/ipv6) addrees + client port进行hash和取模，可以更好的实现后端节点的负载均衡 |
| `hash $connection  consistent` |  按 client 链接到nginx 的 `connection serial number` 进行hash和取模，这个方式类似于`$remote_addr$remote_port`  |

*这里`consistent` 常量的作用是避免增加或者删除后端server时候，大量服务断开的问题。参照：[ consistent parameter](http://nginx.org/en/docs/stream/ngx_stream_upstream_module.html#hash)

Nginx Stream其它负载均衡方法：`least_conn`,`least_time`,`random`。


#### Stream 流量镜像
将生产环境的一部分流量转发到指定节点进行压力测试或者灰度测试， 因为nginx 的mirro module是不支持stream模式下的流量复制，这里需要借助使用`iptables`实现。
实现复制10.224.18.34：9443的进站流量到`10.224.17.246:10095`
```bash
iptables -t mangle -A PREROUTING -d 10.224.18.34 -dport 9443 -j TEE --gateway 10.224.17.246:10095

```
这里需要配置[`iptables-servcie`](https://www.linode.com/docs/security/firewalls/control-network-traffic-with-iptables/)和
[Mirroring outbound https traffic w/ iptables](https://forums.centos.org/viewtopic.php?f=50&t=67768)
注意：如果是TLS加密数据，镜像后的流量需要解密。

#### Stream A/B测试
将流量进行切分，执行A/B测试的场景。
![](https://raw.githubusercontent.com/ordiychen/study_notes/master/res/image/node_image/blog_20200814172223.png)

配置文件：
```bash
stream {
   upstream backend_ods {
      hash $connection consistent;
      server 10.224.17.246:10091 ;
      server 10.224.17.245:10091  ;
   }
   upstream test_ods{
       server 10.224.17.242:10092;
    }
    
    #20% 流量用于验证 test_ods group upstream 
    split_clients "${remote_addr}AAA" $upstream {
                  80%                backend_ods;
                  *                  test_ods;
    }

   server {
        listen 9443 so_keepalive=on so_keepalive=30m::10;
        #后端节点链接超时时间，如果所有后端节点存在异常，应快速断开，避免数据堆积
        proxy_connect_timeout 10s;
        proxy_timeout 30m;
        proxy_pass $upstream;
     }
}
```
- `split_clients`分流算法使用`MurmurHash2`
- 详情参考[ngx_stream_split_clients_module](http://nginx.org/en/docs/stream/ngx_stream_split_clients_module.html)


#### 配置Stream TLS/SSL 
如果程序涉及的数据比较机密或者或者网络环境不可信时，需要使用`stream_ssl_preread_module`配置TLS 证书进行加密,配置如下：
```bash
server {
    listen     9443;
    proxy_pass backend_ods;
    proxy_ssl  on;
    ssl_certificate        /etc/ssl/certs/server.crt;
    ssl_certificate_key    /etc/ssl/certs/server.key;
    proxy_ssl_trusted_certificate /etc/ssl/certs/trusted_ca_cert.crt;
    ssl_protocols  TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers    HIGH:!aNULL:!MD5;
    # default 60s
    ssl_handshake_timeout 10s;
    ssl_session_cache shared:SSL:1m;
    ssl_session_timeout 4h;
}
```
* 可能涉及配置证书等操作，请参照[HTTP2 TLS加密通信理解与应用](https://ordiychen.github.io/2020-01-01-tls-truststores-md/)
* 跟多配置信息[ngx_stream_ssl_module](http://nginx.org/en/docs/stream/ngx_stream_ssl_module.html)


#### 配置Stream log 
在Nginx Stream 调试时，需要输出一些详细日志用于问题定位和检查，需要使用`ngx_stream_log_module` 打印更多日志信息。
记录请求数据日志：
```bash
stream {
   log_format basic '$remote_addr$remote_port [$time_local] '
                 '$protocol $status $bytes_sent $bytes_received '
                 '$session_time  "$upstream_addr" ' '"$upstream_bytes_sent" "$upstream_bytes_received" "$upstream_connect_time"';
   access_log /var/log/nginx/nginx-access.log basic buffer=32k;
   error_log  /var/log/nginx/error.log info;
   open_log_file_cache max=1000 inactive=20s valid=1m min_uses=2;

   server {
        ......
   }
}
```
增加对TLS 的日志记录，便于查看client 使用的加密方法等信息：
```bash
upstream {
    log_format sslparams '$ssl_protocol $ssl_cipher '
                  '$remote_addr ' ;
   access_log  /var/log/nginx/sslparams.log sslparams;
}
```
* 注意：使用yum intall nginx 安装的无法配置 stream log( 缺少`ngx_stream_log_module`)
* 跟多配置参数：[ngx_stream_log_module](http://nginx.org/en/docs/stream/ngx_stream_log_module.html)


### 配置多活
使用keepalive 配置多活，这里keepalived + VIP + DNS 实现多活，整个逻辑和实现如下图
![images](https://raw.githubusercontent.com/ordiychen/study_notes/master/res/image/node_image/blog_20200817100506.png)
- 安装于配置[keepalived multiple vips](https://access.redhat.com/discussions/3007011)


### Nginx Stream L4 代理遇到的问题

#### Health Check 
Nginx Stream 官方的health check([ngx_stream_upstream_hc_module](http://nginx.org/en/docs/stream/ngx_stream_upstream_hc_module.html#health_check))需要使用商业订阅, $2500/Year起。社区有一些替代方案：
[ngx_stream_upstream_health_check](https://github.com/lusis/ngx_stream_upstream_check_module)  
- 注意 ngx_stream_upstream_health_check 方案需要后端程序提供http port （对于微服务很适用)
- 吐槽 PS:  HaProxy Health Check 在社区版本是免费提供

#### 后端服务平滑升级会出现 TCP链接断开的问题
为避免增加或者删除后端服务节点时，出现大量TCP 链接重连，建议将loadBalance策略配置为 `hash $remote_addr$remote_port  consistent` 或者类似的，可以减少链接断开的情况，但后端服务重启时部分反向代理到该节点的client 连接依然会断开。这个问题暂时没解决。

#### 参数优化问题
- TCP keepalived 参数设置,优化点如下；
```bash
        # 允许一定时间的会话保持 避免频繁断开连接
        listen 9443 so_keepalive=on so_keepalive=30m::10;
        #后端节点链接超时时间，如果所有后端节点存在异常，应快速断开，避免数据堆积
        proxy_connect_timeout 10s;
        proxy_timeout 30m;
```
- 设置读写缓冲区
```
listen address:9443 ssl sndbuf=128k rcvbuf=128k

server {
   preread_buffer_size 1024k
  }
```
设置`sndbuf` `rcvbuf` 可以设置每个 Socket的读写缓冲区大小。

#### 流量镜像的操作非常不方便
如果需要使用该功能，还是推荐使用HaProxy

#### 性能方面
Nginx Stram 性能测试：
```
机器: 8核心16G内存 Centos7 
流量:  速率5W/S （流量大小：grpc request 1kb）
备注：这里没有测试到Nginx Stream 在以上配置和场景下可以承载流量的最大值，结合社区的资料估计在15W+ 
```

![](https://raw.githubusercontent.com/ordiychen/study_notes/master/res/image/node_image/blog_20200817102547.png)
- 备注：在TCP 反向代理上，HaProxy 在性能方面更有优势

### 参考  
参考文献：
 [http://nginx.org/en/docs/stream/ngx_stream_upstream_module.html#hash](http://nginx.org/en/docs/stream/ngx_stream_upstream_module.html#hash)

## 附录 Nginx 安装
### 检查openssl 版本
```bashshell
openssl version
```
`OpenSSL 1.0.1e-fips 11 Feb 2013` 为了便于TLS1.3等使用，需要将openssl 升级到最新版本 `1.1.1`

### 升级openssl 
```bashshell
cd ~
wget http://nginx.org/download/nginx-1.17.0.tar.gz
tar -zxvf nginx-1.17.0.tar.gz

cd nginx-1.17.0

#install make 
./config
make
sudo make install

```
运行openssl 出现错误:
```bashshell
/usr/local/bin/openssl version
/usr/local/bin/openssl: error while loading shared libraries: libcrypto.so.1.1: cannot open shared object file: No such file or directory

```
使用以下步骤修复该问题：

- Create links to libssl:
```bashshell
  sudo ln -s /usr/local/lib64/libssl.so.1.1 /usr/lib64/
  sudo ln -s /usr/local/lib64/libcrypto.so.1.1 /usr/lib64/
```

- Finally create link to new openssl
```bash
  sudo ln -s /usr/local/bin/openssl /usr/bin/openssl_latest
```
- 测试版本
```bash
openssl_latest version
OpenSSL 1.1.0f 25 May 2017
Additional tips
```
设置最新的openssl:

```bash
cd /usr/bin/
mv openssl openssl_old
mv openssl_latest openssl
```

检查：
```bash
openssl version
```

### 检查和升级zlib 
nginx 压缩gzip 使用 zlip库进行压缩。
```bash
yun info zlip 
```
版本是 2.0.7 将其升级到zlib-1.2.11

```bash
wget http://zlib.net/zlib-1.2.11.tar.gz

tar -zxvf zlib-1.2.11.tar.gz

# install 
cd zlib-1.2.11 
./configure --prefix=/usr/local/zlib
sudo make && sudo make check && sudo make install

# 在/etc/ld.so.conf 新增lib 
sudo echo "/usr/local/zlib/lib" >> /etc/ld.so.conf

# reoload 
sudo ldconfig -v

```
zlib 升级完成

### PCRE
PCRE 用于Nginx正则进行重写要用到, 需要注意nginx 是不支持PCRE2的。这里将其升级到 PCRE 8.44 
```bash
#nginx 支持的最新 pcre版本是 8.43 
cd ./nginx-module
wget https://ftp.pcre.org/pub/pcre/pcre-8.43.tar.gz

tar zxvf https://ftp.pcre.org/pub/pcre/pcre-8.43.tar.gz
cd pcre-8.43

./configure
make 
sudo make install

#check 
pcre-config --verison
```

### 编译安装 nginx 
执行编译
```bash
cd ~/nginx-18.0

# configure
./configure \
--sbin-path=/usr/local/nginx/nginx \
--conf-path=/usr/local/nginx/nginx.conf \
--pid-path=/usr/local/nginx/nginx.pid \
--conf-path=/etc/nginx/nginx.conf \
--error-log-path=/var/log/nginx/error.log \
--pid-path=/var/run/nginx.pid \
--http-log-path=/var/log/nginx/access.log \
--user=nginx \
--group=nginx \
--with-http_stub_status_module \
--with-http_ssl_module \
--with-http_v2_module \
--with-stream \
--with-stream_ssl_module \
--with-stream_realip_module \
--with-stream_geoip_module \
--with-stream_ssl_preread_module  \
--with-pcre=./nginx-modules/pcre-8.43 \
--with-pcre-jit \
--with-openssl=./nginx-modules/openssl-1.1.1g \
--with-zlib=./nginx-modules/zlib-1.2.11 \
--add-module=./ngx_stream_upstream_check_module \
--with-debug

make 
sudo make install

#check 
/usr/local/nginx/nginx -V 
```
输出：
```bash
nginx version: nginx/1.18.0
built by gcc 4.8.5 20150623 (Red Hat 4.8.5-39) (GCC)
built with OpenSSL 1.1.1g  21 Apr 2020
TLS SNI support enabled
configure arguments: --sbin-path=/usr/local/nginx/nginx --conf-path=/usr/local/nginx/nginx.conf --pid-path=/usr/local/nginx/nginx.pid --user=nginx --group=nginx --with-http_ssl_module --with-http_v2_module --with-stream --with-stream=dynamic --with-stream_ssl_module --with-stream_realip_module --with-stream_geoip_module --with-stream_geoip_module=dynamic --with-stream_ssl_preread_module --with-pcre=./nginx-modules/pcre-8.43 --with-pcre-jit --with-openssl=./nginx-modules/openssl-1.1.1g --with-zlib=./nginx-modules/zlib-1.2.11 --with-debug
```

### 设置防火墙
```bash

sudo firewall-cmd --add-port=8443/tcp --permanent
sudo firewall-cmd --add-port=8443/udp --permanent

# reload 
sudo firewall-cmd --reload

#检查
sudo firewall-cmd --zone=public --list-all
```

#### 使用`nc` 测试stream 
在nginx node 可以使用`nc -l 10091` 启动端口监听，方便进行测试。
client可以使用telnet 也可以使用`nc`。

参考：
- [Building nginx from Sources](http://nginx.org/en/docs/configure.html)