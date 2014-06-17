docked-p2pool
=============
An attempt at creating a much nicer method for starting up your own p2pool node.
Initially targeted at the vertcoin-3 pool as that's what I'm trying to get
setup, I do intend to expand this to be able to more easily create nodes for
other pools as well though.

I highly suggest you read through both the Vagrantfile and setup.sh to
understand what this is doing before attempting to use it. There should be no
chance of this interfering with any other part of your system as it runs
everything on a pair of coreos VMs, but it is not well tested yet.

The only requirements for this are: running on a unix system (only actually
tested on OS X so far) and having [Vagrant](https://www.vagrantup.com) and
[Virtualbox](https://www.virtualbox.org) installed.

To use simply edit `user-data/master` and update the fee/auther-token/address to
values you want (or leave them as-is if you wish to send your mined blocks my
way :smile:) then run `setup.sh` from this directory. This will step-by-step
setup the VMs, pull the required tools and build the containers before finally
starting the master VM that will run vertcoind and p2pool. Once vertcoind
finishes pulling the blockchain you should be able to access p2pool on the
provided url. To check on the status run `vagrant ssh -c 'systemctl status
p2pool-vtc3.service'` 
