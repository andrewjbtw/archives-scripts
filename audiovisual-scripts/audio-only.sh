#!/bin/bash

filepath=$1
output_directory=$2
basefilename=$(basename "$filepath")
log_file="$output_directory/audio.log"

# check if output directory already exists
if [ -d "$output_directory" ]
then
    # check if output mp3 already exists
    if [ -f "$output_directory/$basefilename".mp3 ]
    then
        echo "Audio already extracted from $filepath"
        exit
    else
        if [ -f "$log_file" ]
        then
            printf "Previous attempt to extract audio from $basefilename failed.\n" >&2
            # check if previous attempt failed because MOV file was incomplete
            # try again in case file is now complete (i.e. finished copying)
            if ( grep -q "moov atom not found" "$log_file" )
            then
                printf "Trying again.\n" >&2
            else
                printf "See $log_file for details.\n" >&2
                exit
            fi
        fi
    fi
else
    echo -e "$(date '+%d/%b/%Y:%H:%M:%S %z')\tCreating output directory $output_directory"
    mkdir -p "$output_directory"
fi

# Calculate number of audio streams
num_streams=$(ffprobe -v error -select_streams a -show_entries stream=index -of default=noprint_wrappers=1 "$filepath" | wc -l)

if [ $num_streams -eq 0 ] 
then
    echo -e "$(date '+%d/%b/%Y:%H:%M:%S %z')\tNo audio streams found for $filepath" | tee -a "$log_file" >&2
    echo -e "$(date '+%d/%b/%Y:%H:%M:%S %z')\tOutputting ffprobe error to log" | tee -a "$log_file" >&2
    ffprobe -v error -select_streams a -show_entries stream=index -of default=noprint_wrappers=1 "$filepath" 2>>"$log_file"
    exit
fi

echo -e "$(date '+%d/%b/%Y:%H:%M:%S %z')\tProcessing $filepath"

# Generate wav file. If there are multiple streams, mix them down to one.
if [ $num_streams -eq 1 ] ; then
    ffmpeg -loglevel error -n -i "$filepath" -vn "$output_directory/$basefilename".wav 2> >(tee -a "$log_file" >&2)
else 
    ffmpeg -loglevel error -n -i "$filepath" -vn -filter_complex "[0:a]amix=inputs=$num_streams[aout]" -map "[aout]" -ac 2 -threads 2 "$output_directory/$basefilename".wav 2> >(tee -a "$log_file" >&2)
fi

# Create mp3 file using dyanmic audio normalization to raise the sound levels.
echo -e "$(date '+%d/%b/%Y:%H:%M:%S %z')\tCreating derivative mp3"
ffmpeg -loglevel error -n -i "$output_directory/$basefilename".wav -write_xing 0 -af dynaudnorm=b=true "$output_directory/$basefilename".mp3 2> >(tee -a "$log_file" >&2)

# Remove intermediate wav file
echo -e "$(date '+%d/%b/%Y:%H:%M:%S %z')\tRemoving intermediate wav file."
rm -v "$output_directory/$basefilename".wav

# Remove log file if empty
if [ ! -s "$log_file" ]
then
    rm "$log_file"
fi

echo -e "$(date '+%d/%b/%Y:%H:%M:%S %z')\tProcessing complete."
