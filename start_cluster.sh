#! /bin/bash

MODULE='START_CEPH_CLUSTER'

source ./settings.sh

for (( i = 0; i < $NUM_NODES; i++)); do
	((j = i + 2))
	NODE_IP="$IP_NETWORK$j"

	log $MODULE "Start Docker container ${node_name[$i]}..."
	sudo docker start ${node_name[$i]} &>> $DEBUG_FILE
done

log $MODULE "Containers in cluster:"
sudo docker ps
log $MODULE "Start ceph cluster... Finished!"
