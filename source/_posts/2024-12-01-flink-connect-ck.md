---
title:  Flink job query data form clickhouse
date: 2024-12-01 17:51:37
categories:
  - Data
tags:
  - Clickhouse
  - Flink
  - ETL
  - 实时数仓
excerpt: 在基于Clickhouse实时数仓架构中，部分需求需要使用Flink Job的MapFunction 以及 UDF 中读取Clickhouse数据. 
layout: post
---

# query data from clickhouse 
应用场景：需要将流的物化结果表，从Clickhouse中进行读取

在flink project pom.xml 添加以下dependency:
```xml

<!-- https://mvnrepository.com/artifact/com.clickhouse/clickhouse-jdbc -->
		<dependency>
			<groupId>com.clickhouse</groupId>
			<artifactId>clickhouse-jdbc</artifactId>
			<version>0.7.2</version>
			<!-- use uber jar with all dependencies included, change classifier to http for smaller jar -->
			<classifier>shaded-all</classifier>
		</dependency>

       <!-- flink 1.17 + jdk 8 , HikariCP version  < 5.x-->
		<dependency>
			<groupId>com.zaxxer</groupId>
			<artifactId>HikariCP</artifactId>
			<version>4.0.3</version>
		</dependency>

```



# 应用
在Flink RichMap中读取数据 （ 如果是Flink SQL 可以定一个 UDF 来实现）

```java 

    ParameterTool params = ParameterTool.fromArgs(args);
    final StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
    env.getConfig().setGlobalJobParameters(params);

    //env soruce ...

    //env stream 
     kafkaStream
                .keyBy(MyPojo::getKeyID)
                .map(new RichMapFunction<MyPojo, Tuple2<String, String>>() {
                    // version convert
                    private ObjectMapper objectMapper;
                    private transient HikariDataSource dataSource; // 需要序列化

                    @Override
                    public void open(Configuration parameters) throws Exception {
                        // 从 env GlobalJobParameters 读取配置信息
                        ExecutionConfig executionConfig = getRuntimeContext().getExecutionConfig();
                        ExecutionConfig.GlobalJobParameters jobParameters = executionConfig.getGlobalJobParameters();
                        Map<String, String> map = jobParameters.toMap();
                        String url = map.get("clickhouse_jdbc_url");
                        String username = map.get("clickhouse_username");
                        String password = map.get("clickhouse_password");

                        // 配置 HikariCP 连接池
                        HikariConfig config = new HikariConfig();
                        config.setJdbcUrl(url);
                        config.setUsername(username);
                        config.setPassword(password);
                        config.setDriverClassName("com.clickhouse.jdbc.ClickHouseDriver");

                        // 配置连接池属性
                        config.setMaximumPoolSize(30); // 最大连接数，根据并发量调整
                        config.setMinimumIdle(5);     // 最小空闲连接数
                        config.setIdleTimeout(30000); // 空闲连接超时时间（毫秒）
                        config.setConnectionTimeout(10000); // 获取连接的超时时间（毫秒）
                        config.setLeakDetectionThreshold(2000); // 检测连接泄漏的时间（毫秒）
                        config.setKeepaliveTime(Long.MAX_VALUE);
                        config.addDataSourceProperty("socket_keepalive", "true");

                        // 初始化连接池
                        this.dataSource = new HikariDataSource(config);

                        // 测试连接池
                        try (Connection conn = dataSource.getConnection();
                             Statement stmt = conn.createStatement()) {
                            ResultSet resultSet = stmt.executeQuery(" SELECT version() ");
                            if (resultSet.next()) {
                                logger.info("Connection test successful, current time: {}", resultSet.getString(1));
                            }
                        }
                        objectMapper = new ObjectMapper();
                        // 配置忽略未知字段
                        objectMapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
                    }

                    @Override
                    public Tuple2<String, String> map(Pojo InPojo) throws Exception {
                        // 业务代码
                         String sql = "select key from data_ods.key_dict_cache where value = %s limit 1 ";
                          sql = String.fromt(sql, InPojo.getId ) ;

                           // 从连接池获取连接
                        try (Connection conn = dataSource.getConnection();
                             Statement stmt = conn.createStatement();
                             ResultSet resultSet = stmt.executeQuery(sql);) {
                                while (resultSet.next()) {
                                    //handle query result 

                                }
                        } catch (Exception e) {
                            logger.error("query clickhouse error,cause:", e);
                        }

         }
```

## debug  日志  

```js
# log4j2.properties 
# 可以将clickhouse pakage 设置一个 level = debug 

rootLogger.level = DEBUG
rootLogger.appenderRef.console.ref = ConsoleAppender

appender.console.name = ConsoleAppender
appender.console.type = CONSOLE
appender.console.layout.type = PatternLayout
appender.console.layout.pattern = %d{HH:mm:ss,SSS} %-5p [%t] %-60c %x - %m%n

```

- Clickhouse client debug 日志信息  

 Clickhouse JDBC 使用的是HTTP协议进行通信（ 也支持HTTPS/gRPC)

