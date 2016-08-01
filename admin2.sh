#! /bin/bash

# setup the proper pg num
ceph osd pool set rbd pg_num 200
ceph osd pool set rbd pgp_num 200

# TODO wait until it is HEALTH_OK
read

# create new block device
rbd create ceph_cluster --size 2048
rbd --image ceph_cluster info
