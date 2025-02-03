#!/bin/bash
#
# File: env.sh
# Created: 1/3/2025
# Author: jaden
#
# Description:
# A file that will write all globals to the current scope.
# This should not be used as a configuration file.
#

ROOT_DIR="$(cd .. && pwd)"
export ROOT_DIR

BIN_DIR="$(cd ../bin && pwd)"
export BIN_DIR

export PATH=$PATH:$BIN_DIR

VERSION="$(cat "$ROOT_DIR"/VERSION)"
export VERSION

BUILD="$(cat "$ROOT_DIR"/BUILD)"
export BUILD

OS=$(uname -s)
export OS

DB_DIR="$ROOT_DIR/db"
export DB_DIR

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
#log "$ON_RED  $ON_GREEN  $ON_YELLOW  $ON_BLUE  $ON_PURPLE  $ON_CYAN  $ON_WHITE  $ON_BLACK  $COLOR_OFF"
# --- END OF COLORS ---

# Redefine printf to include the prefix with filename and date
log() {
  local filename
  filename="$(basename "$0")"
  local datetime;
  datetime=$(date "+%H:%M:%S")
  prefix="$filename | $datetime |"

  printf "$prefix %b\n" "$*"
}
export -f log

# Function to run the spinner
spinner() {
#  local states=("⣾" "⣽" "⣻" "⢿" "⡿" "⣟" "⣯" "⣷")
#  local states=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█" "▇" "▆" "▅" "▄" "▃" "▂" "▁")
#  local states=("▉" "▊" "▋" "▌" "▍" "▎" "▏" "▎" "▍" "▌" "▋" "▊" "▉")
  local states=("" "" "" "" "" "" "" "" "" "" "" "" "" "" ""
                "" "" "" "" "" "" "" "" "" "" "" "" ""
                "" "" "" "" "" "" "" "" "" "" "" "" ""
                "" "" "" "" "" "" "" "" "" "" "" "" "" "" "")

  while true; do
    # Instead of process substitution, just use a simple `cat` to read the file
    status_text=$(cat "$STATUS_TEXT_FILE")
    for state in "${states[@]}"; do
      # Clear both lines: the spinner line and the blank line
      printf "\033[2K"
      printf "\r$CYAN$state$COLOR_OFF %s\n" "$status_text"
      # Print a blank line on the second line
      printf "\033[2K\033[A"
      sleep 0.05
    done
  done
}

update_spinner() {
  if [[ ! -f "$STATUS_TEXT_FILE" ]]; then
    log "Warning: Update spinner called but spinner not started."
    return 1
  fi

  printf "%s\n" "$1" > "$STATUS_TEXT_FILE"
}

start_spinner() {
  # Create a temporary file to store the status text
  STATUS_TEXT_FILE=$(mktemp)
  printf "" > "$STATUS_TEXT_FILE"
  spinner &
  SPINNER_PID=$!
  printf "\033[?25l" # Hide the cursor
}

# Trap SIGINT (Ctrl+C) to clean up the spinner
trap 'stop_spinner; exit 1' SIGINT

stop_spinner() {
  printf "\033[2K%s" "$1"
  kill "$SPINNER_PID" 2>/dev/null
  wait "$SPINNER_PID" 2>/dev/null
  rm -f "$STATUS_TEXT_FILE"
  printf "\033[?25h" # Show the cursor
  echo
}

export -f spinner start_spinner stop_spinner update_spinner
