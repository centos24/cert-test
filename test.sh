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
#           echo "Wybrano ${QUESTION_1} - generowanie certyfikatu SSL"
            echo "Wprowadź nazwę domeny np. domena.pl"
            while :; do
                read -r -p "Nazwa domeny: " DOMAIN
                if [[ ${DOMAIN:0:2} = "*." ]];then
                    echo "Nie używaj domeny typu Wildcard! Podaj nazwę np. domena.pl"
                else
                    break
                fi
            done
            echo "Wprowadź nazwę subdomeny np. www.domena.pl"
            while :; do
                read -r -p "Nazwa subdomeny: " DOMAIN_2
                if [[ ${DOMAIN_2:0:2} = "*." ]];then
                    echo "Nie używaj subdomeny typu Wildcard! Podaj nazwę np. www.domena.pl"
                else
                    break
                fi
            done
            echo "Wprowadź adres IP hosta dla certyfikatu."
            read -p "Adres IP: " IP_NEW
            if [ "${IP_NEW}" != "" ]; then
                while ! valid_ip "${IP_NEW}"
                do
                    read -p "Nieprawidłowy adres IP. Wprowadź ponownie: " IP_NEW
                done
#               echo "Sukces. Podałeś prawidłowy adres IP."
                IP="${IP_NEW}"
            fi
        elif ((QUESTION_1 == 2)); then
#           echo "Wybrano ${QUESTION_1} - generowanie certyfikatu SSL typu Wildcard"
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

    if ((QUESTION_1 == 1)); then
        echo "DNS.1 = ${DOMAIN}" >> ${PATH}/cert.conf
        echo "DNS.2 = ${DOMAIN_2}" >> ${PATH}/cert.conf
        echo "IP.1 = ${IP}" >> ${PATH}/cert.conf
    elif ((QUESTION_1 == 2)); then
        echo "DNS.1 = ${DOMAIN}" >> ${PATH}/cert.conf
    fi
