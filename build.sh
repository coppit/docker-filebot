#!/usr/bin/env bash

docker build --rm=true -t coppit/filebot . 

# Final test before pushing:
#docker build --no-cache=true -t coppit/filebot:dev .

