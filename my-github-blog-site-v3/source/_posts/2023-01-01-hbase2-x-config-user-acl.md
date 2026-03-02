---
layout: post
title: HBase 2.x config user ACL - Grant or Ranger
categories:
  - tech
tags:
  - blog
excerpt: HBase 2.x config user ACL , Grant or Ranger
date: 2023-01-01 13:13:43
---


# config hbase ACL with grant 
```xml
<property>
  <name>hbase.security.authentication</name>
  <value>simple</value>
</property>
<property>
  <name>hbase.security.authorization</name>
  <value>true</value>
</property>
<property>
  <name>hbase.coprocessor.master.classes</name>
  <value>org.apache.hadoop.hbase.security.access.AccessController</value>
</property>
<property>
  <name>hbase.coprocessor.region.classes</name>
  <value>org.apache.hadoop.hbase.security.access.AccessController</value>
</property>
<property>
  <name>hbase.coprocessor.regionserver.classes</name>
  <value>org.apache.hadoop.hbase.security.access.AccessController</value>
</property>
<property>
  <name>hbase.rpc.engine</name>
  <value>org.apache.hadoop.hbase.ipc.SecureRpcEngine</value>
</property>
<property>
  <name>hbase.superuser</name>
  <value>hbase</value>
</property>

```
更新各节点配置文件，滚动重启HBase Master、RegionServer

给developer用户、push用户授权
```shell
hbase shell > 
          grant 'dev', 'RW', 'userprof_imi'
          grant 'dev', 'RW', 'md5'
          grant 'push_user', 'RW', 'userprof_imi'
          grant 'push_user', 'RW', 'md5'
```


# HBase 	慢查询日志
在配置文件中添加，设置2s慢查询
```xml
<property>
	<name>hbase.ipc.warn.response.time</name>
	<value>2000</value>
</property>

```

# HBase ACL config by Ranger 

hbase-site.xml配置文件：
```xml
    <property>
      <name>hbase.security.authorization</name>
      <value>true</value>
    </property>
    <property>
        <name>hbase.coprocessor.master.classes</name>
        <value>org.apache.ranger.authorization.hbase.RangerAuthorizationCoprocessor,org.apache.hadoop.hbase.rsgroup.RSGroupAdminEndpoint</value>
    </property>

    <property>
        <name>hbase.coprocessor.region.classes</name>
        <value>org.apache.ranger.authorization.hbase.RangerAuthorizationCoprocessor</value>
    </property>


```