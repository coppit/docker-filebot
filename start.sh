#!/bin/bash

function ts {
  echo [`date '+%b %d %X'`]
}

echo "$(ts) Starting FileBot container"

# Create filebot.sh unless there is already one
if [ ! -f /config/filebot.sh ]; then
  echo "$(ts) Creating /config/filebot.sh and exiting"
  cp /root/filebot.sh /config/filebot.sh
  exit 1
fi

USER_VERSION=$(grep '^VERSION=' /config/filebot.sh 2>/dev/null | sed 's/VERSION=//')
CURRENT_VERSION=$(grep '^VERSION=' /root/filebot.sh | sed 's/VERSION=//')

echo "$(ts) Comparing user's filebot.sh at version $USER_VERSION versus current version $CURRENT_VERSION"

if [ -z "$USER_VERSION" ] || [ "$USER_VERSION" -lt "$CURRENT_VERSION" ]
then
  echo "$(ts) ERROR: The container's filebot.sh is newer than the one in /config."
  echo "$(ts)   Copying the new script to /config/filebot.sh.new."
  echo "$(ts)   Compare your filebot.sh and filebot.sh.new. Save filebot.sh to reset its timestamp,"
  echo "$(ts)   then restart the container."
  cp /root/filebot.sh /config/filebot.sh.new
  exit 1
fi

function run_filebot_sh {
  # Do this every time in case the user edits their filebot.sh while the container is running
  tr -d '\r' < /config/filebot.sh > /root/filebot.sh
  chmod a+x /root/filebot.sh

  # filebot amc's --log-file will implement locking, which will automatically slow this loop down if there are lots of
  # events. https://www.filebot.net/forums/viewtopic.php?f=4&t=638
  /root/filebot.sh
}

# Run once at the start
echo "$(ts) Running filebot on startup..."
run_filebot_sh

# Wait forever for changes
inotifywait -m -q -e close_write --format '%f' /input | while read FILE
do
  echo "$(ts) Detected new file $FILE. Running FileBot."

  run_filebot_sh
done
