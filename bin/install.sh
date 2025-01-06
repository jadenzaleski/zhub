#!/bin/bash
#
# File: install.sh
# Created: 1/2/2025
# Author: Jaden Zaleski
#
# Description:
# An installation script for ZHub.
#

source env.sh
VERBOSE=0

show_help() {
  cat << EOF
Installation script for ZHub.
Version: $VERSION
Usage: $(basename "$0") [OPTION]

Options:
  -h,  --help                      Print this help
  -v,  --verbose                   Enable verbose output
  -V,  --version                   Print the version of ZHub

Example:
  $(basename "$0") -v
EOF
}

show_arg_error() {
  echo "Error: unrecognized argument(s): $1"
  echo "Usage: $(basename "$0") [OPTION]"
  echo "Try './$(basename "$0") --help' for more options."
  exit 1
}

parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -a|--all)
        # install all applications
        shift
        ;;
      -h|--help)
        show_help
        exit 0
        ;;
      -v|--verbose)
        VERBOSE=1
        shift
        ;;
      -V|--version)
        echo "ZHub Version: $VERSION"
        echo "Usage: $(basename "$0") [OPTION]"
        exit 0
        ;;
      -*)
        show_arg_error "$1"
        ;;
      *)
        show_arg_error "$1"
        ;;
    esac
  done
}

print() {
  if [[ $VERBOSE -eq 1 ]]; then
    log "$@"
  else
    update_spinner "$@"
  fi
}

stop() {
  [ $VERBOSE -eq 0 ] && stop_spinner
  exit "$1"
}

install() {
  parse_arguments "$@"
  [ $VERBOSE -eq 0 ] && start_spinner

  print "Checking dependencies..."
  ./check_dependencies.sh -s || stop 1
  print "Found all dependencies."

  sleep 2  # Simulate step 1
  print "Extracting files..."
  sleep 2  # Simulate step 2
  print "Installing..."
  sleep 2  # Simulate step 3
  print "Finishing installation..."
  sleep 2  # Simulate step 4
  [ $VERBOSE -eq 0 ] && stop_spinner
  echo "Installation complete!"
}

install "$@"
