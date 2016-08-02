#! /bin/bash

NUM_OSD=3
NUM_MON=3
((NUM_NODES = $NUM_MON + $NUM_OSD + 2))

NUM_DISKS=4
NUM_DEVS=$(($NUM_DISKS * $NUM_OSD))
CURRENT_FOLDER=$(pwd)
FILES_DIR=$(realpath ..)"/dev-files"

LOOP_MAJOR=7
START_MINOR=200

NETWORK_IP="172.18.0"
NETWORK_MASK=16
CLUSTER_NETWORK="ceph_network"

USER="pis"
PASSWORD="ceph"
ROOT_PASSWORD="root"

AUTHORIZED_KEYS="/home/ioana/.ssh/authorized_keys"

# create the array of hostnames
osds=""
mons=""
nodes=""
for (( i = 0; i < $NUM_NODES; i++)); do
	if (( i == 0 )); then
		node="admin"
	elif (( i <= $NUM_OSD )); then
		node="osd$i"
		osds="$osds $node"
	elif ((i == $NUM_NODES - 1 )); then
		node="client"
	else
		node="mon"$(($i - $NUM_OSD))
		mons="$mons $node"
	fi
	node_name[$i]=$node
	nodes="$nodes $node"
done

LOGGER="Ceph Docker Disk mounted on"
DEBUG_FILE="debug.txt"

function log {
	echo $3 "[$1] $2" | tee -a $DEBUG_FILE
}
