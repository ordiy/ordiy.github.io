
```
[dp@gznx-hbase02-node21 ~]$ hdfs fsck /hbase/data/fraud/jietiao_customized_feature/1f4d231c39f5ae36d8d7cd7cbd69796c/A/89a1a113042b4fa1a3efa8af357ad5ca_SeqId_64_
Connecting to namenode via http://gznx-hbase02-node02.jpushoa.com:50070/fsck?ugi=hdfs&path=%2Fhbase%2Fdata%2Ffraud%2Fjietiao_customized_feature%2F1f4d231c39f5ae36d8d7cd7cbd69796c%2FA%2F89a1a113042b4fa1a3efa8af357ad5ca_SeqId_64_
FSCK started by hdfs (auth:SIMPLE) from /172.18.64.49 for path /hbase/data/fraud/jietiao_customized_feature/1f4d231c39f5ae36d8d7cd7cbd69796c/A/89a1a113042b4fa1a3efa8af357ad5ca_SeqId_64_ at Fri Mar 11 15:31:54 CST 2022

/hbase/data/fraud/jietiao_customized_feature/1f4d231c39f5ae36d8d7cd7cbd69796c/A/89a1a113042b4fa1a3efa8af357ad5ca_SeqId_64_:  Replica placement policy is violated for BP-1657279700-172.18.64.12-1628675383465:blk_1079124215_5384402. Block should be additionally replicated on 2 more rack(s). Total number of racks in the cluster: 5

/hbase/data/fraud/jietiao_customized_feature/1f4d231c39f5ae36d8d7cd7cbd69796c/A/89a1a113042b4fa1a3efa8af357ad5ca_SeqId_64_: MISSING 1 blocks of total size 134217728 B.
Status: CORRUPT
 Number of data-nodes:	25
 Number of racks:		5
 Total dirs:			0
 Total symlinks:		0

Replicated Blocks:
 Total size:	2519024336 B
 Total files:	1
 Total blocks (validated):	19 (avg. block size 132580228 B)
  ********************************
  UNDER MIN REPL'D BLOCKS:	1 (5.263158 %)
  MINIMAL BLOCK REPLICATION:	1
  CORRUPT FILES:	1
  MISSING BLOCKS:	1
  MISSING SIZE:		134217728 B
  ********************************
 Minimally replicated blocks:	18 (94.73684 %)
 Over-replicated blocks:	0 (0.0 %)
 Under-replicated blocks:	0 (0.0 %)
 Mis-replicated blocks:		1 (5.263158 %)
 Default replication factor:	3
 Average block replication:	1.8947369
 Missing blocks:		1
 Corrupt blocks:		0
 Missing replicas:		0 (0.0 %)

Erasure Coded Block Groups:
 Total size:	0 B
 Total files:	0
 Total block groups (validated):	0
 Minimally erasure-coded block groups:	0
 Over-erasure-coded block groups:	0
 Under-erasure-coded block groups:	0
 Unsatisfactory placement block groups:	0
 Average block group size:	0.0
 Missing block groups:		0
 Corrupt block groups:		0
 Missing internal blocks:	0
FSCK ended at Fri Mar 11 15:31:54 CST 2022 in 2 milliseconds


The filesystem under path '/hbase/data/fraud/jietiao_customized_feature/1f4d231c39f5ae36d8d7cd7cbd69796c/A/89a1a113042b4fa1a3efa8af357ad5ca_SeqId_64_' is CORRUPT
```
