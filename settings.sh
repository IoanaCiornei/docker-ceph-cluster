#! /bin/bash

NUM_OSD=3
NUM_MON=3
((NUM_NODES = $NUM_MON + $NUM_OSD + 1))

NUM_DISKS=4
FILES_DIR=../dev-files

LOOP_MAJOR=7
START_MINOR=200

NETWORK_IP="172.18.0"
NETWORK_MASK=16
CLUSTER_NETWORK="ceph_network"

USER="ioana"
PASSWORD="ceph"
ROOT_PASSWORD="root"

AUTHORIZED_KEYS="/home/ioana/.ssh/authorized_keys"

# create the array of hostnames
for (( i = 0; i < $NUM_NODES; i++)); do
	if (( i == 0 )); then
		node_name[$i]="admin"
	elif (( i <= $NUM_OSD )); then
		node_name[$i]="osd$i"
	else
		node_name[$i]="mon"$(($i - $NUM_OSD))
	fi
done


