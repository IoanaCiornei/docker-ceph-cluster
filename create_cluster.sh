#! /bin/bash

source ./settings.sh

set -x


# create the cluster network
sudo docker network create --subnet=$NETWORK_IP.0/$NETWORK_MASK $CLUSTER_NETWORK

# build the latest image of the ceph_node
sudo docker build -t ceph_node .

# array of devices - devs

# create the files that will represent the extra disks for the containers
mkdir $FILES_DIR
num=0
for (( i = 1; i <= $NUM_OSD; i++)); do

	for (( j = 0; j < $NUM_DISKS; j++)); do
		FILE="osd$i-disk$j"
		HOST_FILE="$FILES_DIR/$FILE"

		[ -f $HOST_FILE ]  || fallocate -l 1G $HOST_FILE
		sudo losetup -f $HOST_FILE
		disk=$(losetup --associated $HOST_FILE | cut -f1 -d:)
		devs[$num]=$disk
		((num = $num + 1))
		echo " DISK _____________ $disk"
	done
done


# partition the disks on the OSDs
num=0
for (( i = 1; i <= $NUM_OSD; i++)); do
	for (( j = 0; j < 3 ; j++)); do
		FILE=${devs[$num]} ; ((num++))
		sudo parted -s $FILE mklabel gpt mkpart primary xfs 0% 100%
		sudo mkfs.xfs $FILE -f
	done
	FILE=${devs[$num]} ; ((num++))
	sudo parted -s $FILE mklabel gpt mkpart primary 0% 33% mkpart primary 34% 66% mkpart primary 67% 100%
done


# create NUM_NODES containers
num=0
for (( i = 0; i < $NUM_NODES; i++)); do
	NODE_IP="$NETWORK_IP.$(($i+2))"

	# start the container
	if (( i >= 1 && i <= $NUM_OSD )); then
		# start the container with multiple disk if it is a OSD
		FILE1=${devs[$num]} ; FILE1_p1="${devs[$num]}p1"; ((num++))
		FILE2=${devs[$num]} ; FILE2_p1="${devs[$num]}p1"; ((num++))
		FILE3=${devs[$num]} ; FILE3_p1="${devs[$num]}p1"; ((num++))
		FILE4=${devs[$num]} ; FILE4_p1="${devs[$num]}p1"; FILE4_p2="${devs[$num]}p2"; FILE4_p3="${devs[$num]}p3"; ((num++))

		sudo docker run -d -it \
			--privileged \
			-v $FILE1:$FILE1 \
			-v $FILE1_p1:$FILE1_p1 \
			-v $FILE2:$FILE2 \
			-v $FILE2_p1:$FILE2_p1 \
			-v $FILE3:$FILE3 \
			-v $FILE3_p1:$FILE3_p1 \
			-v $FILE4:$FILE4 \
			-v $FILE4_p1:$FILE4_p1 \
			-v $FILE4_p2:$FILE4_p2 \
			-v $FILE4_p3:$FILE4_p3 \
			-v /sys/fs/cgroup:/sys/fs/cgroup:ro \
			--net ceph_network --ip $NODE_IP --hostname ${node_name[$i]} --name ${node_name[$i]} ceph_node

	else
		# admin or mon container
		sudo docker run -d -it \
			--privileged \
			-v /sys/fs/cgroup:/sys/fs/cgroup:ro \
			--net ceph_network --ip $NODE_IP --hostname ${node_name[$i]} --name ${node_name[$i]} ceph_node
	fi

	# add the new node into /etc/hosts
	echo -e "$NODE_IP\t${node_name[$i]}" | sudo tee -a /etc/hosts

	# Wait for container to go up before issuing any more commands
	while ! (yes | sshpass -p $PASSWORD ssh $USER@${node_name[$i]} echo -e 'Host $HOSTNAME is up!'); do :; done

	# TODO
	# 1. generate keys on host of there aren't
	# 2. copy them to the containers with docker
	# 3. add UserKnownHostsFile /dev/null  + StrictHostKeyChecking no

	# copy my keys to the other hosts
	sshpass -p $PASSWORD scp -v ~/.ssh/id_rsa ~/.ssh/id_rsa.pub ${node_name[i]}:~/.ssh/
	sshpass -p $PASSWORD scp -v ~/.ssh/authorized_keys ${node_name[$i]}:~/.ssh/authorized_keys
	sshpass -p $ROOT_PASSWORD scp -v ~/.ssh/authorized_keys root@${node_name[$i]}:~/.ssh/authorized_keys

	# give user sudo without password
	CONFIG="$USER ALL=(ALL) NOPASSWD: ALL"
	ssh -t root@${node_name[$i]} "echo \"$CONFIG\" >> /etc/sudoers"

	ssh $USER@${node_name[$i]} "echo -e 'Host *\n\tStrictHostKeyChecking no' >> ~/.ssh/config"

done


echo "Running nodes in cluster:"
sudo docker ps
