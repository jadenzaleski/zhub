#!/bin/bash
#
# File: stop_db.sh
# Created: 1/11/2025
# Author: Jaden Zaleski
#
# Description:
# Stop the MySQL server if it is running.
#

source env.sh

TIMEOUT=0
# Attempt to retrieve the db_port, user, and password values using yq
MYSQL_PORT=$(yq '.globals.db_port' "$ROOT_DIR/config.yaml")
MYSQL_USER=$(yq '.globals.db_user' "$ROOT_DIR/config.yaml")
MYSQL_PASSWORD=$(yq '.globals.db_password' "$ROOT_DIR/config.yaml")

# Check if yq command succeeded and if any of the variables are empty or 'null'
if [[ $? -ne 0 || "$MYSQL_PORT" == "null" || "$MYSQL_USER" == "null" || "$MYSQL_PASSWORD" == "null" || -z "$MYSQL_PORT" || -z "$MYSQL_USER" || -z "$MYSQL_PASSWORD" ]]; then
  echo "Error: Failed to retrieve one or more values ('db_port', 'db_user', 'db_password') from config.yaml"
  exit 1
fi
# Check if MySQL is running
echo "Checking if MySQL is running on port $MYSQL_PORT..."
if "$DB_DIR/bin/mysqladmin" --port="$MYSQL_PORT" ping --silent; then
    echo "Stopping MySQL on port $MYSQL_PORT..."

    # Try to gracefully stop MySQL server
    shutdown_output=$("$DB_DIR/bin/mysqladmin" --user="$MYSQL_USER" --password="$MYSQL_PASSWORD" --port="$MYSQL_PORT" shutdown 2>&1)
    shutdown_exit_code=$?

    if [[ $shutdown_exit_code -ne 0 ]]; then
        echo "Error: $shutdown_output"
        exit 1  # Exit with error code if shutdown fails
    fi

     # Wait for MySQL to completely shut down
    echo "Waiting for MySQL to shut down..."
    while "$DB_DIR/bin/mysqladmin" --port="$MYSQL_PORT" ping --silent; do
        sleep 1
        TIMEOUT=$((TIMEOUT + 1))
        # Check if timeout has reached 60 seconds
        if [ "$TIMEOUT" -ge 30 ]; then
            echo "Error: MySQL did not stop within 30 seconds."
            exit 1
        fi
    done

    echo "MySQL has been stopped."
    exit 0
else
    echo "MySQL is not running on port $MYSQL_PORT."
    exit 0  # Exit with 0 if MySQL is not running
fi