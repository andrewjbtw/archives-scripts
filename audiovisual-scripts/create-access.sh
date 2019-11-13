#!/bin/bash

# Creates a visually high-quality MP4 access copy of a video. 
# Audio is converted to aac using ffmpeg's defaults for MP4. 
# Audio quality may be worth revisiting.

filepath="$1"
output_dir="$2"
video_quality="$3"

num_channels=$(ffprobe -v error -select_streams a -show_entries stream=index -of default=noprint_wrappers=1 "$filepath" | wc -l)
filename="$(basename "$filepath")"

# TODO: validate input

mkdir -pv "$output_dir" >&2

# Set video quality
# Defaults to lower resolution
if [ "$video_quality" = "hq" ]
then
    ffmpeg_video_options=("-crf" "18")
else
    ffmpeg_video_options=("-vf" "scale='min(960,iw)':-2") # reduce image dimensions
fi

if [ "$num_channels" -eq 0 ] 2>/dev/null
    then
        echo "FFprobe could not find audio streams for $filepath"
        < /dev/null ffmpeg -n -i "$filepath" -map 0:v? -pix_fmt yuv420p -c:v libx264 "${ffmpeg_video_options[@]}" "$output_dir/$filename.mp4"
    exit
fi

if [ $num_channels -eq 1 ] 
    then
        echo "$filepath already only has one audio stream."
        < /dev/null ffmpeg -n -i "$filepath" -map 0:v? -map 0:a -pix_fmt yuv420p -c:v libx264 "${ffmpeg_video_options[@]}" -threads 2 "$output_dir/$filename.mp4"
    else 
        # If there's multiple audio streams, remix down to one. This is compatible with more players.
        < /dev/null ffmpeg -n -i "$filepath" -map 0:v? -pix_fmt yuv420p -c:v libx264 "${ffmpeg_video_options[@]}" -filter_complex "[0:a]amix=inputs=$num_channels[aout]" -map "[aout]" -ac 2 -threads 2 "$output_dir/$filename.mp4"
fi
