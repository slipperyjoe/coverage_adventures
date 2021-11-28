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
#     
# -----------------------------------------------------------------------------

usage () {
		cat <<- EOF

    Description:
        Extract percentages by resource type from .har report

    Usage:
        $0  [OPTION]... [FILES]

    Options:
        -p      change format to from 0.98 to 98
        -s      output separator: "," ";" ...
        -h      print this message

    Exit status:
        0 if OK
        1 if problems
EOF
}
# default values
OUT_SEPARATOR=","
PERCENT_FORMAT="1"

while getopts s:ph opt
do
    case $opt in
        p)		PERCENT_FORMAT="100" ;;
        s)		OUT_SEPARATOR="$OPTARG" ;;
        h|\?)		usage ; exit 0;;
		esac
done

# check that argument is provided
shift $((OPTIND -1))
[ "$1" = "" ] && { echo "No input provided"; usage; exit 1; }
INPUT_FILE="$1"

temp_1=$(mktemp toto.XXXXXXXXXX )


cat "$INPUT_FILE" | jq -r '
    .log.entries| .[] | 
    [.response.content.size,.response.content.mimeType,.request.url] |
    @tsv' |
    tee "$temp_1" |

awk '{sum+=$1}END{print sum}' |
{
    read  TOTAL 
#    TOTAL=$(awk '{sum+=$1}END{print sum}' res)
    ## get percentage
    cat "$temp_1" | sort -k 2 | awk '{ 
        if( NR == 1){
            type=$2
            sum=$1
        }
        if(NR > 1){
            if($2 != type) {
                print type"'"$OUT_SEPARATOR"'"sum/'"$TOTAL"'*'"$PERCENT_FORMAT"'
#                print type"'"$OUT_SEPARATOR"'"sum/'"$TOTAL"'*100
                sum=0 
            }
            type=$2 
            sum+=$1
        }
    }
    END{
#        print type"'"$OUT_SEPARATOR"'"sum*100
        print type"'"$OUT_SEPARATOR"'"sum*'"$PERCENT_FORMAT"' 
    }'


}
# sum = (sum+$1)

# cleanup
rm  $temp_1
