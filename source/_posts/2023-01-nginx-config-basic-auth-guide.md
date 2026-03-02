---
title: nginx config basic auth 
tags:
  - nginx
  - security
categories:
  - tech
  - network
excerpt: nginx config basic auth, 增加安全拦截,保护内部资源
date: 2023-01-01 10:08:00
layout: post
---




# install apache2-utils
```shell
sudo apt install apache2-utils -y 

```

# generate password 

```shell
sudo htpasswd -c /etc/nginx/.htpasswd authjia-stg-user02
pwd-stg02-407BEB907FE9
sudo htpasswd -c /etc/nginx/.htpasswd authjia-stg-user01
pwd-stg-407BEB907FE9
```


# config nginx 

```shell
vim /etc/nginx/common-basic-auth.conf 
```

```shell
  auth_basic $auth_type;
  auth_basic_user_file /etc/nginx/.htpasswd;
	add_header Set-Cookie "skip_http_auth=7338b1fe3c5exx; authenticated=true; session_id=testData099241e32f954; domain=.my-test-host.org; path=/; samesite=lax; Max-Age=259200";

skip_http_auth 这个自行定义
domain 
session_id
https 场景下，可以增加：secure

```

```shell
vim nginx.conf
```

```shell
#配置auth map 
http {
       # 其它配置略....

	   # config basic auth config
	   map $cookie_skip_http_auth $auth_type {
               default "Restricted Area";
              "7338b1fe3c5exx" "off";
      } 

}
```


``` vim conf.d/web-app.conf ```
```shell
配置server
    # flink web
    server {
             
             listen 0.0.0.0:8581 ;
             server_name stg-data-flink-web.my-test-host.org;
             #server_name _;

             set $auth_type "Restricted";

             if ($http_cookie ~* "skip_http_auth=7338b1fe3c5exx") {
                  set $auth_skip "off";
            }

              auth_basic $auth_skip;
              auth_basic_user_file /etc/nginx/.htpasswd;

              #  domain， IP  都可以支持
              add_header Set-Cookie "skip_http_auth=7338b1fe3c5exx; authenticated=true; session_id=testData099241e32f954; path=/; domain=.my-test-host.org ; samesite=lax;  Max-Age=259200" always;



              location / {
                    include /etc/nginx/common-basic-auth.conf;
                    proxy_pass http://127.0.0.1:8081;
                    proxy_set_header Host $host;
                    proxy_set_header X-Real-IP $remote_addr;
                    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                    proxy_set_header X-Forwarded-Proto $scheme;
               }
    }
```

test nginx 
```shell
sudo nginx -t 
```

restart nginx 
```shell
sudo systemctl restart nginx 
sudo systemctl  status nginx 
```

# 效果
拦截窗：
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/2024/202503271744641.png)

浏览器session 
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/2024/202503271749713.png)


# 其它
 - 推荐配合HTTPS一起使用，以达到传输加密的效果。

