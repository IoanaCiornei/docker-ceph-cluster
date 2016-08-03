#! /bin/bash

source ./settings.sh

MODULE='STOP_CEPH_CLUSTER'

function stop_cluster {

	for (( i = 0; i < $NUM_NODES; i++)); do
		((j = i + 2))
		NODE_IP="$IP_NETWORK$j"

		log $MODULE "Stop Docker container ${node_name[$i]}..."
		sudo docker stop ${node_name[$i]} &>> $DEBUG_FILE
	done

	log $MODULE "Stop ceph cluster... Finished!"
}
