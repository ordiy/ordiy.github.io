---
layout: post
title: Maven Trouble Debug I —— JDK error
date: 2021-12-02 10:53:45
tags:
  - Maven
categories:
  - tool
  - Maven
excerpt: <p> Maven 编译遇到的jdk问题汇总 </p>
---

# 问题描述
maven package 遇到JDK版本问题，无法正常compile.
```javascript
[ERROR] /home/gitlab-runner/builds/7zQqv6_Q/0/data-platform/hbase-management/hbase-region-manager/src/main/java/cn/isunapp/dp/hbase/service/BootstrapServer.java:[40,36] diamond operator is not supported in -source 1.5
  (use -source 7 or higher to enable diamond operator)
[ERROR] /home/gitlab-runner/builds/7zQqv6_Q/0/data-platform/hbase-management/hbase-region-manager/src/main/java/cn/isunapp/dp/hbase/service/BootstrapServer.java:[53,36] lambda expressions are not supported in -source 1.5
  (use -source 8 or higher to enable lambda expressions)
[INFO] 7 errors 
[INFO] -------------------------------------------------------------
[INFO] ------------------------------------------------------------------------
[INFO] BUILD FAILURE
[INFO] ------------------------------------------------------------------------
```


# 问题解决
遇到该问题是因为GitLab Runner Compiler Server默认JDK版本是1.7,而应用程序是Java8 编写的.
按最小化修改原则，这里只需指定程序的编译JDK即可

```bash
# Runner CI script 
#
JAVA_HOME={{JDK8_HOME}} && mvn -Dmaven.compile.fork=true -Dmaven.compiler.executable={{JDK8_HOME}}/bin/javac clean package
```

# 其它解决方法
## 制定自定义settings文件
在不修改全局setting文件的情况下，copy一个自定义的settings文件：
```bash
# Runner CI script 
#settings.xml
<settings>
  [...]
  <profiles>
    [...]
    <profile>
      <id>compiler</id>
        <properties>
          <JAVA_1_4_HOME>C:\Program Files\Java\j2sdk1.4.2_09</JAVA_1_4_HOME>
        </properties>
    </profile>
  </profiles>
  [...]
  <activeProfiles>
    <activeProfile>compiler</activeProfile>
  </activeProfiles>
</settings>
```
编译时指定使用自定义的settings.xml
```bash
# Runner CI script 
#
JAVA_HOME={{JDK8_HOME}} && mvn --settings /home/user/.m2/jdk8-settings.xml  clean package
```

## project指定compiler jdk version
在项目pom中指定`compiler-plugin`版本(Tips:需要注意maven使用的JDK版本，maven默认使用的JDK版本是JAVA_HOME环境变量指向的版本,可在编译时指定)
```
<project>
  [...]
  <build>
    [...]
    <plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-compiler-plugin</artifactId>
        <version>3.10.1</version>
        <configuration>
          <verbose>true</verbose>
          <fork>true</fork>
          <executable><!-- path-to-javac --></executable>
          <compilerVersion>1.3</compilerVersion>
        </configuration>
      </plugin>
    </plugins>
    [...]
  </build>
  [...]
</project>
```

# 总结
以上三种方法都可以达到目的，直接使用`maven.compile.fork`相对比较方便

# 参考
- [Apache Maven](https://maven.apache.org/plugins/maven-compiler-plugin/examples/compile-using-different-jdk.html)