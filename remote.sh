#!/bin/bash

HOSTS_FILE="remote.hosts"

if [ ! -f "$HOSTS_FILE" ]; then
    echo "No file $HOSTS_FILE!"
    exit 1
fi

while IFS= read -r host; do
    if [[ -z "$host" || "$host" =~ ^[[:space:]]*# ]]; then
        continue
    fi

    host=$(echo "$host" | tr -d '[:space:]')

   ssh -n "$host" "cat /home/test.txt" 2>/dev/null || {
        echo "error"
    }
done < "$HOSTS_FILE"
