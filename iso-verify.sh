#!/bin/bash

# creates an image of a DVD using dvdisaster and checks the integrity
# of the image against the original disk

iso=$1
device=${2:-"/dev/sr0"} # optical device name may differ on your system 

echo "Reading optical disk into file: $iso ..."

dvdisaster -d "$device" -i "$iso" -r

# brief wait before spinning back up to verify (many not be necessary) 
sleep 10

echo "Creating and verifying checksum ..."

# create md5sum-formattted checksum file from original media
#
# reads only the number of bytes that were written to the iso
# in some circumstances a whole disk checksum will not match the iso checksum
# because a it will include all bytes on disk, not just bytes with data 
md5hash=$(head -c $(stat -c %s "$iso") "$device" | md5sum | cut -c -32)
echo "$md5hash  $iso" | tee "$iso".md5

# verify iso checksum
md5sum -c "$iso".md5