---
layout: post
title: HBase Metrics Info 
categories:
  - tech
tags:
  - blog
  - HBase
  - JMX
date: 2021-06-10 20:06:32
excerpt: HBase 2.x JMX Metics info detail and report.
---

# Metrics 信息
 ## RegionServer JMX
```bash
#region server jmx dump
curl -XGET 'http://region_server:port/jmx' 
```

```json
{
  "beans" : [ {
    "name" : "JMImplementation:type=MBeanServerDelegate",
    "modelerType" : "javax.management.MBeanServerDelegate",
    "MBeanServerId" : "gzxy-hbase02-node04.idc01.com_1642046646839",
    "SpecificationName" : "Java Management Extensions",
    "SpecificationVersion" : "1.4",
    "SpecificationVendor" : "Oracle Corporation",
    "ImplementationName" : "JMX",
    "ImplementationVersion" : "1.8.0_181-b13",
    "ImplementationVendor" : "Oracle Corporation"
  }, {
    "name" : "java.lang:type=Runtime",
    "modelerType" : "sun.management.RuntimeImpl",
    "StartTime" : 1642046644885,
    "BootClassPathSupported" : true,
    "VmName" : "Java HotSpot(TM) 64-Bit Server VM",
    "VmVendor" : "Oracle Corporation",
    "VmVersion" : "25.181-b13",
    "LibraryPath" : ":/usr/hdp/3.1.5.0-152/hadoop/lib/native/Linux-amd64-64:/usr/hdp/3.1.5.0-152/hadoop/lib/native/Linux-amd64-64:/usr/hdp/3.1.5.0-152/hadoop/lib/native",
    "BootClassPath" : "/usr/java/jdk1.8.0_181/jre/lib/resources.jar:/usr/java/jdk1.8.0_181/jre/lib/rt.jar:/usr/java/jdk1.8.0_181/jre/lib/sunrsasign.jar:/usr/java/jdk1.8.0_181/jre/lib/jsse.jar:/usr/java/jdk1.8.0_181/jre/lib/jce.jar:/usr/java/jdk1.8.0_181/jre/lib/charsets.jar:/usr/java/jdk1.8.0_181/jre/lib/jfr.jar:/usr/java/jdk1.8.0_181/jre/classes",
    "Uptime" : 12811289959,
    "ManagementSpecVersion" : "1.2",
    "SpecName" : "Java Virtual Machine Specification",
    "SpecVendor" : "Oracle Corporation",
    "SpecVersion" : "1.8",
    "InputArguments" : [ "-Dproc_regionserver", "-XX:OnOutOfMemoryError=kill -9 %p", "-Dhdp.version=3.1.5.0-152", "-XX:+UseG1GC", "-XX:MaxGCPauseMillis=100", "-XX:-ResizePLAB", "-XX:ErrorFile=/var/log/hbase/hs_err_pid%p.log", "-Djava.io.tmpdir=/tmp", "-verbose:gc", "-XX:-PrintGCCause", "-XX:+PrintAdaptiveSizePolicy", "-XX:+PrintGCDetails", "-XX:+PrintGCDateStamps", "-Xloggc:/var/log/hbase/gc.log-202201131204", "-Xms65536m", "-Xmx65536m", "-XX:ParallelGCThreads=32", "-javaagent:/opt/hadoop_jmx/jmx_prometheus_javaagent-0.13.0.jar=18015:/opt/hadoop_jmx/hbase-regionserver.yaml", "-XX:MaxDirectMemorySize=4096m", "-Dhbase.log.dir=/var/log/hbase", "-Dhbase.log.file=hbase-hbase-regionserver-gzxy-hbase02-node04.idc01.com.log", "-Dhbase.home.dir=/usr/hdp/current/hbase-regionserver/bin/..", "-Dhbase.id.str=hbase", "-Dhbase.root.logger=INFO,RFA", "-Djava.library.path=:/usr/hdp/3.1.5.0-152/hadoop/lib/native/Linux-amd64-64:/usr/hdp/3.1.5.0-152/hadoop/lib/native/Linux-amd64-64:/usr/hdp/3.1.5.0-152/hadoop/lib/native", "-Dhbase.security.logger=INFO,RFAS" ],
    "SystemProperties" : [ {
      "key" : "awt.toolkit",
      "value" : "sun.awt.X11.XToolkit"
    }, {
      "key" : "file.encoding.pkg",
      "value" : "sun.io"
    }, {
      "key" : "java.specification.version",
      "value" : "1.8"
    }, {
      "key" : "sun.cpu.isalist",
      "value" : ""
    }, {
      "key" : "sun.jnu.encoding",
      "value" : "UTF-8"
    },
    {
      "key" : "hbase.log.dir",
      "value" : "/var/log/hbase"
    }, {
      "key" : "java.vm.vendor",
      "value" : "Oracle Corporation"
    }, {
      "key" : "sun.arch.data.model",
      "value" : "64"
    }, {
      "key" : "java.vendor.url",
      "value" : "http://java.oracle.com/"
    }, {
      "key" : "hbase.home.dir",
      "value" : "/usr/hdp/current/hbase-regionserver/bin/.."
    }, {
      "key" : "user.timezone",
      "value" : "Asia/Shanghai"
    }, {
      "key" : "os.name",
      "value" : "Linux"
    }, {
      "key" : "java.vm.specification.version",
      "value" : "1.8"
    }, {
      "key" : "hbase.log.file",
      "value" : "hbase-hbase-regionserver-gzxy-hbase02-node04.idc01.com.log"
    }, {
      "key" : "user.country",
      "value" : "US"
    }, {
      "key" : "sun.java.launcher",
      "value" : "SUN_STANDARD"
    }, {
      "key" : "sun.boot.library.path",
      "value" : "/usr/java/jdk1.8.0_181/jre/lib/amd64"
    }, {
      "key" : "sun.java.command",
      "value" : "org.apache.hadoop.hbase.regionserver.HRegionServer start"
    }, {
      "key" : "sun.cpu.endian",
      "value" : "little"
    }, {
      "key" : "user.home",
      "value" : "/home/hbase"
    }, {
      "key" : "user.language",
      "value" : "en"
    }, {
      "key" : "java.specification.vendor",
      "value" : "Oracle Corporation"
    }, {
      "key" : "hdp.version",
      "value" : "3.1.5.0-152"
    }, {
      "key" : "java.home",
      "value" : "/usr/java/jdk1.8.0_181/jre"
    }, {
      "key" : "file.separator",
      "value" : "/"
    }, {
      "key" : "line.separator",
      "value" : "\n"
    }, {
      "key" : "java.vm.specification.vendor",
      "value" : "Oracle Corporation"
    }, {
      "key" : "java.specification.name",
      "value" : "Java Platform API Specification"
    }, {
      "key" : "java.awt.graphicsenv",
      "value" : "sun.awt.X11GraphicsEnvironment"
    }, {
      "key" : "sun.boot.class.path",
      "value" : "/usr/java/jdk1.8.0_181/jre/lib/resources.jar:/usr/java/jdk1.8.0_181/jre/lib/rt.jar:/usr/java/jdk1.8.0_181/jre/lib/sunrsasign.jar:/usr/java/jdk1.8.0_181/jre/lib/jsse.jar:/usr/java/jdk1.8.0_181/jre/lib/jce.jar:/usr/java/jdk1.8.0_181/jre/lib/charsets.jar:/usr/java/jdk1.8.0_181/jre/lib/jfr.jar:/usr/java/jdk1.8.0_181/jre/classes"
    }, {
      "key" : "sun.management.compiler",
      "value" : "HotSpot 64-Bit Tiered Compilers"
    }, {
      "key" : "java.runtime.version",
      "value" : "1.8.0_181-b13"
    }, {
      "key" : "user.name",
      "value" : "hbase"
    }, {
      "key" : "path.separator",
      "value" : ":"
    }, {
      "key" : "os.version",
      "value" : "3.10.0-1160.11.1.el7.x86_64"
    }, {
      "key" : "java.endorsed.dirs",
      "value" : "/usr/java/jdk1.8.0_181/jre/lib/endorsed"
    }, {
      "key" : "java.runtime.name",
      "value" : "Java(TM) SE Runtime Environment"
    }, {
      "key" : "proc_regionserver",
      "value" : ""
    }, {
      "key" : "file.encoding",
      "value" : "UTF-8"
    }, {
      "key" : "java.vm.name",
      "value" : "Java HotSpot(TM) 64-Bit Server VM"
    }, {
      "key" : "jetty.git.hash",
      "value" : "d3e249f86955d04bc646bb620905b7c1bc596a8d"
    }, {
      "key" : "java.vendor.url.bug",
      "value" : "http://bugreport.sun.com/bugreport/"
    }, {
      "key" : "java.io.tmpdir",
      "value" : "/tmp"
    }, {
      "key" : "java.version",
      "value" : "1.8.0_181"
    }, {
      "key" : "user.dir",
      "value" : "/home/hbase"
    }, {
      "key" : "os.arch",
      "value" : "amd64"
    }, {
      "key" : "java.vm.specification.name",
      "value" : "Java Virtual Machine Specification"
    }, {
      "key" : "java.awt.printerjob",
      "value" : "sun.print.PSPrinterJob"
    }, {
      "key" : "hadoop.policy.file",
      "value" : "hbase-policy.xml"
    }, {
      "key" : "sun.os.patch.level",
      "value" : "unknown"
    }, {
      "key" : "hbase.id.str",
      "value" : "hbase"
    }, {
      "key" : "hbase.root.logger",
      "value" : "INFO,RFA"
    }, {
      "key" : "java.library.path",
      "value" : ":/usr/hdp/3.1.5.0-152/hadoop/lib/native/Linux-amd64-64:/usr/hdp/3.1.5.0-152/hadoop/lib/native/Linux-amd64-64:/usr/hdp/3.1.5.0-152/hadoop/lib/native"
    }, {
      "key" : "java.vm.info",
      "value" : "mixed mode"
    }, {
      "key" : "java.vendor",
      "value" : "Oracle Corporation"
    }, {
      "key" : "java.vm.version",
      "value" : "25.181-b13"
    }, {
      "key" : "java.ext.dirs",
      "value" : "/usr/java/jdk1.8.0_181/jre/lib/ext:/usr/java/packages/lib/ext"
    }, {
      "key" : "sun.io.unicode.encoding",
      "value" : "UnicodeLittle"
    }, {
      "key" : "hbase.security.logger",
      "value" : "INFO,RFAS"
    }, {
      "key" : "java.class.version",
      "value" : "52.0"
    } ],
    "Name" : "78334@gzxy-hbase02-node04.idc01.com",
    "ObjectName" : "java.lang:type=Runtime"
  }, {
    "name" : "Hadoop:service=HBase,name=MetricsSystem,sub=Control",
    "modelerType" : "org.apache.hadoop.metrics2.impl.MetricsSystemImpl"
  }, {
    "name" : "java.lang:type=Threading",
    "modelerType" : "sun.management.ThreadImpl",
    "ThreadAllocatedMemoryEnabled" : true,
    "ThreadAllocatedMemorySupported" : true,
    "ThreadContentionMonitoringSupported" : true,
    "CurrentThreadCpuTimeSupported" : true,
    "ObjectMonitorUsageSupported" : true,
    "SynchronizerUsageSupported" : true,
    "ThreadContentionMonitoringEnabled" : false,
    "ThreadCpuTimeEnabled" : true,
    "PeakThreadCount" : 476,
    "DaemonThreadCount" : 430,
    "ThreadCount" : 433,
    "TotalStartedThreadCount" : 1069826,
    "AllThreadIds" : [ 1070049, 1070048, 1070047, 1070045, 1070035, 1070031, 1070030, 1070007, 1069978, 1069959, 402155, 203400, 45787, 2799, 2798, 2797, 2796, 2789, 2776, 2765, 2618, 2617, 2606, 2411, 2406, 2404, 2403, 2391, 2389, 2380, 2379, 2377, 2370, 2366, 2360, 2353, 2349, 2340, 2335, 2328, 2322, 2318, 2308, 2305, 2300, 2293, 2288, 2281, 2277, 2273, 2265, 2259, 2252, 2247, 2241, 2235, 2231, 2222, 2218, 2215, 2210, 2206, 2199, 2193, 2190, 2183, 2176, 2168, 2163, 2158, 2150, 2145, 2137, 2130, 2125, 2119, 2112, 2105, 2098, 2093, 2087, 2080, 2071, 2067, 2066, 2065, 2063, 2056, 2051, 2047, 2036, 2029, 2025, 2020, 2015, 2006, 1998, 1993, 1987, 1982, 1974, 1968, 1965, 1958, 1954, 1945, 1939, 1934, 1928, 1922, 1912, 1906, 1902, 1895, 1889, 1880, 1875, 1867, 1861, 1855, 1846, 1840, 1836, 1831, 1828, 1823, 1814, 1807, 1803, 1798, 1794, 1786, 1781, 1775, 1770, 1765, 1756, 1752, 1746, 1739, 1735, 1725, 1719, 1714, 1708, 1706, 1705, 1704, 1703, 1702, 1701, 1700, 1699, 1698, 1697, 1692, 805, 804, 803, 748, 689, 688, 687, 589, 575, 574, 573, 492, 378, 377, 376, 374, 375, 373, 372, 371, 370, 369, 368, 367, 366, 365, 364, 363, 362, 361, 360, 359, 358, 357, 356, 355, 353, 351, 350, 349, 348, 347, 346, 345, 344, 342, 340, 333, 335, 338, 336, 334, 332, 331, 330, 329, 328, 327, 326, 325, 324, 323, 322, 321, 315, 318, 316, 312, 31, 309, 308, 307, 306, 305, 300, 299, 298, 297, 296, 295, 294, 293, 292, 291, 290, 289, 288, 287, 286, 285, 284, 283, 282, 281, 280, 279, 278, 277, 276, 275, 274, 273, 272, 271, 270, 269, 268, 267, 266, 265, 264, 263, 262, 261, 260, 259, 258, 257, 256, 255, 254, 253, 252, 251, 250, 249, 248, 247, 246, 245, 244, 243, 242, 241, 240, 239, 238, 237, 236, 235, 234, 233, 232, 231, 230, 229, 228, 227, 226, 225, 224, 223, 222, 221, 220, 219, 218, 217, 216, 215, 214, 213, 212, 211, 210, 209, 208, 207, 206, 205, 204, 203, 202, 201, 200, 199, 198, 197, 196, 195, 194, 193, 192, 191, 190, 189, 188, 187, 186, 185, 184, 183, 182, 181, 180, 179, 178, 177, 176, 175, 174, 173, 172, 171, 170, 169, 168, 167, 166, 165, 164, 163, 162, 161, 160, 159, 158, 157, 156, 155, 154, 153, 152, 151, 150, 149, 148, 147, 146, 145, 144, 143, 142, 141, 140, 139, 138, 137, 136, 135, 134, 133, 132, 131, 130, 129, 128, 127, 126, 125, 124, 123, 122, 121, 120, 119, 118, 117, 116, 115, 112, 111, 110, 108, 106, 105, 104, 39, 37, 36, 35, 9, 7, 5, 3, 2, 1 ],
    "CurrentThreadCpuTime" : 2934225,
    "CurrentThreadUserTime" : 0,
    "ThreadCpuTimeSupported" : true,
    "ObjectName" : "java.lang:type=Threading"
  }, {
    "name" : "java.lang:type=OperatingSystem",
    "modelerType" : "sun.management.OperatingSystemImpl",
    "OpenFileDescriptorCount" : 894,
    "MaxFileDescriptorCount" : 32000,
    "ProcessCpuTime" : 29289593230000000,
    "CommittedVirtualMemorySize" : 77254651904,
    "TotalSwapSpaceSize" : 0,
    "FreeSwapSpaceSize" : 0,
    "FreePhysicalMemorySize" : 290252013568,
    "TotalPhysicalMemorySize" : 404343144448,
    "SystemCpuLoad" : 0.0014223065070522697,
    "ProcessCpuLoad" : 3.259355832765415E-4,
    "Version" : "3.10.0-1160.11.1.el7.x86_64",
    "AvailableProcessors" : 64,
    "Arch" : "amd64",
    "SystemLoadAverage" : 0.1,
    "Name" : "Linux",
    "ObjectName" : "java.lang:type=OperatingSystem"
  }, {
    "name" : "Hadoop:service=HBase,name=MetricsSystem,sub=Stats",
    "modelerType" : "MetricsSystem,sub=Stats",
    "tag.Context" : "metricssystem",
    "tag.Hostname" : "gzxy-hbase02-node04.idc01.com",
    "NumActiveSources" : 14,
    "NumAllSources" : 14,
    "NumActiveSinks" : 1,
    "NumAllSinks" : 0,
    "Sink_timelineNumOps" : 3,
    "Sink_timelineAvgTime" : 37.0,
    "Sink_timelineDropped" : 0,
    "Sink_timelineQsize" : 0,
    "SnapshotNumOps" : 17337625,
    "SnapshotAvgTime" : 0.0,
    "PublishNumOps" : 1238402,
    "PublishAvgTime" : 0.0,
    "DroppedPubAll" : 0
  }, {
    "name" : "java.lang:type=MemoryPool,name=Code Cache",
    "modelerType" : "sun.management.MemoryPoolImpl",
    "Valid" : true,
    "Usage" : {
      "committed" : 244318208,
      "init" : 2555904,
      "max" : 251658240,
      "used" : 107376384
    },
    "PeakUsage" : {
      "committed" : 244318208,
      "init" : 2555904,
      "max" : 251658240,
      "used" : 242095616
    },
    "MemoryManagerNames" : [ "CodeCacheManager" ],
    "UsageThreshold" : 0,
    "UsageThresholdExceeded" : false,
    "UsageThresholdCount" : 0,
    "UsageThresholdSupported" : true,
    "CollectionUsage" : null,
    "CollectionUsageThresholdSupported" : false,
    "Name" : "Code Cache",
    "Type" : "NON_HEAP",
    "ObjectName" : "java.lang:type=MemoryPool,name=Code Cache"
  }, {
    "name" : "java.nio:type=BufferPool,name=direct",
    "modelerType" : "sun.management.ManagementFactoryHelper$1",
    "MemoryUsed" : 2172891847,
    "TotalCapacity" : 2172891845,
    "Count" : 1280,
    "Name" : "direct",
    "ObjectName" : "java.nio:type=BufferPool,name=direct"
  }, {
    "name" : "java.lang:type=Compilation",
    "modelerType" : "sun.management.CompilationImpl",
    "CompilationTimeMonitoringSupported" : true,
    "TotalCompilationTime" : 82759607,
    "Name" : "HotSpot 64-Bit Tiered Compilers",
    "ObjectName" : "java.lang:type=Compilation"
  }, {
    "name" : "java.lang:type=GarbageCollector,name=G1 Young Generation",
    "modelerType" : "sun.management.GarbageCollectorImpl",
    "LastGcInfo" : {
      "GcThreadCount" : 66,
      "duration" : 78,
      "endTime" : 12808000480,
      "id" : 36433,
      "memoryUsageAfterGc" : [ {
        "key" : "G1 Survivor Space",
        "value" : {
          "committed" : 100663296,
          "init" : 0,
          "max" : -1,
          "used" : 100663296
        }
      }, {
        "key" : "Metaspace",
        "value" : {
          "committed" : 522256384,
          "init" : 0,
          "max" : -1,
          "used" : 383654488
        }
      }, {
        "key" : "G1 Old Gen",
        "value" : {
          "committed" : 43721424896,
          "init" : 65095598080,
          "max" : 68719476736,
          "used" : 18248660992
        }
      }, {
        "key" : "G1 Eden Space",
        "value" : {
          "committed" : 24897388544,
          "init" : 3623878656,
          "max" : -1,
          "used" : 0
        }
      }, {
        "key" : "Code Cache",
        "value" : {
          "committed" : 244318208,
          "init" : 2555904,
          "max" : 251658240,
          "used" : 100406656
        }
      } ],
      "memoryUsageBeforeGc" : [ {
        "key" : "G1 Survivor Space",
        "value" : {
          "committed" : 134217728,
          "init" : 0,
          "max" : -1,
          "used" : 134217728
        }
      }, {
        "key" : "Metaspace",
        "value" : {
          "committed" : 522256384,
          "init" : 0,
          "max" : -1,
          "used" : 383654488
        }
      }, {
        "key" : "G1 Old Gen",
        "value" : {
          "committed" : 63015223296,
          "init" : 65095598080,
          "max" : 68719476736,
          "used" : 18192574264
        }
      }, {
        "key" : "G1 Eden Space",
        "value" : {
          "committed" : 5570035712,
          "init" : 3623878656,
          "max" : -1,
          "used" : 5268045824
        }
      }, {
        "key" : "Code Cache",
        "value" : {
          "committed" : 244318208,
          "init" : 2555904,
          "max" : 251658240,
          "used" : 100406656
        }
      } ],
      "startTime" : 12808000402
    },
    "CollectionCount" : 36433,
    "CollectionTime" : 4290648,
    "Valid" : true,
    "MemoryPoolNames" : [ "G1 Eden Space", "G1 Survivor Space" ],
    "Name" : "G1 Young Generation",
    "ObjectName" : "java.lang:type=GarbageCollector,name=G1 Young Generation"
  }, {
    "name" : "Hadoop:service=HBase,name=RegionServer,sub=Coprocessor.Region.CP_org.apache.hadoop.hbase.security.access.SecureBulkLoadEndpoint",
    "modelerType" : "RegionServer,sub=Coprocessor.Region.CP_org.apache.hadoop.hbase.security.access.SecureBulkLoadEndpoint",
    "tag.Context" : "regionserver",
    "tag.Hostname" : "gzxy-hbase02-node04.idc01.com"
  }, {
    "name" : "Hadoop:service=HBase,name=RegionServer,sub=Quotas",
    "modelerType" : "RegionServer,sub=Quotas",
    "tag.Context" : "regionserver",
    "tag.Hostname" : "gzxy-hbase02-node04.idc01.com"
  }, {
    "name" : "java.lang:type=MemoryManager,name=CodeCacheManager",
    "modelerType" : "sun.management.MemoryManagerImpl",
    "Valid" : true,
    "MemoryPoolNames" : [ "Code Cache" ],
    "Name" : "CodeCacheManager",
    "ObjectName" : "java.lang:type=MemoryManager,name=CodeCacheManager"
  }, {
    "name" : "java.lang:type=MemoryPool,name=G1 Old Gen",
    "modelerType" : "sun.management.MemoryPoolImpl",
    "Valid" : true,
    "Usage" : {
      "committed" : 43721424896,
      "init" : 65095598080,
      "max" : 68719476736,
      "used" : 18215106560
    },
    "PeakUsage" : {
      "committed" : 65095598080,
      "init" : 65095598080,
      "max" : 68719476736,
      "used" : 26071683568
    },
    "MemoryManagerNames" : [ "G1 Old Generation" ],
    "UsageThreshold" : 0,
    "UsageThresholdExceeded" : false,
    "UsageThresholdCount" : 0,
    "UsageThresholdSupported" : true,
    "CollectionUsageThreshold" : 0,
    "CollectionUsageThresholdExceeded" : false,
    "CollectionUsageThresholdCount" : 0,
    "CollectionUsage" : {
      "committed" : 0,
      "init" : 65095598080,
      "max" : 68719476736,
      "used" : 0
    },
    "CollectionUsageThresholdSupported" : true,
    "Name" : "G1 Old Gen",
    "Type" : "HEAP",
    "ObjectName" : "java.lang:type=MemoryPool,name=G1 Old Gen"
  }, {
    "name" : "java.util.logging:type=Logging",
    "modelerType" : "sun.management.ManagementFactoryHelper$PlatformLoggingImpl",
    "ObjectName" : "java.util.logging:type=Logging",
    "LoggerNames" : [ "global", "org.apache.ambari.metrics.sink.relocated.google.common.cache.CacheBuilder", "com.sun.net.httpserver", "org.apache.jasper.runtime.TldScanner", "javax.management.monitor", "com.google.cloud.hadoop.repackaged.gcs.com.google.cloud.hadoop.util.HttpTransportFactory", "com.google.common.cache.LocalCache", "org.apache.hbase.thirdparty.com.google.common.cache.CacheBuilder", "org.apache.hbase.thirdparty.com.google.protobuf.TextFormat", "com.google.cloud.hadoop.fs.gcs.GoogleHadoopFileSystemConfiguration", "org.apache.ambari.metrics.sink.relocated.google.common.base.Platform", "org.apache.hbase.thirdparty.com.google.common.io.Closeables", "com.google.cloud.hadoop.repackaged.gcs.com.google.cloud.hadoop.util.CredentialConfiguration", "javax.management", "javax.management.snmp", "javax.management.notification", "org.apache.jasper.servlet.JspServlet", "javax.management.snmp.daemon", "javax.management.modelmbean", "sun.net.www.protocol.http.HttpURLConnection", "io.prometheus.jmx.shaded.io.prometheus.client.hotspot.StandardExports", "com.google.common.util.concurrent.AbstractFuture", "org.apache.jasper.EmbeddedServletOptions", "org.apache.hbase.thirdparty.com.google.common.util.concurrent.AbstractFuture", "javax.management.misc", "org.apache.jasper.compiler.JspConfig", "javax.management.mlet", "com.google.cloud.hadoop.fs.gcs.GoogleHadoopFileSystem", "com.google.cloud.hadoop.repackaged.gcs.com.google.cloud.hadoop.util.PropertyUtil", "io.prometheus.jmx.shaded.io.prometheus.client.hotspot.BufferPoolsExports", "org.apache.hbase.thirdparty.com.google.protobuf.Descriptors", "org.apache.ambari.metrics.sink.relocated.google.common.cache.LocalCache", "javax.management.timer", "org.apache.jasper.security.SecurityClassLoad", "org.apache.jasper.runtime.JspFactoryImpl", "com.google.common.base.Platform", "org.apache.hbase.thirdparty.com.google.protobuf.UnsafeUtil", "org.apache.jasper.compiler.JspRuntimeContext", "org.apache.hbase.thirdparty.com.google.protobuf.CodedOutputStream", "javax.management.relation", "org.apache.hbase.thirdparty.com.google.common.cache.LocalCache", "com.google.common.cache.CacheBuilder", "io.prometheus.jmx.shaded.io.prometheus.jmx.JmxCollector", "org.apache.hbase.thirdparty.com.google.common.base.Platform", "com.google.cloud.hadoop.fs.gcs.GoogleHadoopFileSystemConfigurationProperty", "", "javax.management.mbeanserver", "com.google.cloud.hadoop.fs.gcs.GoogleHadoopFileSystemBase" ]
  }, {
    "name" : "java.lang:type=GarbageCollector,name=G1 Old Generation",
    "modelerType" : "sun.management.GarbageCollectorImpl",
    "LastGcInfo" : null,
    "CollectionCount" : 0,
    "CollectionTime" : 0,
    "Valid" : true,
    "MemoryPoolNames" : [ "G1 Eden Space", "G1 Survivor Space", "G1 Old Gen" ],
    "Name" : "G1 Old Generation",
    "ObjectName" : "java.lang:type=GarbageCollector,name=G1 Old Generation"
  }, {
    "name" : "java.lang:type=ClassLoading",
    "modelerType" : "sun.management.ClassLoadingImpl",
    "LoadedClassCount" : 70647,
    "UnloadedClassCount" : 24992295,
    "Verbose" : false,
    "TotalLoadedClassCount" : 25062942,
    "ObjectName" : "java.lang:type=ClassLoading"
  }, {
    "name" : "java.lang:type=MemoryManager,name=Metaspace Manager",
    "modelerType" : "sun.management.MemoryManagerImpl",
    "Valid" : true,
    "MemoryPoolNames" : [ "Metaspace" ],
    "Name" : "Metaspace Manager",
    "ObjectName" : "java.lang:type=MemoryManager,name=Metaspace Manager"
  }, {
    "name" : "Hadoop:service=HBase,name=RegionServer,sub=Regions",
    "modelerType" : "RegionServer,sub=Regions",
    "tag.Context" : "regionserver",
    "tag.Hostname" : "gzxy-hbase02-node04.idc01.com",
    "Namespace_fraud_table_general_feature_m_v2_region_0569b15917774c95c6546e1fb1438a0a_metric_storeCount" : 1,
    "Namespace_fraud_table_general_feature_m_v2_region_0569b15917774c95c6546e1fb1438a0a_metric_storeFileCount" : 2,
    "Namespace_fraud_table_general_feature_m_v2_region_0569b15917774c95c6546e1fb1438a0a_metric_memStoreSize" : 0,
    "Namespace_fraud_table_general_feature_m_v2_region_0569b15917774c95c6546e1fb1438a0a_metric_maxStoreFileAge" : 267315965,
    "Namespace_fraud_table_general_feature_m_v2_region_0569b15917774c95c6546e1fb1438a0a_metric_minStoreFileAge" : 67127298,
    "Namespace_fraud_table_general_feature_m_v2_region_0569b15917774c95c6546e1fb1438a0a_metric_avgStoreFileAge" : 167221631,
    "Namespace_fraud_table_general_feature_m_v2_region_0569b15917774c95c6546e1fb1438a0a_metric_numReferenceFiles" : 0,
    "Namespace_fraud_table_general_feature_m_v2_region_0569b15917774c95c6546e1fb1438a0a_metric_storeFileSize" : 8744395789,
    "Namespace_fraud_table_general_feature_m_v2_region_0569b15917774c95c6546e1fb1438a0a_metric_compactionsCompletedCount" : 103,
    "Namespace_fraud_table_general_feature_m_v2_region_0569b15917774c95c6546e1fb1438a0a_metric_compactionsFailedCount" : 0,
    "Namespace_fraud_table_general_feature_m_v2_region_0569b15917774c95c6546e1fb1438a0a_metric_lastMajorCompactionAge" : 281279264,
    "Namespace_fraud_table_general_feature_m_v2_region_0569b15917774c95c6546e1fb1438a0a_metric_numBytesCompactedCount" : 797529978366,
    "Namespace_fraud_table_general_feature_m_v2_region_0569b15917774c95c6546e1fb1438a0a_metric_numFilesCompactedCount" : 346,
    "Namespace_fraud_table_general_feature_m_v2_region_0569b15917774c95c6546e1fb1438a0a_metric_readRequestCount" : 3601817,
    "Namespace_fraud_table_general_feature_m_v2_region_0569b15917774c95c6546e1fb1438a0a_metric_filteredReadRequestCount" : 1134603,
    "Namespace_fraud_table_general_feature_m_v2_region_0569b15917774c95c6546e1fb1438a0a_metric_writeRequestCount" : 149,
    "Namespace_fraud_table_general_feature_m_v2_region_0569b15917774c95c6546e1fb1438a0a_metric_replicaid" : 0,
    "Namespace_fraud_table_general_feature_m_v2_region_0569b15917774c95c6546e1fb1438a0a_metric_compactionsQueuedCount" : 0,
    "Namespace_fraud_table_general_feature_m_v2_region_0569b15917774c95c6546e1fb1438a0a_metric_flushesQueuedCount" : 0,
    "Namespace_fraud_table_general_feature_m_v2_region_0569b15917774c95c6546e1fb1438a0a_metric_maxCompactionQueueSize" : 1,
    "Namespace_fraud_table_general_feature_m_v2_region_0569b15917774c95c6546e1fb1438a0a_metric_maxFlushQueueSize" : 0
  }, {
    "name" : "Hadoop:service=HBase,name=RegionServer,sub=Server",
    "modelerType" : "RegionServer,sub=Server",
    "tag.zookeeperQuorum" : "gzxy-hbase02-node01.idc01.com:2181,gzxy-hbase02-node02.idc01.com:2181,gzxy-hbase02-node03.idc01.com:2181",
    "tag.serverName" : "gzxy-hbase02-node04.idc01.com,16020,1642046646097",
    "tag.clusterId" : "56b5038b-2544-4b00-a940-534ded033298",
    "tag.Context" : "regionserver",
    "tag.Hostname" : "gzxy-hbase02-node04.idc01.com",
    "regionCount" : 136,
    "storeCount" : 136,
    "hlogFileCount" : 1,
    "hlogFileSize" : 0,
    "storeFileCount" : 194,
    "memStoreSize" : 0,
    "storeFileSize" : 511303826803,
    "maxStoreFileAge" : 535072942,
    "minStoreFileAge" : 839376,
    "avgStoreFileAge" : 184029384,
    "numReferenceFiles" : 0,
    "regionServerStartTime" : 1642046646097,
    "averageRegionSize" : 3759586961,
    "storeFileIndexSize" : 5395096,
    "staticIndexSize" : 5975637568,
    "staticBloomSize" : 2867997696,
    "mutationsWithoutWALCount" : 0,
    "mutationsWithoutWALSize" : 0,
    "percentFilesLocal" : 0.0,
    "percentFilesLocalSecondaryRegions" : 0.0,
    "splitQueueLength" : 0,
    "compactionQueueLength" : 0,
    "smallCompactionQueueLength" : 0,
    "largeCompactionQueueLength" : 0,
    "flushQueueLength" : 0,
    "blockCacheFreeSize" : 15622411208,
    "blockCacheCount" : 119835,
    "blockCacheSize" : 14012855352,
    "blockCacheCountHitPercent" : 45.51087765630544,
    "blockCacheExpressHitPercent" : 92.3094244985123,
    "l1CacheHitCount" : 3956841391,
    "l1CacheMissCount" : 0,
    "l1CacheHitRatio" : 1.0,
    "l1CacheMissRatio" : 0.0,
    "l2CacheHitCount" : 99861773,
    "l2CacheMissCount" : 4856996973,
    "l2CacheHitRatio" : 0.02014618090148014,
    "l2CacheMissRatio" : 0.9798538190985199,
    "mobFileCacheCount" : 0,
    "mobFileCacheHitPercent" : 0.0,
    "totalRequestCount" : 509719497,
    "totalRowActionRequestCount" : 236386866,
    "readRequestCount" : 236376901,
    "filteredReadRequestCount" : 25394658,
    "writeRequestCount" : 9965,
    "rpcGetRequestCount" : 509707077,
    "rpcScanRequestCount" : 0,
    "rpcMultiRequestCount" : 0,
    "rpcMutateRequestCount" : 0,
    "checkMutateFailedCount" : 0,
    "checkMutatePassedCount" : 0,
    "blockCacheHitCount" : 4056703164,
    "blockCacheHitCountPrimary" : 4056703164,
    "blockCacheMissCount" : 4856996973,
    "blockCacheMissCountPrimary" : 4856996973,
    "blockCacheEvictionCount" : 333469087,
    "blockCacheEvictionCountPrimary" : 333469087,
    "blockCacheFailedInsertionCount" : 71,
    "blockCacheDataMissCount" : 330525333,
    "blockCacheLeafIndexMissCount" : 2159762,
    "blockCacheBloomChunkMissCount" : 934374,
    "blockCacheMetaMissCount" : 0,
    "blockCacheRootIndexMissCount" : 0,
    "blockCacheIntermediateIndexMissCount" : 701,
    "blockCacheFileInfoMissCount" : 0,
    "blockCacheGeneralBloomMetaMissCount" : 0,
    "blockCacheDeleteFamilyBloomMissCount" : 0,
    "blockCacheTrailerMissCount" : 0,
    "blockCacheDataHitCount" : 97648325,
    "blockCacheLeafIndexHitCount" : 2998406714,
    "blockCacheBloomChunkHitCount" : 844958770,
    "blockCacheMetaHitCount" : 0,
    "blockCacheRootIndexHitCount" : 0,
    "blockCacheIntermediateIndexHitCount" : 110536804,
    "blockCacheFileInfoHitCount" : 0,
    "blockCacheGeneralBloomMetaHitCount" : 0,
    "blockCacheDeleteFamilyBloomHitCount" : 0,
    "blockCacheTrailerHitCount" : 0,
    "updatesBlockedTime" : 0,
    "flushedCellsCount" : 0,
    "compactedCellsCount" : 952388255396,
    "majorCompactedCellsCount" : 1060189942945,
    "flushedCellsSize" : 0,
    "compactedCellsSize" : 63901013725783,
    "majorCompactedCellsSize" : 76151157664676,
    "cellsCountCompactedFromMob" : 0,
    "cellsCountCompactedToMob" : 0,
    "cellsSizeCompactedFromMob" : 0,
    "cellsSizeCompactedToMob" : 0,
    "mobFlushCount" : 0,
    "mobFlushedCellsCount" : 0,
    "mobFlushedCellsSize" : 0,
    "mobScanCellsCount" : 0,
    "mobScanCellsSize" : 0,
    "mobFileCacheAccessCount" : 0,
    "mobFileCacheMissCount" : 0,
    "mobFileCacheEvictedCount" : 0,
    "hedgedReads" : 0,
    "hedgedReadWins" : 0,
    "blockedRequestCount" : 0,
    "MajorCompactionTime_num_ops" : 1337,
    "MajorCompactionTime_min" : 0,
    "MajorCompactionTime_max" : 0,
    "MajorCompactionTime_mean" : 0,
    "MajorCompactionTime_25th_percentile" : 0,
    "MajorCompactionTime_median" : 0,
    "MajorCompactionTime_75th_percentile" : 0,
    "MajorCompactionTime_90th_percentile" : 0,
    "MajorCompactionTime_95th_percentile" : 0,
    "MajorCompactionTime_98th_percentile" : 0,
    "MajorCompactionTime_99th_percentile" : 0,
    "MajorCompactionTime_99.9th_percentile" : 0,
    "PauseTimeWithGc_num_ops" : 35,
    "PauseTimeWithGc_min" : 0,
    "PauseTimeWithGc_max" : 0,
    "PauseTimeWithGc_mean" : 0,
    "PauseTimeWithGc_25th_percentile" : 0,
    "PauseTimeWithGc_median" : 0,
    "PauseTimeWithGc_75th_percentile" : 0,
    "PauseTimeWithGc_90th_percentile" : 0,
    "PauseTimeWithGc_95th_percentile" : 0,
    "PauseTimeWithGc_98th_percentile" : 0,
    "PauseTimeWithGc_99th_percentile" : 0,
    "PauseTimeWithGc_99.9th_percentile" : 0,
    "compactedOutputBytes" : 18183113101899,
    "pauseWarnThresholdExceeded" : 0,
    "ScanTime_num_ops" : 0,
    "ScanTime_min" : 0,
    "ScanTime_max" : 0,
    "ScanTime_mean" : 0,
    "ScanTime_25th_percentile" : 0,
    "ScanTime_median" : 0,
    "ScanTime_75th_percentile" : 0,
    "ScanTime_90th_percentile" : 0,
    "ScanTime_95th_percentile" : 0,
    "ScanTime_98th_percentile" : 0,
    "ScanTime_99th_percentile" : 0,
    "ScanTime_99.9th_percentile" : 0,
    "Increment_num_ops" : 0,
    "Increment_min" : 0,
    "Increment_max" : 0,
    "Increment_mean" : 0,
    "Increment_25th_percentile" : 0,
    "Increment_median" : 0,
    "Increment_75th_percentile" : 0,
    "Increment_90th_percentile" : 0,
    "Increment_95th_percentile" : 0,
    "Increment_98th_percentile" : 0,
    "Increment_99th_percentile" : 0,
    "Increment_99.9th_percentile" : 0,
    "Delete_num_ops" : 0,
    "Delete_min" : 0,
    "Delete_max" : 0,
    "Delete_mean" : 0,
    "Delete_25th_percentile" : 0,
    "Delete_median" : 0,
    "Delete_75th_percentile" : 0,
    "Delete_90th_percentile" : 0,
    "Delete_95th_percentile" : 0,
    "Delete_98th_percentile" : 0,
    "Delete_99th_percentile" : 0,
    "Delete_99.9th_percentile" : 0,
    "Put_num_ops" : 0,
    "Put_min" : 0,
    "Put_max" : 0,
    "Put_mean" : 0,
    "Put_25th_percentile" : 0,
    "Put_median" : 0,
    "Put_75th_percentile" : 0,
    "Put_90th_percentile" : 0,
    "Put_95th_percentile" : 0,
    "Put_98th_percentile" : 0,
    "Put_99th_percentile" : 0,
    "Put_99.9th_percentile" : 0,
    "DeleteBatch_num_ops" : 0,
    "DeleteBatch_min" : 0,
    "DeleteBatch_max" : 0,
    "DeleteBatch_mean" : 0,
    "DeleteBatch_25th_percentile" : 0,
    "DeleteBatch_median" : 0,
    "DeleteBatch_75th_percentile" : 0,
    "DeleteBatch_90th_percentile" : 0,
    "DeleteBatch_95th_percentile" : 0,
    "DeleteBatch_98th_percentile" : 0,
    "DeleteBatch_99th_percentile" : 0,
    "DeleteBatch_99.9th_percentile" : 0,
    "splitRequestCount" : 4,
    "FlushMemstoreSize_num_ops" : 0,
    "FlushMemstoreSize_min" : 0,
    "FlushMemstoreSize_max" : 0,
    "FlushMemstoreSize_mean" : 0,
    "FlushMemstoreSize_25th_percentile" : 0,
    "FlushMemstoreSize_median" : 0,
    "FlushMemstoreSize_75th_percentile" : 0,
    "FlushMemstoreSize_90th_percentile" : 0,
    "FlushMemstoreSize_95th_percentile" : 0,
    "FlushMemstoreSize_98th_percentile" : 0,
    "FlushMemstoreSize_99th_percentile" : 0,
    "FlushMemstoreSize_99.9th_percentile" : 0,
    "CompactionInputFileCount_num_ops" : 6356,
    "CompactionInputFileCount_min" : 0,
    "CompactionInputFileCount_max" : 0,
    "CompactionInputFileCount_mean" : 0,
    "CompactionInputFileCount_25th_percentile" : 0,
    "CompactionInputFileCount_median" : 0,
    "CompactionInputFileCount_75th_percentile" : 0,
    "CompactionInputFileCount_90th_percentile" : 0,
    "CompactionInputFileCount_95th_percentile" : 0,
    "CompactionInputFileCount_98th_percentile" : 0,
    "CompactionInputFileCount_99th_percentile" : 0,
    "CompactionInputFileCount_99.9th_percentile" : 0,
    "PutBatch_num_ops" : 0,
    "PutBatch_min" : 0,
    "PutBatch_max" : 0,
    "PutBatch_mean" : 0,
    "PutBatch_25th_percentile" : 0,
    "PutBatch_median" : 0,
    "PutBatch_75th_percentile" : 0,
    "PutBatch_90th_percentile" : 0,
    "PutBatch_95th_percentile" : 0,
    "PutBatch_98th_percentile" : 0,
    "PutBatch_99th_percentile" : 0,
    "PutBatch_99.9th_percentile" : 0,
    "CompactionTime_num_ops" : 6356,
    "CompactionTime_min" : 0,
    "CompactionTime_max" : 0,
    "CompactionTime_mean" : 0,
    "CompactionTime_25th_percentile" : 0,
    "CompactionTime_median" : 0,
    "CompactionTime_75th_percentile" : 0,
    "CompactionTime_90th_percentile" : 0,
    "CompactionTime_95th_percentile" : 0,
    "CompactionTime_98th_percentile" : 0,
    "CompactionTime_99th_percentile" : 0,
    "CompactionTime_99.9th_percentile" : 0,
    "Get_num_ops" : 509706333,
    "Get_min" : 0,
    "Get_max" : 0,
    "Get_mean" : 0,
    "Get_25th_percentile" : 0,
    "Get_median" : 0,
    "Get_75th_percentile" : 0,
    "Get_90th_percentile" : 0,
    "Get_95th_percentile" : 0,
    "Get_98th_percentile" : 0,
    "Get_99th_percentile" : 0,
    "Get_99.9th_percentile" : 0,
    "MajorCompactionInputFileCount_num_ops" : 1337,
    "MajorCompactionInputFileCount_min" : 0,
    "MajorCompactionInputFileCount_max" : 0,
    "MajorCompactionInputFileCount_mean" : 0,
    "MajorCompactionInputFileCount_25th_percentile" : 0,
    "MajorCompactionInputFileCount_median" : 0,
    "MajorCompactionInputFileCount_75th_percentile" : 0,
    "MajorCompactionInputFileCount_90th_percentile" : 0,
    "MajorCompactionInputFileCount_95th_percentile" : 0,
    "MajorCompactionInputFileCount_98th_percentile" : 0,
    "MajorCompactionInputFileCount_99th_percentile" : 0,
    "MajorCompactionInputFileCount_99.9th_percentile" : 0,
    "CheckAndPut_num_ops" : 0,
    "CheckAndPut_min" : 0,
    "CheckAndPut_max" : 0,
    "CheckAndPut_mean" : 0,
    "CheckAndPut_25th_percentile" : 0,
    "CheckAndPut_median" : 0,
    "CheckAndPut_75th_percentile" : 0,
    "CheckAndPut_90th_percentile" : 0,
    "CheckAndPut_95th_percentile" : 0,
    "CheckAndPut_98th_percentile" : 0,
    "CheckAndPut_99th_percentile" : 0,
    "CheckAndPut_99.9th_percentile" : 0,
    "SplitTime_num_ops" : 0,
    "SplitTime_min" : 0,
    "SplitTime_max" : 0,
    "SplitTime_mean" : 0,
    "SplitTime_25th_percentile" : 0,
    "SplitTime_median" : 0,
    "SplitTime_75th_percentile" : 0,
    "SplitTime_90th_percentile" : 0,
    "SplitTime_95th_percentile" : 0,
    "SplitTime_98th_percentile" : 0,
    "SplitTime_99th_percentile" : 0,
    "SplitTime_99.9th_percentile" : 0,
    "MajorCompactionOutputSize_num_ops" : 1337,
    "MajorCompactionOutputSize_min" : 0,
    "MajorCompactionOutputSize_max" : 0,
    "MajorCompactionOutputSize_mean" : 0,
    "MajorCompactionOutputSize_25th_percentile" : 0,
    "MajorCompactionOutputSize_median" : 0,
    "MajorCompactionOutputSize_75th_percentile" : 0,
    "MajorCompactionOutputSize_90th_percentile" : 0,
    "MajorCompactionOutputSize_95th_percentile" : 0,
    "MajorCompactionOutputSize_98th_percentile" : 0,
    "MajorCompactionOutputSize_99th_percentile" : 0,
    "MajorCompactionOutputSize_99.9th_percentile" : 0,
    "majorCompactedInputBytes" : 10549529700616,
    "slowAppendCount" : 0,
    "flushedOutputBytes" : 0,
    "CompactionOutputFileCount_num_ops" : 6356,
    "CompactionOutputFileCount_min" : 0,
    "CompactionOutputFileCount_max" : 0,
    "CompactionOutputFileCount_mean" : 0,
    "CompactionOutputFileCount_25th_percentile" : 0,
    "CompactionOutputFileCount_median" : 0,
    "CompactionOutputFileCount_75th_percentile" : 0,
    "CompactionOutputFileCount_90th_percentile" : 0,
    "CompactionOutputFileCount_95th_percentile" : 0,
    "CompactionOutputFileCount_98th_percentile" : 0,
    "CompactionOutputFileCount_99th_percentile" : 0,
    "CompactionOutputFileCount_99.9th_percentile" : 0,
    "slowDeleteCount" : 0,
    "Replay_num_ops" : 0,
    "Replay_min" : 0,
    "Replay_max" : 0,
    "Replay_mean" : 0,
    "Replay_25th_percentile" : 0,
    "Replay_median" : 0,
    "Replay_75th_percentile" : 0,
    "Replay_90th_percentile" : 0,
    "Replay_95th_percentile" : 0,
    "Replay_98th_percentile" : 0,
    "Replay_99th_percentile" : 0,
    "Replay_99.9th_percentile" : 0,
    "FlushTime_num_ops" : 0,
    "FlushTime_min" : 0,
    "FlushTime_max" : 0,
    "FlushTime_mean" : 0,
    "FlushTime_25th_percentile" : 0,
    "FlushTime_median" : 0,
    "FlushTime_75th_percentile" : 0,
    "FlushTime_90th_percentile" : 0,
    "FlushTime_95th_percentile" : 0,
    "FlushTime_98th_percentile" : 0,
    "FlushTime_99th_percentile" : 0,
    "FlushTime_99.9th_percentile" : 0,
    "MajorCompactionInputSize_num_ops" : 1337,
    "MajorCompactionInputSize_min" : 0,
    "MajorCompactionInputSize_max" : 0,
    "MajorCompactionInputSize_mean" : 0,
    "MajorCompactionInputSize_25th_percentile" : 0,
    "MajorCompactionInputSize_median" : 0,
    "MajorCompactionInputSize_75th_percentile" : 0,
    "MajorCompactionInputSize_90th_percentile" : 0,
    "MajorCompactionInputSize_95th_percentile" : 0,
    "MajorCompactionInputSize_98th_percentile" : 0,
    "MajorCompactionInputSize_99th_percentile" : 0,
    "MajorCompactionInputSize_99.9th_percentile" : 0,
    "pauseInfoThresholdExceeded" : 35,
    "splitSuccessCount" : 0,
    "CheckAndDelete_num_ops" : 0,
    "CheckAndDelete_min" : 0,
    "CheckAndDelete_max" : 0,
    "CheckAndDelete_mean" : 0,
    "CheckAndDelete_25th_percentile" : 0,
    "CheckAndDelete_median" : 0,
    "CheckAndDelete_75th_percentile" : 0,
    "CheckAndDelete_90th_percentile" : 0,
    "CheckAndDelete_95th_percentile" : 0,
    "CheckAndDelete_98th_percentile" : 0,
    "CheckAndDelete_99th_percentile" : 0,
    "CheckAndDelete_99.9th_percentile" : 0,
    "CompactionInputSize_num_ops" : 6356,
    "CompactionInputSize_min" : 0,
    "CompactionInputSize_max" : 0,
    "CompactionInputSize_mean" : 0,
    "CompactionInputSize_25th_percentile" : 0,
    "CompactionInputSize_median" : 0,
    "CompactionInputSize_75th_percentile" : 0,
    "CompactionInputSize_90th_percentile" : 0,
    "CompactionInputSize_95th_percentile" : 0,
    "CompactionInputSize_98th_percentile" : 0,
    "CompactionInputSize_99th_percentile" : 0,
    "CompactionInputSize_99.9th_percentile" : 0,
    "MajorCompactionOutputFileCount_num_ops" : 1337,
    "MajorCompactionOutputFileCount_min" : 0,
    "MajorCompactionOutputFileCount_max" : 0,
    "MajorCompactionOutputFileCount_mean" : 0,
    "MajorCompactionOutputFileCount_25th_percentile" : 0,
    "MajorCompactionOutputFileCount_median" : 0,
    "MajorCompactionOutputFileCount_75th_percentile" : 0,
    "MajorCompactionOutputFileCount_90th_percentile" : 0,
    "MajorCompactionOutputFileCount_95th_percentile" : 0,
    "MajorCompactionOutputFileCount_98th_percentile" : 0,
    "MajorCompactionOutputFileCount_99th_percentile" : 0,
    "MajorCompactionOutputFileCount_99.9th_percentile" : 0,
    "ScanSize_num_ops" : 0,
    "ScanSize_min" : 0,
    "ScanSize_max" : 0,
    "ScanSize_mean" : 0,
    "ScanSize_25th_percentile" : 0,
    "ScanSize_median" : 0,
    "ScanSize_75th_percentile" : 0,
    "ScanSize_90th_percentile" : 0,
    "ScanSize_95th_percentile" : 0,
    "ScanSize_98th_percentile" : 0,
    "ScanSize_99th_percentile" : 0,
    "ScanSize_99.9th_percentile" : 0,
    "slowGetCount" : 2264,
    "flushedMemstoreBytes" : 0,
    "CompactionOutputSize_num_ops" : 6356,
    "CompactionOutputSize_min" : 0,
    "CompactionOutputSize_max" : 0,
    "CompactionOutputSize_mean" : 0,
    "CompactionOutputSize_25th_percentile" : 0,
    "CompactionOutputSize_median" : 0,
    "CompactionOutputSize_75th_percentile" : 0,
    "CompactionOutputSize_90th_percentile" : 0,
    "CompactionOutputSize_95th_percentile" : 0,
    "CompactionOutputSize_98th_percentile" : 0,
    "CompactionOutputSize_99th_percentile" : 0,
    "CompactionOutputSize_99.9th_percentile" : 0,
    "majorCompactedOutputBytes" : 9473720985791,
    "PauseTimeWithoutGc_num_ops" : 0,
    "PauseTimeWithoutGc_min" : 0,
    "PauseTimeWithoutGc_max" : 0,
    "PauseTimeWithoutGc_mean" : 0,
    "PauseTimeWithoutGc_25th_percentile" : 0,
    "PauseTimeWithoutGc_median" : 0,
    "PauseTimeWithoutGc_75th_percentile" : 0,
    "PauseTimeWithoutGc_90th_percentile" : 0,
    "PauseTimeWithoutGc_95th_percentile" : 0,
    "PauseTimeWithoutGc_98th_percentile" : 0,
    "PauseTimeWithoutGc_99th_percentile" : 0,
    "PauseTimeWithoutGc_99.9th_percentile" : 0,
    "slowPutCount" : 0,
    "slowIncrementCount" : 0,
    "compactedInputBytes" : 26919647124205,
    "Append_num_ops" : 0,
    "Append_min" : 0,
    "Append_max" : 0,
    "Append_mean" : 0,
    "Append_25th_percentile" : 0,
    "Append_median" : 0,
    "Append_75th_percentile" : 0,
    "Append_90th_percentile" : 0,
    "Append_95th_percentile" : 0,
    "Append_98th_percentile" : 0,
    "Append_99th_percentile" : 0,
    "Append_99.9th_percentile" : 0,
    "FlushOutputSize_num_ops" : 0,
    "FlushOutputSize_min" : 0,
    "FlushOutputSize_max" : 0,
    "FlushOutputSize_mean" : 0,
    "FlushOutputSize_25th_percentile" : 0,
    "FlushOutputSize_median" : 0,
    "FlushOutputSize_75th_percentile" : 0,
    "FlushOutputSize_90th_percentile" : 0,
    "FlushOutputSize_95th_percentile" : 0,
    "FlushOutputSize_98th_percentile" : 0,
    "FlushOutputSize_99th_percentile" : 0,
    "FlushOutputSize_99.9th_percentile" : 0,
    "Bulkload_count" : 11883,
    "Bulkload_mean_rate" : 9.275419960206437E-4,
    "Bulkload_1min_rate" : 0.003998550250995539,
    "Bulkload_5min_rate" : 0.014938702838813355,
    "Bulkload_15min_rate" : 0.008729489346842588,
    "Bulkload_num_ops" : 11883,
    "Bulkload_min" : 0,
    "Bulkload_max" : 0,
    "Bulkload_mean" : 0,
    "Bulkload_25th_percentile" : 0,
    "Bulkload_median" : 0,
    "Bulkload_75th_percentile" : 0,
    "Bulkload_90th_percentile" : 0,
    "Bulkload_95th_percentile" : 0,
    "Bulkload_98th_percentile" : 0,
    "Bulkload_99th_percentile" : 0,
    "Bulkload_99.9th_percentile" : 0
  }, {
    "name" : "Hadoop:service=HBase,name=RegionServer,sub=Memory",
    "modelerType" : "RegionServer,sub=Memory",
    "tag.Context" : "regionserver",
    "tag.Hostname" : "gzxy-hbase02-node04.idc01.com",
    "blockedFlushGauge" : 0,
    "memStoreSize" : 0,
    "IncreaseBlockCacheSize_num_ops" : 0,
    "IncreaseBlockCacheSize_min" : 0,
    "IncreaseBlockCacheSize_max" : 0,
    "IncreaseBlockCacheSize_mean" : 0,
    "IncreaseBlockCacheSize_25th_percentile" : 0,
    "IncreaseBlockCacheSize_median" : 0,
    "IncreaseBlockCacheSize_75th_percentile" : 0,
    "IncreaseBlockCacheSize_90th_percentile" : 0,
    "IncreaseBlockCacheSize_95th_percentile" : 0,
    "IncreaseBlockCacheSize_98th_percentile" : 0,
    "IncreaseBlockCacheSize_99th_percentile" : 0,
    "IncreaseBlockCacheSize_99.9th_percentile" : 0,
    "unblockedFlushGauge" : 0,
    "DecreaseBlockCacheSize_num_ops" : 0,
    "DecreaseBlockCacheSize_min" : 0,
    "DecreaseBlockCacheSize_max" : 0,
    "DecreaseBlockCacheSize_mean" : 0,
    "DecreaseBlockCacheSize_25th_percentile" : 0,
    "DecreaseBlockCacheSize_median" : 0,
    "DecreaseBlockCacheSize_75th_percentile" : 0,
    "DecreaseBlockCacheSize_90th_percentile" : 0,
    "DecreaseBlockCacheSize_95th_percentile" : 0,
    "DecreaseBlockCacheSize_98th_percentile" : 0,
    "DecreaseBlockCacheSize_99th_percentile" : 0,
    "DecreaseBlockCacheSize_99.9th_percentile" : 0,
    "IncreaseMemStoreSize_num_ops" : 0,
    "IncreaseMemStoreSize_min" : 0,
    "IncreaseMemStoreSize_max" : 0,
    "IncreaseMemStoreSize_mean" : 0,
    "IncreaseMemStoreSize_25th_percentile" : 0,
    "IncreaseMemStoreSize_median" : 0,
    "IncreaseMemStoreSize_75th_percentile" : 0,
    "IncreaseMemStoreSize_90th_percentile" : 0,
    "IncreaseMemStoreSize_95th_percentile" : 0,
    "IncreaseMemStoreSize_98th_percentile" : 0,
    "IncreaseMemStoreSize_99th_percentile" : 0,
    "IncreaseMemStoreSize_99.9th_percentile" : 0,
    "BlockedFlushes_num_ops" : 0,
    "BlockedFlushes_min" : 0,
    "BlockedFlushes_max" : 0,
    "BlockedFlushes_mean" : 0,
    "BlockedFlushes_25th_percentile" : 0,
    "BlockedFlushes_median" : 0,
    "BlockedFlushes_75th_percentile" : 0,
    "BlockedFlushes_90th_percentile" : 0,
    "BlockedFlushes_95th_percentile" : 0,
    "BlockedFlushes_98th_percentile" : 0,
    "BlockedFlushes_99th_percentile" : 0,
    "BlockedFlushes_99.9th_percentile" : 0,
    "DecreaseMemStoreSize_num_ops" : 0,
    "DecreaseMemStoreSize_min" : 0,
    "DecreaseMemStoreSize_max" : 0,
    "DecreaseMemStoreSize_mean" : 0,
    "DecreaseMemStoreSize_25th_percentile" : 0,
    "DecreaseMemStoreSize_median" : 0,
    "DecreaseMemStoreSize_75th_percentile" : 0,
    "DecreaseMemStoreSize_90th_percentile" : 0,
    "DecreaseMemStoreSize_95th_percentile" : 0,
    "DecreaseMemStoreSize_98th_percentile" : 0,
    "DecreaseMemStoreSize_99th_percentile" : 0,
    "DecreaseMemStoreSize_99.9th_percentile" : 0,
    "tunerDoNothingCounter" : 0,
    "UnblockedFlushes_num_ops" : 0,
    "UnblockedFlushes_min" : 0,
    "UnblockedFlushes_max" : 0,
    "UnblockedFlushes_mean" : 0,
    "UnblockedFlushes_25th_percentile" : 0,
    "UnblockedFlushes_median" : 0,
    "UnblockedFlushes_75th_percentile" : 0,
    "UnblockedFlushes_90th_percentile" : 0,
    "UnblockedFlushes_95th_percentile" : 0,
    "UnblockedFlushes_98th_percentile" : 0,
    "UnblockedFlushes_99th_percentile" : 0,
    "UnblockedFlushes_99.9th_percentile" : 0,
    "aboveHeapOccupancyLowWaterMarkCounter" : 0,
    "blockCacheSize" : 0
  }, {
    "name" : "Hadoop:service=HBase,name=RegionServer,sub=IPC",
    "modelerType" : "RegionServer,sub=IPC",
    "tag.Context" : "regionserver",
    "tag.Hostname" : "gzxy-hbase02-node04.idc01.com",
    "queueSize" : 0,
    "numCallsInGeneralQueue" : 0,
    "numCallsInReplicationQueue" : 0,
    "numCallsInPriorityQueue" : 0,
    "numCallsInMetaPriorityQueue" : 0,
    "numOpenConnections" : 0,
    "numActiveHandler" : 0,
    "numGeneralCallsDropped" : 0,
    "numLifoModeSwitches" : 0,
    "numCallsInWriteQueue" : 0,
    "numCallsInReadQueue" : 0,
    "numCallsInScanQueue" : 0,
    "numActiveWriteHandler" : 0,
    "numActiveReadHandler" : 0,
    "numActiveScanHandler" : 0,
    "receivedBytes" : 5578235163994,
    "exceptions.RegionMovedException" : 302,
    "exceptions.multiResponseTooLarge" : 0,
    "authenticationSuccesses" : 0,
    "authorizationFailures" : 0,
    "TotalCallTime_num_ops" : 509718932,
    "TotalCallTime_min" : 0,
    "TotalCallTime_max" : 0,
    "TotalCallTime_mean" : 0,
    "TotalCallTime_25th_percentile" : 0,
    "TotalCallTime_median" : 0,
    "TotalCallTime_75th_percentile" : 0,
    "TotalCallTime_90th_percentile" : 0,
    "TotalCallTime_95th_percentile" : 0,
    "TotalCallTime_98th_percentile" : 0,
    "TotalCallTime_99th_percentile" : 0,
    "TotalCallTime_99.9th_percentile" : 0,
    "exceptions.RegionTooBusyException" : 0,
    "exceptions.FailedSanityCheckException" : 0,
    "ResponseSize_num_ops" : 509718932,
    "ResponseSize_min" : 0,
    "ResponseSize_max" : 0,
    "ResponseSize_mean" : 0,
    "ResponseSize_25th_percentile" : 0,
    "ResponseSize_median" : 0,
    "ResponseSize_75th_percentile" : 0,
    "ResponseSize_90th_percentile" : 0,
    "ResponseSize_95th_percentile" : 0,
    "ResponseSize_98th_percentile" : 0,
    "ResponseSize_99th_percentile" : 0,
    "ResponseSize_99.9th_percentile" : 0,
    "exceptions.UnknownScannerException" : 0,
    "exceptions.OutOfOrderScannerNextException" : 0,
    "exceptions" : 744,
    "ProcessCallTime_num_ops" : 509718932,
    "ProcessCallTime_min" : 0,
    "ProcessCallTime_max" : 0,
    "ProcessCallTime_mean" : 0,
    "ProcessCallTime_25th_percentile" : 0,
    "ProcessCallTime_median" : 0,
    "ProcessCallTime_75th_percentile" : 0,
    "ProcessCallTime_90th_percentile" : 0,
    "ProcessCallTime_95th_percentile" : 0,
    "ProcessCallTime_98th_percentile" : 0,
    "ProcessCallTime_99th_percentile" : 0,
    "ProcessCallTime_99.9th_percentile" : 0,
    "authenticationFallbacks" : 0,
    "exceptions.NotServingRegionException" : 442,
    "exceptions.callQueueTooBig" : 0,
    "authorizationSuccesses" : 5282,
    "exceptions.ScannerResetException" : 0,
    "RequestSize_num_ops" : 509718932,
    "RequestSize_min" : 0,
    "RequestSize_max" : 0,
    "RequestSize_mean" : 0,
    "RequestSize_25th_percentile" : 0,
    "RequestSize_median" : 0,
    "RequestSize_75th_percentile" : 0,
    "RequestSize_90th_percentile" : 0,
    "RequestSize_95th_percentile" : 0,
    "RequestSize_98th_percentile" : 0,
    "RequestSize_99th_percentile" : 0,
    "RequestSize_99.9th_percentile" : 0,
    "sentBytes" : 684595932924,
    "QueueCallTime_num_ops" : 509718932,
    "QueueCallTime_min" : 0,
    "QueueCallTime_max" : 0,
    "QueueCallTime_mean" : 0,
    "QueueCallTime_25th_percentile" : 0,
    "QueueCallTime_median" : 0,
    "QueueCallTime_75th_percentile" : 0,
    "QueueCallTime_90th_percentile" : 0,
    "QueueCallTime_95th_percentile" : 0,
    "QueueCallTime_98th_percentile" : 0,
    "QueueCallTime_99th_percentile" : 0,
    "QueueCallTime_99.9th_percentile" : 0,
    "authenticationFailures" : 0
  }, {
    "name" : "java.lang:type=Memory",
    "modelerType" : "sun.management.MemoryImpl",
    "HeapMemoryUsage" : {
      "committed" : 68719476736,
      "init" : 68719476736,
      "max" : 68719476736,
      "used" : 31066454016
    },
    "NonHeapMemoryUsage" : {
      "committed" : 751894528,
      "init" : 2555904,
      "max" : -1,
      "used" : 510309880
    },
    "ObjectPendingFinalizationCount" : 0,
    "Verbose" : true,
    "ObjectName" : "java.lang:type=Memory"
  }, {
    "name" : "java.lang:type=MemoryPool,name=G1 Eden Space",
    "modelerType" : "sun.management.MemoryPoolImpl",
    "Valid" : true,
    "Usage" : {
      "committed" : 24897388544,
      "init" : 3623878656,
      "max" : -1,
      "used" : 12750684160
    },
    "PeakUsage" : {
      "committed" : 43251662848,
      "init" : 3623878656,
      "max" : -1,
      "used" : 41204842496
    },
    "MemoryManagerNames" : [ "G1 Old Generation", "G1 Young Generation" ],
    "UsageThresholdSupported" : false,
    "CollectionUsageThreshold" : 0,
    "CollectionUsageThresholdExceeded" : false,
    "CollectionUsageThresholdCount" : 0,
    "CollectionUsage" : {
      "committed" : 24897388544,
      "init" : 3623878656,
      "max" : -1,
      "used" : 0
    },
    "CollectionUsageThresholdSupported" : true,
    "Name" : "G1 Eden Space",
    "Type" : "HEAP",
    "ObjectName" : "java.lang:type=MemoryPool,name=G1 Eden Space"
  }, {
    "name" : "java.nio:type=BufferPool,name=mapped",
    "modelerType" : "sun.management.ManagementFactoryHelper$1",
    "MemoryUsed" : 0,
    "TotalCapacity" : 0,
    "Count" : 0,
    "Name" : "mapped",
    "ObjectName" : "java.nio:type=BufferPool,name=mapped"
  }, {
    "name" : "com.sun.management:type=DiagnosticCommand",
    "modelerType" : "sun.management.DiagnosticCommandImpl"
  }, {
    "name" : "Hadoop:service=HBase,name=RegionServer,sub=Users",
    "modelerType" : "RegionServer,sub=Users",
    "tag.Context" : "regionserver",
    "tag.Hostname" : "gzxy-hbase02-node04.idc01.com",
    "numUsers" : 1,
    "User_finapp_metric_get_num_ops" : 509706333,
    "User_finapp_metric_get_min" : 0,
    "User_finapp_metric_get_max" : 0,
    "User_finapp_metric_get_mean" : 0,
    "User_finapp_metric_get_25th_percentile" : 0,
    "User_finapp_metric_get_median" : 0,
    "User_finapp_metric_get_75th_percentile" : 0,
    "User_finapp_metric_get_90th_percentile" : 0,
    "User_finapp_metric_get_95th_percentile" : 0,
    "User_finapp_metric_get_98th_percentile" : 0,
    "User_finapp_metric_get_99th_percentile" : 0,
    "User_finapp_metric_get_99.9th_percentile" : 0,
    "User_finapp_metric_scanTime_num_ops" : 0,
    "User_finapp_metric_scanTime_min" : 0,
    "User_finapp_metric_scanTime_max" : 0,
    "User_finapp_metric_scanTime_mean" : 0,
    "User_finapp_metric_scanTime_25th_percentile" : 0,
    "User_finapp_metric_scanTime_median" : 0,
    "User_finapp_metric_scanTime_75th_percentile" : 0,
    "User_finapp_metric_scanTime_90th_percentile" : 0,
    "User_finapp_metric_scanTime_95th_percentile" : 0,
    "User_finapp_metric_scanTime_98th_percentile" : 0,
    "User_finapp_metric_scanTime_99th_percentile" : 0,
    "User_finapp_metric_scanTime_99.9th_percentile" : 0,
    "User_finapp_metric_delete_num_ops" : 0,
    "User_finapp_metric_delete_min" : 0,
    "User_finapp_metric_delete_max" : 0,
    "User_finapp_metric_delete_mean" : 0,
    "User_finapp_metric_delete_25th_percentile" : 0,
    "User_finapp_metric_delete_median" : 0,
    "User_finapp_metric_delete_75th_percentile" : 0,
    "User_finapp_metric_delete_90th_percentile" : 0,
    "User_finapp_metric_delete_95th_percentile" : 0,
    "User_finapp_metric_delete_98th_percentile" : 0,
    "User_finapp_metric_delete_99th_percentile" : 0,
    "User_finapp_metric_delete_99.9th_percentile" : 0,
    "User_finapp_metric_increment_num_ops" : 0,
    "User_finapp_metric_increment_min" : 0,
    "User_finapp_metric_increment_max" : 0,
    "User_finapp_metric_increment_mean" : 0,
    "User_finapp_metric_increment_25th_percentile" : 0,
    "User_finapp_metric_increment_median" : 0,
    "User_finapp_metric_increment_75th_percentile" : 0,
    "User_finapp_metric_increment_90th_percentile" : 0,
    "User_finapp_metric_increment_95th_percentile" : 0,
    "User_finapp_metric_increment_98th_percentile" : 0,
    "User_finapp_metric_increment_99th_percentile" : 0,
    "User_finapp_metric_increment_99.9th_percentile" : 0,
    "User_finapp_metric_replay_num_ops" : 0,
    "User_finapp_metric_replay_min" : 0,
    "User_finapp_metric_replay_max" : 0,
    "User_finapp_metric_replay_mean" : 0,
    "User_finapp_metric_replay_25th_percentile" : 0,
    "User_finapp_metric_replay_median" : 0,
    "User_finapp_metric_replay_75th_percentile" : 0,
    "User_finapp_metric_replay_90th_percentile" : 0,
    "User_finapp_metric_replay_95th_percentile" : 0,
    "User_finapp_metric_replay_98th_percentile" : 0,
    "User_finapp_metric_replay_99th_percentile" : 0,
    "User_finapp_metric_replay_99.9th_percentile" : 0,
    "User_finapp_metric_put_num_ops" : 0,
    "User_finapp_metric_put_min" : 0,
    "User_finapp_metric_put_max" : 0,
    "User_finapp_metric_put_mean" : 0,
    "User_finapp_metric_put_25th_percentile" : 0,
    "User_finapp_metric_put_median" : 0,
    "User_finapp_metric_put_75th_percentile" : 0,
    "User_finapp_metric_put_90th_percentile" : 0,
    "User_finapp_metric_put_95th_percentile" : 0,
    "User_finapp_metric_put_98th_percentile" : 0,
    "User_finapp_metric_put_99th_percentile" : 0,
    "User_finapp_metric_put_99.9th_percentile" : 0,
    "User_finapp_metric_append_num_ops" : 0,
    "User_finapp_metric_append_min" : 0,
    "User_finapp_metric_append_max" : 0,
    "User_finapp_metric_append_mean" : 0,
    "User_finapp_metric_append_25th_percentile" : 0,
    "User_finapp_metric_append_median" : 0,
    "User_finapp_metric_append_75th_percentile" : 0,
    "User_finapp_metric_append_90th_percentile" : 0,
    "User_finapp_metric_append_95th_percentile" : 0,
    "User_finapp_metric_append_98th_percentile" : 0,
    "User_finapp_metric_append_99th_percentile" : 0,
    "User_finapp_metric_append_99.9th_percentile" : 0
  }, {
    "name" : "Hadoop:service=HBase,name=UgiMetrics",
    "modelerType" : "UgiMetrics",
    "tag.Context" : "ugi",
    "tag.Hostname" : "gzxy-hbase02-node04.idc01.com",
    "LoginSuccessNumOps" : 1,
    "LoginSuccessAvgTime" : 3.0,
    "LoginFailureNumOps" : 0,
    "LoginFailureAvgTime" : 0.0,
    "GetGroupsNumOps" : 0,
    "GetGroupsAvgTime" : 0.0,
    "RenewalFailuresTotal" : 0,
    "RenewalFailures" : 0
  }, {
    "name" : "com.sun.management:type=HotSpotDiagnostic",
    "modelerType" : "sun.management.HotSpotDiagnostic",
    "DiagnosticOptions" : [ {
      "name" : "HeapDumpBeforeFullGC",
      "origin" : "DEFAULT",
      "value" : "false",
      "writeable" : true
    }, {
      "name" : "HeapDumpAfterFullGC",
      "origin" : "DEFAULT",
      "value" : "false",
      "writeable" : true
    }, {
      "name" : "HeapDumpOnOutOfMemoryError",
      "origin" : "DEFAULT",
      "value" : "false",
      "writeable" : true
    }, {
      "name" : "HeapDumpPath",
      "origin" : "DEFAULT",
      "value" : "",
      "writeable" : true
    }, {
      "name" : "CMSAbortablePrecleanWaitMillis",
      "origin" : "DEFAULT",
      "value" : "100",
      "writeable" : true
    }, {
      "name" : "CMSWaitDuration",
      "origin" : "DEFAULT",
      "value" : "2000",
      "writeable" : true
    }, {
      "name" : "CMSTriggerInterval",
      "origin" : "DEFAULT",
      "value" : "-1",
      "writeable" : true
    }, {
      "name" : "PrintGC",
      "origin" : "VM_CREATION",
      "value" : "true",
      "writeable" : true
    }, {
      "name" : "PrintGCDetails",
      "origin" : "VM_CREATION",
      "value" : "true",
      "writeable" : true
    }, {
      "name" : "PrintGCDateStamps",
      "origin" : "VM_CREATION",
      "value" : "true",
      "writeable" : true
    }, {
      "name" : "PrintGCTimeStamps",
      "origin" : "VM_CREATION",
      "value" : "true",
      "writeable" : true
    }, {
      "name" : "PrintGCID",
      "origin" : "DEFAULT",
      "value" : "false",
      "writeable" : true
    }, {
      "name" : "PrintClassHistogramBeforeFullGC",
      "origin" : "DEFAULT",
      "value" : "false",
      "writeable" : true
    }, {
      "name" : "PrintClassHistogramAfterFullGC",
      "origin" : "DEFAULT",
      "value" : "false",
      "writeable" : true
    }, {
      "name" : "PrintClassHistogram",
      "origin" : "DEFAULT",
      "value" : "false",
      "writeable" : true
    }, {
      "name" : "MinHeapFreeRatio",
      "origin" : "DEFAULT",
      "value" : "40",
      "writeable" : true
    }, {
      "name" : "MaxHeapFreeRatio",
      "origin" : "DEFAULT",
      "value" : "70",
      "writeable" : true
    }, {
      "name" : "PrintConcurrentLocks",
      "origin" : "DEFAULT",
      "value" : "false",
      "writeable" : true
    }, {
      "name" : "UnlockCommercialFeatures",
      "origin" : "DEFAULT",
      "value" : "false",
      "writeable" : true
    } ],
    "ObjectName" : "com.sun.management:type=HotSpotDiagnostic"
  } ]
```

