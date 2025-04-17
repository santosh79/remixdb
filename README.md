Remixdb
=======

[![Build Status](https://github.com/santosh79/remixdb/actions/workflows/elixir.yml/badge.svg)](https://github.com/santosh79/remixdb/actions/workflows/elixir.yml)

## A Redis Protocol Compliant NoSQL database targeting Concurrency
RemixDB is a distributed NoSQL database, that implements the [Redis](http://redis.io) protocol, built on the legendary Erlang VM. It aims for matching all of the performance of Redis while leveraging all of the good Systems Tooling of the BEAM VM - High Availability and High Throughput.

## How fast is this?
It's Fast! Pretty close to **matching redis** in terms of performance.

Here are some results of running `redis-benchmark` on an early 2021 M1 Macbook Air:

```
redis-benchmark -t get -n 100000 -r 100000000
====== GET ======
  100000 requests completed in 1.25 seconds
  50 parallel clients
  3 bytes payload
  keep alive: 1

96.57% <= 1 milliseconds
99.29% <= 2 milliseconds
99.68% <= 3 milliseconds
99.81% <= 4 milliseconds
99.91% <= 5 milliseconds
99.93% <= 6 milliseconds
99.96% <= 7 milliseconds
99.97% <= 8 milliseconds
99.98% <= 9 milliseconds
99.98% <= 10 milliseconds
99.98% <= 11 milliseconds
99.99% <= 12 milliseconds
99.99% <= 13 milliseconds
100.00% <= 14 milliseconds
100.00% <= 15 milliseconds
100.00% <= 18 milliseconds
80192.46 requests per second
```

## How do I play with this?
Docker is the preferred way to run this:

```
docker container run -d --rm -p 6379:6379 --name remixdb santoshdocker2021/remixdb:latest
```

NO docker, then:

```
git clone https://github.com/santosh79/remixdb
mix release
_build/dev/rel/remixdb/bin/remixdb start
```

You don't need any drivers - **this should work with your redis drivers**.


## Why do this?
We need Databases that are fault-tolerant, highly available and that can scale and take FULL advantage of the latest in Hardware specs (more cores). The Erlang VM is **uniquely positioned** to do this and this Database is an effort to prove it! :)

## Status
This library is still being worked on, so it does NOT support all of redis' commands -- that being said, the plan is to get it to full compliance with Redis' single server commands, ASAP. Redis Cluster is something I do not believe in - since I do not understand the Availability Guarantees it provides.

## Module Architecture

```
                        +-------------------+
                        |    Client App     |
                        +---------+---------+
                                  |
                                  | TCP/Redis Protocol
                                  v
+----------------------------------------------------------------+
|                   Remixdb Application                          |
|  +-------------------+            +-------------------+        |
|  |    TCP Server     |<---------->|   Redis Parser    |        |
|  +---------+---------+            +---------+---------+        |
|            |                              |                    |
|            |    Parsed Commands           |                    |
|            v                              v                    |
|    +-----------------------------------------------+           |
|    |               Command Router                 |            |
|    +----------------------+-----------------------+            |
|           |            |             |         |               |
|           v            v             v         v               |
|    +-----------+  +-----------+  +-----------+  +-----------+  |
|    |  String   |  |   Hash    |  |   List    |  |    Set    |  |
|    |  Module   |  |  Module   |  |  Module   |  |  Module   |  |
|    +-----+-----+  +-----+-----+  +-----+-----+  +-----+-----+  |
|           |            |             |               |         |
|           |            |             |               |         |
|           v            v             v               v         |
|    +-----------------------------------------------+           |
|    |            Data Storage Layer                 |           |
|    |   (GenServer state and/or ETS tables)         |           |
|    +-----------------------------------------------+           |
+----------------------------------------------------------------+
                                  ^
                                  | Supervised by
                                  v
+---------------------------------------------------------------+
|                     Supervision Tree                          |
|                                                               |
|    +------------------------+                                 |
|    |   Remixdb Supervisor   |                                 |
|    +-----------+------------+                                 |
|                |                                              |
|         +------+-----+                                        |
|         |            |                                        |
|         v            v                                        |
|    +----------+   +---------------------------+               |
|    | TcpServer|   | Datastructures Supervisor |               |
|    |          |   +-----------+---------------+               |
|    +----------+               |                               |
|                      +--------+--------+                      |
|                      |        |        |                      |
|                      v        v        v                      |
|                  +--------+ +--------+ +----------+           |
|                  | String | |  Hash  | | List/Set |           |
|                  +--------+ +--------+ +----------+           |
+---------------------------------------------------------------+
                                  |
                                  | Uses
                                  v
+---------------------------------------------------------------+
|                      Utility Modules                          |
|  +----------+   +----------+   +---------------------+        |
|  | Renamer  |   | Counter  |   |  Other Utilities    |        |
|  +----------+   +----------+   +---------------------+        |
+---------------------------------------------------------------+

+---------------------------------------------------------------+
|                     Benchmark Suite                           |
|        (Independent tools for measuring performance)          |
+---------------------------------------------------------------+
```


## Clustering and Master Read Replica setup with Automatic Failover
This will happen, soon!

## Missing commands
- RENAMENX
- Expiry and TTL commands
- Sorted sets
- Bitmaps & HyperLogLogs
- Blocking commands
- Pub Sub commands
- LUA scripting

## Author

Santosh Kumar :: santosh79@gmail.com :: @santosh79
