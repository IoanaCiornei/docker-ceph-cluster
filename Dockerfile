FROM ubuntu:14.04
MAINTAINER Ioana Ciornei <ciorneiioana@gmail.com>

RUN apt-get update
RUN apt-get install -y openssh-server
RUN apt-get install -y x11-apps
RUN apt-get install -y vim tmux
RUN apt-get install -y vim curl
RUN apt-get install -y vim git
RUN apt-get install -y ntp ntpdate ntp-doc
RUN apt-get install -y parted xfsprogs

# Add Ceph repositories to the ceph-deploy admin node. Then, install ceph-deploy
RUN wget -q -O- 'https://download.ceph.com/keys/release.asc' | sudo apt-key add -
RUN echo deb http://download.ceph.com/debian-jewel/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list
RUN apt-get update && apt-get install -y ceph-deploy

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


###### RUN SSH server as a root ######
USER root
CMD ["/usr/sbin/sshd", "-D"]
