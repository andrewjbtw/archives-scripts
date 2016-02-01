#!/bin/bash

# Generates still images from a video file by extracting frames at a regular interval. Each image is stamped with the time elapsed since the beginning of the file. Also generates a playable video file from the images. Images and video are placed in their own output directory.
#
# Usage: 
#
# This script takes three arguments:
#
# extract-frames.sh path/to/file path/to/output/directory interval

input_file=$1
output_directory=$2
interval=$3 # in seconds. A value of '30' means one frame every 30 seconds.

# Check if input file exists
if [ ! -f "$input_file" ]
then
    echo "The file $input_file could not be found."
    exit
fi

# Calculate offset for the timestamp of first extracted frame. Instead of starting with the first frame, start at half of the selected interval.
# Example: if interval=20 seconds, the first frame will be from 10 seconds into the file
offset=$(echo "scale=3;($interval / 2)" | bc) # Use decimal places to account for odd-numbered intervals

# Calculate number of frames to extract based on interval and duration.
duration=$(ffprobe -i "$input_file" -v error -show_entries format=duration -of default=nokey=1:noprint_wrappers=1)
frames=$(echo "scale=0;($duration + $offset)/$interval" | bc) # Needs to be a whole number

# If no images will be created, alert the user and quit.
if [ "$frames" == 0 ]
then
    echo "No images will be created. Please check if your interval is longer than the file."
    echo "Selected interval: $interval."
    echo "Duration of $input_file: $duration."
    exit
fi

# Create output directory. To be safe, make sure this is a new directory.
if [ -d "$output_directory" ]
then
    echo "A folder with the name $output_directory already exists. Please choose a new location."
    exit
else
    printf "\nCreating output directory.\n"
    mkdir -pv "$output_directory"/frames
fi

printf "\nProcessing $input_file:\n"

# Extract the frames
# Exact path to font file will depend on your system configuration.
# This uses a loop to extract to extract frames at specific points in the video via seeking to exact times. This is much faster than the original method used in this script, which relied on ffmpeg to process the entire file.
printf "Extracting frames:\n"

# Calculate font size based on height of video, with a maximum of 24
height=$(ffprobe -i "$input_file" -v error -select_streams v:0 -show_entries stream=height -of default=nokey=1:noprint_wrappers=1) 
font_size=$(($height/20))
if [ $font_size -gt 24 ]
then
    font_size=24
fi

# Extract frames
i=0
while [ $i -lt $(($frames)) ]
do
    jump=$(echo "scale=3;x=$i*$interval+$offset;if(x < 1) print 0;x" | bc) # ffmpeg seek requires leading zero for values < 1
    paddedi=$(printf "%04d" $i) # for padding frame filenames
    ffmpeg -loglevel error -ss $jump -i "$input_file" -filter_complex "scale=w='min(960\, iw):h=-2',drawtext=fontfile=/usr/share/fonts/truetype/freefont/FreeSans.ttf: text='%{pts \\: hms \\: $jump} ' : x=w/10: y=h-(h/10): fontsize=$font_size: fontcolor=yellow@0.8: box=1: boxcolor=blue@0.9" -vframes 1 "$output_directory"/frames/frame"$paddedi".jpg
    printf "Extracting $(($i+1))/$frames\r"
    i=$(($i + 1))
done

# Workaround for VLC playback. VLC doesn't seem to play the final frame in the image sequence video. Duplicate first frame to add one final frame so that the real final frame appears if played on VLC. There may be a better way to do this.
# Note: ffplay will show all frames, including the fake final frame.
fakefinalframe=$(printf "%04d" $frames)
cp "$output_directory"/frames/frame0000.jpg "$output_directory"/frames/frame"$fakefinalframe".jpg

# Make a video from the image sequence  
printf "\nFinished extracting frames.\nCreating image sequence video:\n"
ffmpeg -loglevel error -stats -f image2 -framerate 3/1 -i "$output_directory"/frames/frame%04d.jpg -an -vf fps=25 "$output_directory"/"$(basename "${input_file%.*}")-frames.mkv"

printf "Processing is complete. The new files are located at $output_directory\n"
