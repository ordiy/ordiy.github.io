---
title:  Cloud上ARM CPU的调研及和几点思考
excerpt: 随着Apple在ARM CPU替代Intel CPU的取得的巨大成功后，对ARM在云市场上大规模应用和部署是否也可行？。总体来看，ARM CPU在成本、灵活性和功耗上，相比X86CPU都有明显的优势。本文以Ampera ARM CPU为代表，简单分析其技术、性能测试和应用场景。
layout: post
date: 2025-04-27 11:06:31
tags:
 - vm
 - OCI
 - AWS
 - benchmark
 - ARM
 - CPU
categories: 
 - tech
---

# ARM CPU on cloud 
目前云厂商大规模部署基于ARM CPU的服务器的典型产品:
- AWS Graviton 
- Azure cobalt 100 
- Google Cloud TPU
独立的第三方厂商AmpereComputing(已经可以规大规模出货)。（服务器成本在IDC建设中大约占到60%-75%，电力成本在IDC运营期间占50%——60%左右， 云厂商使用ARM CPU服务器的高密度部署/低功耗，可能在未来云市场中会有更大市场份额）。

# 主要的ARM CPU基本信息
## OCI Ampere A1 
OCI Ampere A1 采用 AmpereComputing的 `altra` ARM 机器（基于ARM N1 架构，最大核心数80核）

```shell
# vm shap 与 信息
VM.Standard.A1.Flex	 --> (OCPU is 1 core of an Altra processor)   7nm

```
- 配置参数：

![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/2024/202504271112180.png)

- Altra 芯片架构（ARMV8 架构 +  N1技术 + 自研扩展技术）

![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/2024/202504271113033.png)

