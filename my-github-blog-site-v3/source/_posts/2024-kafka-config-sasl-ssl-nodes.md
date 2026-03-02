---
title:  Kafka broker 配置PLAINTEXT和SASL_SSL双协议
layout: post
date: 2024-12-01 00:00:00
tags:
  - tech
  - kafka
  - sasl_ssl
categories: 
  - blog
excerpt: Kafka broker 配置多协议混合, 内网使用PLAINTEXT协议, 公网使用SASL_SSL
---

# 需求
 Kafka 同一个集群实现，内网使用PLAINTEXT协议, 公网使用SASL_SSL。

```js

client --SASL_SSL --> LB(NAT) ---> kafka_broker 

client ---PLAINTEXT ----> kafka_broker 
 
```

#  先配置PLAINTEXT 实现集群正常

## install broker 
```shell 

sudo chown ubuntu:ubuntu -R /data
sudo apt install openjdk-17-jdk -y
# download jdk https://jdk.java.net/archive/

cd /data/
wget https://downloads.apache.org/kafka/3.8.0/kafka_2.13-3.8.0.tgz
#!/bin/bash

sudo chown ubuntu:ubuntu -R /data


sudo  apt-get update
sudo apt install openjdk-17-jdk -y 

cd /data/
wget https://downloads.apache.org/kafka/3.8.0/kafka_2.13-3.8.0.tgz 

tar -zxvf kafka_2.13-3.8.0.tgz 
ln -s kafka_2.13-3.8.0 kafka-bin

#config zk

#NODES=("10.10.157.141" "10.10.148.147" "10.10.149.188")
export KAFKA_BROKER_DIR=/data/kafka-bin

#mkdir $ZOOKEEPER_DIR/conf

cd $KAFKA_BROKER_DIR

#step 1
# config properties 

cp config/server.properties config/server.properties.bak
broker_server_config="config/server.properties"
broker_id="1"

sed -i "s/localhost:2181/10.10.157.141:2181,10.10.148.147:2181,10.10.149.188:2181/g" $broker_server_config
sed "s/^broker.id=.*/broker.id=${broker_id}/g" $broker_server_config

#config kafka broker data dir 
mkdir /data/kafka-data

# sed "s/log.dirs\=\/tmp\/kafka-logs/log.dirs\=\/data\/kafka-data/g" $broker_server_config  | grep "log.dir"
sed  -i "s/log.dirs\=\/tmp\/kafka-logs/log.dirs\=\/data\/kafka-data/g" $broker_server_config 

sewd -i 

# step 2 
# config  jvm
old_string="1G"
new_string="3G"
file_path="./bin/kafka-server-start.sh"
sed -i "s/${old_string}/${new_string}/g" "$file_path" 


#step3 
#config service

sudo bash -c 'cat > /usr/lib/systemd/system/kafka.service << EOF
  [Unit]
  Description=Apache Kafka Service
  After=network.target
  After=time-sync.target network-online.target
  Wants=time-sync.target

  [Service]
  Type=simple
  User=ubuntu
  Group=ubuntu
  ExecStart=/data/kafka/bin/kafka-server-start.sh /data/kafka/config/server.properties
  ExecStop=/data/kafka/bin/kafka-server-stop.sh
  Restart=always
  RestartSec=30
  TimeoutStopSec=300
  LimitNOFILE=65536
  StandardOutput=null
  StandardError=null

  [Install]
  WantedBy=multi-user.target
EOF'


#config jmx 
cd /data/kafka 
mkdir prometheus 
cd prometheus
wget https://repo.maven.apache.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/1.0.1/jmx_prometheus_javaagent-1.0.1.jar 


bash -c ' cat > kafka-2_0_0.yml << EOF 
rules:
  - pattern: kafka.server<type=(\w+), name=(\w+)(, topic=(\w+))?.*>
    name: kafka_server_$1_$2
    labels:
      topic: "$4"
  - pattern: kafka.network<type=(\w+), name=(\w+), request=(\w+),.*>
    name: kafka_network_$1_$2
    labels:
      request: "$3"
  - pattern: kafka.network<type=RequestMetrics, name=(\w+), request=(\w+),.*>
    name: kafka_request_metrics_$1
    labels:
      request: "$2"

EOF'

cd /data/kafka

sed -i '16a\ export KAFKA_OPTS="$KAFKA_OPTS -javaagent:/data/kafka/prometheus/jmx_prometheus_javaagent-1.0.1.jar=7071:/data/kafka/prometheus/kafka-2_0_0.yml" ' bin/kafka-server-start.sh


sudo systemctl daemon-reload
sudo systemctl restart kafka 
sudo systemctl status kafka
sudo systemctl enable kafka 
sudo systemctl status kafka



```



##  test 

```js
# show log 

tail -f logs/server.log 

```

# 配置 SASL_SSL 协议

## JKS证书生成

