#!/bin/bash
# Simple Port Scanner. I wrote that little script for environments where no netcat or other tools are available

function scanMe {
	printf "\033[0;33mThis script will check for open ports on one ore multiple remote hosts.\033[0m\n"
	printf "All Ports and Hosts have to be separated by a \033[0;33mSPACE\033[0m e.g. 80 443 25 110 ... \n"
	printf "\n"
	printf "Which Hosts do you want to scan? "
	read -a hosts
	printf "What Ports do you want to scan? "
	read -a ports
	printf "\n"

	if [[ $hosts == "" || $ports == "" ]]
	then
		printf "\033[0;33mHost or Port can't be empty!\033[0m\n"
		scanMe
	else
		for host in ${hosts[@]}
		do
			for port in ${ports[@]}
			do
   				portScan $host $port 2>/dev/null
			done
		done
		scanAgain
	fi
}

function portScan {
	host=$1
	port=$2
		# change timeout according to your environment/connection quality. Higher timeout takes longer but might be more precise!
		timeout 0.5 bash -c "echo >/dev/tcp/$host/$port" &&
		printf "$host:$port -> \033[0;32m[open]\033[0m\n" ||
		printf "$host:$port -> \033[0;31m[closed]\033[0m\n"
}

# returning to main menu if needed
function scanAgain {
	printf "\033[0;33m\nStart another scan? [Y/n]: \033[0m"
	read newScan
	if [[ $newScan == "y" || $newScan == "Y" ]]
	then
		scanMe
	else
		printf "Quitting\n"
		exit
	fi
}

scanMe

