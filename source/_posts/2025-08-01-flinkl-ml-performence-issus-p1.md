---
layout: post
title: "FlinkML 遇到的性能问题--避坑"
tags:
 - Flink
categories:
  - tech
excerpt: "FlinkML进行矩阵计算的遇到的性能问题,以及原因分析"
date: 2025-10-01 00:00:00
---


# Flink ML进行矩阵计算的性能问题
使用scikit-learn训练了几个简单的机器学习模型，计划应用到线上的广告流量反欺诈上，验证FlinkML方案是否可行（原因：小团队，需要在架构上减少维护的组件数量）


# 遇到的问题
FlinkML会将向量计算转换为Flink算子执行计算，如下图:
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/2024/202509221902287.png)


在特征简单的情况下是可以的，但是类似于广告欺诈等场景，feature会很多(高维度），然后Flink算子执行向量计算就会成为瓶颈（性能瓶颈）。
同时需要消耗大量的Slot用于执行FlinkML转换过来的算子，本来简单的向量计算变成了分布式pipeline计算，所以结果就是性能下降和计算资源消耗大。  

整个执行逻辑链路就是：
```
FlinkML --> flink stream 算子 
            ---> FlinkCore/breeze ---> JVM ---> OS ---> CPU
```

任务占用的Flink Slot：
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/2024/202509221921631.png)


任务项目代码:
```java

import org.apache.flink.api.common.restartstrategy.RestartStrategies;
import org.apache.flink.ml.classification.naivebayes.NaiveBayes;
import org.apache.flink.ml.classification.naivebayes.NaiveBayesModel;
import org.apache.flink.ml.linalg.DenseVector;
import org.apache.flink.ml.linalg.Vectors;
import org.apache.flink.runtime.state.hashmap.HashMapStateBackend;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.table.api.Table;
import org.apache.flink.table.api.bridge.java.StreamTableEnvironment;
import org.apache.flink.types.Row;
import org.apache.flink.util.CloseableIterator;

import java.util.concurrent.TimeUnit;

/** Simple program that trains a NaiveBayes model and uses it for classification. */
public class NaiveBayesTestMe {
    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        env.setParallelism(16);
        env.setStateBackend(new HashMapStateBackend());
        env.setRestartStrategy(RestartStrategies.fixedDelayRestart(3,
                org.apache.flink.api.common.time.Time.of(20, TimeUnit.SECONDS)));
        StreamTableEnvironment tEnv = StreamTableEnvironment.create(env);

        // Generates input training and prediction data.
        DataStream<Row> trainStream =
                env.fromElements(
                        Row.of(Vectors.dense(59,1,3,3,3,3,6),0),
                        Row.of(Vectors.dense(12,1,1,1,3,1,4),0),
                        Row.of(Vectors.dense(14,1,4,2,1,2,4),0),
                        Row.of(Vectors.dense(80,1,1,1,1,1,4),0),
                        Row.of(Vectors.dense(14,1,2,2,1,2,5),0),
                        Row.of(Vectors.dense(25,1,2,2,1,2,4),0),
                        Row.of(Vectors.dense(35,1,2,2,1,2,4),0),
                        Row.of(Vectors.dense(42,1,8,2,3,1,15),0),
                        Row.of(Vectors.dense(7,1,1,1,1,1,4),0),
                        Row.of(Vectors.dense(4,1,0,2,2,1,1),1),
                        Row.of(Vectors.dense(2,1,0,2,2,1,1),1),
                        Row.of(Vectors.dense(2,1,0,2,2,1,1),1),
                        Row.of(Vectors.dense(4,1,0,2,2,1,1),1),
                        Row.of(Vectors.dense(2,1,0,2,2,1,1),1),
                        Row.of(Vectors.dense(4,1,0,2,2,1,1),1),
                        Row.of(Vectors.dense(2,1,0,2,2,1,1),1),
                        Row.of(Vectors.dense(4,1,0,2,2,1,1),1),
                        Row.of(Vectors.dense(5,1,0,2,2,1,1),1)
                );
        Table trainTable = tEnv.fromDataStream(trainStream).as("features", "label");

        DataStream<Row> predictStream =
                env.fromElements(
                        Row.of(Vectors.dense(6,1,3,2,1,2,4)),
                        Row.of(Vectors.dense(23,1,4,2,1,2,4 )),
                        Row.of(Vectors.dense(45,1,2,2,1,2,4 )),
                        Row.of(Vectors.dense(32,1,4,3,2,2,9 )),
                        Row.of(Vectors.dense(6,1,1,1,1,1,5 )),
                        Row.of(Vectors.dense(18,1,1,1,1,1,3 )),
                        Row.of(Vectors.dense(14,1,1,1,1,1,2 )),
                        Row.of(Vectors.dense(30,1,2,2,1,2,5 )),
                        Row.of(Vectors.dense(6,1,2,1,2,1,4 )),
                        Row.of(Vectors.dense(19,1,2,2,1,2,2 ))
                );
        Table predictTable = tEnv.fromDataStream(predictStream).as("features");

        // Creates a NaiveBayes object and initializes its parameters.
        NaiveBayes naiveBayes =
                new NaiveBayes()
                        .setSmoothing(1.0)
                        .setFeaturesCol("features")
                        .setLabelCol("label")
                        .setPredictionCol("prediction")
                        .setModelType("multinomial");

        // Trains the NaiveBayes Model.
        NaiveBayesModel naiveBayesModel = naiveBayes.fit(trainTable);

        // Uses the NaiveBayes Model for predictions.
        Table outputTable = naiveBayesModel.transform(predictTable)[0];

        // Extracts and displays the results.
        outputTable.execute().print();
//
//        for (CloseableIterator<Row> it = outputTable.execute().collect(); it.hasNext(); ) {
//            Row row = it.next();
//            DenseVector features = (DenseVector) row.getField(naiveBayes.getFeaturesCol());
//            double predictionResult = (Double) row.getField(naiveBayes.getPredictionCol());
//
//            System.out.printf("Features: %s \tPrediction Result: %s\n", features, predictionResult);
//        }

        env.execute("my_job");
    }
}
```


