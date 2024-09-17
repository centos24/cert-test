#!/bin/bash

MONITORED_DIR="/home/test/"
REMOTE_USER="root"
REMOTE_SERVER="domain.local"
REMOTE_DIR="/home/test/"
RSYNC_OPTIONS="-az --delete"
LOG_FILE="/var/log/sync-monitor.log"

log() {
    local TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$TIMESTAMP $1" >> "$LOG_FILE"
}

inotifywait -m -r -e modify,create,delete,move "$MONITORED_DIR" --format '%w%f' |
while read FILE
do
    log "Plik $FILE został zmodyfikowany. Rozpoczęcie synchronizacji..."
    rsync $RSYNC_OPTIONS "$MONITORED_DIR" "$REMOTE_USER@$REMOTE_SERVER:$REMOTE_DIR" >> "$LOG_FILE" 2>&1
    if [ $? -eq 0 ]; then
        log "Synchronizacja zakończona pomyślnie."
    else
        log "Błąd podczas synchronizacji!"
    fi
done



[Unit]
Description=Monitoring directory and syncing with remote server
After=network.target

[Service]
ExecStart=/home/sync-haproxy.sh
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