```js 
18:14:56,587 DEBUG  com.clickhouse.client.internal.apache.hc.client5.http.wire   [] - http-outgoing-6 >> "POST /?compress=1&max_result_rows=100&extremes=0&query_id=ec8a8354-b8b7-4927-9b1e-ace3740781dc HTTP/1.1[\r][\n]"
18:14:56,587 DEBUG  com.clickhouse.client.internal.apache.hc.client5.http.wire   [] - http-outgoing-6 >> "accept: */*[\r][\n]"
18:14:56,587 DEBUG  com.clickhouse.client.internal.apache.hc.client5.http.wire   [] - http-outgoing-6 >> "user-agent: ClickHouse-JdbcDriver ClickHouse-JavaClient/0.7.2-SNAPSHOT (OpenJDK 64-Bit Server VM/25.422-b05; Apache-HttpClient/5.2.1)[\r][\n]"
18:14:56,587 DEBUG  com.clickhouse.client.internal.apache.hc.client5.http.wire   [] - http-outgoing-6 >> "Authorization: Basic c3RnX3Rlc3RfYWRtaW46UnB6MUkycDFLbE1PSXZG[\r][\n]"
18:14:56,587 DEBUG  com.clickhouse.client.internal.apache.hc.client5.http.wire   [] - http-outgoing-6 >> "x-clickhouse-database: data_ods[\r][\n]"
18:14:56,587 DEBUG  com.clickhouse.client.internal.apache.hc.client5.http.wire   [] - http-outgoing-6 >> "x-clickhouse-format: RowBinaryWithNamesAndTypes[\r][\n]"
18:14:56,587 DEBUG  com.clickhouse.client.internal.apache.hc.client5.http.wire   [] - http-outgoing-6 >> "accept-encoding: lz4[\r][\n]"
18:14:56,587 DEBUG  com.clickhouse.client.internal.apache.hc.client5.http.wire   [] - http-outgoing-6 >> "Content-Type: text/plain; charset=UTF-8[\r][\n]"
18:14:56,587 DEBUG  com.clickhouse.client.internal.apache.hc.client5.http.wire   [] - http-outgoing-6 >> "Transfer-Encoding: chunked[\r][\n]"
18:14:56,587 DEBUG  com.clickhouse.client.internal.apache.hc.client5.http.wire   [] - http-outgoing-6 >> "Host: 54.225.8.41:16464[\r][\n]"
18:14:56,587 DEBUG  com.clickhouse.client.internal.apache.hc.client5.http.wire   [] - http-outgoing-6 >> "Connection: keep-alive[\r][\n]"
18:14:56,587 DEBUG  com.clickhouse.client.internal.apache.hc.client5.http.wire   [] - http-outgoing-6 >> "[\r][\n]"
18:14:56,587 DEBUG  com.clickhouse.client.internal.apache.hc.client5.http.wire   [] - http-outgoing-6 >> "12[\r][\n]"
18:14:56,587 DEBUG  com.clickhouse.client.internal.apache.hc.client5.http.wire   [] - http-outgoing-6 >> " SELECT version() [\r][\n]"
18:14:56,587 DEBUG  com.clickhouse.client.internal.apache.hc.client5.http.wire   [] - http-outgoing-6 >> "0[\r][\n]"
18:14:56,587 DEBUG  com.clickhouse.client.internal.apache.hc.client5.http.wire   [] - http-outgoing-6 >> "[\r][\n]"
18:14:56,587 DEBUG  com.clickhouse.client.internal.apache.hc.client5.http.wire   [] - http-outgoing-0 >> "POST /?compress=1&max_result_rows=100&extremes=0&query_id=0c773532-708c-487e-b2f4-8afb809df84b HTTP/1.1[\r][\n]"
18:14:56,587 DEBUG  com.clickhouse.client.internal.apache.hc.client5.http.wire   [] - http-outgoing-0 >> "accept: */*[\r][\n]"
18:14:56,587 DEBUG  com.clickhouse.client.internal.apache.hc.client5.http.wire   [] - http-outgoing-0 >> "user-agent: ClickHouse-JdbcDriver ClickHouse-JavaClient/0.7.2-SNAPSHOT (OpenJDK 64-Bit Server VM/25.422-b05; Apache-HttpClient/5.2.1)[\r][\n]"
18:14:56,587 DEBUG  com.clickhouse.client.internal.apache.hc.client5.http.wire   [] - http-outgoing-0 >> "Authorization: Basic c3RnX3Rlc3RfYWRtaW46UnB6MUkycDFLbE1PSXZG[\r][\n]"
18:14:56,587 DEBUG  com.clickhouse.client.internal.apache.hc.client5.http.wire   [] - http-outgoing-4 >> "user-agent: ClickHouse-JdbcDriver ClickHouse-JavaClient/0.7.2-SNAPSHOT (OpenJDK 64-Bit Server VM/25.422-b05; Apache-HttpClient/5.2.1)[\r][\n]"
18:14:56,587 DEBUG  com.clickhouse.client.internal.apache.hc.client5.http.wire   [] - http-outgoing-0 >> "x-clickhouse-database: data_ods[\r][\n]"
18:14:56,587 DEBUG  com.clickhouse.client.internal.apache.hc.client5.http.wire   [] - http-outgoing-2 >> "user-agent: ClickHouse-JdbcDriver ClickHouse-JavaClient/0.7.2-SNAPSHOT (OpenJDK 64-Bit Server VM/25.422-b05; Apache-HttpClient/5.2.1)[\r][\n]"
18:14:56,587 DEBUG  com.clickhouse.client.internal.apache.hc.client5.http.wire   [] - http-outgoing-2 >> "Authorization: Basic c3RnX3Rlc3RfYWRtaW46UnB6MUkycDFLbE1PSXZG[\r][\n]"
18:14:56,587 DEBUG  com.clickhouse.client.internal.apache.hc.client5.http.wire   [] - http-outgoing-2 >> "x-clickhouse-database: data_ods[\r][\n]"
18:14:56,587 DEBUG  com.clickhouse.client.internal.apache.hc.client5.http.wire   [] - http-outgoing-2 >> "x-clickhouse-format: RowBinaryWithNamesAndTypes[\r][\n]"
18:14:56,587 DEBUG  com.clickhouse.client.internal.apache.hc.client5.http.wire   [] - http-outgoing-2 >> "accept-encoding: lz4[\r][\n]"
```

