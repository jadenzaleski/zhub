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
  [ $VERBOSE -eq 0 ] && stop_spinner "$2"
  exit "$1"
}

show_warning() {
  printf "${BYELLOW}Warning: ${BWHITE}%s${COLOR_OFF}\n" "This script will rewrite most files in ZHub."
  echo "It is recommended you make a backup of any file or folder you wish to keep."
  echo "Your apps directory will not be touched."
  printf "%s" "Would you like to continue? [yes/no]: "

  # Read user input
  read -r response
  response=$(echo "$response" | tr '[:upper:]' '[:lower:]') # Convert to lowercase

  # Check the response
  if [[ "$response" == "yes" || "$response" == "y" ]]; then
    return
  elif [[ "$response" == "no" || "$response" == "n" ]]; then
    echo "Exiting the script."
    exit 1
  else
    echo "Invalid input. Please enter 'yes' or 'no'."
    show_warning
  fi
}

install() {
  parse_arguments "$@"
  show_warning
  [ $VERBOSE -eq 0 ] && start_spinner

  print "Checking dependencies..."
  if [ $VERBOSE -eq 0 ]; then
    ./check_dependencies.sh -s || stop 1
  elif [ $VERBOSE -eq 1 ]; then
    ./check_dependencies.sh || stop 1
  else
    stop 1 "Invalid verbosity level."
  fi
  print "Found all dependencies."

  print "Installing yq..."
  # Remove the old version if it exists (optional, for a truly fresh install)
  rm -f "$BIN_DIR/yq" > /dev/null 2>&1
  # Download and install the latest version of yq
  if [ "$OS" == "Linux" ]; then
    YQ_URL="https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64"
  elif [ "$OS" == "Darwin" ]; then
    YQ_URL="https://github.com/mikefarah/yq/releases/latest/download/yq_darwin_amd64"
  else
    stop 1 "Error: Unsupported operating system: $OS"
  fi
  wget "$YQ_URL" -O "$BIN_DIR/yq" > /dev/null 2>&1 && \
  chmod +x "$BIN_DIR/yq" > /dev/null 2>&1
  # Verify if installation was successful
  if command -v yq &> /dev/null; then
    print "yq installed successfully."
  else
    stop 1 "Error: yq installation failed."
  fi

  # config.yaml
  print "Creating config.yaml..."
  rm -f "$ROOT_DIR/config.yaml" > /dev/null 2>&1
  touch config.yaml
  print "config.yaml has been created."



  [ $VERBOSE -eq 0 ] && stop_spinner "Complete!"
}

install "$@"
