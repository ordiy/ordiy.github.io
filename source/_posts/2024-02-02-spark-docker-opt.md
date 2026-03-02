---
layout: post
title: Spark Docker opt
categories:
  - tech
tags:
  - blog
excerpt: spark docker opt
date: 2023-02-18 17:08:18
---



# spark docer 
启动docker 
```bash
# start 
docker pull apache/spark-py:latest


docker run  -p 7077:7077 18080:8080 -it apache/spark-py /opt/spark/bin/pyspark 


```

# PySpark install 
```
pip install pyspark
```
https://pypi.org/project/pyspark/
https://spark.apache.org/documentation.html
https://hub.docker.com/r/apache/spark-py/tags 



# start spark with jupyter docker 
```bash

sudo docker run -it --rm -p 8088:8888 jupyter/all-spark-notebook

```

# test case
在jupyter notebook 中使用案例。

## 使用spark-shell 读取文件
```shell

$ spark-shell
    scala> val words = sc.textFile("file:///usr/local/spark-3.5.0-bin-hadoop3/NOTICE")
    words: org.apache.spark.rdd.RDD[String] = file:///usr/local/spark-3.5.0-bin-hadoop3/NOTICE MapPartitionsRDD[7] at textFile at <console>:23

    scala> val rddtest = words.cache
    rddtest: words.type = file:///usr/local/spark-3.5.0-bin-hadoop3/NOTICE MapPartitionsRDD[7] at textFile at <console>:23

    scala> val fk = rddtest.first
    fk: String = Apache Spark


```

## Spark streaming 
流式数据处理是将输入数据连续输入分散单元的过程。
Spark Streaming 是一个Spark组建，使用该组件执行实时分析（延迟只需几秒钟）。数据流被切分成多个批次，每个批次都组评委单独的Spark RDD。

```shell 
spark-shell > 
        import org.apache.spark._
        import org.apache.spark.streaming._
        import org.apache.spark.streaming.StreamingContext._ // not necessary since Spark 1.3

        // Create a local StreamingContext with two working thread and batch interval of 1 second.
        // The master requires 2 cores to prevent a starvation scenario.

      
        val ssc = new StreamingContext(sc, Seconds(1))

        // Create a DStream that will connect to hostname:port, like localhost:9999
        val lines = ssc.socketTextStream("localhost", 9999)

        // Split each line into words
        val words = lines.flatMap(_.split(" "))


        val pairs = words.map(word => (word, 1))
        val wordCounts = pairs.reduceByKey(_ + _)

        wordCounts.print()
        ssc.start()             // Start the computation

```
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20231213191015.png)