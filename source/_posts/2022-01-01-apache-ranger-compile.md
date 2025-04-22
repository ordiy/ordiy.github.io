---
layout: post
title: Apache Ranger 2.1 compile 
categories:
  - tech
tags:
  - blog
date: 2022-11-09 10:15:45
excerpt: apache maven ranger compile 笔记
---

# 环境信息
```javascript
MacOS MBC2019 
JDK:1.8
maven:3.8
python3
```

# compile
```javascript
wget 


# mvn -DskipJSTests   -DskipTests=false -Dmaven.test.skip  -Drat.numUnapprovedLicenses=200  compile package install 
```

```javascript
[ERROR] Failed to execute goal org.apache.rat:apache-rat-plugin:0.11:check (default) on project ranger: Too many files with unapproved license: 1 See RAT report in: /opt/ordiy/compile/apache-ranger-2.1.0/target/rat.txt -> [Help 1]
[ERROR]
[ERROR] To see the full stack trace of the errors, re-run Maven with the -e switch.
[ERROR] Re-run Maven using the -X switch to enable full debug logging.
[ERROR]
[ERROR] For more information about the errors and possible solutions, please read the following articles:
[ERROR] [Help 1] http://cwiki.apache.org/confluence/display/MAVEN/MojoFailureException
```
rat问题，设置`-Drat.skip `或者`-Drat.numUnapprovedLicenses=200`。
*注：`rat.numUnapprovedLicenses`时将project 中不同license数量设置为一个较大的数，避免rat check failed.


