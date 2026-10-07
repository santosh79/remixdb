Remixdb
=======

[![Build Status](https://github.com/santosh79/remixdb/actions/workflows/elixir.yml/badge.svg)](https://github.com/santosh79/remixdb/actions/workflows/elixir.yml)

## A Redis Protocol Compliant NoSQL database targeting Concurrency
RemixDB is a distributed NoSQL database, that implements the [Redis](http://redis.io) protocol, built on the legendary Erlang VM. It aims for matching all of the performance of Redis while leveraging all of the good Systems Tooling of the BEAM VM - High Availability and High Throughput.

## How fast is this?
It's Fast! Pretty close to **matching redis** in terms of performance.

Here are some results of running `redis-benchmark` on an early 2023 M1 iMac:

```
redis-benchmark -h 0.0.0.0 -t get -n 100000 -r 100000000 -c 100
GET: rps=0.0 (overall: nan) avg_msec=nan (overall: nan)
GET: rps=103820.0 (overall: 103820.0) avg_msec=0.596 (overall: 0.596)
GET: rps=117300.0 (overall: 110560.0) avg_msec=0.534 (overall: 0.563)
GET: rps=110263.0 (overall: 110460.7) avg_msec=0.528 (overall: 0.551)
====== GET ======
  100000 requests completed in 0.93 seconds
  100 parallel clients
  3 bytes payload
  keep alive: 1
  host configuration "save": 3600 1 300 100 60 10000
  host configuration "appendonly": 3600 1 300 100 60 10000
  multi-thread: no

Latency by percentile distribution:
0.000% <= 0.111 milliseconds (cumulative count 1)
50.000% <= 0.503 milliseconds (cumulative count 50210)
75.000% <= 0.631 milliseconds (cumulative count 75658)
87.500% <= 0.743 milliseconds (cumulative count 87767)
93.750% <= 0.855 milliseconds (cumulative count 93920)
96.875% <= 0.991 milliseconds (cumulative count 96948)
98.438% <= 1.327 milliseconds (cumulative count 98439)
99.219% <= 1.791 milliseconds (cumulative count 99251)
99.609% <= 1.831 milliseconds (cumulative count 99665)
99.805% <= 1.855 milliseconds (cumulative count 99834)
99.902% <= 1.871 milliseconds (cumulative count 99913)
99.951% <= 1.887 milliseconds (cumulative count 99954)
99.976% <= 1.951 milliseconds (cumulative count 99978)
99.988% <= 2.111 milliseconds (cumulative count 99988)
99.994% <= 2.263 milliseconds (cumulative count 99994)
99.997% <= 2.327 milliseconds (cumulative count 99997)
99.998% <= 2.343 milliseconds (cumulative count 99999)
99.999% <= 2.359 milliseconds (cumulative count 100000)
100.000% <= 2.359 milliseconds (cumulative count 100000)

Cumulative distribution of latencies:
0.000% <= 0.103 milliseconds (cumulative count 0)
0.038% <= 0.207 milliseconds (cumulative count 38)
0.512% <= 0.303 milliseconds (cumulative count 512)
16.193% <= 0.407 milliseconds (cumulative count 16193)
50.210% <= 0.503 milliseconds (cumulative count 50210)
71.931% <= 0.607 milliseconds (cumulative count 71931)
84.372% <= 0.703 milliseconds (cumulative count 84372)
91.815% <= 0.807 milliseconds (cumulative count 91815)
95.445% <= 0.903 milliseconds (cumulative count 95445)
97.114% <= 1.007 milliseconds (cumulative count 97114)
97.835% <= 1.103 milliseconds (cumulative count 97835)
98.252% <= 1.207 milliseconds (cumulative count 98252)
98.412% <= 1.303 milliseconds (cumulative count 98412)
98.512% <= 1.407 milliseconds (cumulative count 98512)
98.653% <= 1.503 milliseconds (cumulative count 98653)
98.776% <= 1.607 milliseconds (cumulative count 98776)
98.858% <= 1.703 milliseconds (cumulative count 98858)
99.411% <= 1.807 milliseconds (cumulative count 99411)
99.968% <= 1.903 milliseconds (cumulative count 99968)
99.982% <= 2.007 milliseconds (cumulative count 99982)
99.986% <= 2.103 milliseconds (cumulative count 99986)
100.000% <= 3.103 milliseconds (cumulative count 100000)

Summary:
  throughput summary: 107181.13 requests per second
  latency summary (msec):
          avg       min       p50       p95       p99       max
        0.560     0.104     0.503     0.887     1.759     2.359



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
