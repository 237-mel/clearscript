#!/bin/bash

show_help() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -d, --directory DIR  Directory to check (default: current)"
    echo "  -h, --help           Show this help message"
    exit 0
}

DIR="."
FOUND=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            ;;
        -d|--directory)
            if [[ -z "$2" || "$2" =~ ^- ]]; then
                echo "Error: Missing directory argument for $1" >&2
                exit 1
            fi
            DIR="$2"
            shift 2
            ;;
        -d*)
            DIR="${1#-d}"
            if [[ -z "$DIR" ]]; then
                echo "Error: Missing directory argument for $1" >&2
                exit 1
            fi
            shift
            ;;
        --directory=*)
            DIR="${1#*=}"
            if [[ -z "$DIR" ]]; then
                echo "Error: Missing directory argument for $1" >&2
                exit 1
            fi
            shift
            ;;
        *)
            echo "Error: Unknown option: $1" >&2
            echo "Use -h or --help for usage information" >&2
            exit 1
            ;;
    esac
done

if [[ ! -d "$DIR" ]]; then
    echo "Error: Directory '$DIR' not found" >&2
    exit 1
fi

OPEN_FILES=$(lsof +D "$DIR" 2>/dev/null | awk '{print $9}')
FOUND=0

for subdir in "$DIR"/*/; do
    [[ ! -d "$subdir" ]] && continue
    DIR_NAME="${subdir%/}"
    HAS_OPEN=0
    
    for open in $OPEN_FILES; do
        if [[ "$open" == "$DIR_NAME"/* ]]; then
            HAS_OPEN=1
            break
        fi
    done
    
    if [[ $HAS_OPEN -eq 0 ]]; then
        echo "$DIR_NAME"
        FOUND=1
    fi
done

[[ $FOUND -eq 0 ]] && exit 1 || exit 0