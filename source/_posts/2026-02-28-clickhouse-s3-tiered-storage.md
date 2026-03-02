---
layout: post
title: ClickHouse 分层存储实践：基于 S3 宽温分离
date: 2026-02-28 14:00:00
tags:
  - ClickHouse
  - AWS S3
excerpt: "通过 ClickHouse 原生的 XML storage_policy 配置，将不再高频查询的旧分区平滑卸载到 AWS S3，实现冷热数据分离。"
categories:
  - tech
---

随着底层流量日志的暴涨，ClickHouse 的本地磁盘(NVMe/SSD)容量很快就会面临瓶颈。为了兼顾查询性能与高昂的存储成本，ClickHouse 提供了强大的 tiered storage（分层存储）能力。

本文将演示如何利用 ClickHouse 原生的 XML storage_policy 配置，将不再属于高频查询的旧业务分区平滑卸载到 AWS S3 廉价对象存储中，实现冷热数据分离的架构。

<!-- more -->

## 1. 挂载并配置 S3 磁盘底座

首先，需要在机器或集群配置的 XML 中定义 S3 类型的 `disk`，以及连接策略 `policies`。打开配置管理目录（如 `/etc/clickhouse-server/config.d/`）：

```xml
<clickhouse>
  <storage_configuration>
    <disks>
      <!-- 定义本地热盘 -->
      <local_disk>
        <type>local</type>
        <path>/var/lib/clickhouse/data/</path>
      </local_disk>
      
      <!-- 定义 S3 冷盘 -->
      <s3_disk>
        <type>s3</type>
        <!-- 替换为你的真实 S3 Bucket -->
        <endpoint>https://your-bucket.s3.amazonaws.com/</endpoint>
        <access_key_id>YOUR_ACCESS_KEY</access_key_id>
        <secret_access_key>YOUR_SECRET_KEY</secret_access_key>
        <!-- 元数据存放的本地路径，用于保持表结构索引 -->
        <metadata_path>/var/lib/clickhouse/disks/s3_disk/</metadata_path>
      </s3_disk>
    </disks>

    <!-- 定义分层流转策略 -->
    <policies>
      <hot_to_cold>
        <volumes>
          <hot>
            <disk>local_disk</disk>
          </hot>
          <cold>
            <disk>s3_disk</disk>
          </cold>
        </volumes>
      </hot_to_cold>
    </policies>
  </storage_configuration>
</clickhouse>
```

重启 ClickHouse 节点以加载此驱动盘片。

## 2. 修改业务表的策略映射

对于需要开启分层存储的大型日志表（例如示例中的我们庞大的 `cdn_aws_cloudfront_cdn_log_v1_local` 表），直接执行 `MODIFY SETTING` 指向我们定义好的分层策略名 `hot_to_cold`。

```sql
-- 将表的底层存储结构代理迁移至分层流转模式
ALTER TABLE cdn_ods.cdn_aws_cloudfront_cdn_log_v1_local
MODIFY SETTING storage_policy = 'hot_to_cold';
```

## 3. 人工强制下沉分区 (Move Partition)

一旦策略接管，你可以设定 TTL 来实现自动下沉到 S3，也可以出于运维需要直接手动强制移动过去的冷门月份：

```sql
-- 将四月份的日志整体平替到 S3 对象存储（无需重启或中断前端查询）
ALTER TABLE cdn_ods.cdn_aws_cloudfront_cdn_log_v1_local 
MOVE PARTITION '2025-04-01' TO DISK 's3_disk';
```

在执行完这段命令后，ClickHouse 会发起内部的 `asynchronous_metrics` 任务，自动在后台将底层 `bin` / `mrk` 文件序列打包上传到 S3 存储桶，而在原本表结构所在的 `local_disk`，只留下几 KB 的轻量化查询元数据链接，完美压榨硬件性能！