## HBase JMX Metrics 新增监控指标
 ### GC 信息变化
 HBase2 默认使用G1GC ，JMX中的日志新增了关于G1GC的监控日志 （Hbase1.x的CMS)

 ### 新增 RIT（Region-In-Transition ）日志的监控
 RIT 调整，参照[JIRA-HBASE-9194](https://issues.apache.org/jira/browse/HBASE-9194):

 ```
 {
    "name" : "Hadoop:service=HBase,name=Master,sub=AssignmentManager",
    "modelerType" : "Master,sub=AssignmentManager",
    "tag.Context" : "master",
    "tag.Hostname" : "szgl-dp-hadoop-dev03-9131.xxxx.com",
    "operationCount" : 5,
    "ritOldestAge" : 0,
    "RitDuration_num_ops" : 0,
    "RitDuration_min" : 0,
    "RitDuration_max" : 0,
    "RitDuration_mean" : 0,
    "RitDuration_25th_percentile" : 0,
    "RitDuration_median" : 0,
    "RitDuration_75th_percentile" : 0,
    "RitDuration_90th_percentile" : 0,
    "RitDuration_95th_percentile" : 0,
    "RitDuration_98th_percentile" : 0,
    "RitDuration_99th_percentile" : 0,
    "RitDuration_99.9th_percentile" : 0,
    "ritCount" : 0,
    "ritCountOverThreshold" : 0
  }

 ```
 HBase1.x  VS HBase2.x
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20220610185535.png)


### timeLine 监控

```
#  ====
# 新增timeline 监控 （没找到相关JIRA)
{
    "name" : "Hadoop:service=HBase,name=MetricsSystem,sub=Stats",
    "modelerType" : "MetricsSystem,sub=Stats",
    "tag.Context" : "metricssystem",
    "tag.Hostname" : "szgl-dp-hadoop-dev03-9131.xxxx.com",
    "NumActiveSources" : 11,
    "NumAllSources" : 11,
    "NumActiveSinks" : 1,
    "NumAllSinks" : 0,
    "Sink_timelineNumOps" : 25357,
    "Sink_timelineAvgTime" : 3.0,
    "Sink_timelineDropped" : 0,
    "Sink_timelineQsize" : 0,
    "SnapshotNumOps" : 304282,
    "SnapshotAvgTime" : 0.0,
    "PublishNumOps" : 25357,
    "PublishAvgTime" : 0.0,
    "DroppedPubAll" : 0
  }

```

# 参考

HBase 集群监控
https://developer.aliyun.com/article/225817
HBaseMetricsAssignment
https://hbase.apache.org/devapidocs/src-html/org/apache/hadoop/hbase/master/MetricsAssignmentManagerSource.html#line.52
