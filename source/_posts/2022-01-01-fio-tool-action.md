---
layout: post
title: FIO tool in action
categories:
  - tech
  - OS
tags:
  - blog
  - FIO
  - i/o
  - linux
date: 2022-01-01 18:45:06
excerpt: 使用FIO工具测试 HDD/SSD 读写性能。
---

# fio 说明
`FIO`一个Linux I/O子系统和调度程序测试的强大工具.
```
Fio was written by Jens Axboe <axboe@kernel.dk> to enable flexible testing of the Linux I/O subsystem and schedulers. He got tired of writing specific test applications to simulate a given workload, and found that the existing I/O benchmark/test tools out there weren’t flexible enough to do what he wanted.
```

# FIO install 
```
# centos 
sudo yum install libaio -y
sudo yum install libaio-devel -y
sudo yum install fio -y
```

# fio test 
选择需要测试的磁盘挂载：
```
#检查磁盘信息
sudo fdisk -lu
```

## test action
- 测试顺序read 
```javascript
$ sudo fio -direct=1 -iodepth=128 -rw=read -ioengine=libaio -bs=128k -numjobs=1 -time_based=1 -runtime=1000 -group_reporting -filename=/dev/vdd -name=test
test: (g=0): rw=read, bs=(R) 128KiB-128KiB, (W) 128KiB-128KiB, (T) 128KiB-128KiB, ioengine=libaio, iodepth=128
fio-3.7
Starting 1 process
Jobs: 1 (f=1): [R(1)][100.0%][r=251MiB/s,w=0KiB/s][r=2010,w=0 IOPS][eta 00m:00s]
test: (groupid=0, jobs=1): err= 0: pid=4305: Wed Nov  9 10:58:41 2022
   read: IOPS=1853, BW=232MiB/s (243MB/s)(226GiB/1000062msec)
    slat (usec): min=3, max=176, avg=10.48, stdev= 4.28
    clat (msec): min=21, max=189, avg=69.04, stdev= 6.86
     lat (msec): min=21, max=189, avg=69.05, stdev= 6.86
    clat percentiles (msec):
     |  1.00th=[   56],  5.00th=[   61], 10.00th=[   63], 20.00th=[   65],
     | 30.00th=[   67], 40.00th=[   68], 50.00th=[   68], 60.00th=[   69],
     | 70.00th=[   70], 80.00th=[   72], 90.00th=[   78], 95.00th=[   81],
     | 99.00th=[   93], 99.50th=[  102], 99.90th=[  118], 99.95th=[  138],
     | 99.99th=[  169]
   bw (  KiB/s): min=192000, max=265216, per=99.99%, avg=237268.10, stdev=10703.72, samples=2000
   iops        : min= 1500, max= 2072, avg=1853.65, stdev=83.62, samples=2000
  lat (msec)   : 50=0.01%, 100=99.37%, 250=0.62%
  cpu          : usr=0.35%, sys=2.62%, ctx=488619, majf=0, minf=4107
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=0.1%, >=64=100.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.1%
     issued rwts: total=1853894,0,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=128

Run status group 0 (all jobs):
   READ: bw=232MiB/s (243MB/s), 232MiB/s-232MiB/s (243MB/s-243MB/s), io=226GiB (243GB), run=1000062-1000062msec

Disk stats (read/write):
  vdd: ios=1854792/1, merge=273/0, ticks=128357846/1, in_queue=127954002, util=100.00%
```
- 随机读:
```javascript
$ sudo fio -direct=1 -iodepth=128 -rw=randread -ioengine=libaio -bs=4k -size=1G -numjobs=1 -runtime=1000 -group_reporting -filename=/dev/vdd -name=Rand_Read_Testing

Rand_Read_Testing: (g=0): rw=randread, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=libaio, iodepth=128
fio-3.7
Starting 1 process
bs: 1 (f=1): [r(1)][6.8%][r=3224KiB/s,w=0KiB/s][r=806,w=0 IOPS][eta 05m:00s]
fio: terminating on signal 2

Rand_Read_Testing: (groupid=0, jobs=1): err= 0: pid=17095: Wed Nov  9 11:57:38 2022
   read: IOPS=815, BW=3262KiB/s (3340kB/s)(72.8MiB/22866msec)
    slat (nsec): min=2115, max=45294, avg=5667.10, stdev=2685.80
    clat (msec): min=2, max=1058, avg=156.91, stdev=105.39
     lat (msec): min=2, max=1058, avg=156.91, stdev=105.39
    clat percentiles (msec):
     |  1.00th=[   16],  5.00th=[   31], 10.00th=[   45], 20.00th=[   69],
     | 30.00th=[   94], 40.00th=[  117], 50.00th=[  140], 60.00th=[  165],
     | 70.00th=[  190], 80.00th=[  220], 90.00th=[  284], 95.00th=[  359],
     | 99.00th=[  527], 99.50th=[  567], 99.90th=[  768], 99.95th=[  818],
     | 99.99th=[ 1003]
   bw (  KiB/s): min= 1616, max= 3704, per=100.00%, avg=3277.33, stdev=485.40, samples=45
   iops        : min=  404, max=  926, avg=819.33, stdev=121.35, samples=45
  lat (msec)   : 4=0.01%, 10=0.18%, 20=1.74%, 50=10.42%, 100=20.43%
  lat (msec)   : 250=53.37%, 500=12.51%, 750=1.24%, 1000=0.10%
  cpu          : usr=0.38%, sys=1.29%, ctx=18627, majf=0, minf=138
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=0.1%, 16=0.1%, 32=0.2%, >=64=99.7%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.1%
     issued rwts: total=18648,0,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=128

Run status group 0 (all jobs):
   READ: bw=3262KiB/s (3340kB/s), 3262KiB/s-3262KiB/s (3340kB/s-3340kB/s), io=72.8MiB (76.4MB), run=22866-22866msec

Disk stats (read/write):
  vdd: ios=18557/1, merge=0/0, ticks=2909219/1, in_queue=2897777, util=99.59%

```


