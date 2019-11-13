#!/bin/bash

# Checks whether a video is already encoded in h264 and is smaller than 10 GB
# There is little to gain from trying to further compress this kind of video
# when creating small review copies that can be watched at Shustek.
#
# This is best used to run checks before transcoding.

video=$1

vcodec=$(ffprobe -loglevel error "$video" -show_streams -print_format json | jq -r '.streams[] | select(.codec_type == "video") | .codec_name') 
vsize=$(stat -c "%s" "$video")
#echo "$video,$vcodec,$vsize" 
if [ "$vcodec" == "h264" ] && [ "$vsize" -lt 10000000000 ] 
    then 
        echo "true" 
    else 
        echo "false" 
fi
