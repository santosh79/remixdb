Remixdb
=======

## A fully distributed NoSQL database, built on the Redis protocol
RemixDB is a distributed NoSQL database, that implements the [Redis](http://redis.io) protocol, built on the legendary Erlang VM.


## Features
- True Parallelism: Unlike Redis, which is single threaded, RemixDB is built to take advantage of all the cores on your machine.
- Truly Distributed: Built on the Erlang VM, RemixDB takes full advantage of [OTP](https://github.com/erlang/otp) and all of the distributed goodies that ship in the Erlang VM. Further, you can throw in more instances into you your cluster in real time without bringing down the server. In other words, **real time scaling with zero downtime**.
- Fault Tolerant: Failure in software is not a matter of *if*, but rather a matter of *when*. Taking full advantage of Supervisor Trees, RemixDB is built from the ground up with failure in mind and how best to recover from it.

Finally:
- Zero Code change required: Your code works with Redis, awesome. RemixDB speaks the Redis protocol. So you can try it without making any code change or changing your drivers. **If it works with Redis, it works with RemixDB**.


## Getting Started
TBD
### Installing
TBD
### Starting RemixDB
TBD
### Making backups
TBD

