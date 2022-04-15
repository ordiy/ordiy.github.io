---
layout: post
title: 使用supervisord管理进程
indexing: true
categories:
  - tech
  - tools
tags:
  - blog
  - supervisord
  - python
date: 2019-01-01 00:00:00
excerpt: supervisord 是一个进程管理工具，可以方便的对进程进行启动、关闭、重启等操作。在程序意外退出，或者系统重启后拉起进程非常有用，相比systemctl更加简单且安全（无需使用sudo)。和crontab相比则更加灵活。
---

# supervisord install & config
- 初始化环境
```bash

# 假设使用公共用户app，运行程序
sudo mkdir -p /opt/app/logs
sudo mkdir -p /opt/app/super
#修改权限
sudo chown app -R /opt/app

#supervisor install
# 指定为用户安装可以使用pip install supervisord --user
sudo pip install supervisord
sudo echo_supervisord_conf > /opt/app/supervisord.conf

#修改文件权限
 sudo chown app:users /opt/app/supervisord.conf

```

- 设置supervisord 配置
```bash
# 切换用户
sudo su - app

# 配置service
cat << EOF > /opt/app/supervisord.conf
[unix_http_server]
file=/opt/app/super/supervisor.sock   ; (the path to the socket file)
 
 
[inet_http_server]         ; inet (TCP) server disabled by default
port=127.0.0.1:9001        ; (ip_address:port specifier, *:port for all iface)
 
 
[supervisord]
logfile=/opt/app/super/supervisord.log ; (main log file;default /supervisord.log)
logfile_maxbytes=50MB        ; (max main logfile bytes b4 rotation;default 50MB)
logfile_backups=10           ; (num of main logfile rotation backups;default 10)
loglevel=info                ; (log level;default info; others: debug,warn,trace)
pidfile=/opt/app/super/supervisord.pid ; (supervisord pidfile;default supervisord.pid)
nodaemon=false               ; (start in foreground if true;default false)
minfds=1024                  ; (min. avail startup file descriptors;default 1024)
minprocs=200                 ; (min. avail process descriptors;default 200)
 
 
[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface
 
 
[supervisorctl]
serverurl=unix:///opt/app/super/supervisor.sock ; use a unix:// URL  for a unix socket


[include]
files=/opt/app/super/*.conf ; config file dir
 
EOF
```

- 注册supervisord 为系统的service
```bash
#切换用户
sudo su - app

# 开机启动
cat << EOF > /usr/lib/systemd/system/supervisord.service
[Unit]
Description=Supervisor process control system for UNIX
Documentation=http://supervisord.org
After=network.target
 
[Service]
EnvironmentFile=/etc/hbase/conf/hbase-env.sh
ExecStart=/bin/bash -a -c "source /home/dp/.bash_profile && /usr/bin/supervisord -n -c /opt/app/supervisord.conf"
ExecStop=/usr/bin/supervisorctl $OPTIONS shutdown
ExecReload=/usr/bin/supervisorctl -c /opt/app/supervisord.conf $OPTIONS reload
KillMode=process
Restart=on-failure
RestartSec=50s
Restart=always
User=app
Group=users
 
[Install]
WantedBy=multi-user.target
EOF
```
*注： 这里设置了`User=app`可能造成环境变量未能加载，需要在启动程序时手动加载一次，[systemctl参数](http://0pointer.de/public/systemd-man/systemd.exec.html#Environment=)


- 启动supervisord.service
```bash
#开机启动
sudo systemctl enable supervisord.service

# start
sudo systemctl start supervisord.service
sudo systemctl status supervisord.service

# 查看启动异常信息
sudo journalctl -u supervisord.service -b

# reload service file 
sudo systemctl daemon-reload

```

# 配置服务和启动程序
- 设置program conf配置文件
```bash

vim /opt/app/super/app.conf

[program:app-service]
command=java -XX:+UseG1GC -Xms4g -Xmx4g  -Dlogging.config=./log4j2.xml -jar test-app.jar --spring.profiles.active=pro
directory=/opt/app/app-service
priority=1
numprocs=1
autostart=true
autorestart=true
startretries=10
stopsignal=INT
stopwaitsecs=60
redirect_stderr=true
stdout_logfile=/opt/app/logs/app-service.out.log

```

- 将配置的程序reload & start
```bash
supervisorctl  -c ./supervisord.conf
# 加载未load的program
supervisor> reload 
# 查看program状态
supervisor> status

```

- 其它命令
```bash
# 重启
 supervisorctl  -c ./supervisord.conf restart app-service 

# 重新读取program conf(不会重启进程）
supervisorctl  -c ./supervisord.conf restart app-service

# 更新conf，并进行重启(谨慎操作）
supervisorctl  -c ./supervisord.conf update

```

# `$PATH`环境变量异常
- 解决方法-`Environment`
错误信息：
```bash
supervisorctl -c ./supervisord.conf restart app-service

supervisorctl> can't find command 'java'
```
初步确定是systemctl 启动进程后`PATH`环境变量未能读取，解决方法：
使用`Environment`手动配置`PATH`:
```javascript
sudo vim /usr/lib/systemd/system/supervisord.service
```
添加
```javascript
Environment="PATH=/usr/lib64/qt-3.3/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/usr/java/default/bin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"
```
这里需要注意Environment 不支持`$PATH`的表达式方法，所以把`echo $PATH`中全局配置的信息拷贝出来，新的service文件内容如下：
```javascript
[Unit]
Description=Supervisor process control system for UNIX
Documentation=http://supervisord.org
After=network.target

[Service]
Environment="PATH=/usr/lib64/qt-3.3/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/usr/java/default/bin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"
ExecStart=/usr/bin/supervisord -n -c /opt/app/supervisord.conf
ExecStop=/usr/bin/supervisorctl  shutdown
ExecReload=/usr/bin/supervisorctl -c /opt/app/supervisord.conf  reload
KillMode=process
Restart=on-failure
RestartSec=50s
Restart=always
User=app
Group=users

[Install]
WantedBy=multi-user.target

```
重新reload:
```bash
sudo systemctl daemon-reload
```
重启:
```bash
sudo systemctl restart supervisord.service
```
查看启动信息：
```bash
sudo journalctl -u supervisord.service -b
```
启动正常。

- 另一种解决方法-ExecStart
在service文件中配置：
```bash
ExecStart=/bin/bash -c "PATH=/home/someUser/bin:$PATH exec /usr/bin/php /some/path/to/a/script.php"
```


# 参考
- [supervisord](http://supervisord.org/index.html)


