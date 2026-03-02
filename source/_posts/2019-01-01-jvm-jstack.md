---
layout: post
title: jdk jstack used guide
categories:
  - tech
tags:
  - blog
date: 2019-01-01 00:00:00
update: 2019-01-01 00:00:00
comments: false
excerpt: jdk jstack command used guide
---

# jstack used
使用`jstack`实用程序的故障（troubleshooting）排除技的用途/场景：
- Troubleshoot with jstack Utility 
- Force a Stack Dump (`jstack -F <pid> `,macos 用`jhsdb jstack` 替代)
- Stack Trace from a Core Dump (`jstack $JAVA_HOME/bin/java core`,`macos 用`jhsdb jstack` 替代)
- Mixed Stack (`jstack -m <pid> `,macos 用`jhsdb jstack` 替代)

# jstack trace thread stats
`jstack`排查`thread`是一个常用场景，以此为例：
```
#jps/jcmd  查找java进程

# 排查出blocking thread id 
$ top -Hp <<pid>>
```
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20220630195735.png)

```
# 将thread id 转换为16进制
# 6821
printf "%x\n" 26657
```
使用`jstack` 排查该`thread`:
```bash
$ jstack 47377 | grep -20 6821
```
![](https://raw.githubusercontent.com/ordiy/study_notes/master/res/image/node_image/blog_20220630200326.png)

当`thread`处于`BLOCKED`/`WAITING`需要重点观察。


## jstack Mixed Stack
```
jstack -m 10537
Attaching to process ID 10537, please wait...
Debugger attached successfully.
Server compiler detected.
JVM version is 25.181-b13
Deadlock Detection:

No deadlocks found.

----------------- 10538 -----------------
0x00007ff192812a35	__pthread_cond_wait + 0xc5
0x00007ff191938f15	_ZN13ObjectMonitor4waitElbP6Thread + 0xa75
0x00007ff191748272	JVM_MonitorWait + 0x182
0x00007ff17d0186c7	* java.lang.Object.wait(long) bci:0 (Interpreted frame)
0x00007ff17d0082bd	* java.lang.Object.wait() bci:2 line:502 (Interpreted frame)
0x00007ff17d0082bd	* org.eclipse.jetty.util.thread.QueuedThreadPool.join() bci:18 line:391 (Interpreted frame)
0x00007ff17d008302	* org.eclipse.jetty.server.Server.join() bci:4 line:411 (Interpreted frame)
0x00007ff17d0082bd	* com.hortonworks.support.tools.server.SupportToolServer.run() bci:1287 line:304 (Interpreted frame)
0x00007ff17d0082bd	* com.hortonworks.support.tools.server.SupportToolServer.main(java.lang.String[]) bci:48 line:651 (Interpreted frame)
0x00007ff17d0007a7	<StubRoutines>
0x00007ff1916b5a76	_ZN9JavaCalls11call_helperEP9JavaValueP12methodHandleP17JavaCallArgumentsP6Thread + 0x1056
0x00007ff1916f71c2	_ZL17jni_invoke_staticP7JNIEnv_P9JavaValueP8_jobject11JNICallTypeP10_jmethodIDP18JNI_ArgumentPusherP6Thread + 0x362
0x00007ff191713a2a	jni_CallStaticVoidMethod + 0x17a
0x00007ff1925f90ff	JavaMain + 0x81f
```

# 扩展
Oracle在JDK文档建议使用`jcmd`替代`jstack`.


# 参考
- [man jstack](https://docs.oracle.com/javase/8/docs/technotes/tools/unix/jstack.html)
- [jstack utile](https://docs.oracle.com/javase/8/docs/technotes/guides/troubleshoot/tooldescr016.html)
- https://www.cnblogs.com/myseries/p/12050083.html
