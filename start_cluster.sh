#! /bin/bash

source ./settings.sh

set -x

# create the cluster network
sudo docker network create --subnet=$NETWORK_IP.0/$NETWORK_MASK $CLUSTER_NETWORK

# build the latest image of the ceph_node
sudo docker build -t ceph_node .

# create the files that will represent the extra disks for the containers
mkdir $FILES_DIR
minor=$START_MINOR
for (( i = 1; i <= $NUM_OSD; i++)); do

	for (( j = 0; j < $NUM_DISKS; j++)); do
		FILE="osd$i-disk$j"
		HOST_FILE="$FILES_DIR/$FILE"
		BLK_FILE="/dev/$FILE"

		[ -f $HOST_FILE ]  || fallocate -l 1G $HOST_FILE
		sudo mknod $BLK_FILE b $LOOP_MAJOR $minor
		sudo losetup $BLK_FILE $HOST_FILE

		(( minor = $minor + 1 ))
	done
done

# create NUM_NODES containers
for (( i = 0; i < $NUM_NODES; i++)); do
	NODE_IP="$NETWORK_IP.$(($i+2))"

	# start the container
	FILE="/dev/osd$i-disk"
	if (( i >= 1 && i <= $NUM_OSD )); then
		# start the container with multiple disk if it is a OSD
		sudo docker run -d -it \
			--privileged \
			-v "$FILE"0:"$FILE"0 \
			-v "$FILE"1:"$FILE"1 \
			-v "$FILE"2:"$FILE"2 \
			-v "$FILE"3:"$FILE"3 \
			--net ceph_network --ip $NODE_IP --hostname ${node_name[$i]} --name ${node_name[$i]} ceph_node
	else
		# admin or mon container
		sudo docker run -d -it --net ceph_network --ip $NODE_IP --hostname ${node_name[$i]} --name ${node_name[$i]} ceph_node
	fi

	# add the new node into /etc/hosts
	echo -e "$NODE_IP\t${node_name[$i]}" | sudo tee -a /etc/hosts

	# copy ssh keys to the node
	sshpass -p $PASSWORD ssh-copy-id $USER@${node_name[$i]}
	sshpass -p $ROOT_PASSWORD ssh-copy-id root@${node_name[$i]}

	ssh ${node_name[$i]} "ssh-keygen -f ~/.ssh/id_rsa -N ''"

	# create a temp file with the id_rsa.pub of the node
	scp ${node_name[$i]}:.ssh/id_rsa.pub ./tmp-node$i

	# give user sudo without password
	CONFIG="$USER ALL=(ALL) NOPASSWD: ALL"
	ssh -t root@${node_name[$i]} "echo \"$CONFIG\" >> /etc/sudoers"

done

# partition the disks on the OSDs
for (( i = 1; i <= $NUM_OSD; i++)); do
	FILE="osd$i-disk"
	for (( j = 0; j < 3 ; j++)); do
		ssh -t root@${node_name[$i]} "parted -s /dev/$FILE$j mklabel gpt mkpart primary xfs 0% 100%"
		ssh -t root@${node_name[$i]} "mkfs.xfs /dev/$FILE$j -f"
	done
	ssh -t root@${node_name[$i]} "parted -s /dev/$FILE3 mklabel gpt mkpart primary 0% 33% mkpart primary 34% 66% mkpart primary 67% 100%"
done

# concatenate the keys from all the nodes in order to create .ssh/authorized_keys
cat ./tmp-node* > ./tmp-all
cat ~/.ssh/id_rsa.pub >> ./tmp-all
sudo cp ./tmp-all ~/.ssh/authorized_keys
cat ./tmp-all

# copy the authorized key file to all the nodes
for (( i = 0; i < $NUM_NODES; i++)); do
	scp $AUTHORIZED_KEYS ${node_name[$i]}:$AUTHORIZED_KEYS
done

# cleanup
rm ./tmp*

echo "Running nodes in cluster:"
sudo docker ps
