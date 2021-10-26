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
${NC}This script will scan hosts for open tcp ports.
    ${YELLOW}-h${BLUE} To show this message.
    ${YELLOW}-t${BLUE} Host(s) to scan. For multiple hosts use commas (e.g. 192.168.0.1,192.168.0.2,etc.)
    ${YELLOW}-p${BLUE} Port(s) to scan. For multiple ports use commas (e.g. 80,8080,443,8443,etc.)
    ${YELLOW}-i${BLUE} Use ping before scanning a host - this will test if the host is reachable via ICMP (might generate false-positives if a firewall blocks ICMP)
    ${YELLOW}-w${BLUE} Wait time before the script will mark a port as closed (default 0.5) - this should be changed accordingly to the network quality
    ${YELLOW}-q${BLUE} Quiet mode, dont show closed ports"

WAITPORT=0.5
WAITICMP=3
ICMP="false"
QUIET="false"
OPENPORTS=0
CLOSEDPORTS=0
ONLINEHOSTS=0
OFFLINEHOSTS=0

OPTION='h?t:p:iw:q'

# fix the errors and all together argument handling
while getopts $OPTION flag; do
    case "${flag}" in
        h  ) printf "%s\n\n" "$HELP$NC" >&2; exit 1;;
        t  ) HOSTS="${OPTARG}";;
        p  ) PORTS="${OPTARG}";;
        i  ) ICMP="true";;
        w  ) WAITPORT="${OPTARG}";;
	    q  ) QUIET="true";;
        \? ) printf "${RED}Unknown option: -%s\n" "$OPTARG$NC" >&2; printf "%s\n\n" "$HELP$NC" >&2; exit 1;;
        :  ) printf "${YELLOW}Missing option argument for -%s\n" "$OPTARG$NC" >&2; printf "%s\n\n" "$HELP$NC" >&2; exit 1;;
        *  ) printf "${YELLOW}Unimplemented option: -%2\n" "$OPTARG$NC" >&2; printf "%s\n\n" "$HELP$NC" >&2; exit 1;;
    esac
done


# functions
scanMe () {
    host=$1
    port=$2
    
    if [ $QUIET == "true" ]; then
        timeout $WAITPORT bash -c "echo >/dev/tcp/$host/$port" 2> /dev/null &&
        printf "${BLUE}$host${NC}:${GREEN}$port${NC} -> ${GREEN}[open]${NC}\n" && OPENPORTS=$((OPENPORTS+1)) ||
        echo "closed" > /dev/null && CLOSEDPORTS=$((CLOSEDPORTS+1))
    else
    	timeout $WAITPORT bash -c "echo >/dev/tcp/$host/$port" 2> /dev/null &&
    	printf "${BLUE}$host${NC}:${GREEN}$port${NC} -> ${GREEN}[open]${NC}\n" && OPENPORTS=$((OPENPORTS+1)) ||
    	printf "${BLUE}$host${NC}:${RED}$port${NC} -> ${RED}[closed]${NC}\n" && CLOSEDPORTS=$((CLOSEDPORTS+1))
    fi
}

# mandatory arguments
if [ $HOSTS ] && [ $PORTS ]; then
    IFS=',' read -r -a hostArray <<< "$HOSTS"
    for host in "${hostArray[@]}"
    do
        printf "Scanning Host: ${BLUE}%s${NC}\n" "$host"
        if [ $ICMP == "true" ]; then
	       if [ $host == *":"* ]; then
                timeout $WAITICMP bash -c "ping6 -c 1 $host" &> /dev/null &&
                ONLINE="true" || ONLINE="false" 

                if [ $ONLINE == "true" ]; then
                    TTL=$(ping6 -c 1 $host | grep -oP '(?<=ttl=)[^ ]*')
                    printf "${BLUE}%s${GREEN} is online! -> TTL=%s${NC}\n" "$host" "$TTL"
                elif [ $ONLINE == "false" && $QUIET == "true" ]; then
                    printf "${YELLOW}Skipping Host (${RED}offline${YELLOW}): ${BLUE}%s${NC}\n\n" "$host"
                    OFFLINEHOSTS=$((OFFLINEHOSTS+1))
                    continue
                else
                    # create prompt here if offline host should be scanned anyway
                    printf "${YELLOW}Host seems offline. If you are sure that the host is online, omit -i option when running the script${NC}\n"
                    printf "${YELLOW}Do you want to scan the host anyway? [y\\N] ${NC}"
                    read -p "" offlineHost

                    if [ $offlineHost == "y" ] || [ $offlineHost == "Y" ]; then
                        printf "Scanning Host: ${BLUE}%s${NC}\n" "$host"
                    else
                        printf "${YELLOW}Skipping Host (${RED}offline${YELLOW}): ${BLUE}%s${NC}\n\n" "$host"
                        OFFLINEHOSTS=$((OFFLINEHOSTS+1))
                        continue 
                    fi
                fi
            else
                timeout $WAITICMP bash -c "ping -c 1 $host" &> /dev/null &&
                ONLINE="true" || ONLINE="false"

                if [ $ONLINE == "true" ]; then
                    TTL=$(ping -c 1 $host | grep -oP '(?<=ttl=)[^ ]*')
                    printf "${BLUE}%s${GREEN} is online! -> TTL=%s${NC}\n" "$host" "$TTL"
                elif [ $ONLINE == "false" ] && [ $QUIET == "true" ]; then
                    printf "${YELLOW}Skipping Host (${RED}offline${YELLOW}): ${BLUE}%s${NC}\n\n" "$host"
                    OFFLINEHOSTS=$((OFFLINEHOSTS+1))
                    continue
                else
                    # create prompt here if offline host should be scanned anyway
                    printf "${YELLOW}Host seems offline. If you are sure that the host is online, omit -i option when running the script${NC}\n"
                    printf "${YELLOW}Do you want to scan the host anyway? [y/N] ${NC}"
                    read -p "" offlineHost

                    if [ $offlineHost == "y" ] || [ $offlineHost == "Y" ]; then
                        printf "Scanning Host: ${BLUE}%s${NC}\n" "$host"
                    else
                        printf "${YELLOW}Skipping Host (${RED}offline${YELLOW}): ${BLUE}%s${NC}\n\n" "$host"
                        OFFLINEHOSTS=$((OFFLINEHOSTS+1))
                        continue 
                    fi
                fi
            fi
        fi
        ONLINEHOSTS=$((ONLINEHOSTS+1))
        
        IFS=',' read -r -a portArray <<< "$PORTS"
        for port in "${portArray[@]}"
        do
            if [ $port -lt 1 ] || [ $port -gt 65535 ]; then
                printf "Port is invalid: ${RED}%s${NC}\n" "$port"
                continue
            else
                scanMe "$host" "$port"
            fi
        done
        printf "\n"
    done
    
    printf "\nSummary of the scan:\n"
    printf "Scanned hosts: ${YELLOW}$ONLINEHOSTS${NC}\n"
    printf "Skipped hosts: ${YELLOW}$OFFLINEHOSTS${NC}\n"
    printf "Open ports: ${GREEN}$OPENPORTS${NC}\n"
    printf "Closed ports: ${RED}$CLOSEDPORTS${NC}\n"
elif [ ! $HOSTS]; then
        printf "${RED}You have to specify at least one destination host!${NC}\n"
        exit 1
else
        printf "${RED}You have to specify at least one destination port!${NC}\n"
        exit 1
fi
