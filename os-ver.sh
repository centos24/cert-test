#!/bin/bash

FILE="/etc/oracle-release"

if [ -f $FILE ]; then
    ver=$(cat $FILE | awk '{ print $5 }' | cut -c1)
    case $ver in
        "9") echo "Version $ver" ;;
        "8") echo "Version $ver" ;;
        "7") echo "Version $ver" ;;
        *) echo "unknown" ;;
    esac
else
    echo "File $FILE does not exist!"
fi
