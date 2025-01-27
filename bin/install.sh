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
FORCE=0
PORT=10000
DB_PORT=$((PORT + 1))

logo() {
echo " ______   _       _     ";
echo "|__  / | | |_   _| |__  ";
echo "  / /| |_| | | | | '_ \\ ";
echo " / /_|  _  | |_| | |_) |";
echo "/____|_| |_|\\__,_|_.__/ ";
echo ""
echo "Version: $VERSION"
}

show_help() {
  cat << EOF
Installation script for ZHub.
Version: $VERSION
Usage: $(basename "$0") [OPTION]

Options:
  -h,  --help                      Print this help
  -f,  --force                     Accept all warnings
  -v,  --verbose                   Enable verbose output
  -V,  --version                   Print the version of ZHub
  -p=<port>, --port=<port>         Specify the base port for ZHub (default: 10000)

Example:
  $(basename "$0") -v -f --port=12345
EOF
}

show_arg_error() {
  echo "Error: unrecognized argument(s): $1"
  echo "Usage: $(basename "$0") [OPTION]"
  echo "Try './$(basename "$0") --help' for more options."
  stop 1
}

parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        show_help
        stop 0
        ;;
      -f|--force)
        FORCE=1
        shift
        ;;
      -v|--verbose)
        VERBOSE=1
        shift
        ;;
      -V|--version)
        echo "ZHub Version: $VERSION"
        echo "Usage: $(basename "$0") [OPTION]"
        stop 0
        ;;
      -p=*|--port=*)
        PORT=${1#*=}
        if ! [[ $PORT =~ ^[0-9]+$ ]]; then
          stop 1 "Error: Invalid port value '$PORT'. Port must be a number."
        fi
        DB_PORT=$((PORT + 1))
        shift
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
  rm -rf "$DB_DIR" > /dev/null 2>&1
  sleep 1 # Wait for the directory to be deleted even though this doesn't make a lot of sense
  mkdir -p "$DB_DIR/logs" > /dev/null 2>&1 || stop 1 "Error creating DB/logs directory."

  ARCH=$(uname -m)

  if [[ "$OS" == "Linux" ]]; then
    case "$ARCH" in
      x86_64)
        MYSQL_URL="https://dev.mysql.com/get/Downloads/MySQL-9.1/mysql-9.2.0-linux-glibc2.28-x86_64.tar.xz"
        ;;
      aarch64)
        MYSQL_URL="https://dev.mysql.com/get/Downloads/MySQL-9.1/mysql-9.2.0-linux-glibc2.28-aarch64.tar.xz"
        ;;
      *)
        stop 1 "Error: Unsupported architecture: $ARCH"
        ;;
    esac
  elif [[ "$OS" == "Darwin" ]]; then
    case "$ARCH" in
      arm64)
        MYSQL_URL="https://dev.mysql.com/get/Downloads/MySQL-9.1/mysql-9.2.0-macos15-arm64.tar.gz"
        ;;
      x86_64)
        MYSQL_URL="https://dev.mysql.com/get/Downloads/MySQL-9.1/mysql-9.2.0-macos15-x86_64.tar.gz"
        ;;
      *)
        stop 1 "Error: Unsupported architecture: $ARCH"
        ;;
    esac
  else
    stop 1 "Error: Unsupported operating system: $OS"
  fi

  print "Downloading MySQL..."
  wget "$MYSQL_URL" -O "$DB_DIR/mysql.tar.gz" > /dev/null 2>&1

  print "Extracting MySQL..."
  tar -xJf "$DB_DIR/mysql.tar.gz" --strip-components=1 -C "$DB_DIR" || stop 1 "Error: Extraction of MySQL tar file failed."
  rm -rf "$DB_DIR/mysql.tar.gz" > /dev/null 2>&1

  print "Creating my.cnf..."
  cat > "$DB_DIR/my.cnf" <<EOF
[mysqld]
datadir=$DB_DIR/data
port=$DB_PORT
socket=$DB_DIR/mysql.sock
log-error=$DB_DIR/logs/error.log
general-log=1
general-log-file=$DB_DIR/logs/general.log
slow-query-log=1
slow-query-log-file=$DB_DIR/logs/slow.log
long_query_time=2

[client]
socket=$DB_DIR/mysql.sock
port=$DB_PORT
EOF

  print "Initializing MySQL..."
  if [[ $VERBOSE -eq 1 ]]; then
    "$DB_DIR/bin/mysqld" --defaults-file="$DB_DIR/my.cnf" --initialize-insecure || stop 1 "Error: MySQL initialization failed."
  else
    "$DB_DIR/bin/mysqld" --defaults-file="$DB_DIR/my.cnf" --initialize-insecure > /dev/null 2>&1 || stop 1 "Error: MySQL initialization failed."
  fi

  print "Starting MySQL..."
  if [[ $VERBOSE -eq 1 ]]; then
    ./start_db.sh
  else
    ./start_db.sh > /dev/null 2>&1
  fi

  MYSQL_USER=$(yq '.globals.db_user' "$ROOT_DIR/config.yaml")
  MYSQL_PASSWORD=$(yq '.globals.db_password' "$ROOT_DIR/config.yaml")
  print "Setting up MySQL user and password..."
  echo "CREATE USER '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';
  GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_USER'@'localhost' WITH GRANT OPTION;
  ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';
  FLUSH PRIVILEGES;" | "$DB_DIR/bin/mysql" --defaults-file="$DB_DIR/my.cnf" --user="root" --port="$DB_PORT" || stop 1 "Error: MySQL user setup failed."
}

initialize_ui() {
  # code here
  whoami > /dev/null 2>&1
}

install() {
  parse_arguments "$@"

  [ $FORCE -eq 0 ] && show_warning

  logo
  # start up the spinner if not verbose
  [ $VERBOSE -eq 0 ] && start_spinner
  # make sure everything is installed
  check_dependencies
  # config.yaml
  initialize_config
  # install & start MySQL
  initialize_mysql
  # install ui
  initialize_ui

  print "Installation Complete!"
  # stop the spinner
  [ $VERBOSE -eq 0 ] && stop_spinner "Installation Complete!"
}

install "$@"

# If everything goes to plan, exit 0
exit 0
