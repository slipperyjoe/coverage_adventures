#!/bin/sh

# -----------------------------------------------------------------------------
# DESCRIPTION:  
#    Downloads a list of pages using puppeteer or wget and saves them to a
#    specified directory
#    
# AUTHOR:
#			slipperyjoe <contact@slipperyjoe.xyz>
#
# COPYRIGHT:      
#      Copyright © 2021 slipperyjoe. License GPLv3+: GNU GPL version 3
#      or later <https://gnu.org/licenses/gpl.html>.
#      This is free software: you are free to change and redistribute it. There
#      is NO WARRANTY, to the extent permitted by law.
#
# -----------------------------------------------------------------------------
# NOTES:
#     log in the proper directory with the _request file for the corresponding
#     level
# -----------------------------------------------------------------------------

usage () {
		cat <<- EOF

   Usage: $0  [OPTION]... [FILE]
   Download all files from url file
   
   -p      url prefix
   -d      output directory
   -l      log file
   
   Exit status:
       0 if OK
       1 if problems 

EOF
}

while getopts p:d:l:h opt
do
    case $opt in
        p)		PREFIX="$OPTARG" ;;
        d)		OUT_DIR="$OPTARG" ;;
        l)		LOG_FILE="$OPTARG" ;;
        h|\?)		usage ; exit 0;;
		esac
done

# check that argument is provided
shift $((OPTIND -1))
[ "$1" = "" ] && echo "No input directory provided" && usage && exit 1
INPUT_FILE="$1"

# remove trailing / if there is one for robustness
OUT_DIR=$(echo $OUT_DIR | sed -r 's/\/$//g')

>"$LOG_FILE"

# takes file with urls and downloads each of them to appropriate dir with filenames corresponding to urls
for i in $( cat "$INPUT_FILE" )
		do 
				wget "$PREFIX""$i" -O "$OUT_DIR/$(echo "$i" | sed -r 's/\//:::/g')"
				# log success/failure to file
				echo "$?			$i" >> "$LOG_FILE"
				sleep 3
		done

# rewrite it with a "while read"?
