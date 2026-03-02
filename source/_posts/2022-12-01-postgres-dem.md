---
layout: post
title: PostgreSQL Demo
categories:
  - tech
tags:
  - blog
date: 2022-12-01 00:00:00
excerpt: postgres start and SQL demo 
---


# start docker 
```
docker run --name some-postgres -p 5432:5432 -e POSTGRES_PASSWORD=testpwd256 -d postgres 

# 正式部署建议使用compose or k8s 

```

# init database 
```bash
# 进入docker bash 
docker exec -it some-postgres bash

# docker 内执行
CREATE DATABASE tsl_employee; 

\c tsl_employee 
```
![alt text](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20240418195021.png)



# create table and test SQL 
```SQL 
CREATE TABLE dealer (id INT PRIMARY KEY NOT null , city TEXT , car_model TEXT , quantity INT);

INSERT INTO dealer VALUES
    (101, 'Fremont', 'Honda Accord', 15),
    (102, 'Fremont', 'Honda CRV', 7),
    (200, 'Dublin', 'Honda Civic', 20),
    (201, 'Dublin', 'Honda Accord', 10),
    (202, 'Dublin', 'Honda CRV', 3),
    (303, 'San Jose', 'Honda Civic', 5),
    (301, 'San Jose', 'Honda Accord', 8);
    
  
   /**
    *  查询dealer 表 在 Fremont 城市的交易商总数量
    */
   SELECT city, sum(quantity) AS sum, city  FROM dealer GROUP BY city HAVING city = 'Fremont'; 
  ```

  # 总结
  postgres 在DDL 语法上与MySQL 略有不同, 但在SQL完备性上更好，比如支持HAVING 查询，效果更好