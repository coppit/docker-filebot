#!/bin/bash

function ts {
  echo [`date '+%b %d %X'`]
}

#-----------------------------------------------------------------------------------------------------------------------

function initialize_configuration {
  echo "$(ts) Creating /config/filebot.conf.new"
  cp /files/filebot.conf /config/filebot.conf.new

  if [ ! -f /config/filebot.conf ]
  then
    echo "$(ts) Creating /config/filebot.conf"
    cp /files/filebot.conf /config/filebot.conf
    chmod a+w /config/filebot.conf
  fi

  # Create filebot.sh unless there is already one
  if [ ! -f /config/filebot.sh ]
  then
    echo "$(ts) Creating /config/filebot.sh and exiting"
    cp /files/filebot.sh /config/filebot.sh
    exit 1
  fi
}

#-----------------------------------------------------------------------------------------------------------------------

function check_filebot_sh_version {
  USER_VERSION=$(grep '^VERSION=' /config/filebot.sh 2>/dev/null | sed 's/VERSION=//')
  CURRENT_VERSION=$(grep '^VERSION=' /files/filebot.sh | sed 's/VERSION=//')

  echo "$(ts) Comparing user's filebot.sh at version $USER_VERSION versus current version $CURRENT_VERSION"

  if [ -z "$USER_VERSION" ] || [ "$USER_VERSION" -lt "$CURRENT_VERSION" ]
  then
    echo "$(ts) ERROR: The container's filebot.sh is newer than the one in /config."
    echo "$(ts)   Copying the new script to /config/filebot.sh.new."
    echo "$(ts)   Compare your filebot.sh and filebot.sh.new. Save filebot.sh to reset its timestamp,"
    echo "$(ts)   then restart the container."
    cp /files/filebot.sh /config/filebot.sh.new
    exit 1
  fi
}

#-----------------------------------------------------------------------------------------------------------------------

function create_conf_and_sh_files {
  # Create the config file for monitor.py
  tr -d '\r' < /config/filebot.conf > /files/FileBot.conf

  cat <<"EOF" >> /files/FileBot.conf

WATCH_DIR=/input

COMMAND="bash /files/filebot.sh"

IGNORE_EVENTS_WHILE_COMMAND_IS_RUNNING=0

USER_ID=$USER_ID
GROUP_ID=$GROUP_ID
UMASK=$UMASK
EOF

  # Strip \r from the user-provided filebot.sh
  tr -d '\r' < /config/filebot.sh > /files/filebot.sh
}

#-----------------------------------------------------------------------------------------------------------------------

function setup_opensubtitles_account {
  . /config/filebot.conf

  if [ "$OPENSUBTITLES_USER" != "" ]; then
    echo "$(ts) Configuring for OpenSubtitles user \"$OPENSUBTITLES_USER\""
    echo -en "$OPENSUBTITLES_USER\n$OPENSUBTITLES_PASSWORD\n" | /files/runas.sh $USER_ID $GROUP_ID $UMASK filebot -script fn:configure
  else
    echo "$(ts) No OpenSubtitles user set. Skipping setup..."
  fi
}

#-----------------------------------------------------------------------------------------------------------------------

echo "$(ts) Starting FileBot container"

initialize_configuration

check_filebot_sh_version

create_conf_and_sh_files

setup_opensubtitles_account

# Run once at the start
echo "$(ts) Running FileBot on startup"
/files/runas.sh $USER_ID $GROUP_ID $UMASK /files/filebot.sh &

# Start monitoring
/files/monitor.py /files/FileBot.conf
