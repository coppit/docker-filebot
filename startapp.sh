#!/bin/bash

. /files/FileBot.conf

function ts {
  echo [`date '+%b %d %X'`]
}

#-----------------------------------------------------------------------------------------------------------------------

export DISPLAY=:1

if [ "$RUN_UI" == "yes" ]
then
  echo "$(ts) Running FileBot GUI"
  /files/runas.sh $USER_ID $GROUP_ID $UMASK filebot
else
  echo "$(ts) Not running FileBot GUI"
  sv stop guacd tomcat7 filebot-ui X11rdp xrdp xrdp-sesman openbox
fi
