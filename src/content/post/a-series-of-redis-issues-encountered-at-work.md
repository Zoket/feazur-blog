---
title: 一个工作中遇到的一连串Redis key同步问题
description: 在redis集群中实现多key协同去重时遇到的问题
tags:
  - Redis
  - Flink
  - concurrent
  - online-issues
  - experience-summary
  - lua
pubDate: 2023-07-11
draft: false
---
## 问题起源

有一个开发任务是实现一个去重算法，需求是要求可以对一定时间或一定范围的数据做排重，要支持分布式并发（因为是在Flink中实现）。从其他代码中抄了一份过来，这个算法是这样子实现的：

- 算法的核心是利用redis的set数据结构来去重，但是set结构并不能设定上限，且并不能对set中的元素单独设置过期时间，如果单纯用set去重可能会出现set中的数据过多会导致在set中查询速度下降，降低去重效率的问题；
- 所以这里引入了第二个数据结构，queue队列。数据先执行sadd进入set，redis会返回添加的元素数量，如果返回1，即数据没有重复，这时将数据再推入queue。这里我们设定了一个可以容纳的最大key的常量。如果queue的长度超过了可以容纳的最大key数量，则从queue中弹出最底层的一条数据。到这里就完成了通过queue控制set容量的目的；
- 但是引入更多的结构和命令会带来第三个问题：无法保证并发的正确性。在并发中多条命令可能会交替执行，会导致容量控制不可控制。所以这里使用了lua脚本来执行上述逻辑，以保证redis操作的原子性。以下贴出lua脚本：
```lua
local union = ARGV[1]
local maxKey = tonumber(ARGV[2])
local addNum = redis.call(\"sadd\", \"distinct:set\", union)
if
  addNum == 1
then
  local count = redis.call(\"lpush\", \"distinct:queue\", union)
  print(count)
  if
    count > maxKey
  then
    local remove = redis.call(\"rpop\", \"distinct:queue\", 1)
    redis.call(\"srem\", \"distinct:set\", remove[1])
  end
  return 1
else
  return 0
end
```

## 问题描述&解决
#### 问题1
这段lua脚本执行在redis集群的时候遇到了第一个异常：
```
READONLY You can't write against a read only replicas.
```
从异常信息来看，是lua脚本在尝试写的时候写在了一个只读的从节点上，看起来需要一个参数指定写redis的时候指定写到主节点的配置。
#### 问题1解决
在一阵Google后，锁定了redis客户端的ReadFrom参数。将此参数设置为REPLICA，问题解决。
#### 问题2
解决第一个问题后，出现了第二个异常：
```
lua script attempted to access a non local key in a cluster node.
```
从异常信息来看，lua脚本访问到了不属于当前执行脚本的节点上的key。这里想到，redis集群模式会根据key的值做hash，将key hash到集群的很多个slot上，可能是因为set和queue的key被hash到了不同的slot导致的。
#### 问题2解决？
在又一阵Google后，找到了一个解决方式：`hash tag`，即在两个key的相同部分使用{}包裹，含有被{}包裹的key，在计算hash的时候只使用{}中间的部分参与计算，而不会使用整个key来计算。即以上lua脚本的key改为`{distinct}:set`，`{distinct}:queue`。（这里可以使用一个redis命令`CLUSTER KEYSLOT key`来查看这个key经过redis的hash之后是否一样。经过验证后，使用了hash tag的两个key分配的slot是同一个。）
#### 问题3
可惜事不遂人愿，使用hash tag后，上面的异常依然会抛出。
这里注意到，异常透露出的信息并不是两个key没有分配在同一个节点上，而是分配的节点没有在lua脚本当前执行所在的节点上。这里经过再一次疯狂google之后发现了端倪。
首先是根据异常搜索到一篇博客指出，可以使用redis的`KEYS`命令，将要操作的key作为参数传递给lua脚本。之后在redis官方文档中找到了关于KEYS的描述：

> Important: to ensure the correct execution of scripts, both in standalone and clustered deployments, all names of keys that a function accesses must be explicitly provided as input key arguments. The script should only access keys whose names are given as input arguments. Scripts should never access keys with programmatically-generated names or based on the contents of data structures stored in the database.

大概翻译是：不论是独立部署还是集群部署，为了确保脚本的正确执行，函数访问所有的key都需要用KEYS命令传递，脚本不应该使用程序生成的名称或者数据库中存储的结构中的名称来访问key。
OK，那么上面的lua脚本改为这样：
```
local union = ARGV[1]
local maxKey = tonumber(ARGV[2])
local queueKey = KEYS[1]
local setKey = KEYS[2]
local addNum = redis.call("sadd", setKey, union)
if
  addNum == 1
then
  local count = redis.call("lpush", queueKey, union)
  print(count)
  if
    count > maxKey
  then
    local remove = redis.call("rpop", queueKey, 1)
    redis.call("srem", setKey, remove[1])
  end
  return 1
else
  return 0
end
```
将key改为参数传递之后，ReadFrom不设置参数也不会出现问题1的异常了，问题顺利解决。