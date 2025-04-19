#!/bin/bash
export INPUT_FILE="$1"
export OUTPUT_FILE="processed/$2"
sed -i 's/\r$//' "$INPUT_FILE"
if [[ ! $INPUT_FILE =~ \.log$ ]]; then
    echo "Invalid file extension, please upload .log file" >&2
    exit 1
fi
VALID=1
VALID=$(awk -f bash_scripts/check.awk "$INPUT_FILE")
if [[ $VALID -eq 0 ]]; then
    echo "Invalid format for uploading Apache log file" >&2
    exit 1
fi
bash bash_scripts/process.sh "$INPUT_FILE" "$OUTPUT_FILE"
exit 0