#!/bin/bash
input_file="$1"
output_file="$2"
event_filter="$3"
level_filter="$4"
from_date="$5"
to_date="$6"
sort_by="$7"

declare -A month_map=(
    [Jan]=1 
    [Feb]=2 
    [Mar]=3 
    [Apr]=4 
    [May]=5 
    [Jun]=6 
    [Jul]=7 
    [Aug]=8
    [Sep]=9 
    [Oct]=10 
    [Nov]=11 
    [Dec]=12
)

if [[ -z $from_date ]]; then
    fromtime="Jan 00 00:00:00 0000"
fi

if [[ -z $to_time ]]; then
    to_time="Dec 99 99:99:99 9999"
fi


convert_date(){

    local timestamp=$1
    local month_num date realtime year

    month_num=${month_map[$(echo "$timestamp" | awk "{print $1}")]}

    date=$(echo "$timestamp" | awk "{print $2}")

    realtime=$(echo "$timestamp" | awk "{print $3}")

    year=$(echo "$timestamp" | awk "{print $4}")

    printf "04%d02%d%02d%s\n", "$year", "$month_num", "$date", "${realtime//:/}" 
}
convertin_date(){

    local timestamp=$1
    local month_num date realtime year

    month_num=${month_map[$(echo "$timestamp" | awk "{print $2}")]}

    date=$(echo "$timestamp" | awk "{print $3}")

    realtime=$(echo "$timestamp" | awk "{print $4}")

    year=$(echo "$timestamp" | awk "{print $5}")

    printf "04%d02%d%02d%s\n", "$year", "$month_num", "$date", "${realtime//:/}" 
}

from_timestamp=$(convert_date $from_date)
to_timestamp=$(convert_date $to_date)

tmp="tmpfile.txt"


header=$(head -n 1 "$input_file")
echo "$header" > "$output_file"
echo "0,$header"> "$tmp"

tail -n +2 "$input_file" | while IFS= read -r line || [[ -n $line ]] ; do
    include_line=true

    IFS="," read -r LineId Time Level Content EventId EventTemplate <<< "$line"

    time_timestamp=$(convertin_date $Time)
    if [[ $from_timestamp -gt $time_timestamp || $time_timestamp -gt $to_timestamp ]];then
        include_line=false
    fi

    if [[ -n "$event_filter" && ! "$line" =~ $event_filter ]]; then
        include_line=false
    fi

    if [[ -n "$level_filter" && ! "$line" =~ $level_filter ]]; then
        include_line=false
    fi

    if $include_line; then
        echo "$line" >> "$output_file"
        echo "$time_timestamp,$line" >> "$tmp"
    fi
done

case "$sort_by" in 
            "Time")
                sort -t, -k1 "$tmp"| cut -d"," -f2- > "$output_file"
                ;;
            "Level")
                sort -t, -k3 "$output_file" -o "$output_file"
                ;;
            "EventId")
                sort -t, -k5n "$output_file" -o "$output_file"
                ;;
            # *)
            #     sort -t, -k2 "$output_file" -o "$output_file"
esac

cat "$output_file"

rm $tmp
