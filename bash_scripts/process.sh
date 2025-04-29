#!/bin/bash
INPUT_FILE="$1"
OUTPUT_FILE="$2"
mkdir -p processed/
awk -f bash_scripts/parse.awk "$INPUT_FILE" > "$OUTPUT_FILE" 
