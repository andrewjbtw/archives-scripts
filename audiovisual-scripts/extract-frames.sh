#!/bin/bash

# Generates still images from a video file by extracting frames at a regular interval. Each image is stamped with the time elapsed since the beginning of the file. 
# Also generates a playable video file from the images. Images and video are placed in their own output directory.
#
# Usage: 
#
# This script takes three arguments:
#
# extract-frames.sh path/to/video-file path/to/output/directory interval-between-frames

input_file=$1
output_directory=$2
output_file=$(basename "$input_file-frames.mp4")
interval=$3 # in seconds. A value of '30' means one frame every 30 seconds.
log_file=$output_directory/"$output_file"-log.txt

# Check if input file exists
if [ ! -f "$input_file" ]
then
    printf "The file $input_file could not be found.\n" >&2
    exit
fi

# check if output directory exists
if [ ! -d "$output_directory" ]
then
    printf "Creating output directory.\n" >&2
    mkdir -pv "$output_directory" >&2
fi

# check if output frames file already exists
if [ -f "$output_directory"/"$output_file" ]
then
    printf "Existing frames found for $input_file.\n" >&2
    exit
else
    if [ -f "$log_file" ]
    then
        printf "Previous attempt to create frames failed.\n" >&2
        if ( grep -q "moov atom not found" "$log_file" ) 
        then
            printf "Trying again.\n" >&2
            rm "$log_file"
        else
            printf "See $log_file for details.\n" >&2
            exit
        fi
    fi
fi


# check if file has video streams
printf "$(date -Is) : Checking for video stream\n" >> "$log_file"
if grep -q video <(ffprobe -v error -show_entries stream=codec_type -of default=nw=1 "$input_file" 2> >(tee -a "$log_file" >&2))
then 
    printf "Video stream found in $input_file\n" | tee -a "$log_file" >&2
else 
    printf "No video stream found in $input_file\n" | tee -a "$log_file" >&2
    exit # If there's no video stream, no frames can be extracted.
fi

# Calculate offset for the timestamp of first extracted frame. Since the first frame of a file is often blank, start at half of the selected interval.
# Example: if interval=20 seconds, the first frame will be taken 10 seconds into the file
offset=$(echo "scale=3;($interval / 2)" | bc) # Use decimal places to account for odd-numbered intervals

# Calculate number of frames to extract based on interval and duration.
printf "$(date -Is) : Calculating duration and number of frames to create\n" >> "$log_file"
duration=$(ffprobe -probesize 10000000 -i "$input_file" -v error -show_entries format=duration -of default=nokey=1:noprint_wrappers=1 2> >(tee -a "$log_file" >&2))

# Test if the file has a duration. ffprobe outputs "N/A" if there is no duration. Some still image formats show as videos with no duration.
if [ "$duration" = 'N/A' ]
then
    printf "The file $input_file has no duration. No frames will be generated.\n" | tee -a "$log_file" >&2
    printf "Duration of $input_file = $duration" >> "$log_file" >&2
    exit
fi

# Using the duration, calculate number of frames.
frames=$(echo "scale=0;($duration + $offset)/$interval" | bc) # Needs to be a whole number

# If no images will be created, alert the user and quit.
if [ "$frames" == 0 ]
then
    printf "No images will be created. Your selected interval may be longer than the file.\n" | tee -a "$log_file" >&2
    printf "Selected interval: $interval.\n" | tee -a "$log_file" >&2
    printf "Duration of $input_file: $duration.\n" | tee -a "$log_file" >&2
    exit
fi

# Create output directory.
printf "\nCreating directory for still frames.\n" >&2
mkdir -pv "$output_directory"/frames


# Extract the frames
printf "\n$(date -Is) : Extracting $frames frames for $input_file\n" >> "$log_file"
printf "Extracting frames:\n"

# Calculate font size based on height of video, with a maximum font size of 24
height=$(ffprobe -probesize 10000000 -i "$input_file" -v error -select_streams v:0 -show_entries stream=height -of default=nokey=1:noprint_wrappers=1 | head -n 1) 
font_size=$(($height/20))
if [ $font_size -gt 24 ]
then
    font_size=24
fi

# Extract frames
# Note: exact path to font file will depend on your system configuration.
i=0
while [ $i -lt $frames ]
do
    jump=$(echo "scale=3;x=$i*$interval+$offset;if(x < 1) print 0;x" | bc) # ffmpeg seek requires leading zero for values < 1
    paddedi=$(printf "%04d" $i) # for padding frame filenames
    ffmpeg -loglevel error -probesize 10000000 -ss $jump -i "$input_file" -filter_complex "scale=w='min(960\, iw):h=-2',drawtext=fontfile=/usr/share/fonts/truetype/freefont/FreeSans.ttf: text='%{pts \\: hms \\: $jump} ' : x=w/10: y=h-(h/10): fontsize=$font_size: fontcolor=yellow@0.8: box=1: boxcolor=blue@0.9" -vframes 1 "$output_directory"/frames/frame"$paddedi".jpg 2> >(tee -a "$log_file" >&2)
    printf "Extracting $(($i+1))/$frames\r"
    i=$(($i + 1))
done

# Check if frames were extracted. If there are no frames in the frame directory, output a message and quit.

if [ $(find "$output_directory"/frames/ -empty | wc -l) -ne 0 ]
then
    printf "\nNo frames were created. Cannot create image sequence." | tee -a "$log_file" >&2
    exit
fi

# Workaround for VLC playback. VLC doesn't seem to play the final frame in the image sequence video. 
# Duplicate final frame to add one final frame so that the real final frame appears if played on VLC. There may be a better way to do this.
# Note: ffplay will show all frames, including the fake final frame.
fakefinalframe=$(printf "%04d" $frames)
cp "$output_directory"/frames/frame"$(printf %04d $(($frames-1)))".jpg "$output_directory"/frames/frame"$(printf %04d $frames)".jpg

# Make a video from the image sequence  
printf "\nFinished extracting frames.\nCreating image sequence video:\n"
ffmpeg -loglevel error -stats -f image2 -framerate 2/1 -i "$output_directory"/frames/frame%04d.jpg -pix_fmt yuv420p -an -vf fps=25 "$output_directory"/"$output_file"

# Clean up individual frame jpegs
printf "\nCleaning up frame directory.\n"
rm "$output_directory"/frames/*.jpg
rmdir -v "$output_directory"/frames

printf "Processing is complete. The new files are located at $output_directory\n" >&2

if ( grep -q "moov atom not found" "$log_file" )
then
    echo "Video may not be complete: moov atom not found." >&2
    echo "Will try again next time." >&2
else
    rm "$log_file"
fi
