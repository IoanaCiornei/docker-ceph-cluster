#! /bin/bash

source ./settings.sh

# delete the containers
for (( i = 0; i < $NUM_NODES; i++)); do
	echo "Stopping Docker container ${node_name[$i]}..."
	((j = i + 2))
	NODE_IP="$IP_NETWORK$j"
	sudo docker stop ${node_name[$i]}
done

