---
title: 关于Flink on YARN的三种部署方式
description: 关于Flink on YARN的三种部署方式
tags:
  - Flink
  - Hadoop
  - YARN
  - big-data
pubDate: 2023-05-11
draft: false
---
##  session模式
提交Flink作业前先创建一个被称为``yarn-session``的YARN集群，然后可以将多个Flink作业提交到这个集群中，这些Flink作业共享同一个JobManager和公共的TaskManager。``yarn-session``的生命周期独立于这些作业。
- 优点：
  + 同一个``yarn-session``中的多个Flink作业资源可伸缩；
-  缺点：
  - 由于TaskManager多作业共享，可能因为某个task出现异常导致整个TaskManager被关闭从而影响了未发生异常的作业；
  - JobManager负责多个作业的记录，负载更大；
## per-job模式
YARN为每一个提交的Flink作业单独创建并启动一个集群，该集群仅对本作业可用。作业执行完成后集群将被销毁，释放资源并清除滞留资源。集群的生命周期和作业的生命周期绑定在一起。
- 优点：
  - 良好的资源隔离性。多个作业之间互不影响；
  - JobManager的负载相比session模式更小，每一个作业单独由一JobManager分管；
- 缺点：
  - 相比session模式可能会出现资源浪费的情况；
  - 相比于application模式，网络带宽消耗更大；
## application模式
以上两种模式（session和per-job模式）中，Flink的``main()``方法都是在Client————也就是提交作业的服务器，执行的。这个过程包括在本地下载Flink作业中需要用到的依赖关系，执行``main()``方法提取JobGraph，并将依赖jar包和JobGraph发送到集群执行。这样的操作使得Client每次提交都需要占用大量网络带宽下载依赖和发送文件，以及占用CPU提取JobGraph，在多用户提交任务时问题会更大。
application模式与per-job模式的主要区别在于，Flink作业的``main()``方法在JobManager上执行。并且和per-job模式一样提供了良好的资源隔离性。applicaiton模式为每个提交的FLink作业创建一个“仅在特定作业之间共享”的会话集群，并在作业完成时销毁。
- 优点：
  - 同时拥有per-job的资源隔离性，和session的资源可伸缩性；
  - 由于application模式并不依赖Client提交依赖和JobGraph，可以将依赖和作业放到HDFS上，提交时只指定HDFS目录即可；