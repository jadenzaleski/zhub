#!/bin/bash
#
# File: start_db.sh
# Created: 1/11/2025
# Author: Jaden Zaleski
#
# Description:
# Start the MySQL server. Make sure it is initialized first.
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

# Check if MySQL is already running
echo "Checking if MySQL is running on port $MYSQL_PORT..."
if "$DB_DIR/bin/mysqladmin" --port="$MYSQL_PORT" ping --silent; then
    echo "MySQL is already running on port $MYSQL_PORT."
else
    echo "Starting MySQL on port $MYSQL_PORT..."
    # Start MySQL with the specified port
    "$DB_DIR/bin/mysqld" --user="$MYSQL_USER" --basedir="$DB_DIR" --datadir="$DB_DIR/data" --port="$MYSQL_PORT" &

    # Wait for MySQL to be ready
    echo "Waiting for MySQL..."
    while ! "$DB_DIR/bin/mysqladmin" --port="$MYSQL_PORT" ping --silent; do
        sleep 1
        TIMEOUT=$((TIMEOUT + 1))
        # Check if timeout has reached 60 seconds
        if [ "$TIMEOUT" -ge 30 ]; then
            echo "Error: MySQL did not start within 30 seconds."
            exit 1
        fi
    done
    echo "MySQL is up and running on port $MYSQL_PORT."
fi