#!/bin/bash

SCRIPT_PATH=`/usr/bin/pwd`
CA_KEY="${SCRIPT_PATH}/ca.key"
CA_CRT="${SCRIPT_PATH}/cacert.pem"
SERVER_CONF="${SCRIPT_PATH}/server_cert.cnf"
SERVER_EXT="${SCRIPT_PATH}/server_ext.cnf"
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
            echo "1 - Tak, podaj nazwę subdomeny np. www.domena.pl"
            echo "2 - Nie"
            echo "0 - Zakończ"
            read -p "Wybierz opcje: " QUESTION_2
            [[ ${QUESTION_2} =~ ^[0-9]+$ ]] || { continue; }
            if ((QUESTION_2 == 0 || QUESTION_2 == 1 || QUESTION_2 == 2)); then
                case "${QUESTION_2}" in
                    "1") QUESTION_2=1;
                        while :; do
                            read -r -p "Nazwa subdomeny: " DOMAIN_2
                            if [[ ${DOMAIN_2:0:2} = "*." ]];then
                                echo "Nie używaj subdomeny typu Wildcard! Podaj nazwę np. www.domena.pl"
                            else
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
            echo "1 - Tak, podaj adres IP np. 10.8.1.1"
            echo "2 - Nie"
            echo "0 - Zakończ"
            read -p "Wybierz opcje: " QUESTION_3
            [[ ${QUESTION_3} =~ ^[0-9]+$ ]] || { continue; }
            if ((QUESTION_3 == 0 || QUESTION_3 == 1 || QUESTION_3 == 2)); then
                case "${QUESTION_3}" in
                    "1") QUESTION_3=1;
                        while :; do
                            read -p "Adres IP: " IP_NEW
                            if [ "${IP_NEW}" != "" ]; then
                                while ! valid_ip "${IP_NEW}"
                                    do
                                    echo "Nieprawidłowy adres IP !"
                                    read -p "Wprowadź poprawny IP: " IP_NEW
                                done
                                IP="${IP_NEW}"
                                break
                            fi
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
                "1") echo "Wybrano 1 rok   (365 dni)" ;;
                "2") echo "Wybrano 2 lata  (730 dni)" ;;
                "3") echo "Wybrano 5 lat  (1825 dni)" ;;
                "4") echo "Wybrano 10 lat (3650 dni)" ;;
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
default_bit = 4096
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
        echo "DNS.2 = ${DOMAIN_2}" >> ${SERVER_EXT}
    fi

    if ((QUESTION_3 == 1)); then
        echo "IP.1 = ${IP}" >> ${SERVER_EXT}
    fi
}

function generate_server_certificate {
    
    echo "Generating server private key"
    ${OPENSSL_CMD} genrsa -out ${SERVER_KEY} 4096 2>/dev/null
    [[ $? -ne 0 ]] && echo "ERROR: Failed to generate ${SERVER_KEY}" && exit 1
    
    echo "Generating certificate signing request for server"
    ${OPENSSL_CMD} req -new -key ${SERVER_KEY} -out ${SERVER_CSR} -config ${SERVER_CONF} 2>/dev/null
    [[ $? -ne 0 ]] && echo "ERROR: Failed to generate ${SERVER_CSR}" && exit 1
    
    echo "Generating RootCA signed server certificate"
    ${OPENSSL_CMD} x509 -req -in ${SERVER_CSR} -CA ${CA_CRT} -CAkey ${CA_KEY} -out ${SERVER_CRT} -CAcreateserial -days ${SERVER_DAYS} -sha512 -extfile ${SERVER_EXT} 2>/dev/null
    [[ $? -ne 0 ]] && echo "ERROR: Failed to generate ${SERVER_CRT}" && exit 1
    
    echo "Verifying the server certificate against RootCA"
    ${OPENSSL_CMD} verify -CAfile ${CA_CRT} ${SERVER_CRT} >/dev/null 2>&1
    [[ $? -ne 0 ]] && echo "ERROR: Failed to verify ${SERVER_CRT} against $CA_CRT" && exit 1

    echo "================================================================================="
    echo "Certyfikaty znajdują się w katalogu ${SCRIPT_PATH}/${CERT_PATH}"
    echo "================================================================================="
}

# MAIN
intro
getType
generate_conf
generate_server_certificate
