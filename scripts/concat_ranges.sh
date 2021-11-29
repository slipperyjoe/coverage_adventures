#!/bin/sh

# -----------------------------------------------------------------------------
# DESCRIPTION:  
#     Script that takes a set of coverage files and concatenates the ranges for
#     a url or a set of urls
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
#       warning: urls should all be absolute
#       not ideal at the moment because we iterate on the urls, hence we read
#       the coverage files more than once.

#       TODO: add a distinct final coverage file per url/resource in batch mode
#       TODO: add examples
# -----------------------------------------------------------------------------


usage () {
		cat <<- EOF

    Usage: $0  [OPTION]... [FILES]
    Warning: all urls should be absolute (i.e. https://... )
    
        -f		final coverage file
        -u		url
        -b		batch url file
        -p    url prefix for relative urls

    Example:
        $0 -b url_batch -f final_coverage ./*.coverage

    Exit status:
        0 if OK
        1 if problems

EOF
}

# need to define to avoid ambiguous check later (variable not defined vs variable empty)
URL=""
URL_BATCH=""

while getopts f:u:b:p:h opt
do
    case $opt in
        f)		FINAL_COVERAGE="$OPTARG" ;;
        u)		URL="$OPTARG" ;;
        b)		URL_BATCH="$OPTARG" ;;
        p)		PREFIX="$OPTARG" ;;
        h|\?)		usage ; exit 0;;
		esac
done

# check that argument is provided
shift $((OPTIND -1))
[ "$1" = "" ] && { echo "No input provided" ; usage ; exit 1; }
#INPUT_FILE="$1"

# escape special characters in prefix
# used in a regex down the line
PREFIX=$( echo "$PREFIX" | sed -r 's/\//\\\//g; s/\./\\\./g; s/\?/\\\?/g')

# check if urls are provided (single or batch file)
if [ "$URL" = "" ] && [ "$URL_BATCH" = "" ]; then
		echo "No url provided"
		usage
		exit 1
fi

# -b -u are mutually exclusive options
if [ "$URL" != "" ] && [ "$URL_BATCH" != "" ]; then
		echo "Choose either batch mode or single url mode"
		usage
		exit 1
fi

# 
if [ "$URL" != "" ]; then
		echo "$URL"
elif	[ "$URL_BATCH" != "" ]; then
		cat "$URL_BATCH"
fi |

# MAIN LOOP: 
# -----------------
#		curl each url to temp file && count number of bytes in file
#		search for url in all coverage files
#		aggregate all ranges (bytes of used code)
#		print formatted result to stdin
#		remove temp file

# NOTE: we are CURLing a RESOURCE here (ex: main.css, lib.js, ...) so we don't
# aleready have is saved up somewhere


while read -r LOCAL_URL
do

#    echo $LOCAL_URL
        
    QUERY_URL=$(echo "$LOCAL_URL" | sed -r 's/^\//'"$PREFIX"'\//')

		temp_file=$(mktemp)

		# get resource directly and fail if unavailable
		#curl -f "$LOCAL_URL" 2>/dev/null 1>"$temp_file" || { echo "Curl failed with return code $?"; exit 1; }
#		curl -f "$QUERY_URL" 2>/dev/null 1>"$temp_file" || { echo "Curl failed with return code $?"; exit 1; }
		curl --fail "$QUERY_URL" 2>/dev/null 1>"$temp_file" || { 
        echo "Curl failed to get url $QUERY_URL with return code $?";
        continue
    }

		# get total byte count of the resource if curl doesn't fail
		TOTAL_BYTES=$(wc -c "$temp_file" | cut -d" " -f 1)

		# read files given in as arguments
		cat "$@" |

		# select only ranges that correspond to the url
		jq -r '.[] | 
				select(.url=="'"$LOCAL_URL"'") | 
				.ranges | 
				.[] | 
				"\(.start)-\(.end)"' |
		sort -t"-" -nu |

    # OUTPUT:
    # 0-279
    # 302-478
    # 564-584
    # 609-639
    # 774-963
    # ...

		# "concatenate" ranges 
		awk -F'-' -v left=0 -v right=0 '

				NR==1{left=$1;right=$2} 
				NR>=2{ 
						if($1 < right) 
								right=$2
						else
								print left" "right
								left=$1
								right=$2

		}' |
    # OUTPUT:
    # 0 279
    # 302 478
    # 564 584
    # 609 639
    # 774 963
    # ... 

		# save global coverage for that url
		tee "$FINAL_COVERAGE"  |

		# prints the final BYTE count for ranges of USED code
		awk '{ s+=($2 - $1)} END{print s}'| 

		# calculate percentage with bc
		xargs -I{} echo "scale=4; {}/$TOTAL_BYTES" | bc |

		# format it nicely 
		xargs -I{} echo "{}    $LOCAL_URL"  

		 # cleanup
		rm -f "$temp_file" 

done
