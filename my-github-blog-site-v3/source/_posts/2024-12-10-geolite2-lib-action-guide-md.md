---
title:  FlinkJob GeoLite2 Guide
date: 2024-12-10 17:51:37
categories:
  - Data
tags:
  - Flink
  - ETL
  - IP2GeoInfo
excerpt: Flink 使用GeoLite2实时解析IP的Geolocation Info.
layout: post
---

# GeoLite2 

GeoLite 离线文件下载地址:
```
https://github.com/P3TERX/GeoLite.mmdb

# GeoLite2-ASN.mmdb
# GeoLite2-City.mmdb
# GeoLite2-Country.mmdb
```

## Country Reponse data  说明
```json 
{
   "continent":{
      "code":"NA",
      "geoname_id":6255149,
      "names":{
      }
   },
   "country":{
      "geoname_id":6252001,
      "is_in_european_union":false,
      "iso_code":"US",
      "names":{
      }
   },
   "maxmind":{
      
   },
   "registered_country":{
      "geoname_id":6252001,
      "is_in_european_union":false,
      "iso_code":"US",
      "names":{
      }
   },
   "represented_country":{
      "is_in_european_union":false
   },
   "traits":{
      "ip_address":"128.101.101.101",
      "is_anonymous":false,
      "is_anonymous_proxy":false,
      "is_anonymous_vpn":false,
      "is_anycast":false,
      "is_hosting_provider":false,
      "is_legitimate_proxy":false,
      "is_public_proxy":false,
      "is_residential_proxy":false,
      "is_satellite_provider":false,
      "is_tor_exit_node":false,
      "network":"128.101.0.0/16"
   }
}

```

## Geo City Reponse 
```json 
{
  "continent": {
    "code": "NA",
    "geoname_id": 123456,
    "names": {
    }
  },
  "country": {
    "geoname_id": 6252001,
    "is_in_european_union": false,
    "iso_code": "US",
    "names": {
    }
  },
  "maxmind": {
    "queries_remaining": 54321
  },
  "registered_country": {
    "geoname_id": 6252001,
    "is_in_european_union": true,
    "iso_code": "US",
    "names": {
    }
  },
  "represented_country": {
    "geoname_id": 6252001,
    "is_in_european_union": true,
    "iso_code": "US",
    "names": {
    },
    "type": "military"
  },
  "traits": {
    "ip_address": "1.2.3.4",
    "is_anycast": true,
    "network": "1.2.3.0/24",
    "autonomous_system_number": 1239,
    "autonomous_system_organization": "Linkem IR WiMax Network",
    "connection_type": "Cable/DSL",
    "domain": "example.com",
    "isp": "Linkem spa",
    "mobile_country_code": "310",
    "mobile_network_code": "004",
    "organization": "Linkem IR WiMax Network"
  },
  "city": {
    "geoname_id": 54321,
    "names": {
      "en": "Los Angeles"
    }
  },
  "location": {
    "accuracy_radius": 20,
    "latitude": 37.6293,
    "longitude": -122.1163,
    "metro_code": 807,
    "time_zone": "America/Los_Angeles"
  },
  "postal": {
    "code": "90001"
  },
  "subdivisions": [
    {
      "geoname_id": 5332921,
      "iso_code": "CA",
      "names": {
        "en": "California"
      }
    }
  ]
}
```

## GeoLite2 ISP 字段信息

```js

network,isp,organization,autonomous_system_number,autonomous_system_organization,mobile_country_code,mobile_network_code
2001:1700::/27,,,6730,"Sunrise Communications AG",,

```

# GetLite2 数据读取
##  java read demo 
https://github.com/maxmind/GeoIP2-java

## IPGeoinfo API servcie 

个人使用spring-boot实现的ip-geo-info servcie, 源代码:

https://github.com/ordiy/my-public-repository-collect/tree/main/java-api-service-ip-to-geo-info

特点：
 - 定义异步原子刷新GeoLite2 databaseSet(高QPS场景下 不会因为IP库更新出现 error)
 - 引入了guava load cache 提高缓存加载效率，同时使用cache提高服务QPS
 - 高性能高响应速度：4C8G instance 可实现 20K+ QPS 
 - repsonse 简单，可以快速用于FlinkSQL UDF 


# 在Flink 中使用


## Flink UDF 使用

```java
  // tabEnv 定义UDF  URL 
        String urlConfigIpGeoInfo = parameterTool.get("url_config.ip_geo_info_server", "http://127.0.0.1:18901/data_v1/ip_geo_info/");
        MyIP2GeoInfoUDF myIP2GeoInfoUDF = new MyIP2GeoInfoUDF(urlConfigIpGeoInfo);
        tableEnv.createTemporaryFunction("ip_geo_info", myIP2GeoInfoUDF);

```

```java
        
// UDF IpGeoInfo        
import org.apache.flink.shaded.jackson2.com.fasterxml.jackson.databind.JsonNode;
import org.apache.flink.shaded.jackson2.com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.flink.table.annotation.DataTypeHint;
import org.apache.flink.table.annotation.FunctionHint;
import org.apache.flink.table.functions.FunctionContext;
import org.apache.flink.table.functions.ScalarFunction;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.HashMap;
import java.util.Map;

import org.apache.flink.types.Row;

@FunctionHint(
        output = @DataTypeHint("ROW<c_lat DOUBLE, c_lan DOUBLE, c_country STRING, c_geokey STRING>")
)
public class MyIP2GeoInfoUDF extends ScalarFunction {
    private static final ObjectMapper mapper = new ObjectMapper();
    private final Map<String, Row> cache = new HashMap<>();
    private  String host_url ;


    public MyIP2GeoInfoUDF(String hostUrl) {
        this.host_url = hostUrl;
    }

    @Override
    public void open(FunctionContext context) throws Exception {
        super.open(context);
    }

    public Row eval(String ip) {
        if (ip == null || ip.equals("-")) {
            return Row.of(0.0, 0.0, "", "");
        }

        if (cache.containsKey(ip)) {
            return cache.get(ip);
        }

        HttpURLConnection conn = null;
        try {
            String urlString = host_url + ip;
            URL url = new URL(urlString);
            conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("GET");
            conn.setConnectTimeout(5000);
            conn.setReadTimeout(5000);

            int responseCode = conn.getResponseCode();
            if (responseCode == HttpURLConnection.HTTP_OK) {
                BufferedReader in = new BufferedReader(
                        new InputStreamReader(conn.getInputStream()));
                StringBuilder response = new StringBuilder();
                String inputLine;
                while ((inputLine = in.readLine()) != null) {
                    response.append(inputLine);
                }
                in.close();

                JsonNode jsonNode = mapper.readTree(response.toString());
                Row result = Row.of(
                        jsonNode.get("lat").asDouble(),
                        jsonNode.get("lon").asDouble(),
                        jsonNode.get("country_code").asText(),
                        jsonNode.get("geo_id").asText()
                );
                cache.put(ip, result);
                return result;
            } else {
                Row error = Row.of(0.0, 0.0, "Error: HTTP " + responseCode, "");
                cache.put(ip, error);
                return error;
            }
        } catch (Exception e) {
            Row error = Row.of(0.0, 0.0, "Error: " + e.getMessage(), "");
            cache.put(ip, error);
            return error;
        } finally {
            if (conn != null) {
                conn.disconnect();
            }
        }
    }
}
```

## 将GeoLite2 

# 参考

https://dev.maxmind.com/geoip/docs/web-services/responses


