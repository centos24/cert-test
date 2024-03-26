#!/bin/bash

SCRIPT_PATH=`/usr/bin/pwd`
CA_KEY="${SCRIPT_PATH}/ca.key"
CA_CRT="${SCRIPT_PATH}/cacert.pem"
SERVER_CONF="${SCRIPT_PATH}/server_cert.cnf"
SERVER_EXT="${SCRIPT_PATH}/server_ext.cnf"
TMP_DNS_NAME="${SCRIPT_PATH}/.dns_name.tmp"
TMP_IP="${SCRIPT_PATH}/.ip.tmp"
OPENSSL_CMD="/usr/bin/openssl"
CAT_CMD="/usr/bin/cat"

function intro {
    echo "================================================================================="
    echo "=                    Skrypt generujący certyfikat dla domeny                    ="
    echo "================================================================================="
}

function getType {
    while :; do
        echo "Wybierz typ certyfikatu:"
        echo "1 - certyfikat dla domeny np. domena.pl"
        echo "2 - certyfikat typu Wildcard  np. *.domena.pl"
        echo "0 - Zakończ"
        read -p "Wybierz opcje: " QUESTION_1
        [[ ${QUESTION_1} =~ ^[0-9]+$ ]] || { continue; }
        if ((QUESTION_1 == 0 || QUESTION_1 == 1 || QUESTION_1 == 2)); then
            case "${QUESTION_1}" in
                "1") QUESTION_1=1; getDomain; ;;
                "2") QUESTION_1=2; getDomain; ;;
                "0") echo "Przerwano generowanie! Zamykam!"; exit 1 ;;
                *) echo "Nic nie wybrałeś"
            esac
            break
        fi
    done
}

