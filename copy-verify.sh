#!/bin/bash

# TODO: list dependencies and document Mac OSX vs Linux differences

source_full_path=$1
target_full_path=$2

# TODO: output messages to stderr

# script currently takes exactly two arguments: full path to source; full path to target

if [ "$#" -ne 2 ] ; then
   echo "This script requires two arguments."
   exit 0
fi

if [ ! -d "$source_full_path" ]
then
    echo "The directory \"$source_full_path\" could not be found."
    exit
fi

if [ -d "$target_full_path" ]
then
    echo "Found existing directory at \"$target_full_path\". The target path must be a new directory."
    exit
fi

source=$(basename "$source_full_path")
source_parent=$(dirname "$source_full_path")

# create target directory
mkdir -pv "$target_full_path/data"

# generate payload checksum manifest that conforms to the BagIt structure
# change into parent directory of source in order to list relative pathnames in manifest
# prepend "data" to manifest filepath to match path in target folder
cd "$source_parent"
find "$source" -type f -exec md5sum {} \; | sed 's/./&data\//34' | tee "$target_full_path/manifest-md5.txt" 

# generate file count and total size for payload
count=$(find "$source" -type f | wc -l)
size=$(find "$source" -type f -exec stat -c "%s" {} \; | awk '{n += $1} ; END{printf "%.0f", n}')

# TODO: add rsync log file to target directory
rsync -rvh --times --itemize-changes --progress "$source" "$target_full_path"/data/

# create bag-info.txt file
echo "Bag-Software-Agent: copy-verify.sh script 
Bagging-Date: $(date -I)
Payload-Oxum: $size.$count" > "$target_full_path/bag-info.txt"

# create bagit.txt file
echo "BagIt-Version: 0.97
Tag-File-Character-Encoding: UTF-8" > "$target_full_path/bagit.txt"

# change into target directory to create tag manifest using relative paths within bag
cd "$target_full_path"
md5sum "bagit.txt" "bag-info.txt" "manifest-md5.txt" > tagmanifest-md5.txt

# validate bag
# TODO: log result to file
bagit.py --validate "$PWD"
