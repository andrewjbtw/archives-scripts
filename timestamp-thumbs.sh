#!/bin/bash

input_file=$1
output_directory=$2
interval=$3
frames=$(echo "$(ffprobe -i "$input_file" -v error -show_entries format=duration -of default=nokey=1:noprint_wrappers=1)/$interval" | bc)
offset=$(echo "scale=1;($interval / 2)" | bc)

mkdir -pv "$output_directory"/thumbnails

#make the thumbnails
#ffmpeg -i "$input_file" -filter_complex "fps=1/$interval,scale=960:-1" -vframes $frames "$output_directory"/thumbnails/thumb%04d.jpg

#ffmpeg -i "$input_file" -filter_complex "fps=1/5,scale=960:-1,drawtext=fontfile=/usr/share/fonts/truetype/freefont/FreeSerif.ttf: text='frame %{n}\\: %{pict_type}\\: pts=%{pts \\: hms \\: $offset}': x=100: y=50: fontsize=24: fontcolor=yellow@0.8: box=1: boxcolor=blue@0.9" "$output_directory"/thumbnails/thumb%04d.jpg

ffmpeg -i "$input_file" -filter_complex "fps=1/$interval,scale=960:-1,drawtext=fontfile=/usr/share/fonts/truetype/freefont/FreeSerif.ttf: text='%{pts \\: hms \\: $offset}': x=100: y=h-100: fontsize=24: fontcolor=yellow@0.8: box=1: boxcolor=blue@0.9" -vframes $frames "$output_directory"/thumbnails/thumb%04dtimecoded.jpg

#once you have images
#for i in "$output_directory"/thumbnails/thumb[0-9][0-9][0-9][0-9].jpg; do
#    multiplier=$(echo $i | grep -oE [[:digit:]]{4}) 
#    timecode=$(date -d@$(echo "scale=1;($multiplier - 1) * $interval + $offset" | bc) -u +%H:%M:%S) 
#    convert $i -fill yellow -gravity South -pointsize 40 -annotate +0+5 "$timecode" "${i/.jpg/timecoded}.jpg"
#done

#make the image sequence video  
ffmpeg -framerate 3/1 -f image2 -i "$output_directory"/thumbnails/thumb%04dtimecoded.jpg -an "$output_directory"/"$(basename "$input_file")-timecodedindex.mkv"

#clean up thumbnails
#rm -rf "$output_directory"/thumbnails/*
#rmdir -v "$output_directory"/thumbnails