function getDomain {
    if ((QUESTION_1 == 1)); then
        echo "Wprowadź nazwę domeny np. domena.pl"
        while :; do
            read -r -p "Nazwa domeny: " DOMAIN
            if [[ ${DOMAIN:0:2} = "*." ]];then
                echo "Nie używaj domeny typu Wildcard! Podaj nazwę np. domena.pl"
            else
                break
            fi
        done
        echo "================================================================================="
        while :; do
            echo "Czy chcesz podać nazwę subdomeny?"
            echo "1 - Tak"
            echo "2 - Nie"
            echo "0 - Zakończ"
            read -p "Wybierz opcje: " QUESTION_2
            [[ ${QUESTION_2} =~ ^[0-9]+$ ]] || { continue; }
            if ((QUESTION_2 == 0 || QUESTION_2 == 1 || QUESTION_2 == 2)); then
                case "${QUESTION_2}" in
                    "1") QUESTION_2=1;
                        if [ -f "${TMP_DNS_NAME}" ]; then
                            rm -f "${TMP_DNS_NAME}"
                        fi
                        j=1
                        while :; do
                            echo "Podaj jedną lub kilka subdomen oddzielając je spacjami np. www.domena.pl www.domena-2.pl www.domena3.pl"
                            read -r -a array -p "Wprowadź: "
                            for i in "${!array[@]}"
                            do
                                if [[ ${array[i]:0:2} = "*." ]];then
                                    echo "Nie używaj subdomeny typu Wildcard!"
                                    ERROR_1=1
                                    break
                                else
                                    ERROR_1=0
                                fi
                            done
                            if (( $ERROR_1==1)); then
                                continue
                            else
                                for i in "${!array[@]}"
                                do
                                    ((j++))
                                    echo "DNS.$j = ${array[i]}" >> ${TMP_DNS_NAME}
                                done
                                break
                            fi
                        done
                    ;;
                    "2") QUESTION_2=2; break ;;
                    "0") echo "Przerwano generowanie! Zamykam!"; exit 1 ;;
                    *) echo "Nic nie wybrałeś"
                esac
                break
            fi
        done
        echo "================================================================================="
        while :; do
            echo "Czy chcesz podać adres IP dla certyfikatu?"
            echo "1 - Tak, podaj adres lub kilka adresów IP oddzielając je spacją np. 10.8.1.1 10.8.2.2 10.8.3.3"
            echo "2 - Nie"
            echo "0 - Zakończ"
            read -p "Wybierz opcje: " QUESTION_3
            [[ ${QUESTION_3} =~ ^[0-9]+$ ]] || { continue; }
            if ((QUESTION_3 == 0 || QUESTION_3 == 1 || QUESTION_3 == 2)); then
                case "${QUESTION_3}" in
                    "1") QUESTION_3=1;
                        if [ -f "${TMP_IP}" ]; then
                            rm -f ${TMP_IP}
                        fi
                        j=0
                        while :; do
                            read -r -a array_ip -p "Adres lub adresy IP: "
                            for i in "${!array_ip[@]}"
                            do
                                if ! valid_ip "${array_ip[i]}"; then
                                    ERROR_1=1
                                    break
                                else
                                    ((j++))
                                    echo "IP.$j = ${array_ip[i]}" >> ${TMP_IP}
                                fi
                            done
                            if ((ERROR_1 == 1)); then
                                continue
                            fi
                            break
                        done
                    ;;
                    "2") QUESTION_3=2; break ;;
                    "0") echo "Przerwano generowanie! Zamykam!"; exit 1 ;;
                    *) echo "Nic nie wybrałeś"
                esac
                break
            fi
        done
    elif ((QUESTION_1 == 2)); then
        while :; do
            echo "Wprowadź nazwę domeny typu Wildcard np. *.domena.pl"
            read -r -p "Nazwa domeny: " DOMAIN
            if [[ ${DOMAIN:0:2} = "*." ]];then
                break
            else
                echo "Błędna nazwa domeny typu Wildcard!"
            fi
        done
    fi
    echo "================================================================================="
    while :; do
        echo "Wybierz ważność certyfikatu:"
        echo "1 - Generuj certyfikat na 1 rok   (365 dni)"
        echo "2 - Generuj certyfikat na 2 lata  (730 dni)"
        echo "3 - Generuj certyfikat na 5 lat  (1825 dni)"
        echo "4 - Generuj certyfikat na 10 lat (3560 dni)"
        echo "0 - Zakończ!"
        read -p "Wpisz liczbę od 1 do 4 lub 0 aby zakończyć: " SERVER_DAYS
        [[ ${SERVER_DAYS} =~ ^[0-9]+$ ]] || { continue; }
        if ((SERVER_DAYS >= 0 && SERVER_DAYS <= 4)); then
            case "${SERVER_DAYS}" in
                "1") echo "Wybrano 1 rok   (365 dni)"; CERT_DAYS=365; ;;
                "2") echo "Wybrano 2 lata  (730 dni)"; CERT_DAYS=750; ;;
                "3") echo "Wybrano 5 lat  (1825 dni)"; CERT_DAYS=1825; ;;
                "4") echo "Wybrano 10 lat (3650 dni)"; CERT_DAYS=3650; ;;
                "0") echo "Przerwano generowanie! Zamykam!"; exit 1 ;;
                *) echo "Nic nie wybrałeś"
            esac
            break
        fi
    done
    echo "================================================================================="

    while :; do
        echo "Wybierz algorytm i długość klucza"
        echo "1 - SHA256 / 2048 bit"
        echo "2 - SHA512 / 4096 bit"
        echo "0 - Zakończ!"
        read -p "Wpisz liczbę od 1 do 2 lub 0 aby zakończyć: " SERVER_DAYS
        [[ ${SERVER_DAYS} =~ ^[0-9]+$ ]] || { continue; }
        if ((SERVER_DAYS >= 0 && SERVER_DAYS <= 2)); then
            case "${SERVER_DAYS}" in
                "1") echo "1 - SHA256 / 2048 bit"; CERT_SHA="-sha256"; CERT_BIT=2048 ;;
                "2") echo "2 - SHA512 / 4096 bit"; CERT_SHA="-sha512"; CERT_BIT=4096 ;;
                "0") echo "Przerwano generowanie! Zamykam!"; exit 1 ;;
                *) echo "Nic nie wybrałeś"
            esac
            break
        fi
    done
    echo "================================================================================="
}

