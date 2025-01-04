#!/bin/bash
#
# File: env.sh
# Created: 1/3/2025
# Author: jaden
#
# Description:
# A file that will write all globals to the current scope.
#


# Redefine printf to include the prefix with filename and date
log() {
  filename="$(basename "$0")"
  datetime=$(date "+%H:%M:%S")
  milliseconds=$(date "+%N" | head -c 3)
  datetime="$datetime.$milliseconds"
  prefix="$filename | $datetime |"

  printf "$prefix %b\n" "$*"
}
export -f log

ROOT_DIR="$(cd .. && pwd)"
export ROOT_DIR
#log "ROOT_DIR: $ROOT_DIR"

BIN_DIR="$(cd ../bin && pwd)"
export BIN_DIR
#log "BIN_DIR: $BIN_DIR"

VERSION="$(cat "$ROOT_DIR"/VERSION)"
export VERSION
#log "VERSION: $VERSION"

# --- COLORS ---
# Reset
COLOR_OFF='\033[0m'       # Text Reset
export COLOR_OFF
# Regular Colors
BLACK='\033[0;30m'        # Black
RED='\033[0;31m'          # Red
GREEN='\033[0;32m'        # Green
YELLOW='\033[0;33m'       # Yellow
BLUE='\033[0;34m'         # Blue
PURPLE='\033[0;35m'       # Purple
CYAN='\033[0;36m'         # Cyan
WHITE='\033[0;37m'        # White
export BLACK RED GREEN YELLOW BLUE PURPLE CYAN WHITE
# Bold
BBLACK='\033[1;30m'       # Black
BRED='\033[1;31m'         # Red
BGREEN='\033[1;32m'       # Green
BYELLOW='\033[1;33m'      # Yellow
BBLUE='\033[1;34m'        # Blue
BPURPLE='\033[1;35m'      # Purple
BCYAN='\033[1;36m'        # Cyan
BWHITE='\033[1;37m'       # White
export BBLACK BRED BGREEN BYELLOW BBLUE BPURPLE BCYAN BWHITE
# Background
ON_BLACK='\033[40m'       # Black
ON_RED='\033[41m'         # Red
ON_GREEN='\033[42m'       # Green
ON_YELLOW='\033[43m'      # Yellow
ON_BLUE='\033[44m'        # Blue
ON_PURPLE='\033[45m'      # Purple
ON_CYAN='\033[46m'        # Cyan
ON_WHITE='\033[47m'       # White
export ON_BLACK ON_RED ON_GREEN ON_YELLOW ON_BLUE ON_PURPLE ON_CYAN ON_WHITE
# Color test
log "$ON_RED  $ON_GREEN  $ON_YELLOW  $ON_BLUE  $ON_PURPLE  $ON_CYAN  $ON_WHITE  $ON_BLACK  $COLOR_OFF"
# --- END OF COLORS ---

