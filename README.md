Remixdb
=======
RemixDB is a distributed NoSQL database, that implements the [Redis](http://redis.io) protocol.

Redis, while awesome and insanely fast, is written in C. This has many downsides:

- No Parallelism
- Poor clustering features
- Fault tolerance is not something C is famous for

Enter RemixDB. This is written in in [Elixir](http://elixir-lang.org/) and runs on the amazing [BEAM VM](https://erlangcentral.org/tag/beam/). So, right out of the bat it is built for running in a highly parallel and distributed setup in a [VM](http://www.erlang.org/) that has been battle tested for over 25 years and one that handles most of the Internet traffic in the world!

### Why consider RemixDB
RemixDB lets you:

### Running on all cylinders
We all know where computing is headed. More CPUs, cheaper memory and no increase in clock speed. Today, 8 cores is common place. Tomorrow, we'd be looking at 200+ cores! What does this mean for you? If you were to hitch your wagon to a star, you'd be better off choosing one that has parallelism built in on the foundation. Wouldn't it be awesome if your software got faster as your hardware became better? For free, without you having to touch a single line of code. This is the promise of the ErlangVM.

### Constant time lookups
Running parallel code has an amazing benefit. Since all code is running parallely, CPU intensive computations don't get to block others from executing.

### Built in clustering
Clustering is something **built into the VM**. This is a really big deal. So no more coming up with some half-baked clustering strategy based on computing the hash of a lookup key and mod'ing that with the number of clusters. Since the ErlangVM was built to never have to be brought down, you can add and remove nodes from the cluster without having to shut down any of your processes. You find that you are running low on memory in one machine in your cluster, just add another machine in real-time to the cluster and stuff just works.

### Fault tolerance
[OTP](https://en.wikipedia.org/wiki/Open_Telecom_Platform), which comes standard with all Erlang distributions has amazing tools for building fault tolerant software with very well established recovery schemes in the event of a failure. So, you can sleep at ease with the knowledge that your data is running in code that has considered failure and how to recover from it.

### Redis protocol compliant
RemixDB is built on the Redis compliant. So you can try it out, with out having to change any code or drivers. If your code works with Redis it will work with RemixDB.
