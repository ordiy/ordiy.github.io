---
layout: post
title: 使用log4j2 JsonLayout自定义JSON格式日志
categories:
  - tech
  - java
tags:
  - blog
  - Java
  - Log4j2
  - Logging
date: 2019-01-01 00:00:00
excerpt:  log4j2 使用JsonLayout输出json格式的日志，以及使用lookup、ThreadContext配置出自定义的jsonlog，可以用于对微服务的日志输出或者其它日志分析。
---

# 需求
log4j2 在性能上提升了很多，可以减小日志输出对高并发程序的性能。
程序的日志需要输出为json格式，通过ELK 收集和存储日志，使用json格式便于Elasticsearch提取JSON字段信息，进行搜索或者通过Kinana展示

![images](https://logging.apache.org/log4j/2.x/images/async-throughput-comparison.png)

# log4j2 JsonLayout使用
 ### log4j2 输出json log 使用示例
 
 maven pom 依赖：
 ```xml
  <properties>
        <java.version>1.8</java.version>
        <java.compile.version>1.8</java.compile.version>
        <log4j-api.version>2.13.1</log4j-api.version>
        <jackson.version>2.10.0</jackson.version>
    </properties>
    <dependencies>
        <dependency>
            <groupId>org.apache.logging.log4j</groupId>
            <artifactId>log4j-core</artifactId>
            <version>${log4j-api.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.logging.log4j</groupId>
            <artifactId>log4j-api</artifactId>
            <version>${log4j-api.version}</version>
        </dependency>
        <!-- json format -->
        <dependency>
            <groupId>com.fasterxml.jackson.core</groupId>
            <artifactId>jackson-core</artifactId>
            <version>${jackson.version}</version>
        </dependency>
        <dependency>
            <groupId>com.fasterxml.jackson.core</groupId>
            <artifactId>jackson-databind</artifactId>
            <version>${jackson.version}</version>
        </dependency>
 ```
- Java Code  示例：
```java
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class LogJsonTest {
    private static Logger log = LogManager.getLogger(LogJsonTest.class);
    public static void main(String[] args) {
        ThreadContext.put("hello","world");
        for (int i = 0; i < 2; i++) {
            log.info("current index:{},date:{}",i, LocalDateTime.now().toString());
        }
        try{
            throw  new RuntimeException("hello i am fool");
        }catch (Exception e){ log.error("error cause:",e); }
        // test json object demo
        log.info("demo str:{}",new Demo());
    }

    static class Demo{
        private List<String> arr = new ArrayList<>();
        private String he="";
        @Override
        public String toString() {
            return Arrays.toString(arr.toArray()) ;
        }
    }
}
```

- log4j `log4j2.xml`配置示例：
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Configuration status="OFF">
    <properties>
        <property name="logPath">logs</property>
        <property name="logLevel">info</property>
        <property name ="project" >spring-cloud-app-demo</property>
    </properties>
    <Appenders>
        <Console name="console" target="SYSTEM_OUT">
            <!-- complete="true"   Complete well-formed JSON    -->
            <JsonLayout complete="false" compact="true" eventEol="true" properties="true"
                        locationInfo="true"  includeStacktrace="true"
                        stacktraceAsString="true"
                        objectMessageAsJsonObject="true">
                <KeyValuePair key="project" value="${project}"/>
            </JsonLayout>
        </Console>
    </Appenders>

    <Loggers>
    <Logger name="com.github.ordiy" level="debug" additivity="false">
        <AppenderRef ref="console"/>
    </Logger>
    <Root level="debug">
        <AppenderRef ref="console"/>
    </Root>
    </Loggers>
</Configuration>
```

- json 日志输出格式

```json
{"thread":"main","level":"ERROR","loggerName":"com.github.ordiy.LogJsonTest","message":"error cause:","thrown":{"commonElementCount":0,"localizedMessage":"hello i am fool","message":"hello i am fool","name":"java.lang.RuntimeException","extendedStackTrace":"java.lang.RuntimeException: hello i am fool\n\tat com.github.ordiy.LogJsonTest.main(LogJsonTest.java:24) [classes/:?]\n"},"endOfBatch":false,"loggerFqcn":"org.apache.logging.log4j.spi.AbstractLogger","instant":{"epochSecond":1594867434,"nanoOfSecond":597759000},"contextMap":{"hello":"world"},"threadId":1,"threadPriority":5,"source":{"class":"com.github.ordiy.LogJsonTest","method":"main","file":"LogJsonTest.java","line":26,"classLoaderName":"app"},"project":"spring-cloud-app-demo"}
{"thread":"main","level":"INFO","loggerName":"com.github.ordiy.LogJsonTest","message":"demo str:com.github.ordiy.LogJsonTest$Demo@18cebaa5","endOfBatch":false,"loggerFqcn":"org.apache.logging.log4j.spi.AbstractLogger","instant":{"epochSecond":1594867434,"nanoOfSecond":611577000},"contextMap":{"hello":"world"},"threadId":1,"threadPriority":5,"source":{"class":"com.github.ordiy.LogJsonTest","method":"main","file":"LogJsonTest.java","line":29,"classLoaderName":"app"},"project":"spring-cloud-app-demo"}
```

### json layout 配置说明
JsonLayout可以使用`compact` `locationInfo` 等配置输出格式和内容,配置项解说参照[log4j2 json layout](https://logging.apache.org/log4j/2.x/manual/layouts.html#JSONLayout)
常用的配置项目：
```xml
 <JsonLayout complete="false" compact="true" eventEol="true" properties="true"
                        locationInfo="true"  includeStacktrace="true"
                        stacktraceAsString="true"
                        objectMessageAsJsonObject="true">
```
json 输出格式及备注：
![images](https://raw.githubusercontent.com/ordiychen/study_notes/master/res/image/node_image/blog_20200716104713.png)



### 使用log4j 输出自定义的日志格式

log4j2.xml 文件内容：
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Configuration status="OFF">
    <properties>
        <property name="logPath">logs</property>
        <property name="logLevel">info</property>
        <property name ="PROJECT_NAME" >spring-cloud-app-demo</property>
    </properties>

    <Appenders>
         <!-- immediateFlush="false"  不会立即写盘 tail时可能有延时 --> 
        <RollingFile name="fileOut" filename="${logPath}/info.log" filepattern="${logPath}/%d{yyyy-MM-dd}-info.log"  immediateFlush="false" append="false">
            <!-- complete="true"   Complete well-formed JSON    -->
            <JsonLayout   complete="false" compact="true" eventEol="true"
                        properties="false" locationInfo="false"
                        includeStacktrace="true" stacktraceAsString="true"
                        objectMessageAsJsonObject="true" >
                <!--                <KeyValuePair key="StudytonightField" value="studytonightValue" />-->
                <KeyValuePair key="project" value="${PROJECT_NAME}"/>
                <KeyValuePair key="timestamp" value="${date:yyyy-MM-dd'T'HH:mm:ss.SSSZZ}" />

                <KeyValuePair key="parent" value="$${ctx:X-B3-ParentSpanId}" />
                <KeyValuePair key="span" value="$${ctx:X-B3-SpanId}" />
                <KeyValuePair key="user" value="$${ctx:X-B3-uId}" />
                <KeyValuePair key="trace" value="${ctx:X-B3-TraceId}" />
                <KeyValuePair key="index" value="${PROJECT_NAME}-${date:yyyy-MM-dd}" />
                <!-- location 记录消耗性能 -->
                <KeyValuePair key="line_number" value="" />

                <!-- docker id  docker部署使用-->
                <!--                <KeyValuePair key="containerId" value="${docker:containerId}"/>-->
                <!--                <KeyValuePair key="containerName" value="${docker:containerName}"/>-->
                <!--                <KeyValuePair key="imageName" value="${docker:imageName}"/>-->
            </JsonLayout>
            <Policies>
                <TimeBasedTriggeringPolicy modulate="true" interval="1"/>
                <SizeBasedTriggeringPolicy size="1000MB"/>
            </Policies>
            <DefaultRolloverStrategy>
                <Delete basePath="${logPath}" maxDepth="1">
                    <IfFileName glob="*info.log*" />
                    <IfLastModified age="30d" />
                </Delete>
            </DefaultRolloverStrategy>
        </RollingFile>
    </Appenders>

    <Loggers>
    <Root level="debug">
        <AppenderRef ref="fileOut"/>
    </Root>
    </Loggers>
</Configuration>
```
- Java 代码示例：
```java
private static Logger log = LogManager.getLogger(LogJsonTest.class);
    public static void main(String[] args) {
        //log4j ctx
        ThreadContext.put("X-B3-ParentSpanId","world");
        ThreadContext.put("X-B3-SpanId","world-span");
        ThreadContext.put("X-B3-uId","world-user");
        ThreadContext.put("X-B3-uId","world-user");
        ThreadContext.put("X-B3-TraceId","world-trace");

        for (int i = 0; i < 100; i++) {
            log.info("current index:{},date:{}",i, LocalDateTime.now().toString());
        }
        try{
            throw  new RuntimeException("hello i am fool");
        }catch (Exception e){ log.error("error cause:",e); }
    }
```

- Json日志输出文件示例：
```
{"thread":"main","level":"INFO","loggerName":"com.github.ordiy.LogJsonTest","message":"demo str:[]","endOfBatch":false,"loggerFqcn":"org.apache.logging.log4j.spi.AbstractLogger","instant":{"epochSecond":1594888243,"nanoOfSecond":231053000},"threadId":1,"threadPriority":5,"project":"spring-cloud-app-demo","timestamp":"2020-07-16T16:30:42.913+0800","parent":"world","span":"world-span","user":"world-user","trace":"world-trace","index":"spring-cloud-app-demo-2020-07-16","line_number":""}
```
进行pretty 优化展示后的格式：
```
{
   "thread":"main",
   "level":"INFO",
   "loggerName":"com.github.ordiy.LogJsonTest",
   "message":"demo str:[]",
   "endOfBatch":false,
   "loggerFqcn":"org.apache.logging.log4j.spi.AbstractLogger",
   "instant":{
      "epochSecond":1594888243,
      "nanoOfSecond":231053000
   },
   "threadId":1,
   "threadPriority":5,
   "project":"spring-cloud-app-demo",
   "timestamp":"2020-07-16T16:30:42.913+0800",
   "parent":"world",
   "span":"world-span",
   "user":"world-user",
   "trace":"world-trace",
   "index":"spring-cloud-app-demo-2020-07-16",
   "line_number":""
}
```

# 需要注意的问题
- `log4j2 jsonLayout` 处理`MDC`的兼容问题
`spring cloud sleuth`默认的 Trace日志默认使用的是`slf4j`在`MDC`中保存的`traceID`等信息，  `log4j2 jsonLayout` 处理`MDC`，会存在兼容性问题。(貌似可以通过重新实现 `JsonLayout`解决该问题，可以参照[log4j2-logstash-layout](https://github.com/vy/log4j2-logstash-layout)的实现)

- 代码地址
[https://github.com/ordiychen/demo-project/tree/master/test-log4j2-json-layout](https://github.com/ordiychen/demo-project/tree/master/test-log4j2-json-layout)


# 参考

- [JSONLayout](https://logging.apache.org/log4j/2.x/manual/layouts.html#JSONLayout)
- [Log4j2 JSON Layout Configuration Example](https://www.studytonight.com/post/log4j2-json-layout-configuration-example)
- [log4j2 lookup](https://logging.apache.org/log4j/2.x/manual/lookups.html)
- [log4j2 performence ](https://logging.apache.org/log4j/2.x/performance.html)