```bash
mvn -DskipJSTests -DskipTests=false -Dmaven.test.skip  -Drat.numUnapprovedLicenses=200  compile package install assembly:assembly
```
log:
```javascript
[INFO] ranger ............................................. SUCCESS [  4.833 s]
[INFO] Jdbc SQL Connector ................................. SUCCESS [  2.956 s]
[INFO] Credential Support ................................. SUCCESS [  3.797 s]
[INFO] Audit Component .................................... SUCCESS [ 11.290 s]
[INFO] ranger-plugin-classloader .......................... SUCCESS [  1.612 s]
[INFO] Common library for Plugins ......................... SUCCESS [ 32.003 s]
[INFO] ranger-intg ........................................ SUCCESS [  3.696 s]
[INFO] Installer Support Component ........................ SUCCESS [  1.070 s]
[INFO] Credential Builder ................................. SUCCESS [  1.899 s]
[INFO] Embedded Web Server Invoker ........................ SUCCESS [  3.134 s]
[INFO] Key Management Service ............................. SUCCESS [ 13.725 s]
[INFO] HBase Security Plugin Shim ......................... SUCCESS [  6.954 s]
[INFO] HBase Security Plugin .............................. SUCCESS [  9.716 s]
[INFO] Hdfs Security Plugin ............................... SUCCESS [  2.647 s]
[INFO] Hive Security Plugin ............................... SUCCESS [ 12.196 s]
[INFO] Knox Security Plugin Shim .......................... SUCCESS [  4.353 s]
[INFO] Knox Security Plugin ............................... SUCCESS [  6.500 s]
[INFO] Storm Security Plugin .............................. SUCCESS [  5.358 s]
[INFO] YARN Security Plugin ............................... SUCCESS [  4.189 s]
[INFO] Ozone Security Plugin .............................. SUCCESS [  4.974 s]
[INFO] Ranger Util ........................................ SUCCESS [  5.441 s]
[INFO] Unix Authentication Client ......................... SUCCESS [  1.849 s]
[INFO] Security Admin Web Application ..................... SUCCESS [01:54 min]
[INFO] KAFKA Security Plugin .............................. SUCCESS [  4.068 s]
[INFO] SOLR Security Plugin ............................... SUCCESS [  4.118 s]
[INFO] NiFi Security Plugin ............................... SUCCESS [  2.726 s]
[INFO] NiFi Registry Security Plugin ...................... SUCCESS [  2.915 s]
[INFO] Kudu Security Plugin ............................... SUCCESS [  2.656 s]
[INFO] Unix User Group Synchronizer ....................... SUCCESS [  7.212 s]
[INFO] Ldap Config Check Tool ............................. SUCCESS [  1.659 s]
[INFO] Unix Authentication Service ........................ SUCCESS [  2.587 s]
[INFO] Unix Native Authenticator .......................... SUCCESS [  2.326 s]
[INFO] KMS Security Plugin ................................ SUCCESS [  4.994 s]
[INFO] Tag Synchronizer ................................... SUCCESS [  6.361 s]
[INFO] Hdfs Security Plugin Shim .......................... SUCCESS [  2.423 s]
[INFO] Hive Security Plugin Shim .......................... SUCCESS [  7.411 s]
[INFO] YARN Security Plugin Shim .......................... SUCCESS [  2.274 s]
[INFO] OZONE Security Plugin Shim ......................... SUCCESS [  2.931 s]
[INFO] Storm Security Plugin shim ......................... SUCCESS [  2.930 s]
[INFO] KAFKA Security Plugin Shim ......................... SUCCESS [  2.820 s]
[INFO] SOLR Security Plugin Shim .......................... SUCCESS [  3.086 s]
[INFO] Atlas Security Plugin Shim ......................... SUCCESS [  2.970 s]
[INFO] KMS Security Plugin Shim ........................... SUCCESS [  4.632 s]
[INFO] ranger-examples .................................... SUCCESS [  0.212 s]
[INFO] Ranger Examples - Conditions and ContextEnrichers .. SUCCESS [  3.217 s]
[INFO] Ranger Examples - SampleApp ........................ SUCCESS [  1.268 s]
[INFO] Ranger Examples - Ranger Plugin for SampleApp ...... SUCCESS [  2.872 s]
[INFO] sample-client ...................................... SUCCESS [  3.022 s]
[INFO] Apache Ranger Examples Distribution ................ SUCCESS [ 11.337 s]
[INFO] Ranger Tools ....................................... SUCCESS [ 22.163 s]
[INFO] Atlas Security Plugin .............................. SUCCESS [  4.947 s]
[INFO] SchemaRegistry Security Plugin ..................... FAILURE [39:57 min]
[INFO] Sqoop Security Plugin .............................. SKIPPED
[INFO] Sqoop Security Plugin Shim ......................... SKIPPED
[INFO] Kylin Security Plugin .............................. SKIPPED
[INFO] Kylin Security Plugin Shim ......................... SKIPPED
[INFO] Presto Security Plugin ............................. SKIPPED
[INFO] Presto Security Plugin Shim ........................ SKIPPED
[INFO] Elasticsearch Security Plugin Shim ................. SKIPPED
[INFO] Elasticsearch Security Plugin ...................... SKIPPED
[INFO] Apache Ranger Distribution ......................... SKIPPED
[INFO] ------------------------------------------------------------------------
[INFO] BUILD FAILURE
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  46:19 min
[INFO] Finished at: 2022-11-08T22:10:50+08:00
[INFO] ------------------------------------------------------------------------
[ERROR] Failed to execute goal on project ranger-schema-registry-plugin: Could not resolve dependencies for project org.apache.ranger:ranger-schema-registry-plugin:jar:2.1.0: The following artifacts could not be resolved: com.hortonworks.registries:registry-common:jar:0.8.1, io.dropwizard:dropwizard-views-freemarker:jar:1.2.4: Could not transfer artifact com.hortonworks.registries:registry-common:jar:0.8.1 from/to mirrorId (http://maven.apache.org/nexus/content/groups/public/): Transfer failed for http://maven.apache.org/nexus/content/groups/public/com/hortonworks/registries/registry-common/0.8.1/registry-common-0.8.1.jar: Read timed out -> [Help 1]
```

# 部分包下载问题,增减settings proxy   

