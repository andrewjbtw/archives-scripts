#!/bin/bash

# script to download files hosted via Stanford's "purl" permanent URL scheme
# note: the actual files have a base URL of stacks.stanford.edu

purl=$1
druid=$(basename "$purl")
stacks_base="https://stacks.stanford.edu/file/$druid"

# download purl xml to get filenames for download
purl_xml=$(curl -gs "${purl}.xml")

echo "$purl_xml" | xmlstarlet sel -t -m '/publicObject/contentMetadata/resource/file/@id' -v "." -n | 
	while read filename
	do
		wget "$stacks_base/$filename"
	done
