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
PORT=10000
DB_PORT=$((PORT + 1))

show_help() {
  cat << EOF
Installation script for ZHub.
Version: $VERSION
Usage: $(basename "$0") [OPTION]

Options:
  -h,  --help                      Print this help
  -v,  --verbose                   Enable verbose output
  -V,  --version                   Print the version of ZHub
  -p,  --port <port>               Specify the base port for ZHub (default: 10000)

Example:
  $(basename "$0") -v --port 12345
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
      -p|--port)
        if [[ -n "$2" && ! "$2" =~ ^- ]]; then
          PORT=$2
          DB_PORT=$((PORT + 1))
          shift 2
        else
          echo "Error: -p,--port requires a value."
          exit 1
        fi
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

initialize_config() {
  print "Creating config.yaml..."
  rm -f "$ROOT_DIR/config.yaml" > /dev/null 2>&1
  touch "$ROOT_DIR/config.yaml"
  print "config.yaml has been created."

  yq eval '.globals.port = '$PORT'' -i "$ROOT_DIR/config.yaml"
  yq eval '.globals.dbPort = '$DB_PORT'' -i "$ROOT_DIR/config.yaml"
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
  initialize_config

  # MySQL
  print "Installing MySQL..."
  rm -rf "$DB_DIR" > /dev/null 2>&1
  mkdir "$ROOT_DIR/db" > /dev/null 2>&1 || stop 1 "Error creating DB directory."

  if [ "$OS" == "Linux" ]; then
    MYSQL_URL="https://dev.mysql.com/get/Downloads/MySQL-9.1/mysql-9.1.0-linux-glibc2.28-aarch64.tar.xz"
  elif [ "$OS" == "Darwin" ]; then
    MYSQL_URL="https://dev.mysql.com/get/Downloads/MySQL-9.1/mysql-9.1.0-macos14-arm64.tar.gz"
  else
    stop 1 "Error: Unsupported operating system: $OS"
  fi
  # Download MySQL
  print "Downloading MySQL..."
  wget "$MYSQL_URL" -O "$DB_DIR/mysql.tar.gz" > /dev/null 2>&1
  # Extract it
  print "Extracting MySQL..."
  tar -xzf "$DB_DIR/mysql.tar.gz" --strip-components=1 -C "$DB_DIR" || stop 1
  # Remove it
  rm -rf "$DB_DIR/mysql.tar.gz" > /dev/null 2>&1
  # initialize
#  print "Initializing MySQL..."
#  "$DB_DIR/bin/mysqld" --initialize --user=mysql --basedir="$DB_DIR" --datadir="$DB_DIR/data" --port="$DB_PORT"
#  # start MySQL
#  print "Starting MySQL..."
#  source start_db.sh
#  # secure install
#  print "Running secure MySQ install..."
#  "$DB_DIR/bin/mysql_secure_installation --port="$DB_PORT""


  # start up ui

  [ $VERBOSE -eq 0 ] && stop_spinner "Installation Complete!"
}

install "$@"