```javascript
vim ~/.m2/settings.xml

    <proxy>
      <id>optional</id>
      <active>true</active>
      <protocol>http</protocol>
      <username>proxyuser</username>
      <password>proxypass</password>
      <host>127.0.0.1</host>
      <port>10092</port>
      <nonProxyHosts>*.myhostname.com|*.aliyun.com|*.huawei.com|local.net|some.host.com</nonProxyHosts>
    </proxy>
```

# 继续compile

```javascript
#遇到部分module 无法compile 成功,将module 注释,不进行编译
vim pom.xml 

<!--                <module>plugin-kylin</module>-->
<!--                <module>ranger-kylin-plugin-shim</module>-->

```

```javascript
[INFO] Building tar: /opt/ordiy/compile/apache-ranger-2.1.0/target/ranger-2.1.0-elasticsearch-plugin.tar.gz
[WARNING] artifact org.apache.ranger:ranger-distro:tar.gz:elasticsearch-plugin:2.1.0 already attached, replace previous instance
[INFO] Building jar: /opt/ordiy/compile/apache-ranger-2.1.0/target/ranger-2.1.0-schema-registry-plugin.jar
[INFO] ------------------------------------------------------------------------
[INFO] BUILD FAILURE
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  7.353 s (Wall Clock)
[INFO] Finished at: 2022-11-08T19:46:30+08:00
[INFO] ------------------------------------------------------------------------
[WARNING] The requested profile "compiler" could not be activated because it does not exist.
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-assembly-plugin:2.6:single (default) on project ranger-distro: Failed to create assembly: Error creating assembly archive schema-registry-plugin: IOException when zipping rMETA-INF/maven/org.apache.ranger/ranger-distro/pom.properties: ZipFile invalid LOC header (bad signature) -> [Help 1]
[ERROR]
[ERROR] To see the full stack trace of the errors, re-run Maven with the -e switch.
[ERROR] Re-run Maven using the -X switch to enable full debug logging.
[ERROR]
[ERROR] For more information about the errors and possible solutions, please read the following articles:
[ERROR] [Help 1] http://cwiki.apache.org/confluence/display/MAVEN/MojoExecutionException
```
这个Ranger2.1 版本的一个Bug: [https://issues.apache.org/jira/browse/RANGER-2721](https://issues.apache.org/jira/browse/RANGER-2721)

```javascript
 $ mvn -DskipJSTests   -DskipTests=false -Dmaven.test.skip  -Drat.numUnapprovedLicenses=200  compile package install

......

[INFO]
[INFO] ranger ............................................. SUCCESS [  2.710 s]
[INFO] Jdbc SQL Connector ................................. SUCCESS [  1.028 s]
[INFO] Credential Support ................................. SUCCESS [  1.291 s]
[INFO] Audit Component .................................... SUCCESS [  2.339 s]
[INFO] ranger-plugin-classloader .......................... SUCCESS [  0.268 s]
[INFO] Common library for Plugins ......................... SUCCESS [  2.541 s]
[INFO] ranger-intg ........................................ SUCCESS [  2.114 s]
[INFO] Installer Support Component ........................ SUCCESS [  0.289 s]
[INFO] Credential Builder ................................. SUCCESS [  0.635 s]
[INFO] Embedded Web Server Invoker ........................ SUCCESS [  1.339 s]
[INFO] Key Management Service ............................. SUCCESS [  2.254 s]
[INFO] HBase Security Plugin Shim ......................... SUCCESS [  2.536 s]
[INFO] HBase Security Plugin .............................. SUCCESS [  2.825 s]
[INFO] Hdfs Security Plugin ............................... SUCCESS [  1.274 s]
[INFO] Hive Security Plugin ............................... SUCCESS [  3.921 s]
[INFO] Knox Security Plugin Shim .......................... SUCCESS [  1.167 s]
[INFO] Knox Security Plugin ............................... SUCCESS [  2.170 s]
[INFO] Storm Security Plugin .............................. SUCCESS [  1.774 s]
[INFO] YARN Security Plugin ............................... SUCCESS [  0.982 s]
[INFO] Ozone Security Plugin .............................. SUCCESS [  1.678 s]
[INFO] Ranger Util ........................................ SUCCESS [  3.361 s]
[INFO] Unix Authentication Client ......................... SUCCESS [  0.336 s]
[INFO] Security Admin Web Application ..................... SUCCESS [ 59.679 s]
[INFO] KAFKA Security Plugin .............................. SUCCESS [  1.166 s]
[INFO] SOLR Security Plugin ............................... SUCCESS [  1.437 s]
[INFO] NiFi Security Plugin ............................... SUCCESS [  0.961 s]
[INFO] NiFi Registry Security Plugin ...................... SUCCESS [  0.943 s]
[INFO] Presto Security Plugin ............................. SUCCESS [  1.096 s]
[INFO] Kudu Security Plugin ............................... SUCCESS [  0.901 s]
[INFO] Unix User Group Synchronizer ....................... SUCCESS [  1.368 s]
[INFO] Ldap Config Check Tool ............................. SUCCESS [  0.236 s]
[INFO] Unix Authentication Service ........................ SUCCESS [  0.958 s]
[INFO] KMS Security Plugin ................................ SUCCESS [  1.288 s]
[INFO] Tag Synchronizer ................................... SUCCESS [  1.313 s]
[INFO] Hdfs Security Plugin Shim .......................... SUCCESS [  0.937 s]
[INFO] Hive Security Plugin Shim .......................... SUCCESS [  1.908 s]
[INFO] YARN Security Plugin Shim .......................... SUCCESS [  0.993 s]
[INFO] OZONE Security Plugin Shim ......................... SUCCESS [  1.094 s]
[INFO] Storm Security Plugin shim ......................... SUCCESS [  0.951 s]
[INFO] KAFKA Security Plugin Shim ......................... SUCCESS [  0.950 s]
[INFO] SOLR Security Plugin Shim .......................... SUCCESS [  1.250 s]
[INFO] Atlas Security Plugin Shim ......................... SUCCESS [  1.009 s]
[INFO] KMS Security Plugin Shim ........................... SUCCESS [  1.198 s]
[INFO] Presto Security Plugin Shim ........................ SUCCESS [  1.045 s]
[INFO] ranger-examples .................................... SUCCESS [  0.179 s]
[INFO] Ranger Examples - Conditions and ContextEnrichers .. SUCCESS [  0.828 s]
[INFO] Ranger Examples - SampleApp ........................ SUCCESS [  0.247 s]
[INFO] Ranger Examples - Ranger Plugin for SampleApp ...... SUCCESS [  0.898 s]
[INFO] sample-client ...................................... SUCCESS [  0.902 s]
[INFO] Apache Ranger Examples Distribution ................ SUCCESS [  3.002 s]
[INFO] Ranger Tools ....................................... SUCCESS [  0.948 s]
[INFO] Atlas Security Plugin .............................. SUCCESS [  1.115 s]
[INFO] SchemaRegistry Security Plugin ..................... SUCCESS [  1.986 s]
[INFO] Sqoop Security Plugin .............................. SUCCESS [  1.111 s]
[INFO] Sqoop Security Plugin Shim ......................... SUCCESS [  0.886 s]
[INFO] Elasticsearch Security Plugin Shim ................. SUCCESS [  0.357 s]
[INFO] Elasticsearch Security Plugin ...................... SUCCESS [  0.948 s]
[INFO] Apache Ranger Distribution ......................... SUCCESS [01:26 min]
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  03:41 min
[INFO] Finished at: 2022-11-08T21:41:45+08:00
[INFO] ------------------------------------------------------------------------

```

检查compile 结果：
```bash
ll -h ./target

total 1.2G
drwxr-xr-x 36 ordiy 1.2K Nov  8 21:38 ./
drwxr-xr-x 73 ordiy 2.3K Nov  8 21:32 ../
-rw-r--r--  1 ordiy   30 Nov  8 21:38 .plxarc
drwxr-xr-x  3 ordiy   96 Nov  8 20:03 antrun/
drwxr-xr-x  2 ordiy   64 Nov  8 20:47 archive-tmp/
-rw-r--r--  1 ordiy   87 Nov  8 21:38 checkstyle-cachefile
-rw-r--r--  1 ordiy 9.0K Nov  8 21:38 checkstyle-checker.xml
-rw-r--r--  1 ordiy  20K Nov  8 21:38 checkstyle-header.txt
-rw-r--r--  1 ordiy   81 Nov  8 21:38 checkstyle-result.xml
-rw-r--r--  1 ordiy 1.2K Nov  8 21:38 checkstyle-suppressions.xml
drwxr-xr-x  3 ordiy   96 Nov  8 20:03 maven-shared-archive-resources/
-rw-r--r--  1 ordiy 282M Nov  8 21:41 ranger-2.1.0-admin.tar.gz
-rw-r--r--  1 ordiy  47M Nov  8 21:41 ranger-2.1.0-atlas-plugin.tar.gz
-rw-r--r--  1 ordiy  31M Nov  8 21:41 ranger-2.1.0-elasticsearch-plugin.tar.gz
-rw-r--r--  1 ordiy  42M Nov  8 21:41 ranger-2.1.0-hbase-plugin.tar.gz
-rw-r--r--  1 ordiy  41M Nov  8 21:41 ranger-2.1.0-hdfs-plugin.tar.gz
-rw-r--r--  1 ordiy  40M Nov  8 21:41 ranger-2.1.0-hive-plugin.tar.gz
-rw-r--r--  1 ordiy  57M Nov  8 21:41 ranger-2.1.0-kafka-plugin.tar.gz
-rw-r--r--  1 ordiy 129M Nov  8 21:41 ranger-2.1.0-kms.tar.gz
-rw-r--r--  1 ordiy  44M Nov  8 21:41 ranger-2.1.0-knox-plugin.tar.gz
-rw-r--r--  1 ordiy  40M Nov  8 21:41 ranger-2.1.0-kylin-plugin.tar.gz
-rw-r--r--  1 ordiy  34K Nov  8 21:41 ranger-2.1.0-migration-util.tar.gz
-rw-r--r--  1 ordiy  47M Nov  8 21:41 ranger-2.1.0-ozone-plugin.tar.gz
-rw-r--r--  1 ordiy  59M Nov  8 21:41 ranger-2.1.0-presto-plugin.tar.gz
-rw-r--r--  1 ordiy  19M Nov  8 21:41 ranger-2.1.0-ranger-tools.tar.gz
-rw-r--r--  1 ordiy 1.4M Nov  8 21:41 ranger-2.1.0-schema-registry-plugin.jar
-rw-r--r--  1 ordiy  40M Nov  8 21:41 ranger-2.1.0-solr-plugin.tar.gz
-rw-r--r--  1 ordiy  37K Nov  8 21:41 ranger-2.1.0-solr_audit_conf.tar.gz
-rw-r--r--  1 ordiy  40M Nov  8 21:41 ranger-2.1.0-sqoop-plugin.tar.gz
-rw-r--r--  1 ordiy 4.3M Nov  8 21:41 ranger-2.1.0-src.tar.gz
-rw-r--r--  1 ordiy  53M Nov  8 21:41 ranger-2.1.0-storm-plugin.tar.gz
-rw-r--r--  1 ordiy  35M Nov  8 21:41 ranger-2.1.0-tagsync.tar.gz
-rw-r--r--  1 ordiy  17M Nov  8 21:41 ranger-2.1.0-usersync.tar.gz
-rw-r--r--  1 ordiy  40M Nov  8 21:41 ranger-2.1.0-yarn-plugin.tar.gz
-rw-r--r--  1 ordiy 179K Nov  8 21:38 rat.txt
-rw-r--r--  1 ordiy    5 Nov  8 21:38 version
 ```

 # 写在最后
 编译需要胆大心细，遇到问题仔细排查。
