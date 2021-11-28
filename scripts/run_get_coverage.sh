#!/bin/sh

# -----------------------------------------------------------------------------
# DESCRIPTION:  
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
#        segment the steps in different options for easier reruns ?
#        The logs are stored as log_level_1_2 for download of level 1 urls
#     
#       ADD A BUNCH OF CONDITIONS FOR LEVEL_0 ?
# -----------------------------------------------------------------------------

# Project-specific hard coded variables

# cookie button selector
BUTTON="button.gdpr-lmd-button.gdpr-lmd-button--main"
# base url
PREFIX="https://lemonde.fr"
# directory where pages are downloaded / urls files stored
DATA_DIR="/home/chieftain/Documents/git_repos/sisyphos_repos/automate_browser/data"
SCRIPTS_DIR="/home/chieftain/Documents/git_repos/sisyphos_repos/automate_browser/scripts"

# file that contains invalid urls (ex: mailto:...)
NON_URLS="$DATA_DIR/non_urls"
# file that contains repetitive / irrelevant urls (ex: /blog/)
REJECT_URLS="$DATA_DIR/reject_urls"


usage () {
		cat <<- EOF

    Description:
        Task runner script for the crawling project

    Usage:
        $0  [OPTION]... [LEVEL_MIN

    Options:
        -d        download & coverage
        -e        extract urls
        -k        try to create directory
        -c        cleanup: all the grep -v (reject urls, non urls and prevous
                  urls)
        -h        print this message

    Example:
        # will read level_0_urls and download in level_1/
        ./$0  -deck 1 

    Exit status:
        0 if OK
        1 if problems
EOF
}

MKDIR="NO"
DOWNLOAD="NO"
EXTRACT="NO"
CLEANUP="NO"
#FINISH="NO"

while getopts kdech opt
do
    case $opt in
        k)      MKDIR="YES";;
        d)      DOWNLOAD="YES";;
        e)      EXTRACT="YES";;
        c)      CLEANUP="YES";;
#        f)      FINISH="YES";;
        h|\?)		usage ; exit 0;;
		esac
done

# check that argument is provided
shift $((OPTIND -1))
[ "$1" = "" ] && { echo "No input provided"; usage; exit 1; }
LEVEL="$1"

#LEVEL_PLUS=$(echo "$LEVEL + 1 " | bc)
# TODO: use (()) eval for this
LEVEL_MIN=$(echo "$LEVEL - 1" | bc)



# fail if directory already exists, might contain files
if [ "$MKDIR" = "YES" ]; then
    mkdir "$DATA_DIR/level_$LEVEL" || exit 1
    ##[ -d "$DATA_DIR/level_$LEVEL" ] ||  mkdir "$DATA_DIR/level_$LEVEL" 
fi

#echo  "$DATA_DIR/level_$LEVEL" 
#echo  "$DATA_DIR/log/log_level_$LEVEL_MIN"_"$LEVEL" 
#echo  "$DATA_DIR/level_$LEVEL_MIN""_urls" 

if [ "$DOWNLOAD" = "YES" ]; then
    # download pages & get coverage
    "$SCRIPTS_DIR"/get_coverage.js -wsc  \
        -e "$BUTTON" \
        -p "$PREFIX" \
        -o "$DATA_DIR/level_$LEVEL" \
        -l "$DATA_DIR/log/log_level_$LEVEL_MIN"_"$LEVEL" \
        -f "$DATA_DIR/level_$LEVEL_MIN""_urls" || \

        { echo " ==> get_coverage.js failed with code $?"; exit 1;}

fi

# check log and print message / exit 1 ?

## run extract_urls on directory
## creates .urls files in directory
if [ "$EXTRACT" = "YES" ]; then
    "$SCRIPTS_DIR/extract_urls.sh" "$DATA_DIR/level_$LEVEL/"*
fi


# sort, extract urls and make temporary file for manual validation
if [ "$CLEANUP" = "YES" ]; then
    cat "$DATA_DIR/level_$LEVEL/"*.urls |
        sort -u |

        # remove non urls and reject_urls
        grep -Evf "$NON_URLS" -f "$REJECT_URLS" |
        #grep -Evf "$NON_URLS" -f "$REJECT_URLS" > "$DATA_DIR/temp_level_$LEVEL""_urls" 

        # remove all previous urls from level_{0..3}_urls
        grep -v "$( eval cat level_{0..$LEVEL_MIN}_urls)" > "level_$LEVEL""_urls"

fi

