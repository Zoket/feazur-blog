---
title: Flink SQL支持Iceberg
description: 本文描述了如何在Flink SQL中开启对Iceberg的支持
tags:
  - Flink
  - Flink-SQL
  - Iceberg
pubDate: 2023-06-13
draft: false
---
## 背景
Iceberg对Flink的支持是较为完整的，但是在Iceberg的官方文档描述的并不详尽。本文结合线上的部署情况，以在数据中台项目中使用的hive catalog为例，记录flink SQL如何支持使用hive catalog的iceberg。

> 本文使用flink版本为1.16，iceberg版本为1.2，hive版本为3.1.0

## 第一步：先开启Flink SQL对Hive的支持
因为iceberg使用的是hive catalog，故首先要根据[flink官网的指示操作](https://nightlies.apache.org/flink/flink-docs-release-1.16/docs/connectors/table/hive/overview/)以支持Hive：
1.  确认设置了`HADOOP_CLASSPATH`以提供flink寻找hadoop相关依赖项；
        
    2.  添加hive依赖：在上述页面下载`flink-sql-connector-hive-3.1.2.jar`或者分别下载flink-`connector-hive_2.12-1.16.2.jar`、`hive-exec-3.1.0.jar`、`libfb303-0.9.3.jar`、`antlr-runtime-3.5.2.jar`并将下载的jar包放`FLINK_HOME/lib`目录下；
        
    3.  移动planner jar包：将`FLINK_HOME/opt`目录下的`flink-table-planner_2.12-1.16.2.jar`挪到`FLINK_HOME/lib`目录下，并将`FLINK_HOME/lib`目录下的`flink-table-planner-loader-1.16.2.jar`挪出该目录（不建议删除）；

## 第二步：开启Flink SQL对Iceberg的支持
开启hive支持后，需要在[iceberg官网](https://iceberg.apache.org/releases/)下载对应flink版本的`iceberg-flink-runtime-1.16-1.2.0.jar`并放到`FLINK_HOME/lib`目录下，以支持iceberg；
1.  在hadoop集群使用华为FusionInsight时，引入`iceberg-flink-runtime`可能会出现类依赖冲突，一般表现为NoSuchMethodError，即`iceberg-flink-runtime`内置的类和华为FusionInsight的依赖项中的类冲突，但是版本不同。此时可能需要重新编译`iceberg-flink-runtime`更改冲突的依赖项以解决问题；

## 第三步：测试&认证配置
执行`FLINK_HOME/bin/sql-client.sh`打开SQL Client测试配置是否生效；
1.  经过测试，并不需要想上述iceberg官网描述的，在启动SQL Client时使用`-j`选项指定jar包，只需要依照第二步操作即可；
        
2.  SQL Client开启后，创建iceberg catalog测试iceberg连通性：
	1.  catalog参数配置参照iceberg官网；
            
    2.  如果Hive服务端开启了kerberos认证的话，需要在flink-conf中配置相应的kerberos认证参数，并在catalog参数中新增`hive-conf-dir`项，value为hive客户端配置文件的路径，路径中必须包含`hive-site.xml`，并且`hive-site.xml`需要有kerberos认证相关的参数配置。如果hadoop集群使用的是华为FusionInsight，其提供了客户端下载功能，在下载的Hive客户端中包含了hive-site.xml配置文件，并配置好了kerberos principal以及服务端需要的配置，但是缺少一个配置：`hive.metastore.sasl.enabled`，如果不配置此项，在创建iceberg catalog，连接hive metastore时会抛出类似Socket closed by peer等异常；