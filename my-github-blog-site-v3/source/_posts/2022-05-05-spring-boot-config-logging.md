---
layout: post
title: spring-boot2 config logging
categories:
  - tech
tags:
  - blog
excerpt: spring boot config logging pattern/logger-level/file
date: 2022-12-16 17:05:44
---


# 需求说明
- 需求如下
```javascript 
 - 配置spring boot logging 
      自定义配置日志 pattern/logger-level/file

```

# 实现
- maven pom 
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>org.example</groupId>
    <artifactId>springboot-schedule-shade-lock</artifactId>
    <version>1.0-SNAPSHOT</version>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>2.3.1.RELEASE</version>
        <relativePath/> <!-- lookup parent from repository -->
    </parent>
    <properties>
        <shedlock.version>4.29.0</shedlock.version>
        
        <mysql-connector.version>5.1.49</mysql-connector.version>
    </properties>

    <dependencies>
        <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter</artifactId>
        </dependency>

        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
        </dependency>

        <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-logging</artifactId>
        </dependency>
    </dependencies>
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
```
- application.yml 
```yml
logging:
  pattern:
    console: "%magenta(%date{ISO8601}) %blue([%thread]) %highlight([%level]) %cyan(%logger{15}:%line) - %green(%msg %n)"
    file: "%date{ISO8601} [%thread] [%level] %logger{15}:%line %msg%n"
  level:
    org.springframework.web: DEBUG
    org.apahe: ERROR
  file:
    path: ./logs
    name: ./logs/logger.log
```
- main class
```java

import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
@Slf4j
public class ScheduleApp {

    public static void main(String[] args) {
        SpringApplication.run(ScheduleApp.class, args);
        log.info(" start app ==== SUCCESS ===== ");
    }
}
```


# 结果
-  console 日志效果：
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_202212161724039.png)
console pattern 配置color 让日志查看更加友好.

- file 日志效果： 
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_202212161751172.png)
file pattern 保证了日志个是的统一，便于ELK进行收集.



# 解读
spring-boot默认使用`spring-boot-logging`作为日志模块，在使用中以`slf4j` 作为日志标准接口，使用`logback` 作为日志实现模块。
- 自定义配置file/console pattern 
   console 使用 color layout 配置颜色，便于控制台高效查看日志
- 指定logger level 
  在application.yml指定`logger level `
- 更复杂的日志输出，比如指定特殊的logger需要通过配置`spring-logback`实现


# 参考
- [ logback layout ](https://logback.qos.ch/manual/layouts.html)
- [spring-boot-logging ](https://docs.spring.io/spring-boot/docs/2.1.18.RELEASE/reference/html/boot-features-logging.html)
- [logback 说明](https://www.cnblogs.com/sinte-beuve/p/5758971.html)