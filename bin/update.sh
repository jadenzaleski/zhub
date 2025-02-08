#!/bin/bash
#
# File: update.sh
# Created: 1/2/2025
# Author: Jaden Zaleski
#
# Description:
# An update script for ZHub.
#


source env.sh

VERBOSE=0
FORCE=0
UPDATE_BUILD=0
CALLED_BY_UPDATER=0

show_help() {
  cat << EOF
Update script for ZHub.
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
        UPDATE_BUILD=1
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
      -u|--updater)
        CALLED_BY_UPDATER=1
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
  if [[ $VERBOSE -eq 0 ]]; then
    stop_spinner "$2"
  else
    log "${@:2}" # all but the first one
  fi
  exit "$1"
}


check_for_update() {
  cd "$ROOT_DIR"/update || stop 1 "Error: Unable to navigate to update directory."
  if [[ $UPDATE_BUILD -eq 1 ]]; then
    curl -L "https://jadenzaleski.github.io/zhub/downloads/latest/build.tar.gz" -o "zhub-latest.tar.gz" > /dev/null 2>&1
  else
    curl -L "https://jadenzaleski.github.io/zhub/downloads/latest/release.tar.gz" -o "zhub-latest.tar.gz" > /dev/null 2>&1
  fi

  if [[ -f "zhub-latest.tar.gz" ]]; then
    if ! tar -xzf "zhub-latest.tar.gz" > /dev/null 2>&1; then
    stop 1 "Error: Failed to extract the downloaded tar.gz file."
    fi
    rm -f "zhub-latest.tar.gz"
  else
    stop 1 "Error: Unable to download the latest build/release."
  fi

  # Check if a new build or release is available
  if [[ -f "$ROOT_DIR"/update/BUILD && -f "$ROOT_DIR"/update/VERSION  ]]; then
    if [[ $FORCE -eq 1 ]]; then
      NEW_BUILD_NUMBER=$(cat "$ROOT_DIR"/update/BUILD)
      NEW_VERSION_NUMBER=$(cat "$ROOT_DIR"/update/VERSION)
      return 0 # update available
    fi

    if [[ $UPDATE_BUILD -eq 1 ]]; then
      if [[ $(cat "$ROOT_DIR"/update/BUILD) -gt $BUILD ]]; then
        NEW_BUILD_NUMBER=$(cat "$ROOT_DIR"/update/BUILD)
        NEW_VERSION_NUMBER=$(cat "$ROOT_DIR"/update/VERSION)
        return 0 # New build available
      else
        return 1 # No new build available
      fi
    else
      if [[ $(cat "$ROOT_DIR"/update/VERSION) -gt $VERSION ]]; then
        NEW_BUILD_NUMBER=$(cat "$ROOT_DIR"/update/BUILD)
        NEW_VERSION_NUMBER=$(cat "$ROOT_DIR"/update/VERSION)
        return 0 # New version available
      else
        return 1 # No new version available
      fi
    fi
  else
    stop 1 "Error: Unable to check the build/release version."
  fi
}

confirm_update() {
  if [[ $FORCE -eq 0 ]]; then
    stop_spinner "New version/build available!"
    printf "$BWHITE%-10s $BCYAN%-10s$BYELLOW → $BGREEN%+10s$COLOR_OFF\n" "Version:" "$VERSION" "$NEW_VERSION_NUMBER"
    printf "$BWHITE%-10s $BCYAN%-10s$BYELLOW → $BGREEN%+10s$COLOR_OFF\n" "Build:" "$BUILD" "$NEW_BUILD_NUMBER"
    read -r -p "Do you want to update to $NEW_VERSION_NUMBER ($NEW_BUILD_NUMBER)? [yes/no] " response
    if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
      [ $VERBOSE -eq 0 ] && start_spinner
      print "Updating to $NEW_VERSION_NUMBER ($NEW_BUILD_NUMBER)..."
    else
      stop 0 "Update cancelled."
    fi
  else
    print "Updating to $NEW_VERSION_NUMBER ($NEW_BUILD_NUMBER)..."
  fi
}

backup() {
  print "Creating backup..."
  mkdir -p "$BACKUPS_DIR"
  local date
  date=$(date +'%Y%m%d_%H%M%S')

  #rsync -a --exclude="$BACKUPS_DIR" --exclude=".git*" --exclude=".idea" "$ROOT_DIR"/ "$BACKUP_DIR"
  if [[ $VERBOSE -eq 1 ]]; then
    tar -cvzf "$BACKUPS_DIR/bak_$date.tar.gz" --exclude="$BACKUPS_DIR" --exclude=".git*" --exclude=".idea" --exclude="db" -C "$ROOT_DIR" .
    tar -cvzf "$BACKUPS_DIR/db_bak_$date.tar.gz" -C "$DB_DIR/" data
  else
    tar -czf "$BACKUPS_DIR/bak_$date.tar.gz" --exclude="$BACKUPS_DIR" --exclude=".git*" --exclude=".idea" --exclude="db" -C "$ROOT_DIR" . > /dev/null 2>&1
    tar -czf "$BACKUPS_DIR/db_bak_$date.tar.gz" -C "$DB_DIR/" data > /dev/null 2>&1
  fi

  print "Backup created."
}

call_update() {
  # After we have made the backup, we can now update the files
  print "Calling new update script..."
  [ $VERBOSE -eq 0 ] && stop_spinner
  exec cp update/bin/update.sh ./update.sh && chmod +x ./update.sh && ./update.sh "$@"
}

# Script process starts here:
parse_arguments "$@"

[ $VERBOSE -eq 0 ] && start_spinner

print "Checking dependencies..."
./check_dependencies.sh > /dev/null 2>&1

print "Creating update folder..."
rm -rf "$ROOT_DIR"/update
mkdir "$ROOT_DIR"/update > /dev/null 2>&1
cd "$ROOT_DIR"/update || stop 1 "Error: Unable to create update directory."

print "Checking for a newer version..."
if check_for_update; then
  confirm_update
else
  stop 0 "No new version available. On version: $VERSION ($BUILD)"
fi

print "Creating backup..."
backup

print "Updating..."
if [[ $CALLED_BY_UPDATER -eq 0 ]]; then
  call_update "$@" -u
fi

# Now that we are on the newest version of the script. do all the normal updates.
# we may just call install.sh here.
print "JADEN ZALESKI"

stop 0 "Update complete!"