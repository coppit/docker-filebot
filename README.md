docker-filebot
==============

This is a Docker container for running [FileBot](http://www.filebot.net/), a media file organizer. Drop files
into the input directory, and they'll be cleaned up and moved to the output directory.

Usage
-----

This docker image is available as a [trusted build on the docker index](https://index.docker.io/u/coppit/filebot/).

Run:

`sudo docker run --name=FileBot -d -v /etc/localtime:/etc/localtime -v /config/dir/path:/config:rw -v /input/dir/path:/input -v /output/dir/path:/output:rw coppit/filebot`

With the default configuration, files written to the input directory will be renamed and copied to the output directory.
It is recommended that you do **not** overlap your input and output directories. FileBot will end up re-processing files
that it already processed, and generally make a mess of things.

To check the status, run:

`docker logs FileBot`

When the container detects a change to the input directory, it will wait up to 60 seconds for changes to stop for 5
seconds. FileBot will be run if the directory stabilizes for 5 seconds, or if the 60 second maximum wait time elapses.

Configuration
-------------

When run for the first time, a script named `filebot.sh` will be created in the config dir, and the container will exit.
Edit this file, customizing how you want FileBot to run. For example, you might want to change the file rename
formatting. Then restart the container.

While editing and testing your filebot.sh, keep in mind that FileBot (actually AMC) will not re-process files. Delete
amc-exclude-list.txt in your config directory, then write a file into the input directory to get FileBot to re-process
your files.

After you gain confidence in how the container is running, you may want to change the action from "copy" to "rename".
FileBot will move the files from the input to the output directory, then clean up any "leftover junk" in the input
directory. If you're going to do this, then it's also probably a good idea to store temporary files and incomplete
downloads in a different directory than the input directory, just in case FileBot decides to move them.

By default, FileBot will create files using user ID 0 (typically root) and group ID 0 (typically root). If you wish to
change this, set the `UGID` environment variable to `<user id>:<group id>`. For example, `-e UGID=99:100`.

Updates to filebot.sh
---------------------

Later, when you update the container, it may exit with this message in the log:

> ERROR: The container's filebot.sh is newer than the one in /config.
>  Copying the new script to /config/filebot.sh.new.
>  Compare your filebot.sh and filebot.sh.new, being sure to copy over the VERSION line.
>  Then restart the container.

This happens because some bugfix or something went into `filebot.sh`. Rather than deleting your `filebot.sh` (and losing
any hard work you put into it), the container will write `filebot.sh.new`. It's your job to merge the two files. You can
delete `filebot.sh`.new when you're done. NOTE: You must increase the VERSION even if you make no other changes.  This
will let the container know that you performed the merge. It will then start normally.
