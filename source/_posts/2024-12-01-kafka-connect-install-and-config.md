---
title: Kafka Connnect install and config 
layout: post
date: 2025-03-28 13:51:03
tags:
 - kafka
 - kafka-connect
categories:
 - data
 - kafka

excerpt: 初始化kafka connect环境，并配置sink组件
---

# kafka connect 应用场景
用Confluent公司的一个图解释kafka connect 的作用（核心数据同步，source + sink ）
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/2024/202503281447666.png)

比FlinkCDC更轻量，无需关注数据状态，直接部署集群配置plugin，增加配置文件即可使用，基本无需编码。


# install kafka connect 
配置环境和组件信息：
```shell 

sudo apt install unzip -y 

cd /data/
wget https://downloads.apache.org/kafka/3.8.0/kafka_2.13-3.8.0.tgz 

tar -zxvf kafka_2.13-3.8.0.tgz 
ln -s kafka_2.13-3.8.0 kafka-bin

cd kafka-bin
mkdir plugins
cd plugins 


# install plugins  for 
# clickhouse
wget https://github.com/ClickHouse/clickhouse-kafka-connect/releases/download/v1.2.3/clickhouse-kafka-connect-v1.2.3.zip
unzip clickhouse-kafka-connect-v1.2.3.zip
rm -rf clickhouse-kafka-connect-v1.2.3.zip

#mysql bin 
wget https://repo1.maven.org/maven2/io/debezium/debezium-connector-mysql/2.7.3.Final/debezium-connector-mysql-2.7.3.Final-plugin.tar.gz
tar -zxvf debezium-connector-mysql-2.7.3.Final-plugin.tar.gz 
rm -rf debezium-connector-mysql-2.7.3.Final-plugin.tar.gz 

#postgrss
wget https://repo1.maven.org/maven2/io/debezium/debezium-connector-postgres/2.7.3.Final/debezium-connector-postgres-2.7.3.Final-plugin.tar.gz
tar -zxvf debezium-connector-postgres-2.7.3.Final-plugin.tar.gz
rm -rf debezium-connector-postgres-2.7.3.Final-plugin.tar.gz

#jdbc
wget https://repo1.maven.org/maven2/io/debezium/debezium-connector-jdbc/2.7.3.Final/debezium-connector-jdbc-2.7.3.Final-plugin.tar.gz
tar -zxvf debezium-connector-jdbc-2.7.3.Final-plugin.tar.gz
rm -rf debezium-connector-jdbc-2.7.3.Final-plugin.tar.gz

#sink s3
weget https://hub-downloads.confluent.io/api/plugins/confluentinc/kafka-connect-s3/versions/10.6.1/confluentinc-kafka-connect-s3-10.6.1.zip
unzip confluentinc-kafka-connect-s3-10.6.1.zip
rm confluentinc-kafka-connect-s3-10.6.1.zip


```

##  config `connect-distributed.properties` 
```bash


cd /data/kakfka-bin

#============
cp ./config/connect-distributed.properties ./config/connect-distributed.properties.bak

bash -c 'cat > ./config/connect-distributed.properties << EOF 
bootstrap.servers=10.20.6.147:7091,10.20.6.147:7092,10.20.6.147:7093

group.id=stg-my-kafka-connect-01
client.id=stg-my-kafka-connect-node01.my-host-stg.com

key.converter=org.apache.kafka.connect.json.JsonConverter
value.converter=org.apache.kafka.connect.json.JsonConverter

key.converter.schemas.enable=true
value.converter.schemas.enable=true

offset.storage.topic=stg-my-connect-offsets
offset.storage.replication.factor=3
offset.storage.partitions=50

config.storage.topic=stg-my-connect-configs
config.storage.replication.factor=3
config.storage.partitions=1

status.storage.topic=stg-my-connect-status
status.storage.replication.factor=3
status.storage.partitions=5

offset.flush.interval.ms=10000
compression.type=zstd

rest.host.name=0.0.0.0
rest.port=8083

offset.flush.timeout.ms=5000
access.control.allow.origin=*
access.control.allow.methods=GET,POST,PUT,DELETE
access.control.allow.headers=origin,content-type,accept,authorization
task.shutdown.graceful.timeout.ms=10000


plugin.path=/data/kafka-bin/plugins

EOF'

```