##  fio test macos ssd performence 
https://www.nivas.hr/blog/2017/09/19/measuring-disk-io-performance-macos/
```
# start test 
fio --randrepeat=1 --ioengine=posixaio --direct=1 --gtod_reduce=1 --name=test --filename=test --bs=4k --iodepth=64 --size=4G --readwrite=randrw --rwmixread=75

```
result :
```
test: (g=0): rw=randrw, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=posixaio, iodepth=64
fio-3.32
Starting 1 process
test: Laying out IO file (1 file / 4096MiB)
Jobs: 1 (f=1): [m(1)][100.0%][r=150MiB/s,w=49.7MiB/s][r=38.5k,w=12.7k IOPS][eta 00m:00s]
test: (groupid=0, jobs=1): err= 0: pid=22520: Fri Nov  4 18:34:40 2022
  read: IOPS=38.3k, BW=149MiB/s (157MB/s)(3070MiB/20543msec)
   bw (  KiB/s): min=141488, max=157932, per=100.00%, avg=153169.27, stdev=2939.88, samples=40
   iops        : min=35372, max=39483, avg=38292.28, stdev=734.94, samples=40
  write: IOPS=12.8k, BW=49.9MiB/s (52.4MB/s)(1026MiB/20543msec); 0 zone resets
   bw (  KiB/s): min=47152, max=52715, per=100.00%, avg=51198.12, stdev=1208.66, samples=40
   iops        : min=11788, max=13178, avg=12799.33, stdev=302.13, samples=40
  cpu          : usr=23.19%, sys=15.98%, ctx=547854, majf=5, minf=16
  IO depths    : 1=0.1%, 2=0.1%, 4=0.1%, 8=47.2%, 16=52.8%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=98.8%, 8=1.2%, 16=0.1%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=785920,262656,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=64

Run status group 0 (all jobs):
   READ: bw=149MiB/s (157MB/s), 149MiB/s-149MiB/s (157MB/s-157MB/s), io=3070MiB (3219MB), run=20543-20543msec
  WRITE: bw=49.9MiB/s (52.4MB/s), 49.9MiB/s-49.9MiB/s (52.4MB/s-52.4MB/s), io=1026MiB (1076MB), run=20543-20543msec
```

