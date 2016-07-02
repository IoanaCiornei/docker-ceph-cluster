FROM debian:jessie
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


###### Create USER ######
RUN useradd --create-home --shell /bin/bash --groups sudo ioana
RUN echo 'ioana:ceph' | chpasswd
RUN mkdir /home/ioana/.ssh/
RUN chown ioana:ioana -R /home/ioana/

###### SSH #######
RUN mkdir /var/run/sshd
RUN echo 'root:root' | chpasswd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

RUN ssh-keygen -f ~/.ssh/id_rsa.pub -t rsa -N ''

EXPOSE 22

###### VIM + TMUX ######

USER ioana

RUN mkdir /home/ioana/src
RUN cd /home/ioana/src ; git clone https://github.com/vladimiroltean/blog.git
RUN cd /home/ioana/src/blog ; ./install.sh ; whoami

RUN curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
RUN echo -e "\n" | vim -c "PlugInstall"; echo ":q"


###### ssh + systemd  ######
USER root

#RUN rm -f /lib/systemd/system/multi-user.target.wants/*;
#RUN rm -f /etc/systemd/system/*.wants/*;
#RUN rm -f /lib/systemd/system/local-fs.target.wants/*;
#RUN rm -f /lib/systemd/system/sockets.target.wants/*udev*;
#RUN rm -f /lib/systemd/system/sockets.target.wants/*initctl*;
#RUN rm -f /lib/systemd/system/basic.target.wants/*;
#RUN rm -f /lib/systemd/system/anaconda.target.wants/*


#RUN ["find / -name 'ssh*.service'"]
RUN ["systemctl",  "enable", "ssh.service"]

VOLUME ["/sys/fs/cgroup"]
CMD [ "/sbin/init"]



