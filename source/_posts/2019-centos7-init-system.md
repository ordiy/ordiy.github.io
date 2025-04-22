---
layout: post
title: Centos7 init env and config security
categories:
  - tech
tags:
  - blog
excerpt: centos7 初始化环境，并安装bbr和ssh. (适用于VPS场景)
date: 2019-01-01 00:00:00
---


# 需求

```javascript
对VPS进行加固，并设置bbr和ssh
```

# update kernal and config env 
```javascript

# 升级内核
sudo yum update 

# epel
sudo yum -y install epel-release -y 

# 安装 gcc
sudo yum install gcc pcre-static pcre-devel -y

# repo
#sudo yum repolist 

```

# 系统设置

## 时间
  - 设置 timedatectl
```javascript
  #查看时区设置 默认是 America/NewYork
  timedatectl  


  # 查看所有 支持的时区名
  timedatectl list-timezones


  # 设置 将硬件时钟调整为与本地时钟一致, 0 为设置为 UTC 时间
  timedatectl set-local-rtc 1


  # 设置系统时区为HongKong
  timedatectl set-timezone Asia/Hong_Kong
  ```

  - ntp 时间校准
  ```javascript
  #install ntp 
   sudo yum install ntp -y


  #设置ntp server,NIST Internet Time Servers , NTP Pool Project
  #
   sudo ntpdate time.nist.gov 


  #或者 pool.ntp.org 延迟 0.05ms 左右，推荐使用
  # 基于GPS授时间
  #asia
   sudo ntpdate asia.pool.ntp.org
  #north-america 
   sudo 1.north-america.pool.ntp.org

  ```

## 用户
```
#//添加一个名为junguoguo的用户 
 adduser noxft42

# //修改密码
 passwd noxft42
Changing password for user junguoguo.
New UNIX password: //在这里输入新密码
Retype new UNIX password: //再次输入新密码
passwd: all authentication tokens updated successfully.



# 增加用户权限 sudo 
# Use the usermod command to add the user to the wheel group.
#
usermod -aG wheel username

# #If you want to delete the user without deleting any of their files, type this command as root:
> userdel username


# If you want to delete the user’s home directory along with the user account itself, type this command as root:
> userdel -r username

```

- 添加root 用户
```
$ adduser sss （创建用户sss）
$passwd sss （创建sss的密码）
$ chmod -v u+w /etc/sudoers   （增加 sudoers 文件的写的权限，默认为只读）
$ vi /etc/sudoers （修改 sudoers）


## Allow root to run any commands anywhere
root    ALL=(ALL)       ALL
sss    ALL=(ALL)       ALL （添加这一行）

```

保存，退出

```
chmod -v u-w /etc/sudoers （删除 sudoers 的写的权限）
##改回只读权限
#chmod 440 /etc/sudoers
```

## ssh 加固
```
#修改 登录目的地机器 ssh-config


vim /etc/ssh/sshd_config

# SSH v2 加固
Protocol 2


PermitRootLogin yes
PubkeyAuthentication yes
PasswordAuthentication no




# restart 
#注意再确定已经配置正确前，不要断开当前ssh (避免机器无法登录，变为木头)
systemctl restart sshd
```

## ssh 加固
```
#修改 登录目的地机器 ssh-config


vim /etc/ssh/sshd_config


PermitRootLogin yes
PubkeyAuthentication yes
PasswordAuthentication no

# restart 
#注意再确定已经配置正确前，不要断开当前ssh (避免机器无法登录，变为木头)
systemctl restart sshd
```



# 部分组件install

## bbr 
BBR解决了下面两个问题：在有一定丢包率的网络链路上充分利用带宽;降低网络链路上的 buffer 占用率，从而降低延迟。
```
#整体完成后会提示重启，输入y并重启VPS。
wget --no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh
chmod u+x bbr.sh
./bbr.sh


#检查内核版本 4.10+
uname -r


# 检查模块
lsmod | grep bbr 
```