```js

mkdir security
cd security/

sudo openssl req -new -x509 -keyout /tmp/snakeoil-ca-1.key -out /tmp/snakeoil-ca-1.crt -days 365 -subj '/CN=ca1.test.confluent.io/OU=TEST/O=CONFLUENT/L=PaloAlto/ST=Ca/C=US' -passin pass:confluent -passout pass:confluent


keytool -genkeypair -alias kafka-broker -keyalg RSA -keysize 2048 \
-validity 3650 -keystore kafka-broker-keystore.jks -dname "CN=b8c4-fa18b654c0b2-data.my-cluster-prod.com, OU=my-cluster-prod, O=my-cluster-prod, L=Los_Angeles, ST=California, C=US" \ -storepass pwdXX2024P87d98ac9wz -keypass oker2024P87d98ac9wz 

keytool -export -alias kafka-broker -file kafka-broker-cert.crt -keystore kafka-broker-keystore.jks -storepass pwdXX2024P87d98ac9wz

keytool -list -v -keystore  kafka-broker-keystore.jks -storepass pwdXX2024P87d98ac9wz

keytool -import -alias kafka-broker -file kafka-broker-cert.crt -keystore truststore.jks -storepass pwdXX2024P87d98ac9wz

keytool -list -v -keystore truststore.jks -storepass truststore_password

keytool -list -v -keystore truststore.jks -storepass pwdXX2024P87d98ac9wz

# load 
keytool -import -trustcacerts -file broker-cmm-certificate.crt   -keystore broker-cmm-truststore.jks   -storetype JKS   -storepass pwdPassword8e95-942e564afa33   -alias pwdPassword8e95-942e564afa33

```

## 配置broker sasl_ssl 


```js

broker.id=1
#需要配置 listeners PLAINTEXT + SASL_SSL 
listeners=PLAINTEXT://0.0.0.0:9092,SASL_SSL://0.0.0.0:19098

#需要配置 advertised.listeners PLAINTEXT + SASL_SSL 
advertised.listeners=PLAINTEXT://10.21.100.21:9092,SASL_SSL://node03.kafka-broker-data.my-prod-host.com:19091
listener.security.protocol.map=PLAINTEXT:PLAINTEXT,SASL_SSL:SASL_SSL

#broker内部通信使用PLAINTEXT

security.inter.broker.protocol=PLAINTEXT

sasl.mechanism.inter.broker.protocol=PLAIN
security.protocol=SASL_SSL
sasl.enabled.mechanisms=PLAIN

ssl.keystore.location=/data/kafka-bin/security/broker-cmm-keystore.jks
ssl.keystore.password=xxx-942e564afa33
ssl.key.password=xxx-942e564afa33
ssl.truststore.location=/data/kafka-bin/security/broker-cmm-truststore.jks
ssl.truststore.password=xxxx-942e564afa33
ssl.endpoint.identification.algorithm=
# SSL config 验证client 证书
ssl.client.auth=required

num.network.threads=6
num.io.threads=12
socket.send.buffer.bytes=524288
socket.receive.buffer.bytes=524288
socket.request.max.bytes=104857600
log.dirs=/data/kafka-data
num.partitions=1
num.recovery.threads.per.data.dir=1
offsets.topic.replication.factor=1
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1
log.retention.hours=168
log.retention.check.interval.ms=300000

compression.type=zstd

zookeeper.connect=10.21.100.88:2181,10.21.100.46:2181,10.21.100.211:2181/prod-kafka-cluster-bigdata
zookeeper.connection.timeout.ms=18000
group.initial.rebalance.delay.ms=0
```

## 配置 servcie

```js

[Unit]
Description=Apache Kafka Service
After=network.target
After=time-sync.target network-online.target
Wants=time-sync.target

[Service]
Type=forking
User=ubuntu
Group=ubuntu
Restart=on-failure
RestartSec=5
TimeoutStopSec=300
LimitNOFILE=260000
LimitFSIZE=infinity
Environment="KAFKA_OPTS= -Djava.security.auth.login.config=/data/kafka-bin/security/kafka_server_jaas.conf -javaagent:/data/kafka-bin/prometheus/jmx_prometheus_javaagent-1.0.1.jar=10071:/data/kafka-bin/prometheus/kafka_broker.yml"
Environment="KAFKA_HEAP_OPTS=-Xms8G -Xmx8G "
ExecStart=/data/kafka-bin/bin/kafka-server-start.sh -daemon /data/kafka-bin/config/server.properties

[Install]
WantedBy=multi-user.target

```

# client test 
```js
./bin/kafka-console-consumer.sh --bootstrap-server node01.kafka-broker-data.my-host-pord.com:19096,node02.kafka-broker-data. my-host-pord.com:19096,node03.kafka-broker-data. my-host-pord.com:19096        --topic source.pro-pro-connect-offsets-v2     --consumer.config kafka-client-sasl-ssl-plain.properties     --partition 0     --property print.value=true --from-beginning

```
