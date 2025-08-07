#!/bin/bash

HOSTS_FILE="hosts.txt"

if [[ ! -f "$HOSTS_FILE" ]]; then
    echo "Error: File $HOSTS_FILE not found!"
    exit 1
fi

while IFS= read -r host; do
    [[ -z "$host" || "$host" =~ ^# ]] && continue

    result=$(ssh "$host" "grep -q '2>\$1' /etc/cron/test && echo 'found' || echo 'not found'")

    if [[ "$result" == "found" ]]; then
        echo "Host: $host - found '2>\$1' w pliku /etc/cron/test"
    fi

done < "$HOSTS_FILE"
