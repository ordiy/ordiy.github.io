---
layout: post
title: Spark输出处理-文本数据
categories:
  - tech
tags:
  - blog
date: 2022-04-17 19:11:47
excerpt: spark 处理大文本数据集
---

# 需求
 - 提取文本日志中指定的字段信息
 - 对字段进行筛选排序

# 文本数据

- 以`tuna tsinghua ` 的网络数据为例子：

```
$fake_remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$sent_http_content_type" "$http_referer" "$http_user_agent" - $scheme
```
格式：
```
203.119.172.233 - - [15/Apr/2024:00:19:31 +0800] "GET /simple/pip/ HTTP/1.1" 403 1513 "text/html" "-" "pip/21.3.1 {\x22ci\x22:null,\x22cpu\x22:\x22x86_64\x22,\x22distro\x22:{\x22id\x22:\x22Paladin\x22,\x22libc\x22:{\x22lib\x22:\x22glibc\x22,\x22version\x22:\x222.17\x22},\x22name\x22:\x22Alibaba Group Enterprise Linux Server\x22,\x22version\x22:\x227.2\x22},\x22implementation\x22:{\x22name\x22:\x22CPython\x22,\x22version\x22:\x223.7.5rc1\x22},\x22installer\x22:{\x22name\x22:\x22pip\x22,\x22version\x22:\x2221.3.1\x22},\x22openssl_version\x22:\x22OpenSSL 1.0.2k-fips  26 Jan 2017\x22,\x22python\x22:\x223.7.5rc1\x22,\x22setuptools_version\x22:\x2241.2.0\x22,\x22system\x22:{\x22name\x22:\x22Linux\x22,\x22release\x22:\x224.19.91-011.ali4000.alios7.x86_64\x22}}" - https

```


# 处理数据
```java

import org.apache.spark.api.java.JavaRDD;
import org.apache.spark.sql.*;
import org.apache.spark.sql.types.DataTypes;
import org.apache.spark.sql.types.Metadata;
import org.apache.spark.sql.types.StructField;
import org.apache.spark.sql.types.StructType;
import scala.Tuple4;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 *  读取 log 文本日志文件
 *   提取部分字段进行筛选和过滤
 */
public class TestReadTxtFile {

    static String regex = "^(\\S+) (\\S+) (\\S+) \\[(.*?)\\] \"(.*?)\" (\\d+) (\\d+) \"(.*?)\" \"(.*?)\" \"(.*?)\" - (.*)$";
    private static Pattern pattern = Pattern.compile(regex);

    public static void main(String[] args) {
        SparkSession sparkSession = getSparkSession();

        //read file
        Dataset<String> dataset = sparkSession.read()
                .textFile(args[0])
                .cache();

        // 使用 mapToPair 方法将每行文本拆分成键值对，按照 $fake_remote_addr 作为键
        JavaRDD<Row> rowRddMap = dataset.toJavaRDD()
                .map(line -> {
                    Matcher matcher = pattern.matcher(line);
                    if (matcher.find()) {
                        return new Tuple4<>(matcher.group(1),
                                matcher.group(3), matcher.group(4), matcher.group(5)
                        );
                    } else {
                        return null;
                    }
                })
                .map(arr -> {
                    return RowFactory.create(arr._1(), arr._2(), arr._3(), arr._4());
                });

        //create dataframe
        Dataset<Row> dataFrame = sparkSession.createDataFrame(rowRddMap, getSchema());
        String tmpTab = "temp_table";
        dataFrame.createOrReplaceTempView(tmpTab);


        // 统计IP 链接次数
        ////  SELECT col1，count(*) as count_ip_times ,col3,col4 FROM xxtab  GROUP BY col1 "
        Dataset<Row> processedData = sparkSession.sql("SELECT col1,col3,col4 FROM " + tmpTab)
                .groupBy("col1")
                .count();

        //debug show log
        processedData.printSchema();
        processedData.show();

        //保存到 csv 文件
        processedData.write()
                .format("csv")
                .option("header", "true")  //adds header to file
                .mode(SaveMode.Overwrite)
                .save("test-5.csv");

        sparkSession.stop();

    }


    private static SparkSession getSparkSession() {
        return SparkSession.builder()
                .appName("spark-data-proc-example")
                .getOrCreate();
    }

    // 获取 DataFrame 的模式（schema）
    private static StructType getSchema() {
        return new StructType(new StructField[]{
                new StructField("col1", DataTypes.StringType, true, Metadata.empty()),
                new StructField("col2", DataTypes.StringType, true, Metadata.empty()),
                new StructField("col3", DataTypes.StringType, true, Metadata.empty()),
                new StructField("col4", DataTypes.StringType, true, Metadata.empty())
        });
    }
}

```
运行：
```shell
mvn package -Dmaven.test.skip=true && \
bin/spark-submit --class org.example.TestReadTxtFile \
 --master  "spark://xxx:7077" \
 --deploy-mode client \
 target/test-spark-env-1.0-SNAPSHOT.jar pypi.log-20240416-head-100

```
执行结果：
![alt text](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20240418191031.png)

# 文本数据
https://mirrors.tuna.tsinghua.edu.cn/news/release-logs/
https://mirrors.tuna.tsinghua.edu.cn/logs/nanomirrors/