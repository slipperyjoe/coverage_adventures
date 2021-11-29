#!/bin/sh

# -----------------------------------------------------------------------------
# DESCRIPTION:  
#    Script to extract URLS from an html document
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
# EXAMPLE:
#     ./extract_urls.sh level_1/*
# -----------------------------------------------------------------------------
# NOTES:
# -----------------------------------------------------------------------------

usage () {
    cat <<- EOF

    Script to extract URLS from set of html documents
    
    Usage:
          $0  [OPTION]... [FILE]
    
    Options:
          -h    Print this message
    
    
    Examples:
        ./extract_urls.sh data/level_2/*

    Exit status:
         No exit status

EOF
}

while getopts h opt
do
    case $opt in
        h|\?)		usage ; exit 1;;
		esac
done

# check that argument is provided
shift $((OPTIND -1))
[ "$1" = "" ] && echo "No input file provided" && usage && exit 1


echo "$*" |
tr ' ' '\n' |
grep -Ev "\.(urls|coverage)$" |

while read -r i
    do

        echo "$i"

        # put every tag on its own line for easier parsing
        sed -r 's/>/>\n/g' "$i" | 

        # keep only the urls
        grep -E 'href' | sed -r "s/.*href=[\"']([^ ]*)[\"'].*/\1/" |
        # remove duplicate urls
        #sort | uniq | 
        sort -u |

        # exclude links to files, anchors
        grep -vE 'css$|js$|ico$|png$|jpg$|json$|xml$|#' | 

        # replace ::: with /
        # transform https://lemonde.fr url in relative ones

        sed -r 's/https:\/\/(www\.)?lemonde\.fr//' | 

        # keep only local relative urls (exlude other subdomains)
        grep -Ev 'https?|^\/$' > "$i.urls"

    done
