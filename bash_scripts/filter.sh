#!/bin/bash

input_file="$1"
output_file="$2"
event_filter="$3"
level_filter="$4"
 from_date="$5"
 to_date="$6"

header=$(head -n 1 "$input_file")
echo "$header" > "$output_file"

tail -n +2 "$input_file" | while IFS= read -r line; do
    include_line=true

    if [[ -n "$event_filter" && ! "$line" =~ $event_filter ]]; then
        include_line=false
    fi

    if [[ -n "$level_filter" && ! "$line" =~ $level_filter ]]; then
        include_line=false
    fi

    if $include_line; then
        echo "$line" >> "$output_file"
    fi
done
