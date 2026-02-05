#!/bin/bash

while IFS= read -r -d '' file; do
    [[ -z "$file" ]] && continue
    
    target="${file}.tar.gz"
    
    if [[ -e "$target" ]]; then
        continue
    else
        if tar -czf "$target" -- "$file" >/dev/null 2>&1; then
            rm -f "$file"
        else
            rm -f -- "$target" 2>/dev/null
        fi
    fi
done < <(find . -maxdepth 1 -type f \
  \( -name '*.[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].log'     \
     -o -name '*.log.[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'   \
     -o -name '*.[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'       \) \
  ! -name '*.gz' ! -name '*.tar.gz' \
  -print0)
