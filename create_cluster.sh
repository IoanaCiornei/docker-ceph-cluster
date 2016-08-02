#! /bin/bash

MODULE='CREATE_CEPH_CLUSTER'

source ./settings.sh

log $MODULE "Copy id_rsa to localhost..."
ssh-copy-id localhost &>> $DEBUG_FILE

log $MODULE "Create cluster network..."
sudo docker network create --subnet=$NETWORK_IP.0/$NETWORK_MASK $CLUSTER_NETWORK &>> $DEBUG_FILE

log $MODULE "Build the latest image of the ceph_node..."
sudo docker build -t ceph_node . &>> $DEBUG_FILE

status=$(systemctl is-active ceph-mount-blk.service)
if [[ "$status" == "inactive" ]]; then
	log $MODULE "Start ceph-mount-blk service..."
	sudo systemctl start ceph-mount-blk.service &>> $DEBUG_FILE
	sleep 5
fi

log $MODULE "Retrieve block devices..."
loop_devs=$(journalctl -b | grep "$LOGGER" | tail -n $NUM_DEVS | awk '{print $NF}')
num=0
for dev in $loop_devs; do
	devs[$num]=$dev
	((num++))
done

log $MODULE "Create containers..."
for ((num=0, i = 0; i < $NUM_NODES; i++)); do
	NODE_IP="$NETWORK_IP.$(($i+2))"

	log $MODULE "Create container ${node_name[$i]}..."
	if (( i >= 1 && i <= $NUM_OSD )); then
		# start the container with multiple disk if it is a OSD
		FILE1=${devs[$num]} ; FILE1_p1="${devs[$num]}p1"; ((num++))
		FILE2=${devs[$num]} ; FILE2_p1="${devs[$num]}p1"; ((num++))
		FILE3=${devs[$num]} ; FILE3_p1="${devs[$num]}p1"; ((num++))
		FILE4=${devs[$num]} ; FILE4_p1="${devs[$num]}p1"; FILE4_p2="${devs[$num]}p2"; FILE4_p3="${devs[$num]}p3"; ((num++))

		# create an OSD container
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
			--net ceph_network --ip $NODE_IP --hostname ${node_name[$i]} --name ${node_name[$i]} ceph_node &>> $DEBUG_FILE
	else
		# create ADMIN or MON container
		sudo docker run -d -it \
			--privileged \
			-v /sys/fs/cgroup:/sys/fs/cgroup:ro \
			--net ceph_network --ip $NODE_IP --hostname ${node_name[$i]} --name ${node_name[$i]} ceph_node &>> $DEBUG_FILE
	fi

	log $MODULE "Add the new node into /etc/hosts..."
	echo -e "$NODE_IP\t${node_name[$i]}" | sudo tee -a /etc/hosts &>> $DEBUG_FILE

	log $MODULE "Wait for container to go up before issuing any more commands..." "-n"
	while ! (sshpass -p $PASSWORD ssh $USER@${node_name[$i]} echo -e 'Host $HOSTNAME is up!' 2>> $DEBUG_FILE); do :; done

	log $MODULE "Copy public keys on the host on the container..."
	sshpass -p $PASSWORD scp -v ~/.ssh/id_rsa ~/.ssh/id_rsa.pub $USER@${node_name[$i]}:~/.ssh/ &>> $DEBUG_FILE
	sshpass -p $ROOT_PASSWORD scp -v ~/.ssh/id_rsa ~/.ssh/id_rsa.pub root@${node_name[$i]}:~/.ssh/ &>> $DEBUG_FILE
	sshpass -p $PASSWORD scp -v ~/.ssh/authorized_keys $USER@${node_name[$i]}:~/.ssh/authorized_keys &>> $DEBUG_FILE
	sshpass -p $ROOT_PASSWORD scp -v ~/.ssh/authorized_keys root@${node_name[$i]}:~/.ssh/authorized_keys &>> $DEBUG_FILE

	log $MODULE "Give user $USER sudo rights without a password on container ${node_name[$i]}..."
	CONFIG="$USER ALL=(ALL) NOPASSWD: ALL"
	ssh -t root@${node_name[$i]} "echo \"$CONFIG\" >> /etc/sudoers" &>> $DEBUG_FILE

	log $MODULE "Disable strict host checking on container ${node_name[$i]}..."
	ssh $USER@${node_name[$i]} "echo -e 'Host *\n\tStrictHostKeyChecking no' >> ~/.ssh/config" &>> $DEBUG_FILE

done
log $MODULE "Cluster nodes:"
sudo docker ps
log $MODULE "Create cluster nodes... Finished"

log $MODULE "Copy admin script on container..."
scp conf admin1.sh $USER@admin:. &>> $DEBUG_FILE

log $MODULE "Deploy cluster on newly create Docker containers"
ssh $USER@admin "/home/$USER/admin1.sh" &>> $DEBUG_FILE

echo "should press space"
read
log $MODULE "Restart cluster..."
./ceph_cluster restart