# 综合结论

## 使用`scikit-learn`

FlinkML项目暂时还不成熟，社区活跃度也很低（https://nightlies.apache.org/flink/flink-ml-docs-master），不建议使用。
  也不太推荐通过UDT在FlinkSQL中进行自定义的向量计算（复杂度较高，部署和维护都是一个很耗费时间的事情，投入的时间和产出不成正比）。
如果队Java/Scala实现向量计算感兴趣，具体可以参考SparkML的（MLlib 使用线性代数包 Breeze 和 dev.ludovic.netlib 来优化数值处理 。这些包可用作系统库或运行时库路径，则它们可以调用本机加速库，例如 Intel MKL 或 OpenBLAS ），

综合考虑在ML模型部署环节还是需要使用python,几直接使用`scikit-learn`库及相关的库。
`scikit-learn`基本都是C/C++实现（已经自动包含了BLAS MKL库，可以调用CPU的指令集进行向量计算，`scikit-learn`的执行计算的链路:
```
`scikit-learn`(C) --> OS --> 硬件资源
```

## Flink处理实时的特征提取
在实时数据处理的环节，即实时提取数据特征使用FlinkStream/FlinkSQL还是最便捷的方案。


# 最终方案
核心还是利用`scikit-learn`ML库进行数据处理， Flink进行实时的特征提取/挖掘。

整个作业链路：
```js
 Flin进行实时的特征提取/挖掘 --结果数据---> 
    kafka topic --> 
        my_hander(python consumer + scikit-learn ML)
            --> sink_kafka 
            ---> Clickhouse Cluster
                ---> API / BI 使用 / 其它AlertAndProcesser
```


# 参考
- FlinkML   
https://github.com/apache/flink-ml
- scikit-learn   
https://scikit-learn.org/