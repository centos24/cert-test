#!/bin/bash

BACKUP_DATE=$(date +"%Y-%m-%d")
BACKUP_FILE="${BACKUP_DATE}_backup_haproxy.tar.gz"
BACKUP_DIR="test"
BACKUP_PATH="/tmp"
BACKUP_TO_PATH="/home/backup"
BACKUP_LOGS_DIR="/home/log"
BACKUP_LOGS_FILE="backup.log"
REMOVE_IN_DAYS=30
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

log() {
    if [ ! -d "$BACKUP_LOGS_DIR" ]; then
        mkdir -p $BACKUP_LOGS_DIR
    fi
    echo "$TIMESTAMP $1" >> "$BACKUP_LOGS_DIR/$BACKUP_LOGS_FILE"
}

backup_files() {
    if [ ! -d "$BACKUP_PATH/$BACKUP_DIR" ]; then
        log "Błąd - katalog $BACKUP_PATH/$BACKUP_DIR nie istnieje!"
        exit 1
    fi

    if [ ! -d "$BACKUP_TO_PATH" ]; then
        mkdir -p $BACKUP_TO_PATH
        log "Katalog $BACKUP_TO_PATH nie istnieje! Tworzę katalog... Utworzono."
    else
        # usuniecie plikow starszych niż wartość w REMOVE_IN_DAYS (dni)
        find "$BACKUP_TO_PATH" -type f -mtime +${REMOVE_IN_DAYS} -exec echo "$TIMESTAMP Usuwam stary plik: {}" \; -exec rm -f {} \; >> "$BACKUP_LOGS_DIR/$BACKUP_LOGS_FILE"
    fi

    if [ -f "$BACKUP_TO_PATH/$BACKUP_FILE" ]
    then
        log "Plik $BACKUP_TO_PATH/$BACKUP_FILE istnieje! Backup nie będzie tworzony!"
        exit 1
    else
        cd ${BACKUP_PATH}
        # wykonanie kopii
        tar -cpzf ${BACKUP_TO_PATH}/${BACKUP_FILE} ${BACKUP_DIR}
        log "Zapisuję backup do pliku ${BACKUP_TO_PATH}/${BACKUP_FILE}"
    fi
}

backup_files