# UDF 中使用  

extends ScalarFunction 实现自定义 UDF.  
```java

/**
 * GeoIp2 cache
 */
public class MyUDFKeyValueDict extends ScalarFunction {
    private static final Logger logger = LoggerFactory.getLogger(MyUDFIPToCountryCodeDict.class);
    static String default_value = "Other";


    static String default_value = "Other";
    // 使用 Guava Cache 存储字典映射
    private static final Cache<String, String> cache = CacheBuilder.newBuilder()
            .expireAfterWrite(120, TimeUnit.SECONDS)  // 设置缓存有效期
            .maximumSize(1000)  // 设置缓存最大条目数
            .build();


     private transient HikariDataSource dataSource; // 需要序列化

    @Override
    public void open(FunctionContext context) throws Exception {
        try {
           //初始化 dataSource 

        // 配置 HikariCP 连接池
        HikariConfig config = new HikariConfig();
        config.setJdbcUrl(url);
        config.setUsername(username);
        config.setPassword(password);
        config.setDriverClassName("com.clickhouse.jdbc.ClickHouseDriver");

        // 配置连接池属性
        config.setMaximumPoolSize(30); // 最大连接数，根据并发量调整
        config.setMinimumIdle(5);     // 最小空闲连接数
        config.setIdleTimeout(30000); // 空闲连接超时时间（毫秒）
        config.setConnectionTimeout(10000); // 获取连接的超时时间（毫秒）
        config.setLeakDetectionThreshold(2000); // 检测连接泄漏的时间（毫秒）
        config.setKeepaliveTime(Long.MAX_VALUE);

        dataSource =  new HikariDataSource(config); 

        try (   Connection conn = dataSource.getConnection();
             Statement stmt = conn.createStatement()) {
            ResultSet resultSet = stmt.executeQuery(" SELECT VERSION() " );
            if(resultSet.next){
                //logger 
                logger.info("test ck cnn result:{}", resultSet.getObject(1))
            }
           
        } catch (Exception e) {
            throw new RuntimeException("Failed to initialize  database", e);
        }
    }

    /**
     * 核心 方法
     * @param ipAddress
     * @return
     */
    public String eval(String value) {
        //  定义查询方法
        // 如果缓存中没有，则查询数据库
        if (Objects.isNull(value)){
            return default_value;
        }
        String myKey = cache.getIfPresent(value);
        if (StringUtils.isBlank(myKey) {
            try (
            Connection conn = dataSource.getConnection();
             Statement stmt = conn.createStatement()) {
                String sql = "SELECT XXX " ;
             ResultSet resultSet = stmt.executeQuery(sql) ;
             // 获取数据结果 并进行处理  
        }

    }

    @Override
    public void close() throws Exception {
        if (dataSource != null) {
            dataSource.close();
        }
    }
}

```
## Flink SQL 中调用方法  
```SQL 
# 配置 jar 包到 FLink JobManager 

  CREATE FUNCTION guava_cache_key_value_dict AS 'ordiy.github.io.MyUDFKeyValueDict' ;

``` 

# 其它  
在其它一些Flink 批处理场景中，可能需要使用Clickhouse作为Source, 需要谨慎使用这种场景，Clickhouse实时数仓CPU可能面临很高的负载，大量从Clickhouse中拉取数据会加剧资源紧张导致系统query 延迟增加。

CPU/IO 资源耗尽导致的QueryFailed:
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/2024202501241832665.png)