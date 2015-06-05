FROM phusion/baseimage:0.9.11

MAINTAINER David Coppit <david@coppit.org>

ENV DEBIAN_FRONTEND noninteractive

# Speed up APT
RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup \
  && echo "Acquire::http {No-Cache=True;};" > /etc/apt/apt.conf.d/no-cache

# Auto-accept Oracle JDK license
RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections

RUN add-apt-repository ppa:webupd8team/java \
  && apt-get update \
  && apt-get install -y oracle-java8-installer

# Use of inotify inspired by inkubux/filebot-inotifywatch
RUN set -x \
#  && apt-get update \
  && apt-get install -y inotify-tools \
  && wget -O /root/filebot.deb 'https://www.filebot.net/download.php?mode=s&type=deb&arch=amd64' \
  && dpkg -i /root/filebot.deb && rm /root/filebot.deb \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

VOLUME ["/input", "/output", "/config"]

# Add scripts
ADD pre-run.sh /root/pre-run.sh
RUN chmod +x /root/pre-run.sh
ADD start.sh /root/start.sh
RUN chmod +x /root/start.sh
ADD filebot.sh /root/filebot.sh
RUN chmod +x /root/start.sh

CMD /root/start.sh
