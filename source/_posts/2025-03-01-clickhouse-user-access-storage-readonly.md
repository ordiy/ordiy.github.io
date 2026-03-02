---
title:  Clickhouse grant add user error 
excerpt: Clickhouse grant add user, 遇到 `ACCESS_STORAGE_READONLY` error 
layout: post
date: 2025-03-31 14:42:19
tags:
  - tech
  - clickhouse
categories: 
  - blog
---



# 问题
 Clickhouse使用Grant给用户添加权限
```SQ:
 GRANT SELECT, INSERT ON  
  system.xxx
   TO read_user01 
    on cluster  xxx  ; 
```
遇到异常 

```js
Code: 495. DB::Exception: Received from localhost:9000. DB::Exception: There was an error on [xx-host.com:9000]: Code: 495. DB::Exception: Cannot update user `read_user01` in users_xml because this storage is readonly. (ACCESS_STORAGE_READONLY) (version 24.10.2.80 (official build)). (ACCESS_STORAGE_READONLY)


```
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/2024/202503311130156.png)


# 原因
`read_user01` 是在 `/etc/clickhouse-server/user.d/user.xml`中配置的，无法使用grant给该用户添加权限。

- 解决
在Clickhouse集群上，手动修改 `/etc/clickhouse-server/user.d/user.xml` 为用户添加权限

```
<clickhouse>
<users>

    <read_user01>
      <profile>readonly-user-max-quato</profile>
      <password_sha256_hex>xxxx</password_sha256_hex>
      <quota>default</quota>
      <allow_databases>
        <database>xxxx</database>
      </allow_databases>
    </read_user01>

</users>
</clickhouse>
```

-  原因
**user兼容性：**
**两种方法可以同时使用，但不能同时管理同一个访问实体。**
**这允许用户从基于文件的方法平滑过渡到SQL配置驱动的方法。**

- 参考文章
https://clickhouse.com/docs/operations/access-rights

