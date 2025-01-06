#!/bin/bash
#
# File: check_dependencies.sh
# Created: 1/5/2025
# Author: Jaden Zaleski
#
# Description:
# Script to sure we have all the dependencies we need to run all script files.
#
# Usage:
# ./check_dependencies.sh [OPTION]
# Options:
# -s, for silent output.
#

source ./env.sh

# List of commands to check
commands=("wget" "npm" "git" "tar" "gzip" "touch")
# Array to store missing commands
missing_commands=()


# Loop through each command and check if it is installed
for cmd in "${commands[@]}"; do
    if command -v "$cmd" &> /dev/null; then
      [[ ! "$*" == *"-s"* ]] && printf "${GREEN} %s$COLOR_OFF\n" "$cmd"
    else
      [[ ! "$*" == *"-s"* ]] && printf "${RED} %s$COLOR_OFF\n" "$cmd"
      missing_commands+=("$cmd")
    fi
done

# If there are missing commands, print them
if [ ${#missing_commands[@]} -gt 0 ]; then
    echo "Please install the following programs:"
    for missing in "${missing_commands[@]}"; do
        echo "- $missing"
    done
    exit 1
else
    [[ ! "$*" == *"-s"* ]] && echo "All dependencies found!"
    exit 0
fi