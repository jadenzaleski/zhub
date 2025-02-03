#!/bin/bash
#
# File: upgrade.sh
# Created: 1/2/2025
# Author: Jaden Zaleski
#
# Description:
# An upgrade script for ZHub.
#


source env.sh

VERBOSE=0
FORCE=0
UPGRADE_BUILD=0

show_help() {
  cat << EOF
Upgrade script for ZHub.
Version: $VERSION
Usage: $(basename "$0") [OPTION]

Options:
  -b,  --build                     Get the latest build instead of latest release
  -h,  --help                      Print this help
  -f,  --force                     Accept all warnings
  -v,  --verbose                   Enable verbose output
Example:
  $(basename "$0") -v -f
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
      -b|--build)
        UPGRADE_BUILD=1
        shift
        ;;
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


check_for_update() {
  cd "$ROOT_DIR"/upgrade || stop 1 "Error: Unable to navigate to upgrade directory."
  if [[ $UPGRADE_BUILD -eq 1 ]]; then
    curl -L "https://jadenzaleski.github.io/zhub/downloads/latest/build" -o "zhub-latest.tar.gz" > /dev/null 2>&1
  else
    curl -L "https://jadenzaleski.github.io/zhub/downloads/latest/release" -o "zhub-latest.tar.gz" > /dev/null 2>&1
  fi

  if [[ -f "zhub-latest.tar.gz" ]]; then
    tar -xzf "zhub-latest.tar.gz"
    rm -f "zhub-latest.tar.gz"
  else
    stop 1 "Error: Unable to download the latest build/release."
  fi

  # Check if a new build or release is available
  if [[ -f "$ROOT_DIR"/upgrade/BUILD && -f "$ROOT_DIR"/upgrade/VERSION ]]; then
    if [[ $UPGRADE_BUILD -eq 1 ]]; then
      if [[ $(cat "$ROOT_DIR"/upgrade/BUILD) -gt $BUILD ]]; then
        NEW_BUILD_NUMBER=$(cat "$ROOT_DIR"/upgrade/BUILD)
        NEW_VERSION_NUMBER=$(cat "$ROOT_DIR"/upgrade/VERSION)
        return 0 # New build available
      else
        return 1 # No new build available
      fi
    else
      if [[ $(cat "$ROOT_DIR"/upgrade/VERSION) -gt $VERSION ]]; then
        NEW_BUILD_NUMBER=$(cat "$ROOT_DIR"/upgrade/BUILD)
        NEW_VERSION_NUMBER=$(cat "$ROOT_DIR"/upgrade/VERSION)
        return 0 # New version available
      else
        return 1 # No new version available
      fi
    fi
  else
    stop 1 "Error: Unable to check the build version."
  fi


}

confirm_update() {
  if [[ $FORCE -eq 0 ]]; then
    stop_spinner "New version/build available!"
    echo "Version: $VERSION → $NEW_VERSION_NUMBER"
    echo "Build: $BUILD → $NEW_BUILD_NUMBER"
    read -r -p "Do you want to upgrade to $NEW_VERSION_NUMBER ($NEW_BUILD_NUMBER)? [yes/no] " response
    if [[ $response =~ ^([yY][eE][sS]|[yY]|)$ ]]; then
      [ $VERBOSE -eq 0 ] && start_spinner
      print "Updating to $NEW_VERSION_NUMBER ($NEW_BUILD_NUMBER)..."
    else
      stop 0 "Update cancelled."
    fi
  else
    print "Updating to $NEW_VERSION_NUMBER ($NEW_BUILD_NUMBER)..."
  fi
}

# Script process starts here:
parse_arguments "$@"

[ $VERBOSE -eq 0 ] && start_spinner

print "Checking dependencies..."
./check_dependencies.sh > /dev/null 2>&1

print "Creating upgrade folder..."
rm -rf "$ROOT_DIR"/upgrade
mkdir "$ROOT_DIR"/upgrade > /dev/null 2>&1
cd "$ROOT_DIR"/upgrade || stop 1 "Error: Unable to create upgrade directory."

print "Checking for a newer version..."
if check_for_update; then
  confirm_update
else
  print "No new version available."
fi

stop 0 "Upgrade complete!"