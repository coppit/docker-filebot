#!/bin/bash

. /files/FileBot.conf

function ts {
  echo [`date '+%b %d %X'`]
}

#-----------------------------------------------------------------------------------------------------------------------

# Run once at the start
echo "$(ts) Running FileBot on startup"
/files/runas.sh $USER_ID $GROUP_ID $UMASK /files/filebot.sh

# Start monitoring
/files/monitor.py /files/FileBot.conf
