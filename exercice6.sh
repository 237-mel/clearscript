#!/bin/bash

show_help() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -d, --directory DIR  Directory to check (default: current)"
    exit 0
}

DIR="."
if [[ "$1" == "-d"  "$1" == "--directory" ]]; then
    DIR="$2"
fi

[[ "$1" == "-h"  "$1" == "--help" ]] && show_help

if [ ! -d "$DIR" ]; then
    echo "Error: Directory '$DIR' not found"
    exit 1
fi

OPEN_FILES=$(lsof +D "$DIR" 2>/dev/null | awk '{print $9}')
FOUND=0

for subdir in "$DIR"/*/; do
    [ ! -d "$subdir" ] && continue
    DIR_NAME="${subdir%/}"
    HAS_OPEN=0
    
    for open in $OPEN_FILES; do
        if [[ "$open" == "$DIR_NAME"/* ]]; then
            HAS_OPEN=1
            break
        fi
    done
    
    if [ $HAS_OPEN -eq 0 ]; then
        echo "$DIR_NAME"
        FOUND=1
    fi
done

[ $FOUND -eq 0 ] && exit 1 || exit 0