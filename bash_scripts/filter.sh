#!/bin/bash

# Script to filter and sort a log CSV file.
# Writes the result to the specified output file.
# Usage: filter_sort.sh <input_csv> <output_temp_csv> [event_filter] [level_filter] [from_date] [to_date] [sort_by_key]

# Input Arguments
input_file="$1"         # Input CSV log file
output_file="$2"        # Output CSV file
event_filter="${3:-}"   # Optional: filter by event
level_filter="${4:-}"   # Optional: filter by level
from_date_str="${5:-}"  # Optional: start date filter
to_date_str="${6:-}"    # Optional: end date filter
sort_by_key="${7:-LineId}"  # Default sort key is 'LineId'

# Temporary filename
output_basename=$(basename "$output_file")
tmp_file="temp_for_${output_basename}.tmp"

# Date Conversion Setup
declare -A month_map=( [Jan]=01 [Feb]=02 [Mar]=03 [Apr]=04 [May]=05 [Jun]=06 [Jul]=07 [Aug]=08 [Sep]=09 [Oct]=10 [Nov]=11 [Dec]=12 )

# Function to convert timestamp into sortable format (YYYYMMDDHHMMSS)
convert_csv_time_to_sortable() {
    local ts="$1"; ts=$(echo "$ts" | xargs)
    [[ -z "$ts" ]] && { echo "0"; return; }
    local n=$(echo "$ts" | wc -w); local d m dt t y mn hh mm ss;

    if [[ "$n" -eq 5 ]]; then 
        read -r d m dt t y <<< "$ts"
    elif [[ "$n" -eq 4 ]]; then 
        read -r m dt t y <<< "$ts"
    else 
        echo "0"; return
    fi

    mn=${month_map[$m]}
    [[ -z "$mn" ]] && { echo "0"; return; }

    [[ "$t" =~ ^([0-9]{1,2}):([0-9]{1,2}):([0-9]{1,2})$ ]] || { echo "0"; return; }
    hh=${BASH_REMATCH[1]}; mm=${BASH_REMATCH[2]}; ss=${BASH_REMATCH[3]}

    # Output timestamp in sortable format
    printf "%04d%02d%02d%02d%02d%02d" "$y" "$mn" "$dt" "$hh" "$mm" "$ss"
}

# Set Date Range
fts=$(convert_csv_time_to_sortable "$from_date_str")
[[ "$fts" == "0" ]] && fts="0"

tts=$(convert_csv_time_to_sortable "$to_date_str")
[[ "$tts" == "0" ]] && tts="99999999999999"

# Prepare Output and Temp File
head -n 1 "$input_file" > "$output_file"  # Write header to output file
> "$tmp_file"  # Clear the temp file

# Column Indices
declare -A ci=( [LineId]=1 [Time]=2 [Level]=3 [Content]=4 [EventId]=5 [EventTemplate]=6 )
ski=${ci[$sort_by_key]:-1}  # Sorting key column index

# Process Input
tail -n +2 "$input_file" | while IFS=, read -r LineId Time Level Content EventId EventTemplate; do
    Tt=$(echo "$Time" | xargs)
    Lt=$(echo "$Level" | xargs)
    Et=$(echo "$EventId" | xargs)
    inc=true

    tst=$(convert_csv_time_to_sortable "$Tt")
    [[ "$tst" == "0" && (-n "$from_date_str" || -n "$to_date_str") ]] && inc=false
    [[ "$tst" -lt "$fts" || "$tst" -gt "$tts" ]] && inc=false

    # Filter by event and level if filters are set
    $inc && [[ -n "$event_filter" && "$Et" != "$event_filter" ]] && inc=false
    $inc && [[ -n "$level_filter" && "$Lt" != "$level_filter" ]] && inc=false

    # If no filters block the entry, append it to the temp file
    $inc && printf "%s,%s,%s,%s,%s,%s\n" "$LineId" "$Time" "$Level" "$Content" "$EventId" "$EventTemplate" >> "$tmp_file"
done

# Sorting
if [[ -s "$tmp_file" ]]; then
    case "$sort_by_key" in
        Time)
            # Sort by timestamp (sortable format)
            awk -F, '
            function convert_timestamp(ts) {
                gsub(/^[ \t]+|[ \t]+$/, "", ts)
                n = split(ts, p, " ")
                if (n == 5) {
                    m = p[2]; dt = p[3]; t = p[4]; y = p[5]
                } else if (n == 4) {
                    m = p[1]; dt = p[2]; t = p[3]; y = p[4]
                } else {
                    return 0
                }
                months["Jan"] = "01"; months["Feb"] = "02"; months["Mar"] = "03"; months["Apr"] = "04"
                months["May"] = "05"; months["Jun"] = "06"; months["Jul"] = "07"; months["Aug"] = "08"
                months["Sep"] = "09"; months["Oct"] = "10"; months["Nov"] = "11"; months["Dec"] = "12"
                mn = months[m]
                if (!mn) return 0
                n = split(t, p, ":")
                if (n != 3) return 0
                h = p[1]; mm = p[2]; s = p[3]
                return sprintf("%04d%02d%02d%02d%02d%02d", y, mn, dt, h, mm, s)
            }
            {
                # Apply conversion to timestamp and prepend the sortable key to each line
                print convert_timestamp($2) "," $0
            }' "$tmp_file" | \
            sort -t, -k1,1n | \
            cut -d, -f2- >> "$output_file"  # Remove the sortable key after sorting
            ;;
        LineId | EventId | Level)
            # Sort by the chosen field (numeric or alphanumeric)
            sort -t, -k"$ski" "$tmp_file" >> "$output_file"
            ;;
        *)
            # Default: Sort by LineId (numeric)
            sort -t, -k1n "$tmp_file" >> "$output_file"
            ;;
    esac
fi

# Cleanup
rm -f "$tmp_file"  # Remove temporary file

exit 0
