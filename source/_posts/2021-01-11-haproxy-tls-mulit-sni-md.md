---
layout: post
title: HAProxy多协议反向代理以及TLS加密传输
indexing: true
categories:
  - tech
tags:
  - blog
date: 2021-01-11 12:04:53
excerpt: 使用HAProxy2.x解决多协议反向代理以及TLS加密传输，以及多个通信协议共用端口问题。
---


# 需求场景于实现
## 需求

在防火墙严格限定机器外网端口的情况下，使用HAProxy实现对支持对HTTPS/SSH/FTP的代理需求，实际场景：
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20210825120341.png)

- 环境信息
```
Centos8 
HAProxy2.2 
OpenSSL1.1.g
```

## 实现
Show code:
```javascript
frontend ft_tcp
    mode tcp
    bind *:443 ssl crt /etc/haproxy/certs/

    tcp-request content accept if { req_ssl_hello_type 1 }
    # The SNI (Server Name Indication) is not encrypted, so inspect the SSL hello for SNI
    # Spread the requests between backends
    use_backend     bk_ssh if {req_ssl_sni -i ssh.example.com}
    use_backend     bk_ftp if {req_ssl_sni -i ftp.example.com}
    use_backend     bk_www  if {req_ssl_sni -i www.example.com}
    default_backend bk_traditional

backend bk_ftp
    mode tcp
    server ftp ftp-nodes.example.com:21 check    

backend bk_www
  mode http
  # This backend server will need to terminate TLS for hola.example.com
  option http-keep-alive
  server www www-nodes.example.com:80 check inter 12000
  errorfile 503 /etc/haproxy/error/maintenance.html
  errorfile 500 /etc/haproxy/error/500.html

backend bk_ssh
    mode tcp
    option redispatch
    option srvtcpka # client keep alived
    option tcpka   #server keep alved
    server ssh ssh-nodes.example.com:20 check
```
* 这里主要依赖于 SSL/TLS SNI实现
* [关于 SNI WIKI](https://en.wikipedia.org/wiki/Server_Name_Indication)


# HAProxy TCP/HTTPS TLS 代理场景总结
## 多域名TLS转发
```javascript
frontend ft_tcp
    mode tcp
    bind *:443

    tcp-request content accept if { req_ssl_hello_type 1 }
    # The SNI (Server Name Indication) is not encrypted, so inspect the SSL hello for SNI
    # Spread the requests between backends
    use_backend     bk_agile if {req_ssl_sni -i agile.example.com}
    use_backend     bk_hola  if {req_ssl_sni -i hola.example.com}
    default_backend bk_traditional

backend bk_agile
    mode tcp
    # This backend server will need to terminate TLS for agile.example.com
    server agile.internal.example.com:443 check    

backend bk_hola
    mode tcp
    # This backend server will need to terminate TLS for hola.example.com
    server hola.internal.example.com:443 check

backend bk_traditional
    mode tcp
    # This backend server will need to terminate TLS
    server traditional.internal.example.com:443 check
```
* 可用于对POP3 IMAP 等TLS代理
参考：
https://www.liip.ch/en/blog/haproxy-selective-tls-termination

## TLS TCP/HTTPS 共用端口(用于按协议分流）
```javascript
frontend tls-in
    maxconn 100
    bind *:443 tfo ssl crt /etc/letsencrypt/live/www.xxxx.app/xxx_crt.pem alpn h2,http/1.1
    #acl http       ssl_fc,not
    #acl https      ssl_fc
    tcp-request inspect-delay 10s
    tcp-request content accept if HTTP
    acl is_stats_req path /stats if HTTP
    use_backend demo if is_stats_req
    use_backend web if HTTP
    #use_backend web if https
    use_backend vmx if !HTTP

backend web
  option http-keep-alive
  mode http
  server srv1 127.0.0.1:8081 check inter 12000
  errorfile 503 /etc/haproxy/error/maintenance.html

backend vmx
    #tcp server 
    option log-health-checks
    option redispatch
    option srvtcpka # client keep alived
    option tcpka   #server keep alved
    server px1 127.0.0.1:1080 check inter 12000
```
* 可用于端口伪装等目的

## TLS转发+HTTPS代理
```javascript
frontend ft_tcp
    mode tcp
    bind *:443

    tcp-request content accept if { req_ssl_hello_type 1 }
    # The SNI (Server Name Indication) is not encrypted, so inspect the TLS hello for SNI
    # Spread the requests between backends
    use_backend     bk_agile if {req_ssl_sni -i agile.example.com}
    default_backend bk_tcp_to_https

backend bk_tcp_to_https
    mode tcp
    server haproxy-https 127.0.0.1:8443 check

frontend ft_https
    mode http
    # HAProxy will take the fitting certificate from the available ones
    bind *:8443 ssl crt /etc/haproxy/certs/

    # Spread the requests between backends
    use_backend     bk_hola  if {hdr(host) -i hola.example.com}
    default_backend bk_traditional

backend bk_agile
    mode tcp
    # This backend server will need to terminate TLS for agile.example.com
    server agile.internal.example.com:443 check    

backend bk_hola
    server hola.internal.example.com:80 check

backend bk_traditional
    server traditional.internal.example.com:80 check
```
* 在防火墙只开发443端口的情况下使用
参考：
https://www.liip.ch/en/blog/haproxy-selective-tls-termination

# 总结
这里涉及到HAProxy Configuration的配置语法，以及TLS协议等，涉及的知识点较多这里主要提供一些实现思路。
当`crt /etc/haproxy/certs/` 下面有多个证书时候，建议使用HAProxy 的 [`crt-list`](http://cbonte.github.io/haproxy-dconv/2.1/configuration.html#5.1-crt-list),解决多证书的配置问题。


# 参考文献
- [HAProxy Document](http://cbonte.github.io/haproxy-dconv/2.2/intro.html)
- [haproxy-selective-tls-termination](https://www.liip.ch/en/blog/haproxy-selective-tls-termination)

