---
layout: post
title: Bash split + xargs 并行处理 ClickHouse 批量数据更新
excerpt: "将海量 ID 文件用 split 切分后，通过 xargs 并行分发给 clickhouse-client 执行，是一种安全、可控的大批量补丁方法。"
date: 2026-02-28 15:00:00
tags:
  - Bash
  - ClickHouse
categories:
  - tech
---

当我们在进行海量用户级别的刷库和矫正处理时，有时候往往只手握一个包含了几百万主键 UUID 和数据的超大文件，如果我们采用单一进程逐行或者利用 SQL 一把梭执行（比如复杂的 OPTIMIZE 或 UPDATE 操作），单线程必定成为性能噩梦并引发各种 Timeout。

本文记录了利用 Linux 下强大的 `split` 与 `xargs` 结合 `clickhouse-client` 来优雅执行十万级数据打靶分片更新的自动化小技巧。

<!-- more -->

## 1. 思路与核心命题

背景：在 `2025-02-06` 发现有一批遗留未处理透彻的数据，我们先利用原有的过滤 SQL 大规模捞取所有需要涉及处理的名单（id 列表或者明细记录文本）。随后由于执行引擎对超大文件文本或者过多查询的抵触配置限制，我们需要先切分为按包管理，分别派送并最终强制压实数据区。

## 2. 自动化落库脚手架全貌

```bash
# 1. 建立操作流水线沙盒
rm -rf 250206
mkdir 250206
cd 250206

# 2. 从上一级抓取统一的处理物料
cp ../query-sql.sql ./
cp ../handle-file.sh ./

# 基于 sed 进行针对日期的自动化替换
sed -i 's/20250209/20250206/g' handle-file.sh
sed -i 's/2025\-02\-12/2025\-02\-06/g' query-sql.sql

# 给核心驱动装弹
sudo chmod +x handle-file.sh

# 3. 第一步打靶：通过命令执行捞取所涉及的超大记录 ID：
clickhouse-client -h ck-host --port 9000 -u default  --database roi_ods \
--queries-file ./query-sql.sql > all_id_0206.txt

# 4. 【核心技能点：并行拆分与分发处理】
# 将产生的全量文本按每 2000 行切割成零碎文件并以前缀 p_0206_ 依次标名
split -l 2000 all_id_0206.txt p0206_

# find 搭配高阶 xargs：
# 将刚切割的小破块喂给包含特定处理逻辑（往往是各种清洗、Update 动作）的执行外壳执行 
find . -type f -name "p0206*" -print0 | xargs -0 -I {} ./handle-file.sh {}

# 5. 最后一道关卡：清理内存残影，促成底层引擎快速合拢段文件（Merge）并合并
# 为了尽快使得之前的更新对于外源可读甚至物理落盘：
clickhouse-client -h ck-host --port 9000 -u default  --database roi_ods \
-q "OPTIMIZE TABLE roi_ods.pwa_event_point_log_local on cluster oci_ck_cluster PARTITION '20250206' FINAL ;"
```

## 总结
由于我们把单体上百万行压测级的任务拆作了粒度较小的单元（2000 行），极大缓冲了内存锁的压力和客户端解析超时。在配合 `xargs -P` 后，甚至可以实现手动开启几线程极速并行跑批（前提是在 `handle-file.sh` 的逻辑内部并不相互冲突！），非常适合处理补丁或临时性的数据兜底。最后一步搭配的 `OPTIMIZE ... FINAL` 是合并重生的最后一环，只有这么做才意味着真正的结束和干净的数据态诞生。