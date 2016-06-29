#! /bin/bash

source ./settings.sh

# delete the containers
for (( i = 0; i < $NUM_NODES; i++)); do
	echo "Stopping and deleting Docker container ${node_name[$i]}..."
	((j = i + 2))
	NODE_IP="$IP_NETWORK$j"
	sudo docker stop ${node_name[$i]}
	sudo docker rm ${node_name[$i]}

	# delete entry in /etc/hosts
	sudo sed -i '$ d' /etc/hosts
done

# delete the cluster network
sudo docker network rm $CLUSTER_NETWORK

sudo losetup -D

echo "Running nodes in cluster:"
sudo docker ps
