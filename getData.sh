function getData {
  while :; do
  read -p "From to: " SERVER_DAYS
    [[ ${SERVER_DAYS} =~ ^[0-9]+$ ]] || { echo "From to!"; continue; }
    if ((SERVER_DAYS >= 365 && SERVER_DAYS <= 3650)); then
      echo "${SERVER_DAYS}"
      break
    else
      echo "Try again"
    fi
  done
  IP=`/usr/bin/dig +short google.com`
  read -p "IP [${IP}]: " IP_NEW
  if [ "${IP_NEW}" != "" ]; then
    while ! valid_ip "${IP_NEW}"
    do
      read -p "Bad IP" IP_NEW
    done
    echo "Good IP."
    IP="${IP_NEW}"
  fi
  echo ${IP}
}
