FROM phusion/baseimage:0.9.19

MAINTAINER David Coppit <david@coppit.org>

ENV DEBIAN_FRONTEND noninteractive

# Speed up APT
RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup \
  && echo "Acquire::http {No-Cache=True;};" > /etc/apt/apt.conf.d/no-cache

# Auto-accept Oracle JDK license
RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections

# Filebot needs Java 8
RUN add-apt-repository ppa:webupd8team/java \
  && apt-get update \
  && apt-get install -y oracle-java8-installer

# Create dir to keep things tidy. Make sure it's readable by $USER_ID
RUN mkdir /files
RUN chmod a+rwX /files

RUN set -x \
#  && apt-get update \
  # libchromaprint-tools for fpcalc, used to compute AcoustID fingerprints for MP3s
  && apt-get install -y python3-watchdog mediainfo libchromaprint-tools \
  && wget -O /files/filebot.deb 'https://app.filebot.net/download.php?type=deb&arch=amd64&version=4.7.8' \
  && dpkg -i /files/filebot.deb && rm /files/filebot.deb \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

VOLUME ["/input", "/output", "/config"]

# Rev-locking this to ensure reproducible builds
RUN wget -O /files/runas.sh \
  'https://raw.githubusercontent.com/coppit/docker-inotify-command/d0b25a4ed40582f5e2d21282c32c58164495c07b/runas.sh'
RUN chmod +x /files/runas.sh
RUN wget -O /files/monitor.py \
  'https://raw.githubusercontent.com/coppit/docker-inotify-command/7ed3d92e8b6c178944b89d986ea8156e5d1f0707/monitor.py'
RUN chmod +x /files/monitor.py

# Add scripts. Make sure start.sh, pre-run.sh, and filebot.sh are executable by $USER_ID
ADD pre-run.sh /files/pre-run.sh
RUN chmod a+x /files/pre-run.sh
ADD start.sh /files/start.sh
RUN chmod a+x /files/start.sh
ADD filebot.sh /files/filebot.sh
RUN chmod a+wx /files/filebot.sh
ADD filebot.conf /files/filebot.conf
RUN chmod a+w /files/filebot.conf

ENV USER_ID 0
ENV GROUP_ID 0
ENV UMASK 0000

# Set the locale, to help filebot deal with files that have non-ASCII characters
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

CMD /files/start.sh
