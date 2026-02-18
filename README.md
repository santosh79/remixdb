Remixdb
=======

[![Build Status](https://github.com/santosh79/remixdb/actions/workflows/elixir.yml/badge.svg)](https://github.com/santosh79/remixdb/actions/workflows/elixir.yml)

## A Redis Protocol Compliant NoSQL database targeting Concurrency
RemixDB is a distributed NoSQL database, that implements the [Redis](http://redis.io) protocol, built on the legendary Erlang VM. It aims for matching all of the performance of Redis while leveraging all of the good Systems Tooling of the BEAM VM - High Availability and High Throughput.

## How fast is this?
It's Fast! Pretty close to **matching redis** in terms of performance.

Here are some results of running `redis-benchmark` on an early 2023 M1 iMac:

```
 
GET: rps=0.0 (overall: nan) avg_msec=nan (overall: nan)
                                                        
GET: rps=94308.0 (overall: 94308.0) avg_msec=0.374 (overall: 0.374)
                                                                    
GET: rps=92304.0 (overall: 93306.0) avg_msec=0.354 (overall: 0.364)
                                                                    
GET: rps=105816.7 (overall: 97487.4) avg_msec=0.342 (overall: 0.356)
                                                                     
GET: rps=104260.0 (overall: 99178.8) avg_msec=0.335 (overall: 0.351)
                                                                     
====== GET ======
  100000 requests completed in 1.01 seconds
  50 parallel clients
  3 bytes payload
  keep alive: 1
  host configuration "save": 3600 1 300 100 60 10000
  host configuration "appendonly": 3600 1 300 100 60 10000
  multi-thread: no

Latency by percentile distribution:
0.000% <= 0.063 milliseconds (cumulative count 2)
50.000% <= 0.327 milliseconds (cumulative count 51284)
75.000% <= 0.415 milliseconds (cumulative count 75607)
87.500% <= 0.495 milliseconds (cumulative count 87757)
93.750% <= 0.583 milliseconds (cumulative count 93939)
96.875% <= 0.647 milliseconds (cumulative count 97126)
98.438% <= 0.727 milliseconds (cumulative count 98506)
99.219% <= 0.855 milliseconds (cumulative count 99253)
99.609% <= 0.951 milliseconds (cumulative count 99632)
99.805% <= 1.007 milliseconds (cumulative count 99812)
99.902% <= 1.039 milliseconds (cumulative count 99908)
99.951% <= 1.071 milliseconds (cumulative count 99955)
99.976% <= 1.175 milliseconds (cumulative count 99977)
99.988% <= 1.223 milliseconds (cumulative count 99988)
99.994% <= 1.279 milliseconds (cumulative count 99994)
99.997% <= 1.303 milliseconds (cumulative count 99997)
99.998% <= 1.319 milliseconds (cumulative count 99999)
99.999% <= 1.519 milliseconds (cumulative count 100000)
100.000% <= 1.519 milliseconds (cumulative count 100000)

Cumulative distribution of latencies:
0.071% <= 0.103 milliseconds (cumulative count 71)
8.179% <= 0.207 milliseconds (cumulative count 8179)
42.672% <= 0.303 milliseconds (cumulative count 42672)
73.870% <= 0.407 milliseconds (cumulative count 73870)
88.566% <= 0.503 milliseconds (cumulative count 88566)
95.313% <= 0.607 milliseconds (cumulative count 95313)
98.220% <= 0.703 milliseconds (cumulative count 98220)
99.075% <= 0.807 milliseconds (cumulative count 99075)
99.434% <= 0.903 milliseconds (cumulative count 99434)
99.812% <= 1.007 milliseconds (cumulative count 99812)
99.970% <= 1.103 milliseconds (cumulative count 99970)
99.985% <= 1.207 milliseconds (cumulative count 99985)
99.997% <= 1.303 milliseconds (cumulative count 99997)
99.999% <= 1.407 milliseconds (cumulative count 99999)
100.000% <= 1.607 milliseconds (cumulative count 100000)

Summary:
  throughput summary: 99304.87 requests per second
  latency summary (msec):
          avg       min       p50       p95       p99       max
        0.351     0.056     0.327     0.607     0.799     1.519
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
|    +----------+   +----------+   +---------------------+      |
|    | Renamer  |   | Counter  |   |  Other Utilities    |      |
|    +----------+   +----------+   +---------------------+      |
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
