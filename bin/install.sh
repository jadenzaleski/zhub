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
  printf "${BYELLOW}Warning: ${BWHITE}%s${COLOR_OFF}\n" "This script will rewrite most files in ZHub (if already installed)."
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

check_dependencies() {
    print "Checking dependencies..."
  if [ $VERBOSE -eq 0 ]; then
    ./check_dependencies.sh -s || stop 1
  elif [ $VERBOSE -eq 1 ]; then
    ./check_dependencies.sh || stop 1
  else
    stop 1 "Invalid verbosity level."
  fi
  print "Found all dependencies."
}

initialize_config() {
  print "Creating config.yaml..."
  rm -f "$ROOT_DIR/config.yaml" > /dev/null 2>&1
  touch "$ROOT_DIR/config.yaml"
  print "config.yaml has been created."

  yq eval '.globals.version = "'$VERSION'"' -i "$ROOT_DIR/config.yaml"
  yq eval '.globals.port = '$PORT'' -i "$ROOT_DIR/config.yaml"
  yq eval '.globals.db_port = '$DB_PORT'' -i "$ROOT_DIR/config.yaml"
  yq eval '.globals.root_directory = "'$ROOT_DIR'"' -i "$ROOT_DIR/config.yaml"
  yq eval '.globals.bin_directory = "'$BIN_DIR'"' -i "$ROOT_DIR/config.yaml"
  yq eval '.globals.db_user = "zhub"' -i "$ROOT_DIR/config.yaml"
  yq eval '.globals.db_password = "password"' -i "$ROOT_DIR/config.yaml"
}

initialize_mysql() {
  print "Installing MySQL..."
  rm -rf "$DB_DIR" > /dev/null 2>&1
  mkdir "$DB_DIR" > /dev/null 2>&1 || stop 1 "Error creating DB directory."

  if [ "$OS" == "Linux" ]; then
    MYSQL_URL="https://dev.mysql.com/get/Downloads/MySQL-9.1/mysql-9.1.0-linux-glibc2.28-aarch64.tar.xz"
  elif [ "$OS" == "Darwin" ]; then
    MYSQL_URL="https://dev.mysql.com/get/Downloads/MySQL-9.1/mysql-9.1.0-macos14-arm64.tar.gz"
  else
    stop 1 "Error: Unsupported operating system: $OS"
  fi

  print "Downloading MySQL..."
  wget "$MYSQL_URL" -O "$DB_DIR/mysql.tar.gz" > /dev/null 2>&1

  print "Extracting MySQL..."
  tar -xzf "$DB_DIR/mysql.tar.gz" --strip-components=1 -C "$DB_DIR" || stop 1 "Error: Extraction of MySQL tar file failed."
  rm -rf "$DB_DIR/mysql.tar.gz" > /dev/null 2>&1

  print "Initializing MySQL..."
  "$DB_DIR/bin/mysqld" --initialize-insecure --user=mysql --basedir="$DB_DIR" --datadir="$DB_DIR/data" --port="$DB_PORT" || stop 1 "Error: MySQL initialization failed."

#  print "Starting MySQL in safe mode..."
#  "$DB_DIR/bin/mysqld_safe" --datadir="$DB_DIR/data" --port="$DB_PORT" &
#  MYSQL_SAFE_PID=$!
#
#  print "Waiting for MySQL to be ready..."
#  until "$DB_DIR/bin/mysqladmin" ping --socket="$DB_DIR/mysql.sock" --port="$DB_PORT" --silent; do
#    sleep 1
#  done
  print "Starting MySQL..."
  ./start_db.sh

  MYSQL_USER=$(yq '.globals.db_user' "$ROOT_DIR/config.yaml")
  MYSQL_PASSWORD=$(yq '.globals.password' "$ROOT_DIR/config.yaml")
  # Create a SQL script to set up users and passwords
  print "Setting up MySQL user and password..."
  echo "CREATE USER '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';
  GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_USER'@'localhost' WITH GRANT OPTION;
  ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';
  FLUSH PRIVILEGES;" | "$DB_DIR/bin/mysql" --user="root" --port="$DB_PORT" || stop 1 "Error: MySQL user setup failed."
}

install_ui() {
  # code here
  whoami > /dev/null 2>&1
}

install() {
  parse_arguments "$@"

  show_warning
  # start up the spinner if not verbose
  [ $VERBOSE -eq 0 ] && start_spinner
  # make sure everything is installed
  check_dependencies
  # config.yaml
  initialize_config
  # install & start MySQL
  initialize_mysql
  # install ui
  install_ui

  # start ui

  # stop the spinner
  [ $VERBOSE -eq 0 ] && stop_spinner "Installation Complete!"
}

install "$@"
