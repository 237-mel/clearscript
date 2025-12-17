#!/bin/bash

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: $0 file"
    exit 0
fi

[[ $# -ne 1 || ! -f "$1" ]] && { echo "Error: Invalid file" >&2; exit 1; }

file="$1"
line_num=0

declare -A coeffs=(
    [s]=1 [min]=60 [h]=3600 [d]=86400
    [mm]=0.001 [sm]=0.01 [cm]=0.01 [dm]=0.1 [m]=1 [km]=1000
    [mg]=0.000001 [g]=0.001 [kg]=1 [t]=1000
)

while IFS= read -r line; do
    ((line_num++))
    line=$(echo "$line" | xargs)
    [[ -z "$line" ]] && continue
    
    if [[ ! "$line" =~ ^([a-zA-Z]+)=(.*)$ ]]; then
        echo "Error line $line_num: Incorrect format" >&2
        continue
    fi
    
    param="${BASH_REMATCH[1]}"
    expr="${BASH_REMATCH[2]}"
    
    prev_type=""
    unit_error=0
    expr_copy="$expr"
    
    while [[ "$expr_copy" =~ ([0-9.]+[a-zA-Z]+) ]]; do
        token="${BASH_REMATCH[1]}"
        unit="${token//[0-9.]/}"
        
        if [[ -z "${coeffs[$unit]}" ]]; then
            echo "Error line $line_num: Invalid unit '$unit' for '$param'" >&2
            unit_error=1
            break
        fi
        
        if [[ "$unit" =~ ^(s|min|h|d)$ ]]; then
            type="time"
        elif [[ "$unit" =~ ^(mm|sm|cm|dm|m|km)$ ]]; then
            type="distance"
        elif [[ "$unit" =~ ^(mg|g|kg|t)$ ]]; then
            type="weight"
        fi
        
        if [[ -n "$prev_type" && "$prev_type" != "$type" ]]; then
            echo "Error line $line_num: Incompatible units for '$param'" >&2
            unit_error=1
            break
        fi
        
        prev_type="$type"
        value="${token%"$unit"}"
        converted=$(echo "$value * ${coeffs[$unit]}" | bc -l)
        
        if [[ "$token" == *"."* ]]; then
            token_pattern="${token//./\\.}"
            expr="${expr//"$token_pattern"/$converted}"
        else
            expr="${expr//"$token"/$converted}"
        fi
        
        expr_copy="${expr_copy/"$token"/ }"
    done
    
    [[ $unit_error -eq 1 ]] && continue
    
    result=$(echo "$expr" | bc -l 2>/dev/null)
    
    if [[ -n "$result" ]]; then
        if [[ "$result" =~ ^[0-9]+\.0+$ ]]; then
            result="${result%.*}"
        fi
        echo "$param=$result"
    else
        echo "Error line $line_num: Invalid expression for '$param'" >&2
    fi
    
done < "$file"