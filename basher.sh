#!/bin/bash
# Simple Port Scanner. I wrote that little script for environments where no netcat or other tools are available

VERSION="v0.1"

# Colors
C=$(printf '\033')
RED="${C}[1;31m"
SED_RED="${C}[1;31m&${C}[0m"
GREEN="${C}[1;32m"
SED_GREEN="${C}[1;32m&${C}[0m"
YELLOW="${C}[1;33m"
SED_YELLOW="${C}[1;33m&${C}[0m"
SED_RED_YELLOW="${C}[1;31;103m&${C}[0m"
BLUE="${C}[1;34m"
SED_BLUE="${C}[1;34m&${C}[0m"
ITALIC_BLUE="${C}[1;34m${C}[3m"
LG="${C}[1;37m" #LightGray
SED_LG="${C}[1;37m&${C}[0m"
DG="${C}[1;90m" #DarkGray
SED_DG="${C}[1;90m&${C}[0m"
NC="${C}[0m"
UNDERLINED="${C}[5m"
ITALIC="${C}[3m"

# Help
HELP=$GREEN"Scan Hosts for open Ports.
${NC}This script will scan hosts for open ports.
    ${YELLOW}-h${BLUE} To show this message.
    ${YELLOW}-s${BLUE} Scan a single host for open ports.
    ${YELLOW}-m${BLUE} Scan multiple hosts for open ports.
    ${YELLOW}-x${BLUE} Hosts to scan.
    ${YELLOW}-p${BLUE} Ports to scan.
    ${YELLOW}-i${BLUE} Use ping before scanning (make sure host responds to ICMP packets)
    ${YELLOW}-w${BLUE} Wait time before the script will mark a port as closed (default 0.5)"

WAITPORT=0.5
WAITICMP=3

OPTION='h?smx:p:iw:'

while getopts $OPTION flag; do
    case "${flag}" in
        h  ) printf "%s\n\n" "$HELP$NC" >&2; exit 1;;
        s  ) SINGLE="true";;
        m  ) MULTIPLE="true";;
        x  ) HOSTS="${OPTARG}";;
        p  ) PORTS="${OPTARG}";;
        i  ) ICMP="true";;
        w  ) WAITPORT="${OPTARG}";; # needs change to input level 1- 0.5s 2- 1s 3- 2s
        \? ) printf "${RED}Unknown option: -%s\n" "$OPTARG$NC" >&2; printf "%s\n\n" "$HELP$NC" >&2; exit 1;;
        :  ) printf "${YELLOW}Missing option argument for -%s\n" "$OPTARG$NC" >&2; printf "%s\n\n" "$HELP$NC" >&2; exit 1;;
        *  ) printf "${YELLOW}Unimplemented option: -%2\n" "$OPTARG$NC" >&2; printf "%s\n\n" "$HELP$NC" >&2; exit 1;;
        ### needs some tweaking, doesnt work that good!
    esac
done

# mandatory arguments
if [ ! "$PORTS" ] || [ ! $HOSTS ]; then
    printf "${RED}Both Host(s) and Port(s) must be provided!${NC}\n\n"
    printf "%s\n\n" "$HELP$NC" >&2; exit 1
fi


    # old stuff, needs to be reused later on maybe
	#if [[ $hosts == "" || $ports == "" ]]
	#then
	#	printf "\033[0;33mHost or Port can't be empty!\033[0m\n"
	#	scanMe
	#else
	#	for host in ${hosts[@]}
	#	do
	#		for port in ${ports[@]}
	#		do
   	#			portScan $host $port 2>/dev/null
	#		done
	#	done
	#	scanAgain
	#fi

if [ $ICMP ]; then
    timeout $WAITICMP bash -c "ping -c 1 ${HOSTS}" &> /dev/null &&
    ONLINE=1 ||
    ONLINE=0

    if [ $ONLINE == 1 ]; then
        printf "${GREEN}Host is online!${NC}\n"
    else
        printf "${YELLOW}Host seems offline. If you are sure that the host is online, omit -i option when running the script!${NC}\n"
        printf "${YELLOW}Skipping host ${HOSTS}${NC}\n"
        exit 1
    fi
fi

timeout $WAITPORT bash -c "echo >/dev/tcp/$HOSTS/$PORTS" &> /dev/null &&
printf "${BLUE}$HOSTS${NC}:${GREEN}$PORTS${NC} -> ${GREEN}[open]${NC}\n" ||
printf "${BLUE}$HOSTS${NC}:${RED}$PORTS${NC} -> ${RED}[closed]${NC}\n"
printf "done\n\n"
