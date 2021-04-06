Remixdb
=======
[![Build Status](https://travis-ci.org/santosh79/remixdb.svg?branch=master)](https://travis-ci.org/santosh79/remixdb)

## A fully distributed NoSQL database, built on the Redis protocol
RemixDB is a distributed NoSQL database, that implements the [Redis](http://redis.io) protocol, built on the legendary Erlang VM. It aims for all of the concurrency benefits of running on the Erlang VM without sacrificing on the Availability of Redis, i.e. it aims to match Redis in terms of performance while giving all of the concurrency benefits of Erlang.

## How fast is this?
Running on my Early 2021 M1 Macbook Air with 16G of memory, here is my `redis-benchmark`:

```
redis-benchmark -t set -n 100000 -r 100000000
====== SET ======
  100000 requests completed in 2.43 seconds
  50 parallel clients
  3 bytes payload
  keep alive: 1

15.18% <= 1 milliseconds
99.58% <= 2 milliseconds
99.91% <= 3 milliseconds
100.00% <= 4 milliseconds
100.00% <= 4 milliseconds
41135.34 requests per second
```

## How do I play with this?
Docker is the preferred way to run this:

```
docker container run -d --rm -p 6379:6379 santoshdocker2021/remixdb:latest
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


## Clustering and Master Slave setup with Automatic Failover
This will happen, soon!

## Missing commands
- Sorted set implementation
- Bitmaps & HyperLogLogs
- Blocking commands
- Pub Sub commands
- LUA scripting stuff

## Author

Santosh Kumar :: santosh79@gmail.com :: @santosh79
