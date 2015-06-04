# Download any scripts
for SCRIPT_TO_DOWNLOAD in ${SCRIPTS_TO_DOWNLOAD[@]}
do
  FILENAME=/config/scripts/${SCRIPT_TO_DOWNLOAD##*/}

  # Sadly, github doesn't supply a Last-Modified header, so wget -N can't be used. So let's instead only pull down new
  # versions once a day
  if ! test "`find $FILENAME -mtime -1 2>/dev/null`"
  then
    echo Downloading $FILENAME
    wget -q -O $FILENAME $SCRIPT_TO_DOWNLOAD
  fi
done

# Avoid a Java encoding error
export LC_ALL="en_US.UTF-8"

