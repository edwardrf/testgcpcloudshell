#!/bin/bash

# Extract the --print_file value from cloudshell_open command in history
PRINT_FILE=$(history | grep cloudshell_open | grep -oP '(?<=--print_file[=\s])\S+' | tail -1)

if [ -z "$PRINT_FILE" ]; then
    echo "No cloudshell_open command with --print_file parameter found in history"
    echo "Using default: tutorial.md"
    PRINT_FILE="tutorial.md"
else
    echo "Found tutorial file from history: $PRINT_FILE"
fi

echo "Setting up Workload Identity Federation..."
echo "Tutorial file: $PRINT_FILE"

# Add your setup logic here
# For example:
# - Configure GCP project
# - Set up workload identity pool
# - Create service accounts
# etc.
