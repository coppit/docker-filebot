#!/bin/bash

. /files/FileBot.conf

function ts {
  echo [`date '+%b %d %X'`]
}

#-----------------------------------------------------------------------------------------------------------------------

export DISPLAY=:1

echo "$(ts) Running FileBot GUI"
/files/runas.sh $USER_ID $GROUP_ID $UMASK filebot
