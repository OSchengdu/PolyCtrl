#!/bin/bash

find . -type f \( -name "*.asm" -o -name "*.c" -o -name "*.h" -o -name "*.cpp" -o -name "*.hpp" \) | while read file; do
    echo "Processing $file"
    cp "$file" "${file}.bak"
    
    sed -i.tmp '
        s/[[:space:]]*;.*$//g
        /^[[:space:]]*;/d
        /^[[:space:]]*\/\//d
        /^[[:space:]]*#/d
        /\/\*/,/\*\//d
        /^[[:space:]]*$/d
        s/[[:space:]]*$//g
    ' "$file"
    
    rm -f "${file}.tmp"
done

echo "Comment removal complete!" 