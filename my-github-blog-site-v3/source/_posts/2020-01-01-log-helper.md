---
layout: post
title: Log4j2 常用配置及SpringBoot集成
categories:
  - tech
  - Java
tags:
  - blog
  - Log
comments: false
update: 2022-05-01 00:00:00
date: 2020-01-01 00:00:00
excerpt: 使用Log4j2 常用配置细节说明，以及SpringBoot集成方法。自定义`JsonTemplateLayout`配置Json日志文件
---


# Console Log style
 - 配置`PatternLayout` Console Style,标示输出信息:
```xml
<Console name="Console" target="SYSTEM_OUT">
    <PatternLayout pattern = "%style{%d{yy-MM-dd HH:mm:ss.SSS}{GMT+8}}{magenta} %style{[%t]}{blue} %style{%-5level:}{yellow} %style{%C{1.}}{bright,yellow}: %style{%msg%n%throwable}{green}" />
</Console>
```
或者使用`STYLE`根据日志级别进行配置
```xml
<PatternLayout pattern = "%highlight{%d [%t] %-5level: %msg%n%throwable}{STYLE=Logback}" />
```
日志输出效果:
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20220712162439.png)

# 定义logger
- 控制某个Class Path下的Logger Level和输出
```xml
    <Loggers>
        <Root level="info">
            <AppenderRef ref="Console" />
            <AppenderRef ref="RollingFile" />
        </Root>
        <Logger name="cn.xxxx" level="trace"></Logger>
    </Loggers>
```

# JSON Layout
 - JsonTemplateLayout
使用lo4j2 [`JsonTemplateLayout`](https://logging.apache.org/log4j/2.x/manual/json-template-layout.html),配置输出Json格式的日志
```xml
<!-- maven dependency log4j2.version 2.8.0 -->
<dependency>
    <groupId>org.apache.logging.log4j</groupId>
    <artifactId>log4j-api</artifactId>
    <version>2.18.0</version>
</dependency>
<dependency>
    <groupId>org.apache.logging.log4j</groupId>
    <artifactId>log4j-core</artifactId>
    <version>2.18.0</version>
</dependency>
<dependency>
    <groupId>org.apache.logging.log4j</groupId>
    <artifactId>log4j-layout-template-json</artifactId>
    <version>2.18.0</version>
</dependency>
```
-`log4j2.xml`配置：
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Configuration>
    <Appenders>
            <!-- 生产中请配置为 RollingFile ,这里仅座位展示 -->
            <Console name="JsonAppender" target="SYSTEM_OUT">
                <JsonTemplateLayout eventTemplateUri="classpath:EcsLayout.json">
                    <EventTemplateAdditionalField
                            key="message"
                            format="JSON"
                            value='{"$resolver": "message", "field": "name"}' />
                </JsonTemplateLayout>
            </Console>
    </Appenders>

    <Loggers>
        <Root level="info">
            <AppenderRef ref="JsonAppender" />
        </Root>
</Configuration>
```
- `EcsLayout.json`文件内容：
```json
{
  "@timestamp": {
    "$resolver": "timestamp",
    "pattern": {
      "format": "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
      "timeZone": "UTC"
    }
  },
  "ecs.version": "1.2.0",
  "log.level": {
    "$resolver": "level",
    "field": "name"
  },
  "message": {
    "$resolver": "message",
    "stringified": true
  },
  "process.thread.name": {
    "$resolver": "thread",
    "field": "name"
  },
  "log.logger": {
    "$resolver": "logger",
    "field": "name"
  },
  "labels": {
    "$resolver": "mdc",
    "flatten": true,
    "stringified": true
  },
  "tags": {
    "$resolver": "ndc"
  },
  "error.type": {
    "$resolver": "exception",
    "field": "className"
  },
  "error.message": {
    "$resolver": "exception",
    "field": "message"
  },
  "error.stack_trace": {
    "$resolver": "exception",
    "field": "stackTrace",
    "stackTrace": {
      "stringified": true
    }
  }
}
```
- Console 输出：
```json
{
    "@timestamp": "2022-07-12T07:34:53.298Z", 
    "ecs.version": "1.2.0", 
    "log.level": "INFO", 
    "message": "Tomcat initialized with port(s): 8024 (http)", 
    "process.thread.name": "main", 
    "log.logger": "org.springframework.boot.web.embedded.tomcat.TomcatWebServer"
}
```
# spring-boot集成log4j2
- maven dependency
```xml
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter</artifactId>
            <exclusions>
                <exclusion>
                    <groupId>org.springframework.boot</groupId>
                    <artifactId>spring-boot-starter-logging</artifactId>
                </exclusion>
            </exclusions>
        </dependency>
        <!-- 使用JsonLayerOut需要将log4j2升级到2.8.0 -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-log4j2</artifactId>
        </dependency>
```

- log4j2-spring.xml文件
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Configuration>
    <Appenders>
        <Console name="Console" target="SYSTEM_OUT">
            <PatternLayout pattern = "%style{%d{yy-MM-dd HH:mm:ss.SSS}{GMT+8}}{magenta} %style{[%t]}{blue} %style{%-5level:}{yellow} %style{%C{1.}}{bright,yellow}: %style{%m%n%throwable}{green}" />
           </Console>
           <!-- demo -->
            <Console name="JsonAppender" target="SYSTEM_OUT">
                <JsonTemplateLayout eventTemplateUri="classpath:EcsLayout.json">
                    <EventTemplateAdditionalField
                            key="message"
                            format="JSON"
                            value='{"$resolver": "message", "field": "name"}' />
                </JsonTemplateLayout>
            </Console>

           <RollingFile name="RollingFile"
                     fileName="./logs/logger.log"
                     filePattern="./logs/$${date:yyyy-MM}/logger-%d{-dd-MMMM-yyyy}-%i.log.gz">
            <PatternLayout>
                <pattern>%d{yy-MM-dd HH:mm:ss.SSS}{GMT+8} %p %c{1.} [%t] %m%n</pattern>
            </PatternLayout>
            <Policies>
                <OnStartupTriggeringPolicy />
                <SizeBasedTriggeringPolicy size="100 MB" />
                <!--按天分日志文件 与filepattern 配合使用-->
                <TimeBasedTriggeringPolicy modulate="true" interval="1"/>
            </Policies>
        </RollingFile>
    </Appenders>
    <Loggers>
        <Root level="info">
           <AppenderRef ref="Console" />
           <AppenderRef ref="RollingFile" />
            <!-- <AppenderRef ref="JsonAppender" /> -->
        </Root>
        <Logger name="cn.xxxx" level="trace"></Logger>
    </Loggers>
</Configuration>
```
- 使用`spring-boot-starter`启动时指定`log4j.configurationFile`
```bash
java -XX:+UseG1GC -Xms2g -Xmx6g -Dcurrent-load-task-limit=1 \
 -Dlog4j.configurationFile=./log4j2-spring.xml \
 -jar zzz-hbase-bulk-load-service.jar \
 --spring.config.location=application.yml --custom.service.cluster-xxx=gl-dev
```
