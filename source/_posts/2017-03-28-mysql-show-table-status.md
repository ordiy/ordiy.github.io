---
layout: post
title: MySQL show status 使用指南
categories:
  - tech
  - mysql
tags:
  - blog
  - java
  - log4j2
  - logging
date: 2017-03-28 00:00:00
excerpt:  MySQL show status 查询表的存储、格式、引擎等信息
---

### mysql show status 
`SHOW TABLE STATUS` 可以查看表/view的大量信息。 这里简述一下用法：
```
#查询数据表 状态
SHOW TABLE STATUS from dp_report_forms_data like 'tb_dp_hera_user_access_statistics' \G
```

结果：
```

Name            | tb_dp_hera_user_access_statistics
Engine          | InnoDB
Version         | 10
Row_format      | Dynamic
Rows            | 9661
Avg_row_length  | 164
Data_length     | 1589248
Max_data_length | 0
Index_length    | 1589248
Data_free       | 2097152
Auto_increment  | 240145
Create_time     | 2020-08-06 10:53:18
Update_time     | <null>
Check_time      | <null>
Collation       | utf8_general_ci
Checksum        | <null>
Create_options  |
Comment         | 用户访问统计表(总表)，按天统计

```

- Name
  表名称

- Engine
  存储引擎-storage engine

- Version
 表的.frm文件的版本号。 

- Row_format
   行的存储格式(Fixed, Dynamic, Compressed, Redundant, Compact)). 
   对于MyISAM表，Dynamic对应于myisamchk -dvv报告为打包的内容。 使用Antelope文件格式时，InnoDB表格式为Redundant或Compact，而使用Barracuda文件格式时，InnoDB表格式为Compressed或Dynamic。

- Rows
   行数。 某些存储引擎（例如MyISAM）存储准确的计数。 对于其他存储引擎，例如InnoDB，此值是一个近似值，可能与实际值相差40％至50％。 在这种情况下，请使用SELECT COUNT（*）获得准确的计数。

- Avg_row_length
   平均行长

- Data_length
  对于MyISAM，Data_length是数据文件的长度，以字节为单位。
  对于InnoDB，Data_length是为聚簇索引分配的大约空间量（以字节为单位）。 具体来说，它是聚簇索引大小（以页为单位）乘以InnoDB页大小。

- Max_data_length
  对于MyISAM，Max_data_length是数据文件的最大长度。 给定使用的数据指针大小，这是表中可以存储的数据字节总数
  不用于InnoDB

- Index_length
  对于MyISAM，Index_length是索引文件的长度，以字节为单位。
  对于InnoDB，Index_length是分配给非聚集索引的大约空间量（以字节为单位）。 具体来说，它是非聚集索引大小（以页为单位）的总和乘以InnoDB页面大小。

- Data_free 
  已分配但未使用的字节数。 
  InnoDB表报告表所属的表空间的可用空间。 对于位于共享表空间中的表，这是共享表空间的可用空间。 如果您使用多个表空间，并且表具有自己的表空间，则可用空间仅用于该表。 可用空间是指完全可用范围中的字节数减去安全裕量。 即使可用空间显示为0，只要不需要分配新的扩展盘区，也可以插入行。
  对于NDB群集，Data_free显示磁盘上为磁盘数据表或磁盘上的碎片分配但未使用的空间。 （内存中的数据资源使用情况由Data_length列报告。）
  对于分区表，此值仅是估计值，可能不是绝对正确。 在这种情况下，获取此信息的一种更准确的方法是查询INFORMATION_SCHEMA PARTITIONS表，如本示例所示：
   ```sql
   SELECT SUM(DATA_FREE)
    FROM  INFORMATION_SCHEMA.PARTITIONS
    WHERE TABLE_SCHEMA = 'mydb'
    AND   TABLE_NAME   = 'mytable';
   ```

- Auto_increment
 下一个AUTO_INCREMENT 值
- Create_time
 表的创建时间

- Update_time 
  数据文件的最后更新时间。 对于某些存储引擎，此值为NULL。 例如，InnoDB在其系统表空间中存储多个表，并且数据文件时间戳不适用。 即使在每个InnoDB表都位于单独的.ibd文件中的每表文件模式下，更改缓冲也会延迟对数据文件的写入，因此文件修改时间与上一次插入，更新或删除的时间不同。 对于MyISAM，使用数据文件时间戳。 但是，在Windows上，时间戳不会通过更新进行更新，因此该值不准确。
  Update_time显示对未分区的InnoDB表执行的最后一次UPDATE，INSERT或DELETE的时间戳记值。 对于MVCC，时间戳记值反映了COMMIT时间，该时间被视为最后更新时间。 重新启动服务器或从InnoDB数据字典高速缓存中清除表时，时间戳记不会保留。
  Update_time列还显示分区的InnoDB表的此信息。

- Check_time
  上次检查表的时间。 并非所有存储引擎这次都更新，在这种情况下，该值始终为NULL。对于分区的InnoDB表，Check_time始终为NULL。
  对于分区的InnoDB表，Check_time始终为NULL。

- TABLE_COLLATION
  该表的默认排序规则。 输出没有显式列出表的默认字符集，但是排序规则名称以字符集名称开头。


- Create_options 
  与CREATE TABLE一起使用的其他选项,查阅(partition_options)[https://dev.mysql.com/doc/refman/5.7/en/create-table.html#create-table-partitioning]
  Create_options显示已分区表的分区。
  Create_options显示在创建或更改每表文件表空间时指定的ENCRYPTION选项。
  创建禁用了严格模式的表时，如果不支持指定的行格式，则使用存储引擎的默认行格式。 该表的实际行格式在Row_format列中报告。 Create_options显示在CREATE TABLE语句中指定的行格式。
  更改表的存储引擎时，不适用于新存储引擎的表选项将保留在表定义中，以便在必要时将具有其先前定义的选项的表恢复到原始存储引擎。 Create_options可能显示保留的选项。

- TABLE_COMMENT
  表的备注说明信息
  

##  INFORMATION_SCHEMA 
INFORMATION_SCHEMA 与show tables的信息有一些相同，重点是表示`information about tables in databases`. 用法：

```

select * from INFORMATION_SCHEMA.TABLES WHERE table_schema = 'db_name' AND table_name LIKE 'tb_dp_hera_user_access_statistics' \G

```
Result:
```
TABLE_CATALOG   | def
TABLE_SCHEMA    | dp_report_forms_data
TABLE_NAME      | tb_dp_hera_user_access_statistics
TABLE_TYPE      | BASE TABLE
ENGINE          | InnoDB
VERSION         | 10
ROW_FORMAT      | Dynamic
TABLE_ROWS      | 9661
AVG_ROW_LENGTH  | 164
DATA_LENGTH     | 1589248
MAX_DATA_LENGTH | 0
INDEX_LENGTH    | 1589248
DATA_FREE       | 2097152
AUTO_INCREMENT  | 240145
CREATE_TIME     | 2020-08-06 10:53:18
UPDATE_TIME     | <null>
CHECK_TIME      | <null>
TABLE_COLLATION | utf8_general_ci
CHECKSUM        | <null>
CREATE_OPTIONS  |
TABLE_COMMENT   | 用户访问统计表(总表)，按天统计
```
- TABLE_TYPE
表格的BASE TABLE，视图的VIEW或INFORMATION_SCHEMA表的SYSTEM VIEW。 

### 参考
[mysql show table statsu](https://dev.mysql.com/doc/refman/5.7/en/show-table-status.html）
