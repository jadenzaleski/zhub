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

check_new_build() {
  curl -s "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/actions/workflows/${CD_WORKFLOW}/runs?status=success" -o cd_workflow_runs.json
  ARTIFACT_ID=$(jq -r '.workflow_runs[0].id' cd_workflow_runs.json)

  curl -s "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/actions/runs/${ARTIFACT_ID}/artifacts" -o build_artifacts.json
  ARTIFACT_URL=$(jq -r '.artifacts[0].archive_download_url' build_artifacts.json)

  curl -L -o "zhub-latest.tar.gz" "${ARTIFACT_URL}"
}

check_new_release() {
  whoami > /dev/null 2>&1
}

# Script process starts here:
parse_arguments "$@"
./check_dependencies.sh

rm -rf "$ROOT_DIR"/upgrade

mkdir "$ROOT_DIR"/upgrade >/dev/null 2>&1
cd "$ROOT_DIR"/upgrade || stop 1 "Error: Unable to create upgrade directory."



if [[ $UPGRADE_BUILD -eq 1 ]]; then
  check_new_build
else
  check_new_release
fi

exit 0;