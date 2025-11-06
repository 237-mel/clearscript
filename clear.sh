#!/bin/bash

show_help() {
    echo "Usage: $0 [OPTION] [PATH]"
    echo "Check directories in PATH and remove those that don't exist"
    echo "or don't contain executable files."
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help"
}

has_executables() {
    local dir="$1"
    
    if [ ! -d "$dir" ]; then
        return 1
    fi
    
    if find "$dir" -maxdepth 1 -type f -executable -quit 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

clean_path() {
    local path="$1"
    local -a valid_dirs
    local -A seen
    local IFS_backup="$IFS"
    
    IFS=":"
    for dir in $path; do
        [ -z "$dir" ] && continue
        
        if [ -n "${seen[$dir]}" ]; then
            continue
        fi
        seen["$dir"]=1
        
        if has_executables "$dir"; then
            valid_dirs+=("$dir")
        fi
    done
    
    IFS="$IFS_backup"
    
    local result=""
    for ((i=0; i<${#valid_dirs[@]}; i++)); do
        if [ $i -eq 0 ]; then
            result="${valid_dirs[i]}"
        else
            result="$result:${valid_dirs[i]}"
        fi
    done
    
    echo "$result"
}

main() {
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_help
        exit 0
    fi
    
    local path_to_check
    if [ $# -eq 0 ]; then
        path_to_check="$PATH"
    else
        path_to_check="$1"
    fi
    
    clean_path "$path_to_check"
}

main "$@"