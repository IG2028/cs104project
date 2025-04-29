#!/bin/bash
export INPUT_FILE="$1"
export OUTPUT_FILE="processed/$2"

#remove any carriage return if present
sed -i 's/\r$//' "$INPUT_FILE"

#show error in landing.html if file isnt a log file
if [[ ! $INPUT_FILE =~ \.log$ ]]; then
    echo "Invalid file extension, please upload .log file" >&2
    exit 1
fi

VALID=1

#check using check.awk and assign the final value of the boolean maintained in awk to VALID
VALID=$(awk -f bash_scripts/check.awk "$INPUT_FILE")

#report an error for incorrect format in landing.html
if [[ $VALID -eq 0 ]]; then
    echo "Invalid format for uploading Apache log file" >&2
    exit 1
fi

#if log file format is correct, proceed 
bash bash_scripts/process.sh "$INPUT_FILE" "$OUTPUT_FILE"
exit 0