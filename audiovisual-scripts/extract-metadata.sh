#!/bin/bash

# Extracts metadata from a video file using mediainfo and ffprobe. Produces three reports for each file:
#
#   1. mediainfo XML file
#   2. ffprobe JSON file
#   3. ffprobe default stderr output -- this is useful for identifying broken or incomplete files
#
#   Incomplete file example: error message: "moov atom not found" 
#   This could mean the input file is broken or that it is still in the process of being copied from another location
#
# File are placed in a directory named after the input file. 

# Usage: 
#
# This script takes two arguments:
#
# extract-metadata.sh path/to/file path/to/output/directory 

input_file=$1
output_directory=$2

# Check if input file exists
if [ ! -f "$input_file" ]
then
    echo "The file $input_file could not be found." >&2
    exit
fi

# Create output directory if one doesn't exist yet
if [ ! -d "$output_directory" ]
then
    printf "\nCreating output directory.\n" >&2
    mkdir -pv "$output_directory"
fi

# check if output ffprobe file already exists -- this is used to test file completeness
if [ -f "$output_directory"/"$(basename "$input_file")".txt ]
    then
 # check if previous metadata attempt failed because file copying was in process, i.e. the "moov atom not found" error
        if ( ! grep -q "moov atom not found" "$output_directory"/"$(basename "$input_file")".txt )
            then
               echo "Metadata for $input_file has already been extracted." >&2
               exit
           else
               echo "Previous attempt to extract metadata failed. Trying again ..." >&2
        fi
    else
        echo "Extracting metadata for $input_file ..." >&2
fi

echo "Testing with ffprobe ..."
ffprobe "$input_file" 2>&1 | tee "$output_directory"/"$(basename "$input_file")".txt 

echo "Creating ffprobe json file ..."
ffprobe "$input_file" -show_format -show_streams -show_data -print_format json | tee "$output_directory"/"$(basename "$input_file")".json

echo "Running mediainfo ..."
mediainfo "$input_file" | tee "$output_directory"/"$(basename "$input_file")"-mediainfo.txt

printf "Processing is complete. The new files are located at $output_directory\n" >&2