# 标准化测试脚本
centos 上执行对本地Disk 进行FIO测试的标准化脚本：
```shell
cat < EOF > disk_fio_test.sh

disk_mount=$1 
echo " test disk ${disk_mount} " 


# read 128K 吞吐
echo " ======== ======= "
echo " ====== read  128K boundwitch ====== "

fio -bs=128k -ioengine=libaio -iodepth=32 -direct=1 -rw=read -time_based -runtime=1000  -refill_buffers -norandommap -randrepeat=0 -group_reporting  --size=1G -filename=${disk_mount} -name=${disk_mount}-test-read-boundwith

# write 128K 吞吐
echo " ======== ======= "
echo " ====== write 128K boundwitch ====== "
fio -bs=128k -ioengine=libaio -iodepth=32 -direct=1 -rw=write -time_based -runtime=1000  -refill_buffers -norandommap -randrepeat=0 -group_reporting  --size=1G -allow_mounted_write=1  -filename=${disk_mount}  -name=${disk_mount}-test-write-boundwitch  

# random read  iops 
# numjobs 测试线程数为4
echo " ======== ======= "
echo " ====== random read iops ====== "
fio -bs=4k -direct=1 -rw=randread  -iodepth=32 \
 -ioengine=libaio -numjobs=4 -time_based \
  -runtime=1000 -group_reporting --size=1G  -filename=${disk_mount} -name=${disk_mount}-test-random-read-iops


# random write  iops 
# numjobs 测试线程数为4
echo " ======== ======= "
echo " ====== random write iops ====== "
fio -bs=4k -direct=1 -rw=randwrite  -iodepth=32 \
 -ioengine=libaio -numjobs=4 -time_based \
 -allow_mounted_write=1 \
  -runtime=1000 -group_reporting  --size=1G -filename=${disk_mount} -name=${disk_mount}-test-random-write-iops


EOF
```
执行标准脚本进行测试，选择Disk mount 为`/dev/sdm` 进行测试
```shell
sudo su - 
sh ./disk_fio_test.sh /dev/sdm

```


# FIO参数说明
FIO参数取值说明
下表以测试云盘随机写IOPS（randwrite）的命令为例，说明各种参数的含义。

|参数	| 说明|
|:-----     |:------------|
|-direct=1	  | 表示测试时忽略I/O缓存，数据直写。 |
|-iodepth=128	|表示使用异步I/O（AIO）时，同时发出I/O数的上限为128。|
|-rw=randwrite	| 表示测试时的读写策略为随机写（random writes）。其它测试可以设置为： <br> randread（随机读random reads） <br> read （顺序读sequential reads）<br> write（顺序写sequential writes）<br> randrw（混合随机读写mixed random reads and writes） |
|-ioengine=libaio	 |  表示测试方式为libaio（Linux AIO，异步I/O）。应用程序使用I/O通有两种方式： <br/>同步:   <br/>同步的I/O一次只能发出一个I/O请求，等待内核完成才返回。这样对于单个线程iodepth总是小于1，但是可以透过多个线程并发执行来解决。通常会用16~32根线程同时工作将iodepth塞满。    <br/>异步    <br/>异步的I/O通常使用libaio这样的方式一次提交一批I/O请求，然后等待一批的完成，减少交互的次数，会更有效率。  | 
|-bs=4k          | <br/> 表示单次I/O的块文件大小为4 KiB。默认值也是4 KiB。 <br/> 测试IObr/S时，建议将bs设置为一个较小的值，如4k。<br/> 测吞吐量时，建议将bs设置为一个较大的值，如1024k。 |
|-size=1G	            | 表示测试文件大小为1 GiB。 |
|-numjobs=1	          | 表示测试线程数为1。 |
|-runtime=1000	      |表示测试时间为1000秒。如果未配置，则持续将前述-size指定大小的文件，以每次-bs值为分块大小写完。   |
|-group_reporting	    | 表示测试结果里汇总每个进程的统计信息，而非以不同job汇总展示信息。 |
|-filename=/dev/your_device	 | 指定的云盘设备名，例如/dev/your_device。          |
|-name=Rand_Write_Testing	 | 表示测试任务名称为Rand_Write_Testing，可以随意设定。 |



# 参考
- [https://help.aliyun.com/document_detail/147897.htm?spm=a2c4g.11186623.0.0.3c8c62e45JA3kA#section-f8v-673-2po]()
- [FIO doc ](https://fio.readthedocs.io/en/latest/)
- [google fio benchmark](https://cloud.google.com/compute/docs/disks/benchmarking-pd-performance)