#!/bin/bash

# script to download files hosted via Stanford's "purl" permanent URL scheme
# note: the actual files have a base URL of stacks.stanford.edu

purl_base="https://purl.stanford.edu"
stacks_base="https://stacks.stanford.edu/file"

usage ()
{
    echo 'Usage : purlget.sh -p <purl> [-r <resource_type>] [--xml-only]'
    exit
}

if [ "$#" -eq 0 ]
then
    usage
    exit
fi

while [ "$1" != "" ]
do
    case "$1" in
        -p )    shift
                purl=$1
                ;;
        -r )    shift
                resource_type=$1
                ;;
        --xml-only )
                xml_only=true
                ;;
    esac
    shift
done

if [ -z "$purl" ]
then
    echo "Please enter a druid or a purl"
    usage
    exit
fi

# handle druids or full URLs
druid=$(basename "$purl")
if [ "$druid" == "$purl" ]
then
	purl="$purl_base/$druid"
fi

# skip downloading files if give the xml-only option
# this option overrides all other options
if [ "$xml_only" == "true" ]
then
	curl -gs "${purl}.xml"
else
	# select only files from the given resource type
	if [ -n "$resource_type" ]
	then
		resource_type="[@type='$resource_type']"
	#	echo "$resource_type"
	fi

	mkdir -v "$druid" || exit # don't download if folder already exists

	# download purl xml to get filenames for download
	purl_xml=$(curl -gs "${purl}.xml")
	contentMetadata=$(echo "$purl_xml" | xmlstarlet sel -t -m "/publicObject/contentMetadata" -c . )

	filenames=$(echo "$purl_xml" |
		xmlstarlet sel -t -m "/publicObject/contentMetadata/resource${resource_type}/file/@id" -v "." -n)

	echo "$filenames" |
		while read filename
		do
			wget -P "$druid" "$stacks_base/$druid/$filename"
		done
fi
