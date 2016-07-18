Create a Ceph cluster with Docker
=================================

This repo is intended to help users create, setup and run a Ceph cluster
using Docker containers on the same machine.


### Dependencies

* docker.io + docker
* sshpass

### Install Docker

In order to use it you should have docker installed. In order to do that
you should follow the instructions from
[Docker](https://docs.docker.com/engine/installation/).


### Create the cluster

	* clone this repo
	* customize the Ceph cluster by changing settings.sh

		My cluster consists of 3 hosts that will each run 3 **OSD deamons**,
		3 hosts that will be **monitors** and one **admin** host that
		will be used for configuration purposes.

		NUM_OSD - number of hosts that will run OSD daemons
		NUM_MON - number of hosts that will be monitors
		NUM_DISKS -  number of disks per OSD host

		LOOP_MAJOR - should be fixed at 7
		START_MINOR - first minor that is not used for loop devices

		NETWORK_IP - shoould be set to a local unused network
		NETWORK_MASK - mask for the cluster network
		CLUSTER_NETWORK - name of the network cluster

		USER - user with sudo rights on all the Docker containers
		PASSWORD - its password
		ROOT_PASSWORD - password for the root user on the containers

		AUTHORIZED_KEYS - fixed

	* run the create script

		./create_cluster.sh

### Stop the cluster

	./stop_cluster.sh

### Start the cluster

	./start_cluster.sh

### Delete the cluster

	./delete_cluster
