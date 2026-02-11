#!/bin/bash

# Extract the --print_file value from cloudshell_open command in history
PRINT_FILE=$(cat ~/.bash_history | grep cloudshell_open | grep -oP '(?<=--print_file[=\s])\S+' | tail -1)

if [ -z "$PRINT_FILE" ]; then
    echo "No cloudshell_open command with --print_file parameter found in history"
    exit 1
else
    echo "Found tutorial file from history: $PRINT_FILE"
fi

echo "Setting up Workload Identity Federation..."
echo "Github Repo: $PRINT_FILE"
