#! /bin/bash

mkdir ceph-deploy
cd ceph-deploy

ceph-deploy new mon1 mon2 mon3

cat ~/conf >> ceph.conf
cat ceph.conf
read

ceph-deploy install admin mon1 mon2 mon3 osd1 osd2 osd3
ceph-deploy mon create-initial
ceph-deploy gatherkeys mon1

read

ceph-deploy disk zap osd1:loop0 osd1:loop1 osd1:loop2
ceph-deploy osd create osd1:loop0:/dev/loop3p1 osd1:loop1:/dev/loop3p2 osd1:loop2:/dev/loop3p3

read

ceph-deploy disk zap osd2:loop4 osd2:loop5 osd2:loop6 
ceph-deploy osd create osd2:loop4:/dev/loop7p1 osd2:loop5:/dev/loop7p2 osd2:loop6:/dev/loop7p3

read

ceph-deploy disk zap osd3:loop8 osd3:loop9 osd3:loop10 
ceph-deploy osd create osd3:loop8:/dev/loop11p1 osd3:loop9:/dev/loop11p2 osd3:loop10:/dev/loop11p3

read

ceph-deploy admin admin mon1 mon2 mon3 osd1 osd2 osd3
sudo chmod +r /etc/ceph/ceph.client.admin.keyring

#sudo sgdisk -t 1:45b0969e-9b03-4f30-b4c6-b4b80ceff106 /dev/loop3
#sudo sgdisk -t 2:45b0969e-9b03-4f30-b4c6-b4b80ceff106 /dev/loop3
#sudo sgdisk -t 3:45b0969e-9b03-4f30-b4c6-b4b80ceff106 /dev/loop3

#sudo systemctl enable ceph-mon.target && sudo systemctl start ceph-mon.target && sudo systemctl status ceph-mon.target
#sudo systemctl enable ceph-osd.target && sudo systemctl start ceph-osd.target && sudo systemctl status ceph-osd.target