function valid_ip()
{
    local  ip=$1
    local  stat=1
    
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
        && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

function generate_conf {
    
${CAT_CMD} > ${SERVER_CONF} <<EOF
default_bit = ${CERT_BIT}
distinguished_name = req_distinguished_name
prompt = no

[req_distinguished_name]
countryName             = PL
stateOrProvinceName     = mazowieckie
localityName            = Warszawa
organizationName        = Vip
commonName              = ${DOMAIN}
EOF
    
${CAT_CMD} > ${SERVER_EXT} <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[alt_names]
EOF
    CERT_PATH="certs"
    if ((QUESTION_1 == 1)); then
        echo "DNS.1 = ${DOMAIN}" >> ${SERVER_EXT}
        if [ ! -d "${SCRIPT_PATH}/${CERT_PATH}" ]; then
            mkdir "${SCRIPT_PATH}/${CERT_PATH}"
        fi
        SERVER_KEY="${SCRIPT_PATH}/${CERT_PATH}/${DOMAIN}.key"
        SERVER_CSR="${SCRIPT_PATH}/${CERT_PATH}/${DOMAIN}.csr"
        SERVER_CRT="${SCRIPT_PATH}/${CERT_PATH}/${DOMAIN}.crt"
    elif ((QUESTION_1 == 2)); then
        echo "DNS.1 = ${DOMAIN}" >> ${SERVER_EXT}
        SERVER_KEY="${SCRIPT_PATH}/${CERT_PATH}/wildcard${DOMAIN:1}.key"
        SERVER_CSR="${SCRIPT_PATH}/${CERT_PATH}/wildcard${DOMAIN:1}.csr"
        SERVER_CRT="${SCRIPT_PATH}/${CERT_PATH}/wildcard${DOMAIN:1}.crt"
    fi

    if ((QUESTION_2 == 1)); then
        ${CAT_CMD} "${TMP_DNS_NAME}" >> ${SERVER_EXT}
    fi

    if ((QUESTION_3 == 1)); then
        ${CAT_CMD} "${TMP_IP}" >> ${SERVER_EXT}
    fi
}

function generate_server_certificate {
    
    echo "Generating server private key"
    ${OPENSSL_CMD} genrsa -out ${SERVER_KEY} ${CERT_BIT} 2>/dev/null
    [[ $? -ne 0 ]] && echo "ERROR: Failed to generate ${SERVER_KEY}" && exit 1
    
    echo "Generating certificate signing request for server"
    ${OPENSSL_CMD} req -new -key ${SERVER_KEY} -out ${SERVER_CSR} -config ${SERVER_CONF} 2>/dev/null
    [[ $? -ne 0 ]] && echo "ERROR: Failed to generate ${SERVER_CSR}" && exit 1
    
    echo "Generating RootCA signed server certificate"
    ${OPENSSL_CMD} x509 -req -in ${SERVER_CSR} -CA ${CA_CRT} -CAkey ${CA_KEY} -out ${SERVER_CRT} -CAcreateserial -days ${CERT_DAYS} ${CERT_SHA} -extfile ${SERVER_EXT} 2>/dev/null
    [[ $? -ne 0 ]] && echo "ERROR: Failed to generate ${SERVER_CRT}" && exit 1
    
    echo "Verifying the server certificate against RootCA"
    ${OPENSSL_CMD} verify -CAfile ${CA_CRT} ${SERVER_CRT} >/dev/null 2>&1
    [[ $? -ne 0 ]] && echo "ERROR: Failed to verify ${SERVER_CRT} against $CA_CRT" && exit 1

    echo "================================================================================="
    echo "Certyfikaty znajdują się w katalogu ${SCRIPT_PATH}/${CERT_PATH}"
    echo "================================================================================="

    if [ -f "${TMP_DNS_NAME}" ]; then
        rm -f "${TMP_DNS_NAME}"
    fi
        if [ -f "${TMP_IP}" ]; then
        rm -f "${TMP_IP}"
    fi
}

# MAIN
intro
getType
generate_conf
generate_server_certificate
