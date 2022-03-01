#!/bin/bash

ACCESS_FILE_PATH=${1:-"/var/log/nginx/access.log"} # Path to nginx logs
IS_LOCAL=$2
FILE_OUTPUT_DIR="output" # Directory to create files which are not in whitelist
WHITELIST_FILE_PATH="whitelist.txt" # Path to whitelist file
FIRST_FILE_PATH="ips.log" # First file to create and read
SECOND_FILE_PATH="ips2.log" # Second file to create and read after timeout
TIMEOUT_SEC=60 # Timeout after second will be created
REQUEST_INSREASE_LIMIT=600 # Max request cap

if  [[ "$IS_LOCAL" != "local" ]]; then
    awk '{print $1}' $ACCESS_FILE_PATH | sort | uniq -c | sort -nr > $FIRST_FILE_PATH
    sleep $TIMEOUT_SEC
    awk '{print $1}' $ACCESS_FILE_PATH | sort | uniq -c | sort -nr > $SECOND_FILE_PATH
fi

IFS=' '
while read ip; do
    read -a ff_line_arr <<< $ip # Split each line from first file by IFS
    ff_count=${ff_line_arr[0]}
    ff_ip=${ff_line_arr[1]}
    
    second_file_match=$(grep "$ff_ip" $SECOND_FILE_PATH)
    read -a sf_line_arr <<< $second_file_match # Split each line from second file by IFS
    sf_count=${sf_line_arr[0]}
    
    if (($sf_count - $ff_count >= $REQUEST_INSREASE_LIMIT))
    then
        if $(grep -q "$ff_ip" $WHITELIST_FILE_PATH)
        then continue
        else mkdir -p "$FILE_OUTPUT_DIR" && touch "$FILE_OUTPUT_DIR/$ff_ip"
        fi
    fi
done < $FIRST_FILE_PATH