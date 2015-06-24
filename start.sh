#!/bin/bash

# After seeing the first event, don't run FileBot until we've processed any other events that might be happening.
# Otherwise we'll end up calling FileBot 100 times for the case where someone moves 100 files into the input directory.

# If we don't see any events for $SETTLE_DURATION time, assume that it's safe to run FileBot
SETTLE_DURATION=5

# However, if we see continuous events for longer than $MAX_WAIT_TIME with no break of $SETTLE_DURATION or more, then
# go ahead and run FileBot. Otherwise we might be waiting forever for the directory to stop getting events.
MAX_WAIT_TIME=60

function ts {
  echo [`date '+%b %d %X'`]
}

echo "$(ts) Starting FileBot container"

# Create filebot.sh unless there is already one
if [ ! -f /config/filebot.sh ]; then
  echo "$(ts) Creating /config/filebot.sh and exiting"
  cp /files/filebot.sh /config/filebot.sh
  exit 1
fi

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

function run_filebot_sh {
  # Do this every time in case the user edits their filebot.sh while the container is running
  tr -d '\r' < /config/filebot.sh > /files/filebot.sh

  # filebot amc's --log-file will implement locking, which will automatically slow this loop down if there are lots of
  # events. https://www.filebot.net/forums/viewtopic.php?f=4&t=638
  bash /files/filebot.sh
}

# Run once at the start
echo "$(ts) Running filebot on startup"
run_filebot_sh

pipe=$(mktemp -u)
mkfifo $pipe

echo "$(ts) Waiting for changes..."
inotifywait -m -q --format '%e %f' /input >$pipe &

while true
do
  if read RECORD
  then
    EVENT=$(echo "$RECORD" | cut -d' ' -f 1)
    FILE=$(echo "$RECORD" | cut -d' ' -f 2-)

#    echo "$RECORD"
#    echo "  EVENT=$EVENT"
#    echo "  FILE=$FILE"

    if [ "$EVENT" == "CREATE,ISDIR" ]
    then
      echo "$(ts) Detected new directory: $FILE"
    elif [ "$EVENT" == "CLOSE_WRITE,CLOSE" ]
    then
      echo "$(ts) Detected new file: $FILE"
    elif [ "$EVENT" == "MOVED_TO" ]
    then
      echo "$(ts) Detected moved file: $FILE"
    else
      continue
    fi

    # Monster up as many events as possible, until we hit the either the settle duration, or the max wait threshold.
    start_time=$(date +"%s")

    while true
    do
      if read -t $SETTLE_DURATION RECORD
      then
        end_time=$(date +"%s")

        if [ $(($end_time-$start_time)) -gt $MAX_WAIT_TIME ]
        then
          echo "$(ts) Input directory didn't stabilize after $MAX_WAIT_TIME seconds. Running FileBot anyway."
          break
        fi
      else
        echo "$(ts) Input directory stabilized for $SETTLE_DURATION seconds. Running FileBot."
        break
      fi
    done

    run_filebot_sh
  fi
done <$pipe
