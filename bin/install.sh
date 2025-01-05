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

install() {
  start_spinner
  sleep 2  # Simulate step 1
  update_spinner "Extracting files..."
  sleep 2  # Simulate step 2
  update_spinner "Installing dependencies..."
  sleep 2  # Simulate step 3
  update_spinner "Finishing installation..."
  sleep 2  # Simulate step 4
  stop_spinner
  echo "Installation complete!"
}

install