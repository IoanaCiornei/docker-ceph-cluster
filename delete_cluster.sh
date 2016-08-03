#! /bin/bash

source ./settings.sh

MODULE='DELETE_CEPH_CLUSTER'

function delete_cluster {
	for (( i = 0; i < $NUM_NODES; i++)); do
		((j = i + 2))
		NODE_IP="$IP_NETWORK$j"

		log $MODULE "Deleting Docker container ${node_name[$i]}..."
		sudo docker rm ${node_name[$i]} &> /dev/null

		log $MODULE "Delete entry from /etc/hosts..."
		sudo sed -i '$ d' /etc/hosts
	done

	log $MODULE "Delete cluster network..."
	sudo docker network rm $CLUSTER_NETWORK &> /dev/null

	status=$(systemctl is-active ceph-mount-blk.service)
	if [[ "$status" == "active" ]]; then
		log $MODULE "Stop ceph-mount-blk service..."
		sudo systemctl stop ceph-mount-blk.service
	fi

	log $MODULE "Delete the files mounted as block devices..."
	sudo rm -rf ../dev-files/

	log $MODULE "Delete cluster... Finished!"
}