## 指定JDK版本为JDK17

```shell 
/usr/local/java/jdk-17
mkdir -p /usr/local/java/
cd /usr/local/java/
sudo wget https://download.java.net/java/GA/jdk17/0d483333a00540d886896bac774ff48b/35/GPL/openjdk-17_linux-aarch64_bin.tar.gz
sudo tar -zxvf openjdk-17_linux-aarch64_bin.tar.gz


export JAVA_HOME="/usr/local/java/jdk-17" 
export PATH=$JAVA_HOME/bin:$PATH
```

- test java version 

```sh
java -version 
```

```js
            openjdk version "17" 2021-09-14
            OpenJDK Runtime Environment (build 17+35-2724)
            OpenJDK 64-Bit Server VM (build 17+35-2724, mixed mode, sharing)

```


- test start application

```shell 
#!/bin/bash
export JAVA_HOME="/usr/local/java/jdk-17" 
export PATH=$JAVA_HOME/bin:$PATH
cd /data/kafka-bin
echo "start application "
./bin/connect-distributed.sh ./config/connect-distributed.properties

```


![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/2024/202503281417429.png)

## config system servcie 

```shell 

sudo bash -c 'cat > /usr/lib/systemd/system/kafka-connect-stg.service << EOF

[Unit]
Description=Apache Kafka Connect Service
After=network.target
After=time-sync.target network-online.target
Wants=time-sync.target

[Service]
Type=forking
User=ubuntu
Group=ubuntu
#指定JDK 17
Environment="JAVA_HOME=/usr/local/java/jdk-17"
Environment="PATH=/usr/local/java/jdk-17/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
Environment="KAFKA_HEAP_OPTS=-Xms3G -Xmx32G"
ExecStart=/data/kafka-connect-node01/kafka-bin/bin/connect-distributed.sh -daemon /data/kafka-connect-node01/kafka-bin/config/connect-distributed.properties
Restart=on-failure
RestartSec=10
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target

EOF'


#==== systemctl 配置

sudo systemctl daemon-reload
sudo systemctl start kafka-connect-stg.service && sudo systemctl status kafka-connect-stg.service

sudo systemctl status kafka-connect-stg.service
sudo systemctl enable kafka-connect-stg.service
```

- 测试
```shell

curl -i http://127.0.0.1:8083

```

```js
HTTP/1.1 200 OK
Date: Fri, 28 Mar 2025 07:01:28 GMT
Content-Type: application/json
Content-Length: 91
Server: Jetty(9.4.54.v20240208)

{"version":"3.8.0","commit":"771b9576b00ecf5b","kafka_cluster_id":"abmGtN2qRqCh2YIQ_4W1Tg"}
```


## 配置web 管理工具

可以使用`conduktor-console`配置web管理工具，进行管理：

![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/2024/202503281424994.png)


#  在多云多/多IDC场景下可能还需要使用SASL_SSL进行跨区通信

- connect-distributed.properties 配置
```js
# 

# config producer sasl
producer.security.protocol=SASL_SSL
producer.sasl.mechanism=PLAIN
producer.sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="alice" password="your-password" ;
producer.ssl.truststore.password=your-password
producer.ssl.truststore.location=/data/kafka-bin/kafka-bin/broker-cmm-truststore.jks
producer.ssl.endpoint.identification.algorithm=

#consumer sasl
consumer.security.protocol=SASL_SSL
consumer.sasl.mechanism=PLAIN
consumer.sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="alice" password="your-password" ;
consumer.ssl.truststore.password=your-password
consumer.ssl.truststore.location=/data/kafka-bin/broker-cmm-truststore.jks
consumer.ssl.endpoint.identification.algorithm=


```
- system servcie 启动参数配置`jaas.conf`
```sh

vim kafka_client_jaas.conf

KafkaClient {
  org.apache.kafka.common.security.plain.PlainLoginModule required
  username="alice"
  password="pwd-alice-you-passowrd";
};

#需要在 system service 文件中添加这个配置：

Environment="KAFKA_OPTS= -Djava.security.auth.login.config=/data/kafka-bin/kafka_client_jaas.conf"


```


