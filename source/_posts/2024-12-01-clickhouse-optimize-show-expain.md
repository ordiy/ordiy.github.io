---
title: Clickhouse Explain 进行SQL性能排查
excerpt: 使用Clickhouse Explain 进行SQL性能排查
layout: post
date: 2025-03-28 20:31:44
tags:
  - clickhouse
  - data
  - olap
categories:
  - data
---

# 问题背景
请分析以下 ClickHouse SQL 查询的性能问题并给出优化建议：
ClickHouse Version: 24.0 

**SQL query**
```sql

SELECT * FROM roi_ods.dwd_user_tags_list
 FINAL WHERE project_id = '6736140024' 
 and is_subscribed = 1 ORDER BY subscribe_ts DESC LIMIT 30000 OFFSET 30000

```
**执行信息**
- 执行时长：149.04秒
- 扫描行数：255,136,165
- 返回行数：0
- 内存使用：866.21MB

**相关表结构DDL**
```sql
-- 使用的是 Distributed + ReplicatedReplacingMergeTree 组合
-- Table: roi_ods.dwd_user_tags_list
CREATE TABLE roi_ods.dwd_user_tags_list
on cluster oci_clickhouse_cluster
AS roi_ods.dwd_user_tags_list_local  
ENGINE = Distributed('oci_clickhouse_cluster', 'roi_ods', 'dwd_user_tags_list_local', toUInt64OrDefault(project_id, toUInt64(1024)));

-- Table: roi_ods.dwd_user_tags_list_local
CREATE TABLE roi_ods.dwd_user_tags_list_local 
on cluster oci_clickhouse_cluster 
(
    `uuid` String,
    `project_id` String DEFAULT '',
    `is_install` Nullable(UInt8),
    `is_startup` Nullable(UInt8),
    `is_subscribed` Nullable(UInt8),
    `subscribe_ts` Nullable(UInt64),
    `is_uninstall` Nullable(UInt8),
    `is_unsubscribed` Nullable(UInt8),
    `tag_version` UInt32 DEFAULT 1 COMMENT 'user tag version ++ ',
    `created_at` Nullable(DateTime64(3, 'UTC')),
    `updated_at` Nullable(DateTime64(3, 'UTC')),
    `msg_event_time` DateTime64(3, 'UTC') DEFAULT now(),
    INDEX idx_project_id project_id TYPE bloom_filter() GRANULARITY 64
)
ENGINE = ReplicatedReplacingMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}', msg_event_time)
PARTITION BY toYYYYMM(msg_event_time)
ORDER BY uuid
SETTINGS index_granularity = 8192
```
**执行计划 ClickHouse Exeplain **
```
explain PLAIN SELECT * FROM roi_ods.dwd_user_tags_list FINAL WHERE project_id = '6736140024'  and is_subscribed = 1 ORDER BY subscribe_ts DESC LIMIT 30000 OFFSET 30000 ;

=== 执行计划 ===
Expression (Project names)
  Limit (preliminary LIMIT (without OFFSET))
    Sorting (Merge sorted streams after aggregation stage for ORDER BY)
      Union
        Sorting (Sorting for ORDER BY)
          Expression ((Before ORDER BY + Projection))
            Filter ((WHERE + Change column names to column identifiers))
              ReadFromMergeTree (roi_ods.dwd_user_tags_list_local)
        ReadFromRemote (Read from remote replica)



EXPLAIN PIPELINE SELECT * FROM roi_ods.dwd_user_tags_list FINAL WHERE project_id = '6736140024'  and is_subscribed = 1 ORDER BY subscribe_ts DESC LIMIT 30000 OFFSET 30000 ; 

```

```SQL 
explain AST SELECT * FROM roi_ods.dwd_user_tags_list FINAL WHERE project_id = '6736140024'  and is_subscribed = 1 ORDER BY subscribe_ts DESC LIMIT 30000 OFFSET 30000 ;

with tmp_tab AS (
    SELECT                                                       
        *    
    FROM roi_ods.dwd_user_tags_list                              
    FINAL                                                        
    WHERE (project_id = '6736140024') AND (is_subscribed = 1) 
    ORDER BY subscribe_ts DESC                                   
    LIMIT 30000, 30000           
 )
 select min(subscribe_ts) from tmp_tab 

 ```







# Clickhouse expain 


