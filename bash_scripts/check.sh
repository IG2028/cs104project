#!/bin/bash
export INPUT_FILE="$1"
export OUTPUT_FILE="$2"
if [[ ! $INPUT_FILE =~ \.log$ ]]; then
    echo "Invalid file extension, please upload .log file" >&2
    exit 1
fi
VALID=1
VALID=$(awk -f check.awk "$INPUT_FILE")
if [[ $VALID -eq 0 ]]; then
    echo "Invalid format for uploading Apache log file" >&2
    exit 1
fi
bash process.sh
exit 0