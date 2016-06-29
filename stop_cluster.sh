#! /bin/bash

source ./settings.sh

# delete the containers
for (( i = 0; i < $NUM_NODES; i++)); do
	echo "Stopping and deleting Docker container node$i..."
	((j = i + 2))
	NODE_IP="$IP_NETWORK$j"
	sudo docker stop node$i
	sudo docker rm node$i

	# delete entry in /etc/hosts
	sudo sed -i '$ d' /etc/hosts
done

# delete the cluster network
sudo docker network rm $CLUSTER_NETWORK

echo "Running nodes in cluster:"
sudo docker ps
