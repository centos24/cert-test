#!/bin/bash

# Lista nazw kontenerów (możesz dodać własne nazwy)
CONTAINER_NAMES=("httpd1" "httpd2" "httpd3")

# Flaga do śledzenia błędów
ERROR_FLAG=0

# Funkcja sprawdzająca wersję Apache w pojedynczym kontenerze
check_apache_version() {
    local CONTAINER_NAME=$1

    # Sprawdzenie, czy kontener istnieje
    if ! docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "Błąd: Kontener ${CONTAINER_NAME} nie istnieje"
        ERROR_FLAG=1
        return 1
    fi

    # Sprawdzenie, czy kontener jest uruchomiony
    if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "Kontener ${CONTAINER_NAME} nie jest uruchomiony. Uruchamiam..."
        docker start "${CONTAINER_NAME}"
    fi

    # Wykonanie polecenia w kontenerze, aby sprawdzić wersję Apache
    echo "Sprawdzanie wersji Apache w kontenerze ${CONTAINER_NAME}..."
    docker exec "${CONTAINER_NAME}" httpd -v

    # Sprawdzenie statusu ostatniego polecenia
    if [ $? -eq 0 ]; then
        echo "Wersja Apache w kontenerze ${CONTAINER_NAME} została pomyślnie wyświetlona"
    else
        echo "Błąd podczas sprawdzania wersji Apache w kontenerze ${CONTAINER_NAME}"
        ERROR_FLAG=1
    fi
    echo "----------------------------------------"

    if [[ $(echo -e "$HTTPD_VER\n$LATEST_HTTPD_VER" | sort -V | head -n1) == "$HTTPD_VER" && "$HTTPD_VER" != "$LATEST_HTTPD_VER" ]]; then
        echo -e "${CONTAINER_NAME} - ${HTTPD_VER}$. {LATEST_HTTPD_VER}"
    else
        echo -e "${CONTAINER_NAME} - ${HTTPD_VER}"
    fi

}

# Pętla po wszystkich kontenerach
for CONTAINER in "${CONTAINER_NAMES[@]}"; do
    check_apache_version "${CONTAINER}"
done

# Sprawdzenie, czy wystąpiły jakiekolwiek błędy
if [ $ERROR_FLAG -eq 0 ]; then
    echo "Wszystkie wersje Apache zostały sprawdzone pomyślnie"
else
    echo "Wystąpiły błędy podczas sprawdzania wersji Apache"
    exit 1
fi
