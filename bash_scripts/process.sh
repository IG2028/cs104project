#!/bin/bash
mkdir -p processed/
awk -f parse.awk "$INPUT_FILE" > processed/$OUTPUT_FILE #> #"processed/${%.log}.csv"
bash timesort.sh processed/$OUTPUT_FILE
