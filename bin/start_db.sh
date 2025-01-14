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

# Attempt to retrieve the db_port value using yq
MYSQL_PORT=$(yq '.globals.db_port' "$ROOT_DIR/config.yaml")

# Check if yq command succeeded
if [[ $? -ne 0 || -z "$MYSQL_PORT" ]]; then
  echo "Error: Failed to retrieve 'db_port' from config.yaml"
  exit 1
fi

# Check if MySQL is already running
echo "Checking if MySQL is running on port $MYSQL_PORT..."
if "$DB_DIR/bin/mysqladmin" --port="$MYSQL_PORT" ping --silent; then
    echo "MySQL is already running on port $MYSQL_PORT."
else
    echo "Starting MySQL on port $MYSQL_PORT..."
    # Start MySQL with the specified port
    "$DB_DIR/bin/mysqld" --user=mysql --basedir="$DB_DIR" --datadir="$DB_DIR/data" --port="$MYSQL_PORT" &

    # Wait for MySQL to be ready
    echo "Waiting for MySQL to be ready..."
    while ! "$DB_DIR/bin/mysqladmin" --port="$MYSQL_PORT" ping --silent; do
        sleep 1
    done
    echo "MySQL is up and running on port $MYSQL_PORT."
fi