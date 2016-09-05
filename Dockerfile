FROM ubuntu:16.04
MAINTAINER Ioana Ciornei <ciorneiioana@gmail.com>

ENV container docker

# https://github.com/phusion/baseimage-docker/issues/58
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN apt-get -y update
RUN apt-get -y upgrade
RUN apt-get install -y systemd systemd-sysv
RUN apt-get install -y openssh-server
RUN apt-get install -y x11-apps
RUN apt-get install -y vim tmux
RUN apt-get install -y curl
RUN apt-get install -y git
RUN apt-get install -y ntp ntpdate ntp-doc
RUN apt-get install -y parted xfsprogs wget
RUN apt-get install -y lsb-release
RUN apt-get install -y sudo
RUN apt-get install -y libpam-systemd dbus

# Add Ceph repositories to the ceph-deploy admin node. Then, install ceph-deploy
RUN wget -q -O- 'https://download.ceph.com/keys/release.asc' | apt-key add -
RUN echo deb http://download.ceph.com/debian-jewel/ $(lsb_release -sc) main | tee /etc/apt/sources.list.d/ceph.list
RUN apt-get -y update
RUN apt-get install -y ceph-deploy


USER root

###### Create USER ######
RUN useradd --create-home --shell /bin/bash --groups sudo pis
RUN echo 'pis:ceph' | chpasswd
RUN mkdir /home/pis/.ssh/
RUN chown pis:pis -R /home/pis/

###### SSH #######
RUN mkdir /root/.ssh
RUN mkdir /var/run/sshd
RUN echo 'root:root' | chpasswd
RUN sed -i 's/PermitRootLogin/#PermitRootLogin/' /etc/ssh/sshd_config
RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

EXPOSE 22

###### VIM + TMUX ######

USER pis

RUN mkdir /home/pis/src
RUN cd /home/pis/src ; git clone https://github.com/vladimiroltean/blog.git
RUN cd /home/pis/src/blog ; ./install.sh ; whoami

RUN curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
RUN echo -e "\n" | vim -c "PlugInstall"; echo ":q"


RUN mkdir -p /home/pis/src/licenta/
USER root

RUN apt-get install -y udev

###### ssh + systemd  ######
RUN ["systemctl",  "enable", "ssh.service"]
VOLUME ["/sys/fs/cgroup"]
CMD [ "/sbin/init"]



