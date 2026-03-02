---
layout: post
title: AWS CloudFront 与 Cloudflare 边缘日志解析对比
excerpt: "通过对比 AWS CloudFront TSV 日志与 Cloudflare Logpush JSON 的字段结构，总结两大 CDN 延迟日志的接入分析方法，以及 Cloudflare 自带 Geo 富化的优势。"
date: 2026-02-28 16:15:00
tags:
  - CDN
  - Cloudflare
  - AWS
categories:
  - tech
---

在全球出海或者广告分发的场景下，所有的流量日志往往并不直接源于 Nginx 等单点服务器，而是直接挂在拥有全球数百个散列边缘节点的国际 CDN（如 AWS CloudFront 或 Cloudflare）。直接解析边缘日志（Edge Log）才是最为纯净的流量追踪来源。

本文通过剖析两大主流公有大厂的访问日志报文段，来提取我们用以数仓分析或者反爬最核心的值点。

<!-- more -->

## 1. 结构概览：AWS CloudFront (W3C 规范系)

AWS CloudFront 产出的多为极其扁平和标准的 TSV 键值对日志形态，其非常适合直接被 ClickHouse 或者 Athena 进行结构化导入与挂载。

从其记录中，我们需要强抽取的字段有：
```sh
# 基础特征与身份
date: 2024-06-19 08:08:40          # 访问时间
c-ip: 2a03:2880:31ff:19::face:b00c # [重点]需要挂载 GeoIP2 离线库翻译或提供风控 IP 拦截
cs(User-Agent): facebookexternalhit/1.1 (+http://www.facebook.com/...) # 解析出其为 FB 爬虫包探测

# 路由与承接参数
cs-uri-stem: /1234567890/__xxxx_install_template2.html
# 从它的 GET 根路经甚至能提取归属哪个 Project_id

cs-uri-query: channel_id=4&rb_pixel_id=1136165677654596&promote_url_id=9755609322&rb_tid=2&invite_code
# [重点] 核心结算逻辑的数据：往往会带有唯一的 rb_pixel_id 标记或是推广 url ID。

```
缺点在于：在没开启复杂的 Lambda@Edge 之前，日志层级很浅。例如想直接依靠 AWS 拿到非常细的客户设备时区和地理归属，需要在日志出库后用流处理组件单独用 IP 挂载 Geo 字典补全（或者依托高阶的屏蔽报表）。


## 2. 结构概览：Cloudflare R2 传输的复杂日志集

与 AWS 追求纯粹文件块不同。Cloudflare 利用其次世代的平台能力下发到 R2 对象存储内的往往是具备高度预处理和自富化的 JSON 对象报文集！

我们分析一则标准推来的 `event-point-report`：
```json
{
  "event": "event-point-report",
  "edge_ts": 1714030056106,
  "r2_key": "prod/20240425/1714030056106-8843-21030-6226061129158527.json",
  "data": {
    "payload": {
       // Cloudflare 根据路由自己剥离拆解好的 KV 对，例如：
      "uuid": "6211299923356796",
      "channel_id": "5",
      "language": "zh-CN"
      //...
    },
    "headers": {
      // ✅ 这是 Cloudflare 区别于其他平台的一大优势！
      "cf-ipcity": "Shenzhen",            // 自带城市级的 Geo 地址富化！！！
      "cf-ipcountry": "CN",               // 免费的国家 ISO 简码
      "cf-iplatitude": "22.55590",        // 精准到小数点级别的经纬度判定，省却全部下游反查计算
      "cf-ray": "879c9c8a8c4c2f0f",       // 具有连路可溯源性的唯一 CF 魔数链路 ID
      "cf-region-code": "GD",             // 省份州码 
      "cf-timezone": "Asia/Shanghai",     // 时区判定
      "sec-ch-ua-platform": "\"Windows\"",  // 反爬指纹
      "x-real-ip": "116.24.66.120"
    }
  }
}
```

## 点评总结

* **AWS CloudFront**：极其符合原始规范，其下置逻辑非常“轻”，纯记录“谁”来了，然后留下一行以制表符相隔的足迹，你若需要分析则必须自行使用 Spark 或 Flink 搞大刀阔斧的计算。
* **Cloudflare (利用 Worker 与 Logpush)**：它是属于边缘智能网络，在访客还没有到达你的代码甚至你的机房之前。除了记录路由日志，CF 甚至帮你算好了访客当前的**所在经纬度、地理位置名、所在时区、设备反追踪信息指纹**（而且由于 CF 体系内的节点库，精准度极高）。将 CF 这套海纳的数据推送给数仓 ClickHouse (尤其是对 JSON 解析优越的引撆表)，可以说分析工程师连关联代码甚至是坐标字典都不需要备就能直出绚丽风眼图。