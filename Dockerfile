FROM debian:wheezy

WORKDIR /root

ENV DEBIAN_FRONTEND noninteractive
RUN echo exit 0 > /usr/sbin/policy-rc.d

RUN echo "root:password" | chpasswd
RUN apt-get update && apt-get install -y \
        inetutils-syslogd \
        python \
        openssh-server \
        curl \
        wget \
        locales \
        libpam-python

RUN locale-gen en_GB.UTF-8

RUN useradd -m admin -s /bin/bash

RUN echo "admin:admin123" | chpasswd
#RUN sed -ri 's/^LogLevel INFO/LogLevel DEBUG/' /etc/ssh/sshd_config
RUN sed -ri 's/^PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -ri 's/^#?PasswordAuthentication\s+.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
# RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config

#RUN echo "UsePAM yes" >> /etc/ssh/ssh_config
#RUN echo "PasswordAuthentication yes" >> /etc/ssh/ssh_config
#RUN echo "PermitRootLogin yes" >> /etc/ssh/ssh_config

RUN mkdir /root/.ssh
ADD ./hp/pwreveal.py  /lib/x86_64-linux-gnu/security/pwreveal.py

RUN sed -i -e "s/@include common-auth/#@include common-auth\nauth requisite pam_python.so \/lib\/x86_64-linux-gnu\/security\/pwreveal.py /" /etc/pam.d/sshd
RUN echo "" > /var/log/auth.log
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D", "-e"]