- AmpereComputing 白皮书资料
[AmpereOne_Efficiency_White_Paper_3bc51280f9.pdf](https://amperecomputing.com/assets/AmpereOne_Efficiency_White_Paper_3bc51280f9.pdf)

[Altra CPU](https://amperecomputing.com/assets/Altra_Rev_A1_DS_v1_50_20240130_3375c3dec5_1c5d4604fa.pdf)

Ampere Computing A1 lscpu info:
```js
Architecture:             aarch64
  CPU op-mode(s):         32-bit, 64-bit
  Byte Order:             Little Endian
CPU(s):                   12
  On-line CPU(s) list:    0-11
Vendor ID:                ARM
  Model name:             Neoverse-N1
    Model:                1
    Thread(s) per core:   1
    Core(s) per socket:   12
    Socket(s):            1
    Stepping:             r3p1
    BogoMIPS:             50.00
    Flags:                fp asimd evtstrm aes pmull sha1 sha2 crc32 atomics fphp asimdhp cpuid asimdrdm lrcpc dcpop asimddp ssbs
NUMA:
  NUMA node(s):           1
  NUMA node0 CPU(s):      0-11
Vulnerabilities:
  Gather data sampling:   Not affected
  Itlb multihit:          Not affected
  L1tf:                   Not affected
  Mds:                    Not affected
  Meltdown:               Not affected
  Mmio stale data:        Not affected
  Reg file data sampling: Not affected
  Retbleed:               Not affected
  Spec rstack overflow:   Not affected
  Spec store bypass:      Mitigation; Speculative Store Bypass disabled via prctl
  Spectre v1:             Mitigation; __user pointer sanitization
  Spectre v2:             Mitigation; CSV2, BHB
  Srbds:                  Not affected
  Tsx async abort:        Not affected

```

## Ampere A2 CPU info 
OCI ARM A2采用 AmpereComputing的 `AmpereOne` ARM CPU服务器（基于ARM N2 架构，最大核心数156核）
```js
ARMv8.6+ 
TSMC 5 nm FinFET
AmpereOne  
Consistent Freq up to 3.7 GHz​

VM.Standard.A1.Flex	 --> (1oCPU is 2 core of  core processor)   5nm
DDR5 
```

A2 lscpu info:
```js
Architecture:             aarch64
  CPU op-mode(s):         64-bit
  Byte Order:             Little Endian
CPU(s):                   12
  On-line CPU(s) list:    0-11
Vendor ID:                Ampere
  Model name:             Ampere-1
    Model:                1
    Thread(s) per core:   1
    Core(s) per socket:   12
    Socket(s):            1
    Stepping:             0x0
    BogoMIPS:             2000.00
    Flags:                fp asimd evtstrm aes pmull sha1 sha2 crc32 atomics fphp asimdhp cpuid asimdrdm jscvt fcma lrcpc dcpop sha3 asimddp sha512 asimdfhm dit uscat ilrcpc flagm ssbs sb pac
                          a pacg dcpodp flagm2 frint i8mm bf16 rng bti ecv
NUMA:
  NUMA node(s):           1
  NUMA node0 CPU(s):      0-11
Vulnerabilities:
  Gather data sampling:   Not affected
  Itlb multihit:          Not affected
  L1tf:                   Not affected
  Mds:                    Not affected
  Meltdown:               Not affected
  Mmio stale data:        Not affected
  Reg file data sampling: Not affected
  Retbleed:               Not affected
  Spec rstack overflow:   Not affected
  Spec store bypass:      Mitigation; Speculative Store Bypass disabled via prctl
  Spectre v1:             Mitigation; __user pointer sanitization
  Spectre v2:             Mitigation; CSV2, BHB
  Srbds:                  Not affected
  Tsx async abort:        Not affected

```

## AWS Graviton ARM CPU 系列
AWS Graviton ARM CPU 目前主要有 Graviton2(X6g系列) ， Graviton3（X7g系列,最大64Core）,Graviton3（X8g系列,最大96Core）.
### AWS Graviton 2 info 
 AWS Graviton 2 CPU info:
```js x
 Architecture:             aarch64
  CPU op-mode(s):         32-bit, 64-bit
  Byte Order:             Little Endian
CPU(s):                   16
  On-line CPU(s) list:    0-15
Vendor ID:                ARM
  Model name:             Neoverse-N1
    Model:                1
    Thread(s) per core:   1
    Core(s) per socket:   16
    Socket(s):            1
    Stepping:             r3p1
    BogoMIPS:             243.75
    Flags:                fp asimd evtstrm aes pmull sha1 sha2 crc32 atomics fphp asimdhp cpuid asimdrdm lrcpc dcpop asimddp ssbs
Caches (sum of all):
  L1d:                    1 MiB (16 instances)
  L1i:                    1 MiB (16 instances)
  L2:                     16 MiB (16 instances)
  L3:                     32 MiB (1 instance)
NUMA:
  NUMA node(s):           1
  NUMA node0 CPU(s):      0-15
Vulnerabilities:
  Gather data sampling:   Not affected
  Itlb multihit:          Not affected
  L1tf:                   Not affected
  Mds:                    Not affected
  Meltdown:               Not affected
  Mmio stale data:        Not affected
  Reg file data sampling: Not affected
  Retbleed:               Not affected
  Spec rstack overflow:   Not affected
  Spec store bypass:      Mitigation; Speculative Store Bypass disabled via prctl
  Spectre v1:             Mitigation; __user pointer sanitization
  Spectre v2:             Mitigation; CSV2, BHB
  Srbds:                  Not affected
  Tsx async abort:        Not affected
  
```

### AWS Graviton 3 info

AWS Graviton 3 lscpu info:
```js
Architecture:             aarch64
  CPU op-mode(s):         32-bit, 64-bit
  Byte Order:             Little Endian
CPU(s):                   48
  On-line CPU(s) list:    0-47
Vendor ID:                ARM
  BIOS Vendor ID:         AWS
  Model name:             Neoverse-V1
    BIOS Model name:      AWS Graviton3 AWS Graviton3 CPU @ 2.6GHz
    BIOS CPU family:      257
    Model:                1
    Thread(s) per core:   1
    Core(s) per socket:   48
    Socket(s):            1
    Stepping:             r1p1
    BogoMIPS:             2100.00
    Flags:                fp asimd evtstrm aes pmull sha1 sha2 crc32 atomics fphp asimdhp cpuid asimdrdm jscvt fcma lrcpc dcpop sha3 sm3 sm4 asimddp sha512 sve asimdfhm dit uscat ilrcpc flagm
                           ssbs paca pacg dcpodp svei8mm svebf16 i8mm bf16 dgh rng
Caches (sum of all):
  L1d:                    3 MiB (48 instances)
  L1i:                    3 MiB (48 instances)
  L2:                     48 MiB (48 instances)
  L3:                     32 MiB (1 instance)
NUMA:
  NUMA node(s):           1
  NUMA node0 CPU(s):      0-47
Vulnerabilities:
  Gather data sampling:   Not affected
  Itlb multihit:          Not affected
  L1tf:                   Not affected
  Mds:                    Not affected
  Meltdown:               Not affected
  Mmio stale data:        Not affected
  Reg file data sampling: Not affected
  Retbleed:               Not affected
  Spec rstack overflow:   Not affected
  Spec store bypass:      Mitigation; Speculative Store Bypass disabled via prctl
  Spectre v1:             Mitigation; __user pointer sanitization
  Spectre v2:             Mitigation; CSV2, BHB
  Srbds:                  Not affected
  Tsx async abort:        Not affected
```
* 支持的指令集和Caches比G2都增加了

## Google TPU
一个特点是：添加了VPU单元，在处理CNN, Transformer模型上做了很多优化
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/2024/202507281415412.png)


## 对比组 AMD X86 (AMD EPYC 7J13)
```js
Architecture:             x86_64
  CPU op-mode(s):         32-bit, 64-bit
  Address sizes:          40 bits physical, 48 bits virtual
  Byte Order:             Little Endian
CPU(s):                   16
  On-line CPU(s) list:    0-15
Vendor ID:                AuthenticAMD
  Model name:             AMD EPYC 7J13 64-Core Processor
    CPU family:           25
    Model:                1
    Thread(s) per core:   2
    Core(s) per socket:   8
    Socket(s):            1
    Stepping:             1
    BogoMIPS:             4890.80
    Flags:                fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm rep_good nopl cpuid
                           extd_apicid tsc_known_freq pni pclmulqdq ssse3 fma cx16 pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand hypervisor lahf_lm cmp_l
                          egacy svm cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw topoext perfctr_core ssbd ibrs ibpb stibp vmmcall fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid
                          rdseed adx smap clflushopt clwb sha_ni xsaveopt xsavec xgetbv1 xsaves clzero xsaveerptr wbnoinvd arat npt nrip_save umip pku ospke vaes vpclmulqdq rdpid fsrm arch_ca
                          pabilities
Virtualization features:
  Virtualization:         AMD-V
  Hypervisor vendor:      KVM
  Virtualization type:    full
Caches (sum of all):
  L1d:                    512 KiB (8 instances)
  L1i:                    512 KiB (8 instances)
  L2:                     4 MiB (8 instances)
  L3:                     16 MiB (1 instance)
NUMA:
  NUMA node(s):           1
  NUMA node0 CPU(s):      0-15
Vulnerabilities:
  Gather data sampling:   Not affected
  Itlb multihit:          Not affected
  L1tf:                   Not affected
  Mds:                    Not affected
  Meltdown:               Not affected
  Mmio stale data:        Not affected
  Reg file data sampling: Not affected
  Retbleed:               Not affected
  Spec rstack overflow:   Vulnerable: Safe RET, no microcode
  Spec store bypass:      Mitigation; Speculative Store Bypass disabled via prctl
  Spectre v1:             Mitigation; usercopy/swapgs barriers and __user pointer sanitization
  Spectre v2:             Mitigation; Retpolines; IBPB conditional; IBRS_FW; STIBP always-on; RSB filling; PBRSB-eIBRS Not affected; BHI Not affected
  Srbds:                  Not affected
  Tsx async abort:        Not affected

```


# 各云厂商AMR CPU性能测试


## 测试结果
以典型的计算素数场景，测试ARM CPU在多核环境下的并行处理能力(内存+CPU整体并行能力）。
```js
sudo apt install sysbench

sysbench cpu --threads=3 run

```
|CPU |E4（ AMD AMD EPYC 7J13)  X86 |Ampere A2 ARM  | Ampere A1 ARM | AWS G3 ARM |AWS G2 ARM|
|:---|:---|:---|:---|:---|:---|
|CPU event per second | 12491.67 | 2321.38 | 10046.69 | 9047.54 |5863.11 |



## 详细的测试信息
### A1 sysbench cpu log
```js
Prime numbers limit: 10000

Initializing worker threads...

Threads started!

CPU speed:
    events per second: 10095.26

General statistics:
    total time:                          10.0003s
    total number of events:              100977

Latency (ms):
         min:                                    0.30
         avg:                                    0.30
         max:                                    0.46
         95th percentile:                        0.30
         sum:                                29979.11

Threads fairness:
    events (avg/stddev):           33659.0000/5.10
    execution time (avg/stddev):   9.9930/0.00

```

### A2 sysbench cpu log
```js
Prime numbers limit: 10000

Initializing worker threads...

Threads started!

CPU speed:
    events per second:  2321.38

General statistics:
    total time:                          10.0011s
    total number of events:              23223

Latency (ms):
         min:                                    1.28
         avg:                                    1.29
         max:                                    1.58
         95th percentile:                        1.30
         sum:                                29995.06

Threads fairness:
    events (avg/stddev):           7741.0000/4.32
    execution time (avg/stddev):   9.9984/0.00
```

### AWS G3 sysbench cpu log

```js
#AWS c7g
Prime numbers limit: 10000

Initializing worker threads...

Threads started!

CPU speed:
    events per second:  9047.54

General statistics:
    total time:                          10.0002s
    total number of events:              90489

Latency (ms):
         min:                                    0.33
         avg:                                    0.33
         max:                                    0.44
         95th percentile:                        0.34
         sum:                                29981.87

Threads fairness:
    events (avg/stddev):           30163.0000/16.39
    execution time (avg/stddev):   9.9940/0.00
    
```
### AWS G2 sysbench cpu log
```js
sysbench 1.0.20 (using system LuaJIT 2.1.0-beta3)

Running the test with following options:
Number of threads: 2
Initializing random number generator from current time


Prime numbers limit: 10000

Initializing worker threads...

Threads started!

CPU speed:
    events per second:  5863.11

General statistics:
    total time:                          10.0004s
    total number of events:              58643

Latency (ms):
         min:                                    0.33
         avg:                                    0.34
         max:                                    0.46
         95th percentile:                        0.35
         sum:                                19988.03

Threads fairness:
    events (avg/stddev):           29321.5000/424.50
    execution time (avg/stddev):   9.9940/0.00
```

**部分机器测试得到的`avg/stddev`的标准方差波动较大， 我猜可能是但是机器还有其它高负载的任务在运行，导致`avg/stddev`可能不能完全反映波动性。**

## CPU测试 AES 加密性能

```
taskset 0x10 openssl speed -evp aes-256-cbc
```
### 测试结果

|AMD | E4	| A2 |	A1 | AWS C7g| |
|:---|:---|:---|:---|:---|:---|
|16k	  | 1024611.67	| 1493336.06	 | 1692734.81 |	1464937.13|
|与A2的比值	 | 69%	   | 100%	     |     113%     |	98%				|
|1k	    | 1024097.28	 | 1468620.12	 | 1658306.22 |	1453796.01 |
|与A2的比值	| 70%	 | 100% |	113% |	99% |


### 测试日志
```
===node1 X86 

type             16 bytes     64 bytes    256 bytes   1024 bytes   8192 bytes  16384 bytes
AES-256-CBC     873110.44k   983650.90k  1015745.54k  1024097.28k  1025736.70k  1024611.67k

node3 A2
====
type             16 bytes     64 bytes    256 bytes   1024 bytes   8192 bytes  16384 bytes
AES-256-CBC     663972.72k  1166063.94k  1396305.32k  1468620.12k  1491359.06k  1493336.06k

node6 A1
type             16 bytes     64 bytes    256 bytes   1024 bytes   8192 bytes  16384 bytes
AES-256-CBC     690535.32k  1258101.72k  1564840.28k  1658306.22k  1696467.63k  1692734.81k

AWS C7g:

The 'numbers' are in 1000s of bytes per second processed.
type             16 bytes     64 bytes    256 bytes   1024 bytes   8192 bytes  16384 bytes
AES-256-CBC    1022386.66k  1331757.89k  1434859.26k  1453796.01k  1464814.25k  1464937.13k

```

##  CPU 压缩/解压数据包测试

### 测试结果
CPU单核解压性能差距很小。
在压缩性能上有30%左右的性能差异（X86表现更好，这可能和指令集优化有关）

| 类别|X86 AMD	 | A2	 | A1 |	C7g|
|:--- |:--- |:--- |:--- |:---|
| 压缩性能   | 5385 |	3736 |	4057 | 4419  |
|  差距     | 0	   | -31%	| -25% |	-18%  |

### 测试数据
```js
# G3 AWS C7g  

1T CPU Freq (MHz):  2578  2581  2582  2579  2582  2581  2581

RAM size:   31491 MB,  # CPU hardware threads:  16
RAM usage:    437 MB,  # Benchmark threads:      1

                       Compressing  |                  Decompressing
Dict     Speed Usage    R/U Rating  |      Speed Usage    R/U Rating
         KiB/s     %   MIPS   MIPS  |      KiB/s     %   MIPS   MIPS

22:       4619   100   4513   4494  |      53972   100   4608   4608
23:       4191   100   4270   4271  |      52899   100   4574   4579
24:       3914   100   4201   4209  |      51663   100   4538   4535
25:       3667   100   4188   4187  |      50200   100   4468   4468
----------------------------------  | ------------------------------
Avr:      4098   100   4293   4290  |      52184   100   4547   4548
Tot:             100   4420   4419

```
- Aepere A1

```js

7z b -mmt1

7-Zip 23.01 (arm64) : Copyright (c) 1999-2023 Igor Pavlov : 2023-06-20
 64-bit arm_v:8 locale=C.UTF-8 Threads:16 OPEN_MAX:1024

 mt1
Compiler: 13.2.0 GCC 13.2.0
Linux : 6.8.0-1013-oracle : #13-Ubuntu SMP Mon Sep  2 12:04:50 UTC 2024 : aarch64
PageSize:4KB THP:madvise hwcap:10119FFF:CRC32:SHA1:SHA2:AES:ASIMD
LE

1T CPU Freq (MHz):  2975  2988  2988  2989  2989  2989  2988

RAM size:   64169 MB,  # CPU hardware threads:  16
RAM usage:    437 MB,  # Benchmark threads:      1

                       Compressing  |                  Decompressing
Dict     Speed Usage    R/U Rating  |      Speed Usage    R/U Rating
         KiB/s     %   MIPS   MIPS  |      KiB/s     %   MIPS   MIPS

22:       3981   100   3879   3873  |      51928   100   4428   4434
23:       3659   100   3739   3729  |      50670   100   4375   4386
24:       3473   100   3739   3735  |      49331   100   4316   4331
25:       3227   100   3682   3685  |      48114   100   4297   4283
----------------------------------  | ------------------------------
Avr:      3585   100   3760   3755  |      50011   100   4354   4358
Tot:             100   4057   4057

```

- Ampere A2 
```js 
1T CPU Freq (MHz):  2978  2989  2989  2988  2989  2987  2989

RAM size:   64166 MB,  # CPU hardware threads:  32
RAM usage:    437 MB,  # Benchmark threads:      1

                       Compressing  |                  Decompressing
Dict     Speed Usage    R/U Rating  |      Speed Usage    R/U Rating
         KiB/s     %   MIPS   MIPS  |      KiB/s     %   MIPS   MIPS

22:       3705   100   3603   3605  |      54395   100   4645   4644
23:       2909   100   2952   2964  |      53468   100   4635   4628
24:       2430   100   2612   2613  |      51752   100   4551   4543
25:       2157   100   2463   2463  |      49757   100   4428   4429
----------------------------------  | ------------------------------
Avr:      2800   100   2907   2911  |      52343   100   4565   4561
Tot:             100   3736   3736

```

-AMD X86 
```js
1T CPU Freq (MHz):  3646  3659  3662  3660  3660  3660  3660

RAM size:   64289 MB,  # CPU hardware threads:  32
RAM usage:    437 MB,  # Benchmark threads:      1

                       Compressing  |                  Decompressing
Dict     Speed Usage    R/U Rating  |      Speed Usage    R/U Rating
         KiB/s     %   MIPS   MIPS  |      KiB/s     %   MIPS   MIPS

22:       7408   100   7227   7207  |      56424   100   4816   4818
23:       5961   100   6096   6074  |      55781   100   4831   4828
24:       5056   100   5442   5437  |      54705   100   4799   4803
25:       4513   100   5163   5153  |      53444   101   4729   4757
----------------------------------  | ------------------------------
Avr:      5735   100   5982   5968  |      55089   100   4794   4801
Tot:             100   5388   5385
```



# 价格对比
- 相比X86 CPU vm, 使用ARM CPU可以节省25%左右的费用。

| 类型        | oCPU*小时 | 1G内存*小时 | 块存储*月 | 性能单位（KIOPS)*月 | 备注      | CPU 与A2相比的价差 |
|-----------|-------------|----------|--------------------|-----------|------------------|------------------|
| OCI A1        | 0.01        | 0.0015   | 0.03               | 0.02      | RAM DDR4         | 142.90%          |
| OCI A2        | 0.007       | 0.002    | 0.03               | 0.02      | RAM DDR5 1oCPU 2Core | 100.00%          |
| OCI E3        | 0.0125      | 0.0015   | 0.03               |           |   1oCPU 2Core       | 178.60%          |
| OCI E4        | 0.0125      | 0.0015   | 0.03               |           |   1oCPU 2Core       | 178.60%          |
| OCI E5        | 0.015       | 0.002    | 0.03               |           |   1oCPU 2Core       | 214.30%          |


