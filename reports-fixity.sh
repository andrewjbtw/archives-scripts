#!/bin/bash

# The purpose of this script is to provide a quick way to walk though a report 
# produced by the AV Preserve Fixity tool: https://github.com/avpreserve/fixity/
#
# It is literally a concatenation of individual commands I found myself entering
# every time I went though a Fixity report. Now that it's a script, it could
# be made more efficient by reading the report only once instead of opening it
# repeatedly, but I haven't had time to fix it up.
#
# This script relies on relative paths and should be run from within the 
# fixity/reports/ directory in your Fixity installation.

echo "Enter report filename:"
read reportname
echo ""

# Read the first 10 lines of the Fixity report, which contain summary info.
head "$reportname"
echo ""

# The remaining steps simply output parts of the report to the screen. If you
# have long lists of files to go through, you might want to modify the script
# to use a paging program like less. For example:
# grep -i "moved or renamed f" "$reportname" | less


# List moved or renamed files.
echo "Press enter to see list of moved or renamed files"
read placeholder # This input is discarded.
grep -i "moved or renamed file" "$reportname"
echo ""

# List new files
echo "Press enter to see list of new files"
read placeholder
grep -i "new file" "$reportname"
echo ""

# List removed files
echo "Press enter to see list of removed files"
read placeholder
grep -i "removed file" "$reportname"
echo ""

# List changed files
echo "Press enter to see list of changed files"
read placeholder
grep -i "changed file" "$reportname"
echo ""

# This last command is designed to look for false positives - that is, files
# listed as changed that have in fact not changed. I've found these happen
# from time to time when a file isn't scanned during one report and then is
# listed as changed in the next one.
#
# This command parses the list of changed files, calculates their checksums,
# and then searches the Fixity history files for previous occurrences of 
# those checksums.
#
# Currently, this only works with MD5 checksums and relies on the md5deep 
# utility. You will need to modify it to work with your local environment 
# or with other checksum algorithms.

echo "Press enter to check the changed file list for false positives"
read placeholder

grep -i "changed file:" "$reportname" | awk 'BEGIN { FS = ":\t" } ; { print $2 }' | while read file ; do echo "Checking on file: $file " ; md5deep -e "$file" | grep $(awk '{print $1}') ../history/* | grep "$file" ; done
