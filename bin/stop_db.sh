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

MYSQL_PORT=10001

# Check if MySQL is running
echo "Checking if MySQL is running on port $MYSQL_PORT..."
if "$DB_DIR/bin/mysqladmin" --port="$MYSQL_PORT" ping --silent; then
    echo "Stopping MySQL on port $MYSQL_PORT..."

    # Try to gracefully stop MySQL server
    shutdown_output=$("$DB_DIR/bin/mysqladmin" --port="$MYSQL_PORT" shutdown 2>&1)
    shutdown_exit_code=$?

    if [[ $shutdown_exit_code -ne 0 ]]; then
        echo "Error: $shutdown_output"
        exit 1  # Exit with error code if shutdown fails
    fi

    echo "MySQL has been stopped."
    exit 0
else
    echo "MySQL is not running on port $MYSQL_PORT."
    exit 0  # Exit with 0 if MySQL is not running
fi