## 获取pipeline 
```js
 (Expression)                                                                                                                                                                                                                                               
 ExpressionTransform                                                                                                                                                                                                                                       
   (Limit)                                                                                                                                                                                                                                                 
   Limit                                                                                                                                                                                                                                                   
     (Sorting)                                                                                                                                                                                                                                             
     MergingSortedTransform 2 → 1                                                                                                                                                                                                                          
       (Union)                                                                                                                                                                                                                                             
         (Sorting)                                                                                                                                                                                                                                         
         MergingSortedTransform 16 → 1                                                                                                                                                                                                                     
           MergeSortingTransform × 16                                                                                                                                                                                                                      
             LimitsCheckingTransform × 16                                                                                                                                                                                                                  
               PartialSortingTransform × 16                                                                                                                                                                                                                
                 (Expression)                                                                                                                                                                                                                              
                 ExpressionTransform × 16                                                                                                                                                                                                                  
                   (Filter)                                                                                                                                                                                                                                
                   FilterTransform × 16                                                                                                                                                                                                                    
                     (ReadFromMergeTree)                                                                                                                                                                                                                   
                     ExpressionTransform × 16                                                                                                                                                                                                              
                       SelectByIndicesTransform                                                                                                                                                                                                            
                         ReplacingSorted 24 → 1                                                                                                                                                                                                            
                           FilterSortedStreamByRange × 24                                                                                                                                                                                                  
                           Description: filter values in ((U2503066053723694847237266), +inf]                                                                                                                                                              
                             ExpressionTransform × 24                                                                                                                                                                                                      
                               MergeTreeSelect(pool: ReadPoolInOrder, algorithm: InOrder) × 24 0 → 1                                                                                                                                                       
                                 SelectByIndicesTransform                                                                                                                                                                                                  
                                   ReplacingSorted 24 → 1                                                                                                                                                                                                  
                                     FilterSortedStreamByRange × 24                                                                                                                                                                                        
                                     Description: filter values in ((U2501237453357293765086292), (U2503066053723694847237266)]                                                                                                                            
                                       ExpressionTransform × 24                                                                                                                                                                                            
                                         MergeTreeSelect(pool: ReadPoolInOrder, algorithm: InOrder) × 24 0 → 1                                                                                                                                             
                                           SelectByIndicesTransform                                                                                                                                                                                        
                                             ReplacingSorted 25 → 1                                                                                                                                                                                        
                                               FilterSortedStreamByRange × 25                                                                                                                                                                              
                                               Description: filter values in ((U2412234383089819073411904), (U2501237453357293765086292)]                                                                                                                  
                                                 ExpressionTransform × 25                                                                                                                                                                                  
                                                   MergeTreeSelect(pool: ReadPoolInOrder, algorithm: InOrder) × 25 0 → 1                                                                                                                                   
                                                     SelectByIndicesTransform                                                                                                                                                                              
                                                       ReplacingSorted 24 → 1                                                                                                                                                                              
                                                         FilterSortedStreamByRange × 24                                                                                                                                                                    
                                                         Description: filter values in ((U2412137943006178807121516), (U2412234383089819073411904)]                                                                                                        
                                                           ExpressionTransform × 24                                                                                                                                                                        
                                                             MergeTreeSelect(pool: ReadPoolInOrder, algorithm: InOrder) × 24 0 → 1                                                                                                                         
                                                               SelectByIndicesTransform                                                                                                                                                                    
                                                                 ReplacingSorted 23 → 1                                                                                                                                                                    
                                                                   FilterSortedStreamByRange × 23                                                                                                                                                          
                                                                   Description: filter values in ((U2411041102665629708447056), (U2412137943006178807121516)]                                                                                              
                                                                     ExpressionTransform × 23                                                                                                                                                              
                                                                       MergeTreeSelect(pool: ReadPoolInOrder, algorithm: InOrder) × 23 0 → 1                                                                                                               
                                                                         SelectByIndicesTransform                                                                                                                                                          
                                                                           ReplacingSorted 25 → 1                                                                                                                                                          
                                                                             FilterSortedStreamByRange × 25                                                                                                                                                
                                                                             Description: filter values in ((U2410035852389628838388409), (U2411041102665629708447056)]                                                                                    
                                                                               ExpressionTransform × 25                                                                                                                                                    
                                                                                 MergeTreeSelect(pool: ReadPoolInOrder, algorithm: InOrder) × 25 0 → 1                                                                                                     
                                                                                   SelectByIndicesTransform                                                                                                                                                
                                                                                     ReplacingSorted 25 → 1                                                                                                                                                
                                                                                       FilterSortedStreamByRange × 25                                                                                                                                      
                                                                                       Description: filter values in ((U2409061212154261646480684), (U2410035852389628838388409)]                                                                          
                                                                                         ExpressionTransform × 25                                                                                                                                          
                                                                                           MergeTreeSelect(pool: ReadPoolInOrder, algorithm: InOrder) × 25 0 → 1                                                                                           
                                                                                             SelectByIndicesTransform                                                                                                                                      
                                                                                               ReplacingSorted 25 → 1                                                                                                                                      
                                                                                                 FilterSortedStreamByRange × 25                                                                                                                            
                                                                                                 Description: filter values in ((U2408118291936389413905633), (U2409061212154261646480684)]                                                                
                                                                                                   ExpressionTransform × 25                                                                                                                                
                                                                                                     MergeTreeSelect(pool: ReadPoolInOrder, algorithm: InOrder) × 25 0 → 1                                                                                 
                                                                                                       SelectByIndicesTransform                                                                                                                            
                                                                                                         ReplacingSorted 25 → 1                                                                                                                            
                                                                                                           FilterSortedStreamByRange × 25                                                                                                                  
                                                                                                           Description: filter values in ((9873455712777114), (U2408118291936389413905633)]                                                                
                                                                                                             ExpressionTransform × 25                                                                                                                      
                                                                                                               MergeTreeSelect(pool: ReadPoolInOrder, algorithm: InOrder) × 25 0 → 1                                                                       
                                                                                                                 SelectByIndicesTransform                                                                                                                  
                                                                                                                   ReplacingSorted 23 → 1                                                                                                                  
                                                                                                                     FilterSortedStreamByRange × 23                                                                                                        
                                                                                                                     Description: filter values in ((8457694112187412), (9873455712777114)]                                                                
                                                                                                                       ExpressionTransform × 23                                                                                                            
                                                                                                                         MergeTreeSelect(pool: ReadPoolInOrder, algorithm: InOrder) × 23 0 → 1                                                             
                                                                                                                           SelectByIndicesTransform                                                                                                        
                                                                                                                             ReplacingSorted 23 → 1                                                                                                        
                                                                                                                               FilterSortedStreamByRange × 23                                                                                              
                                                                                                                               Description: filter values in ((7044899349709094), (8457694112187412)]                                                      
                                                                                                                                 ExpressionTransform × 23                                                                                                  
                                                                                                                                   MergeTreeSelect(pool: ReadPoolInOrder, algorithm: InOrder) × 23 0 → 1                                                   
                                                                                                                                     SelectByIndicesTransform                                                                                              
                                                                                                                                       ReplacingSorted 23 → 1                                                                                              
                                                                                                                                         FilterSortedStreamByRange × 23                                                                                    
                                                                                                                                         Description: filter values in ((5627140852898200), (7044899349709094)]                                            
                                                                                                                                           ExpressionTransform × 23                                                                                        
                                                                                                                                             MergeTreeSelect(pool: ReadPoolInOrder, algorithm: InOrder) × 23 0 → 1                                         
                                                                                                                                               SelectByIndicesTransform                                                                                    
                                                                                                                                                 ReplacingSorted 23 → 1                                                                                    
                                                                                                                                                   FilterSortedStreamByRange × 23                                                                          
                                                                                                                                                   Description: filter values in ((4216935943029252), (5627140852898200)]                                  
                                                                                                                                                     ExpressionTransform × 23                                                                              
                                                                                                                                                       MergeTreeSelect(pool: ReadPoolInOrder, algorithm: InOrder) × 23 0 → 1                               
                                                                                                                                                         SelectByIndicesTransform                                                                          
                                                                                                                                                           ReplacingSorted 23 → 1                                                                          
                                                                                                                                                             FilterSortedStreamByRange × 23                                                                
                                                                                                                                                             Description: filter values in ((2802928268956367), (4216935943029252)]                        
                                                                                                                                                               ExpressionTransform × 23                                                                    
                                                                                                                                                                 MergeTreeSelect(pool: ReadPoolInOrder, algorithm: InOrder) × 23 0 → 1                     
                                                                                                                                                                   SelectByIndicesTransform                                                                
                                                                                                                                                                     ReplacingSorted 23 → 1                                                                
                                                                                                                                                                       FilterSortedStreamByRange × 23                                                      
                                                                                                                                                                       Description: filter values in ((1388889609290171), (2802928268956367)]              
                                                                                                                                                                         ExpressionTransform × 23                                                          
                                                                                                                                                                           MergeTreeSelect(pool: ReadPoolInOrder, algorithm: InOrder) × 23 0 → 1           
                                                                                                                                                                             SelectByIndicesTransform                                                      
                                                                                                                                                                               ReplacingSorted 23 → 1                                                      
                                                                                                                                                                                 FilterSortedStreamByRange × 23                                            
                                                                                                                                                                                 Description: filter values in (-inf, (1388889609290171)]                  
                                                                                                                                                                                   ExpressionTransform × 23                                                
                                                                                                                                                                                     MergeTreeSelect(pool: ReadPoolInOrder, algorithm: InOrder) × 23 0 → 1 

```
# 参考



https://clickhouse.com/docs/sql-reference/statements/explain