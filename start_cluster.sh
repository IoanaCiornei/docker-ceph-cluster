#! /bin/bash

source ./settings.sh

set -x

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

# create the cluster network
sudo docker network create --subnet=$NETWORK_IP.0/$NETWORK_MASK $CLUSTER_NETWORK

# build the latest image of the ceph_node
sudo docker build -t ceph_node .

mkdir $FILES_DIR

# create the files that will represent the extra disks for the containers
(( minor = $START_MINOR ))
for (( osd = 0; osd < $NUM_OSD; osd++)); do
	((node = osd + 1))

	for (( j = 0; j < $NUM_DISKS; j++)); do
		HOST_FILE="$FILES_DIR/node$node-osd$j"
		BLK_FILE="/dev/node$node-osd$j"

		[ -f $HOST_FILE ]  || dd if=/dev/zero of=$HOST_FILE bs=1M count=1000
		sudo mknod $BLK_FILE b 7 $minor
		(( minor = $minor + 1 ))
		sudo losetup $BLK_FILE $HOST_FILE
	done
done

# create NUM_NODES containers
for (( i = 0; i < $NUM_NODES; i++)); do
	((j = i + 2))
	NODE_IP="$NETWORK_IP.$j"

	# start the container
	if (( i >= 1 && i <= 1 + $NUM_OSD )); then
		# start the container with multiple disk if it is a OSD
		sudo docker run -d -it \
			--privileged \
			-v /dev/node$i-osd0:/dev/node$i-osd0 \
			-v /dev/node$i-osd1:/dev/node$i-osd1 \
			-v /dev/node$i-osd2:/dev/node$i-osd2 \
			-v /dev/node$i-osd3:/dev/node$i-osd3 \
			--net ceph_network --ip $NODE_IP --hostname node$i --name node$i ceph_node
	else
		# admin or mon container
		sudo docker run -d -it --net ceph_network --ip $NODE_IP --hostname node$i --name node$i ceph_node
	fi

	# add the new node into /etc/hosts
	echo -e "$NODE_IP\tnode$i" | sudo tee -a /etc/hosts


	# copy ssh keys to the node
	sshpass -p $PASSWORD ssh-copy-id ioana@node$i
	sshpass -p "root" ssh-copy-id root@node$i

	ssh node$i "ssh-keygen -f ~/.ssh/id_rsa -N ''"

	# create a temp file with the id_rsa.pub of the node
	scp node$i:.ssh/id_rsa.pub ./tmp-node$i

	# give user 'ioana' sudo without password
	CONFIG="ioana ALL=(ALL) NOPASSWD: ALL"
	ssh -t root@node$i "echo \"$CONFIG\" >> /etc/sudoers"
done

# partition the disks on the OSDs
for (( i = 1; i <= $NUM_OSD; i++)); do
	for (( j = 0; j < 3 ; j++)); do
		ssh -t node$i "sudo parted -s /dev/node$i-osd$j mklabel gpt mkpart primary xfs 0% 100%"
		ssh -t node$i "sudo mkfs.xfs /dev/node$i-osd$j -f"
	done
	ssh -t node$i "sudo parted -s /dev/node$i-osd3 mklabel gpt mkpart primary 0% 33% mkpart primary 34% 66% mkpart primary 67% 100%"
done

# concatenate the keys from all the nodes in order to create .ssh/authorized_keys
cat ./tmp-node* > ./tmp-all
cat ~/.ssh/id_rsa.pub >> ./tmp-all
sudo cp ./tmp-all ~/.ssh/authorized_keys
cat ./tmp-all

# copy the authorized key file to all the nodes
for (( i = 0; i < $NUM_NODES; i++)); do
	scp ~/.ssh/authorized_keys node$i:$AUTHORIZED_KEYS
done

# cleanup
rm ./tmp*

echo "Running nodes in cluster:"
sudo docker ps
