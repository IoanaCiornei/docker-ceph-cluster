#! /bin/bash

mkdir ceph-deploy
cd ceph-deploy

ceph-deploy new mon1 mon2 mon3

echo "You should put stuff in ceph.conf and then press space"
read

ceph-deploy install admin mon1 mon2 mon3 osd1 osd2 osd3
ceph-deploy mon create-initial
ceph-deploy gatherkeys mon1

ceph-deploy disk zap osd1:loop2 osd1:loop3 osd1:loop4
ceph-deploy osd create osd1:loop2:/dev/loop5p1 osd1:loop3:/dev/loop5p2 osd1:loop4:/dev/loop5p3

ceph-deploy disk zap osd2:loop6 osd2:loop7 osd2:loop8
ceph-deploy osd create osd2:loop6:/dev/loop9p1 osd2:loop7:/dev/loop9p2 osd2:loop8:/dev/loop9p3

ceph-deploy disk zap osd3:loop10 osd3:loop11 osd3:loop12
ceph-deploy osd create osd3:loop10:/dev/loop13p1 osd3:loop11:/dev/loop13p2 osd3:loop12:/dev/loop13p3


sudo gdisk -t 1:45b0969e-9b03-4f30-b4c6-b4b80ceff106 /dev/loop5
sudo gdisk -t 2:45b0969e-9b03-4f30-b4c6-b4b80ceff106 /dev/loop5
sudo gdisk -t 3:45b0969e-9b03-4f30-b4c6-b4b80ceff106 /dev/loop5

sudo systemctl enable ceph-mon.target && sudo systemctl start ceph-mon.target && sudo systemctl status ceph-mon.target

sudo systemctl enable ceph-osd.target && sudo systemctl start ceph-osd.target && sudo systemctl status ceph-osd.target
