#!/bin/bash

# script to download files hosted via Stanford's "purl" permanent URL scheme
# note: the actual files have a base URL of stacks.stanford.edu

purl=$1
resource_type=$2

if [ -z "$purl" ]
then
	echo "no purl, no download"
	exit
fi

if [ ! -z "$resource_type" ]
then
	resource_type="[@type='$resource_type']"
#	echo "$resource_type"
fi

druid=$(basename "$purl")
if [ "$druid" == "$purl" ]
then
#	echo "maybe you forgot the url?"
	purl="https://purl.stanford.edu/$druid"
fi

stacks_base="https://stacks.stanford.edu/file/$druid"


mkdir -v "$druid" || exit # don't download if folder already exists

# download purl xml to get filenames for download
purl_xml=$(curl -gs "${purl}.xml")
contentMetadata=$(echo "$purl_xml" | xmlstarlet sel -t -m "/publicObject/contentMetadata" -c . )

filenames=$(echo "$purl_xml" |
	xmlstarlet sel -t -m "/publicObject/contentMetadata/resource${resource_type}/file/@id" -v "." -n)

echo "$filenames" |	

	while read filename
	do
		wget -P "$druid" "$stacks_base/$filename"
	done
