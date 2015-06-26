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

# Create dir to keep things tidy. Make sure it's readable by $UID
RUN mkdir /files
RUN chmod a+rwX /files

# Use of inotify inspired by inkubux/filebot-inotifywatch
RUN set -x \
#  && apt-get update \
  && apt-get install -y inotify-tools \
  && wget -O /files/filebot.deb 'https://www.filebot.net/download.php?mode=s&type=deb&arch=amd64' \
  && dpkg -i /files/filebot.deb && rm /files/filebot.deb \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

VOLUME ["/input", "/output", "/config"]

# Rev-locking this to ensure reproducible builds
RUN wget -O /files/runas.sh \
  'https://raw.githubusercontent.com/coppit/docker-inotify-command/dd981dc799362d47387da584e1a276bbd1f1bd1b/runas.sh'
RUN chmod +x /files/runas.sh

# Add scripts. Make sure start.sh, pre-run.sh, and filebot.sh are executable by $UID
ADD pre-run.sh /files/pre-run.sh
RUN chmod a+x /files/pre-run.sh
ADD start.sh /files/start.sh
RUN chmod a+x /files/start.sh
ADD filebot.sh /files/filebot.sh
RUN chmod a+wx /files/filebot.sh

ENV USER_ID 0
ENV GROUP_ID 0
ENV UMASK 0000

CMD /files/runas.sh $USER_ID $GROUP_ID $UMASK /files/start.sh
