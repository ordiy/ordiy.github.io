---
layout: post
title: MySQL Create Database and Grant Permissions
categories:
  - tech
tags:
  - blog
  - MySQL
date: 2018-01-01 01:00:00
excerpt: MySQL Create Database and Grant Permissions.
---

# mysql create database
```javascript
mysql -h 127.0.0.1 -P 3306 -u root -p


>  CREATE DATABASE ods_gl_dev CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci ;

> SHOW DATABASES ;

```

# grant permission

```javascript
# create user 
mysql> CREATE USER 'xxx_test'@'%' IDENTIFIED BY 'xxxxDev20_7%';

# check user 
mysql> SELECT * FROM mysql.user  where user = 'ods_test' ;


# grant permission 
# GRANT CREATE, ALTER, DROP, INSERT, UPDATE, DELETE, SELECT, REFERENCES, RELOAD on ods_gl_dev.* TO 'ods_test'@'172.%' WITH GRANT OPTION;
# GRANT ALL PRIVILEGES ON *.* TO 'sammy'@'localhost' WITH GRANT OPTION;
# ods_gl_dev all privileges 

mysql> GRANT ALL PRIVILEGES ON ods_gl_dev.* TO 'ods_test'@'%' WITH GRANT OPTION;

# check privileges 
mysql> SHOW GRANTS FOR  'ods_test'@'%';


```
## delete/update user
```javascript

mysql> DROP USER 'ods_test'@'172.%';

#To change a password for MySQL 5.76 or higher, use this command:
mysql> ALTER USER 'local_user'@'localhost' IDENTIFIED BY 'new_password';

# For older versions of MySQL, use this command instead:
mysql>SET PASSWORD FOR 'local_user'@'localhost' = PASSWORD('new_password');

```

## update privileges 
```SQL
UPDATE mysql.user SET Host='%' WHERE Host='localhost' AND User='username';
UPDATE mysql.db SET Host='%' WHERE Host='localhost' AND User='username';

FLUSH PRIVILEGES;
```

The best option on MySQL 8 / MariaDB 10 would be:
```SQL
RENAME USER 'username'@'oldhost' TO 'username'@'newhost';
```
参考：
https://serverfault.com/questions/483339/changing-host-permissions-for-mysql-users


# debug 
```
CREATE TABLE `load_task_statistics` (
  `task_id` int(11) NOT NULL,
  `metrics_type` varchar(63) NOT NULL,
  `metrics_value` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`task_id`,`metrics_type`),
  KEY `fk_task_id_idx` (`task_id`),
  CONSTRAINT `fk_statistics_task_id` FOREIGN KEY (`task_id`) REFERENCES `load_tasks` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ;

# error 
(1215, 'Cannot add foreign key constraint')

```
解决：
```
 set foreign_key_checks=0
```

