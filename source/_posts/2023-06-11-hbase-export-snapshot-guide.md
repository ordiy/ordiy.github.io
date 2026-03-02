---
layout: post
title: Hbase export snapshot guide
categories:
  - tech
tags:
  - blog
excerpt: hbase export snapshot
date: 2023-03-20 16:58:27
---




# hbase export snapshot 

## create snapshot 

```bash
Usage: hbase [<options>] snapshot <subcommand> [<args>]
Options:
  --config DIR         Configuration direction to use. Default: ./conf
  --hosts HOSTS        Override the list in 'regionservers' file
  --auth-as-server     Authenticate to ZooKeeper using servers configuration
  --internal-classpath Skip attempting to use client facing jars (WARNING: unstable results between versions)
  --help or -h         Print this help message

Subcommands:
  create          Create a new snapshot of a table
  info            Tool for dumping snapshot information
  export          Export an existing snapshot
```


## snapshot export 
```bash
hbase org.apache.hadoop.hbase.snapshot.ExportSnapshot --help
usage: hbase org.apache.hadoop.hbase.snapshot.ExportSnapshot <options>
Options:
    --snapshot <arg>       Snapshot to restore.
    --copy-to <arg>        Remote destination hdfs://
    --copy-from <arg>      Input folder hdfs:// (default hbase.rootdir)
    --target <arg>         Target name for the snapshot.
    --no-checksum-verify   Do not verify checksum, use name+length only.
    --no-target-verify     Do not verify the integrity of the exported snapshot.
    --no-source-verify     Do not verify the source of the snapshot.
    --overwrite            Rewrite the snapshot manifest if already exists.
    --chuser <arg>         Change the owner of the files to the specified one.
    --chgroup <arg>        Change the group of the files to the specified one.
    --chmod <arg>          Change the permission of the files to the specified one.
    --mappers <arg>        Number of mappers to use during the copy (mapreduce.job.maps).
    --bandwidth <arg>      Limit bandwidth to this value in MB/second.
    --reset-ttl            Do not copy TTL for the snapshot
Examples:
  hbase snapshot export \
    --snapshot MySnapshot --copy-to hdfs://srv2:8082/hbase \
    --chuser MyUser --chgroup MyGroup --chmod 700 --mappers 16

  hbase snapshot export \
    --snapshot MySnapshot --copy-from hdfs://srv2:8082/hbase \
    --copy-to hdfs://srv1:50070/hbase

```



# 参考

- [hbase-export-snapshot-another-cluster](https://docs.cloudera.com/runtime/7.2.0/hbase-backup-dr/topics/hbase-export-snapshot-another-cluster.html?)