---
title:  Flink Quick Start With Command 
date: 2024-12-01 17:51:37
categories:
  - Data
tags:
  - Flink
  - Maven
excerpt:  Flink 通过shell command ，快速创建项目。
layout: post
---

# create flink java project 

```shell 
# expor shell 
# flink 1.17.2 为例子 
cd project-dir 
mvn archetype:generate                               \
      -DarchetypeGroupId=org.apache.flink              \
      -DarchetypeArtifactId=flink-quickstart-java      \
      -DarchetypeVersion=1.17.2


# 备注： 指令会根据project artifactId 创建项目文件夹

# version 
# 自动创建项目
mvn archetype:generate                               \
      -DarchetypeGroupId=org.apache.flink              \
      -DarchetypeArtifactId=flink-quickstart-java      \
      -DarchetypeVersion=1.17.2 \
      -DgroupId=my-data-flink \
      -DartifactId=cloudflare-cdn-etl \
      -Dversion=1.0-SNAPSHOT \



# mvn compile test 
cd xx  && mvn clean compile 

```

## shell script quick start

```shell 
curl https://flink.apache.org/q/quickstart.sh | bash -s 1.17.2
```

# 参考
[Apache Filink ](https://nightlies.apache.org/flink/flink-docs-release-1.17/docs/ops/metrics/)