- 厂商机型角度对比：
This content is only supported in a Feishu Docs

| 机型           | 机型价格-小时 |价格(H*$) | 价差  | 块存储 GB*月 (AWS GP3) | 块存储 GB*月 (GP2) | 块存储 GB*月 (Balanced 型) |
|--------------|---------------|-------|-------|------------------------|--------------------|----------------|
| c7g.4xlarge  | 16VCPU 32G    | 0.58  | 330%                   | 0.08               | 0.01                       |
| c6g.4xlarge  | 16VCPU 32G    | 0.544 | 309%                   | 0.08               |                            |
| OCI A1           | 16OCPU 32G    | 0.208 | 118%                   | 0.03                | 0.0425                    |
| OCI A2           | 16OCPU 32G    | 0.176 | 100%                   | 0.03               | 0.0425                     |
* 价格不代表全部信息，仅供参考



# ARM CPU 在Cloud上的应用展望
从总体上看基于ARM N1/N2架构的ARM CPU 服务器在云上的大规模应用以及持续迭代，证明了ARM CPU在Cloud上大规模部署有其性能、经济优势可定制化的灵活性(Google TPU)。随着AI时代带来的巨大算力需求，低成本兼具灵活性的ARM CPU会有更多、更广泛的使用场景。

* Wittich 希望人们习惯于思考这三种架构之间的差异，并制作了这张图表，展示了上述运行Stress-ng 负载生成器的服务器平台各自的可扩展性。下图绘制了每个系统中核心数（对于 Altra）或线程数（对于 Epyc 或 Xeon SP）逐个递增至最大时相对性能的变化。*
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/2024/202505141149507.png)
*参考： https://wiki.ubuntu.com/Kernel/Reference/stress-ng*



# 参考

- Oracle ARM
https://blogs.oracle.com/cloud-infrastructure/post/introducing-oci-ampere-a2-ARM-cloud-compute
- Ampere ARM CPU 
https://amperecomputing.com/press/next-generation-ampere

- JDK AArch64 support
https://openjdk.org/jeps/237

- AmpereComputing 路线图
https://www.nextplatform.com/2022/05/27/ampere-roadmap-has-four-future-ARM-server-chips/

- ARM 公司 CPU 系列参考：
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/2024/202506271157428.png)
