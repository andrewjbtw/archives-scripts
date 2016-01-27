#!/bin/bash

# Generates thumbnails from a video file by extracting still frames at a regular interval. Each thumbnail is stamped with the time elapsed since the beginning of the file. Also generates a playable video file from the thumbnails. Thumbnails and video are placed in their own output directory.
#
# Usage: 
#
# This script takes three arguments:
#
# timestamp-thumbs.sh path/to/file path/to/output/directory interval

input_file=$1
output_directory=$2
interval=$3 # in seconds. A value of '30' means one frame every 30 seconds.

# Calculate offset for timestamp of first extracted frame. ffmpeg takes the first frame at half of the interval you set.
# Example: if interval=20 seconds, the first frame will be from 10 seconds into the file
offset=$(echo "scale=3;($interval / 2)" | bc) # Use decimal places to account for odd-numbered intervals

# Calculate number of frames to extract. If the number of frames is not set, ffmpeg will extract the final frame of the video even if it does not match the interval you've set.
#TODO: check math
duration=$(ffprobe -i "$input_file" -v error -show_entries format=duration -of default=nokey=1:noprint_wrappers=1)
frames=$(echo "scale=0;($duration + $offset)/$interval" | bc) # Needs to be a whole number

# If no thumbnails will be created, alert the user and quit.
if [ "$frames" == 0 ]
then
    echo "No thumbnails will be created. Please check if your interval is too long for this file."
    exit
fi

# Create output directory
if [ -d "$output_directory" ]
then
    echo "A folder with the name $output_directory already exists. Please choose a new location."
    exit
else
    mkdir -pv "$output_directory"/thumbnails
fi

# Create the thumbnails
# Exact path to font file will depend on your system configuration.
# To consider: make the thumbnail file format and size configurable from the command line
ffmpeg -i "$input_file" -filter_complex "fps=1/$interval,scale=960:-1,drawtext=fontfile=/usr/share/fonts/truetype/freefont/FreeSans.ttf: text='%{pts \\: hms \\: $offset}': x=100: y=h-100: fontsize=24: fontcolor=yellow@0.8: box=1: boxcolor=blue@0.9" -vframes $frames "$output_directory"/thumbnails/thumb%04dtimestamped.jpg

# Make a video from the image sequence  
ffmpeg -framerate 3/1 -f image2 -i "$output_directory"/thumbnails/thumb%04dtimestamped.jpg -an "$output_directory"/"$(basename "${input_file%.*}")-thumbs.mkv"

echo "Processing is complete. The new files are located at $output_directory"
