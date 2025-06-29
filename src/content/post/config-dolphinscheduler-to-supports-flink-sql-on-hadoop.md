---
title: 配置Dolphinscheduler以支持在Hadoop上运行Flink SQL
description: Dolphinscheduler官方文档对如何支持Flink SQL的描述不甚详细，本文根据实践详细记录了支持Flink SQL on Hadoop的步骤。
tags:
  - Dolphinscheduler
  - Flink
  - Flink-SQL
  - Hadoop
  - big-data
pubDate: 2024-08-17
draft: false
---
[Dolphinscheduler文档]( https://dolphinscheduler.apache.org/zh-cn/docs/3.2.1/guide/task/flink )中对如何支持Flink的描述是在`dolphinscheduler_env.sh`中添加`FLINK_HOME`环境变量。但是这里经过测试（3.2.1版本）有两个问题：我配置了`FLINK_HOME`后新建了一个shell任务尝试获取`FLINK_HOME`（`echo $FLINK_HOME`）并未获取到；另外官方文档的配置基本是以local模式的flink来考虑的，并未考虑进去hadoop相关的配置。本文的配置项皆以支持华为MRS的Hadoop为准。
1. 准备hadoop客户端&hadoop配置文件。对于华为MRS，执行客户端自带的环境配置（`source bigdata_env`）即在当前shell设置hadoop相关环境变量配置。如果没有现成环境配置脚本，则需要准备hadoop配置文件：`core-site.xml`、`yarn-site.xml`、`hdfs-site.xml`并放在同一目录下，然后设置环境变量：`export HADOOP_CONF_DIR=/path/to/hadoop_conf`。
2. 设置kerberos相关（可选）：此部分和Dolphinschduler无关，仅设置flink支持kerberos即可。
    - 在`/etc`目录下放置`krb5.conf`文件；
    - 在flink目录`/conf/config.yaml`（1.19以下配置文件名为flink-conf.yaml）中新增/更新以下配置：
    ```
    security:
      kerberos:
        login:
          use-ticket-cache: false
          keytab: /path/to/user.keytab
          principal: username
          realm: HADOOP@COM
          contexts: Client,KafkaClient
    ```
3. 设置Dolphinscheduler环境：
    - 安全中心-环境管理-创建环境，在环境配置中输入以下配置：
    ```
    # 设置hadoop相关环境变量（HADOOP_CONF_DIR）
    source /path/to/bigdata_env
    export HADOOP_CLASSPATH=`hadoop classpath`
    #设置Flink
    export FLINK_HOME=/path/to/flink-1.19.1
    export PATH=$FLINK_HOME/bin:$PATH
    ```
    - 理论上Flink对hadoop的依赖仅为`HADOOP_CONF_DIR`，未测试只有此环境变量时是否功能正常；
    - 由于Dolphinscheduler执行Flink并不会按照`FLINK_HOME`检索命令并全路径执行（无法理解官方文档都支持了什么鬼），只会直接调用flink命令，故需要配置`FLINK_HOME`并加入`PATH`；
>此时已经可以提交flink任务了。已测试通过的配置：程序类型：JAVA（官方文档描述这里JAVA SCALA没有区别），部署方式；application，Flink版本：>=1.12。“任务名称”配置似乎不起作用。
4. 支持FLink SQL（以配置Flink SQL支持Hive为例）：
    - 下载flink-sql-connector-hive包并放到flink根目录`/lib`下；
    - 交换flink根目录`/lib/flink-table-planner`和flink根目录`/opt/flink-table-planner-loader`两个包的位置；
5. 创建Flink SQL任务：
    - 项目管理-点击对应的项目-项目管理-项目级别参数，设置一个参数`flink-sql-session-application-id`，参数值为提前开启的用于执行Flink SQL的yarn-session的application id；
    - 创建工作流，添加FLINK组件，程序类型选择“SQL”，初始化脚本按照如下配置：
    ```
    set 'execution.target' = 'yarn-session';
    set 'yarn.application.id' = '${flink-sql-session-application-id}';
    set 'execution.runtime-mode' = 'batch';
    set 'sql-client.execution.result-mode' = 'TABLEAU';
    CREATE CATALOG hive_catalog WITH (
      'type' = 'hive';
      'hive-conf-dir' = '/path/to/hive-conf'
    );
    ```
    - 第一行为设置Flink SQL的执行目标，不设置的话默认以local模式运行；
    - 第二行从项目参数中取application id，考虑到可能出现session重启需要修改的情况；