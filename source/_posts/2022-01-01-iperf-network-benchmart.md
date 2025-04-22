---
layout: post
title: iPerf3 测试网络带宽-benchmark test 
categories:
  - tech
tags:
  - blog
  - i/o
  - iperf
  - linux
  - network
date: 2022-01-01 18:45:06
excerpt: iPerf3 工具测试TCP/UDP 对网络带宽进行基准测试。
---

# iPerf 工具
iPerf-主动测量IP网络上最大可实现带宽的工具,支持TCP, UDP, SCTP with IPv4 and IPv6。

> iPerf3 is a tool for active measurements of the maximum achievable bandwidth on IP networks. It supports tuning of various parameters related to timing, buffers > and protocols (TCP, UDP, SCTP with IPv4 and IPv6). For each test it reports the bandwidth, loss, and other parameters. This is a new implementation that shares >no code with the original iPerf and also is not backwards compatible. iPerf was orginally developed by NLANR/DAST. iPerf3 is principally developed by ESnet / >Lawrence Berkeley National Laboratory. It is released under a three-clause BSD license.


# 网络带宽测试工具-iperf3

## TCP max bandwidth test 

```shell
# server  
yum install iperf3 -y 

# start iperf3 server 
iperf3 -s -p 8443
```

client start 
```shell
iperf3 -Z -c 192.168.0.68 -p 8443

[ ID] Interval           Transfer     Bitrate
[  5]   0.00-1.00   sec  2.33 MBytes  19.5 Mbits/sec
[  5]   1.00-2.00   sec  1.13 MBytes  9.49 Mbits/sec
[  5]   2.00-3.00   sec  1.41 MBytes  11.8 Mbits/sec
[  5]   3.00-4.00   sec  1.48 MBytes  12.4 Mbits/sec
[  5]   4.00-5.00   sec  1.85 MBytes  15.5 Mbits/sec
[  5]   5.00-6.00   sec  1.81 MBytes  15.2 Mbits/sec
[  5]   6.00-7.00   sec  1.78 MBytes  14.9 Mbits/sec
[  5]   7.00-8.00   sec  1.90 MBytes  15.9 Mbits/sec
[  5]   8.00-9.00   sec  1.86 MBytes  15.6 Mbits/sec
[  5]   9.00-10.00  sec  1.71 MBytes  14.4 Mbits/sec
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate
[  5]   0.00-10.00  sec  17.3 MBytes  14.5 Mbits/sec                  sender
[  5]   0.00-10.06  sec  17.2 MBytes  14.3 Mbits/sec                  receiver
```
单位换算：
*Mbits/sec*  M比特(位)  = MBytes M字节  /  8 

## UDP max bandwidth test 
```shell
# server 
iperf3 -s -p 8443
```

```shell
# client 测试
iperf3 -Z -u -c 127.0.0.1  -b 10g -t 60 -p 8443

Connecting to host 127.0.0.1, port 8443
[  5] local 127.0.0.1 port 59316 connected to 127.0.0.1 port 8443
[ ID] Interval           Transfer     Bitrate         Total Datagrams
[  5]   0.00-1.00   sec   119 MBytes   999 Mbits/sec  5706
[  5]   1.00-2.00   sec   119 MBytes  1.00 Gbits/sec  5711
[  5]   2.00-3.00   sec   119 MBytes  1.00 Gbits/sec  5711
[  5]   3.00-4.00   sec   119 MBytes  1.00 Gbits/sec  5711
[  5]   4.00-5.00   sec   119 MBytes  1.00 Gbits/sec  5711
[  5]   5.00-6.00   sec   119 MBytes  1.00 Gbits/sec  5711
[  5]   6.00-7.00   sec   119 MBytes  1.00 Gbits/sec  5711
[  5]   6.00-7.00   sec   119 MBytes  1.00 Gbits/sec  5711
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  5]   0.00-7.00   sec   902 MBytes  1.08 Gbits/sec  0.000 ms  0/43204 (0%)  sender
[  5]   0.00-7.00   sec  0.00 Bytes  0.00 bits/sec  0.000 ms  0/0 (0%)  receiver
iperf3: error - the server has terminated
```
  > 注意防火墙是否对UDP 协议放行。

# 参考
- [iperf doc](https://iperf.fr/iperf-download.php)