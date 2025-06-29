---
title: Git Tips——Git凭证存储
description: 关于git credential的记录
tags:
  - Git
  - Tips
  - security
pubDate: 2023-09-15
draft: false
---
配置新电脑的时候，本来想生成两个ssh key分别给github和公司的git仓库分别使用，但是公司git仓库并没有开放22端口提供给ssh连接，只能使用http连接拉取代码。这时想起来http连接拉取的代码似乎并没有经常输入用户名密码验证身份。

上网搜索了一下，发现git专门有一个凭证系统来处理和远程代码仓库的认证，并且有一个配置：`credential.helper`。这个配置有几个选项：
  - 不设置：则每次连接远程仓库都需要输入用户名密码；
  - cache：将用户名密码放在内存中一段时间，默认15分钟后清除，可以使用`--timeout <time>`参数设置超时清除的时间；
  - store：将用户名密码以明文的形式存储在磁盘上，并且永不过期。可以使用`--file </file/path>`参数设置存储在磁盘上的路径；
  - osxkeychain：MacOS系统特有的模式，会将用户名密码存储在钥匙串中。使用homebrew安装git会默认设置为该模式；
  - manager/manager-core：windows系统特有的模式，使用Git Credential Managet for Windows程序管理用户名和密码；

可以使用`git credential-xxx`命令来管理存储的凭证。这里以MacOS为例，使用默认的`osxkeychain`配置。
  - `git credential-osxkeychain get`：查看是否存在某个凭证。输入命令后按行输入`protocol=http`和`host=host.com`，并输入一个空行，如果存在该凭证，则返回username和password，否则返回空行；
  - `git credential-osxkeychain store`：存储一个凭证。输入命令后按行输入`protocol=http`、`host=host.com`、`username=foo`、`password=bar`，并输入一个空行，没有任何返回则凭证创建成功；
  - `git credential-osxkeychain erase`：删除一个凭证。输入命令后按行输入`protocol=http`、`host=host.com`、`username=foo`、`password=bar`，并输入一个空行，没有任何返回则凭证删除成功；