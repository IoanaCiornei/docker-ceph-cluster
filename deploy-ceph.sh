#! /bin/bash

source ./settings.sh

# setup the monitor nodes
ceph-deploy new $mons

# TODO append ceph.conf to the actual config

# install Ceph in all the nodes in the cluster and the admin node
ceph-deploy install $nodes


