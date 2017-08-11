#!/bin/bash

usage() {
cat << EOF
Usage:\n$0 [-i <wifi-interface>] [-m <mac-address>]

This script must be run with super-user privileges.

OPTIONS:
   -h      Show this message
   -i      Wifi interface name (default is en0)
   -m      MAC Address. If empty, a random address is used
   -v      Verbose
EOF
} 

# validate super-user privileges on start
if [[ $EUID -ne 0 ]]
then
    usage
    exit 1
fi

function getmac(){
    # first byte need to be even number
    # just generate a randon number between 1 and 127 and double it
    n=$[ 1 + $[ RANDOM % 127 ]]
    result=$(($n*2))
    printf -v first_byte "%x:" "$result"
    local new_mac=$first_byte$(openssl rand -hex 5 | sed 's/\(..\)/\1:/g; s/.$//')
    echo $new_mac
}

if [ $# -gt 5 ]
then
    usage
    exit 1
fi

INTERFACE="en0"
MAC=
RNDMAC=1
VERBOSE=
CurrentMAC=
NewMAC=
DissociateFromNetwork="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -z"
DetectHW="networksetup -detectnewhardware"
readMac="ifconfig $INTERFACE | grep ether| cut -d ' ' -f 2"
ON="networksetup -setairportpower $INTERFACE on"
OFF="networksetup -setairportpower $INTERFACE off"
while getopts “hi:m:v” OPTION
do
    case $OPTION in
         h)
             usage
             exit 1
             ;;
         i)
             INTERFACE=$OPTARG
             ;;
         m)
             MAC=$OPTARG
             RNDMAC=0
             ;;
         v)
             VERBOSE=1
             ;;
         ?)
             usage
             exit
             ;;
    esac
done

# Dissociating from the newtork
if [[ "$VERBOSE" != "" ]]
then
    echo -e "Dissociating from the newtork"
fi
eval "$DissociateFromNetwork"

COUNTER=0
until [[ "$CurrentMAC" != "$NewMAC" ]]; do
    if [[ "$COUNTER" -ge 5 ]]; then
       echo "Counter: $COUNTER times reached; Exiting loop!"
       exit 1
    fi

    COUNTER=$((COUNTER+1))

    CurrentMAC=$(eval "$readMac")
    if [[ "$VERBOSE" != "" ]]
    then
        echo -e "Current MAC Address $CurrentMAC"
    fi
    if [[ "$RNDMAC" -eq 1 ]]
    then
        MAC=$(getmac)
        if [[ "$VERBOSE" != "" ]]
        then
            echo -e "MAC Address generated: $MAC"
        fi
    fi

    # Spoof MAC address
    if [[ "$VERBOSE" != "" ]]
    then
        echo -e "Spoofing MAC: ifconfig $INTERFACE ether $MAC"
    fi
    eval "ifconfig $INTERFACE ether $MAC"

    # Detect hardware changes
    eval "$DetectHW"
    NewMAC=$(eval "$readMac")
    if [[ "$VERBOSE" != "" ]]
    then
        echo -e "Detecting hardware changes... new MAC is $NewMAC"
    fi
done

if [[ "$COUNTER" -lt 5 ]]; then
    #Turn wifi off
    if [[ "$VERBOSE" != "" ]]
    then
        echo -e "Turning off wifi"
    fi
    eval "$OFF"

    #Turn wifi on
    if [[ "$VERBOSE" != "" ]]
    then
        echo -e "Turning on wifi"
    fi
    eval "$ON"    
fi