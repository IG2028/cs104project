#!/bin/bash

# Script to filter and sort a log CSV file (Simplified Error Handling & Temp File).
# Writes the result to the specified output file.
# Usage: filter_sort.sh <input_csv> <output_temp_csv> [event_filter] [level_filter] [from_date] [to_date] [sort_by_key]

# --- Input Arguments ---
input_file="$1"
output_file="$2"        # The final output file path from Flask
event_filter="${3:-}"
level_filter="${4:-}"
from_date_str="${5:-}"
to_date_str="${6:-}"
sort_by_key="${7:-LineId}" # Default sort key

# --- Use a predictable temporary filename (relative path) ---
# WARNING: This is less safe than mktemp for concurrent use.
# Including output filename makes it slightly safer than a totally fixed name.
output_basename=$(basename "$output_file")
tmp_file="temp_for_${output_basename}.tmp"

# --- Date Conversion Setup ---
declare -A month_map=( [Jan]=01 [Feb]=02 [Mar]=03 [Apr]=04 [May]=05 [Jun]=06 [Jul]=07 [Aug]=08 [Sep]=09 [Oct]=10 [Nov]=11 [Dec]=12 )
convert_csv_time_to_sortable() {
    local ts="$1"; ts=$(echo "$ts" | xargs); [[ -z "$ts" ]] && { echo "0"; return; }
    local n=$(echo "$ts" | wc -w); local d m dt t y mn hh mm ss sd;
    if [[ "$n" -eq 5 ]]; then read -r d m dt t y <<< "$ts"; elif [[ "$n" -eq 4 ]]; then read -r m dt t y <<< "$ts"; else echo "0"; return; fi
    mn=${month_map[$m]}; [[ -z "$mn" ]] && { echo "0"; return; }
    [[ "$t" =~ ^([0-9]{1,2}):([0-9]{1,2}):([0-9]{1,2})$ ]] || { echo "0"; return; }
    hh=${BASH_REMATCH[1]}; mm=${BASH_REMATCH[2]}; ss=${BASH_REMATCH[3]};
    printf -v dtp "%02d" "$dt"; printf -v hhp "%02d" "$hh"; printf -v mmp "%02d" "$mm"; printf -v ssp "%02d" "$ss";
    printf "%04d%02d%02d%02d%02d%02d" "$y" "$mn" "$dtp" "$hhp" "$mmp" "$ssp"
}

# --- Set Effective Date Range ---
fts=$(convert_csv_time_to_sortable "$from_date_str"); [[ "$fts" == "0" ]] && fts="0"
tts=$(convert_csv_time_to_sortable "$to_date_str"); [[ "$tts" == "0" ]] && tts="99999999999999"

# --- Prepare Output and Clear/Create Temp File ---
head -n 1 "$input_file" > "$output_file" # Write header to final output
> "$tmp_file" # Create or clear the fixed-name temporary file

# --- Define Column Indices ---
declare -A ci=( [LineId]=1 [Time]=2 [Level]=3 [Content]=4 [EventId]=5 [EventTemplate]=6 ); ski=${ci[$sort_by_key]:-1}

# --- Process Input ---
tail -n +2 "$input_file" | while IFS=, read -r LineId Time Level Content EventId EventTemplate; do
    Tt=$(echo "$Time"|xargs); Lt=$(echo "$Level"|xargs); Et=$(echo "$EventId"|xargs); inc=true;
    tst=$(convert_csv_time_to_sortable "$Tt");
    [[ "$tst" == "0" && (-n "$from_date_str" || -n "$to_date_str") ]] && inc=false;
    [[ "$tst" -lt "$fts" || "$tst" -gt "$tts" ]] && inc=false; # Numerical compare
    $inc && [[ -n "$event_filter" && "$Et" != "$event_filter" ]] && inc=false;
    $inc && [[ -n "$level_filter" && "$Lt" != "$level_filter" ]] && inc=false;
    $inc && printf "%s,%s,%s,%s,%s,%s\n" "$LineId" "$Time" "$Level" "$Content" "$EventId" "$EventTemplate" >> "$tmp_file";
done

# --- Sorting (Sort the temporary file and append to output) ---
if [[ -s "$tmp_file" ]]; then
    case "$sort_by_key" in
        Time)
            # Use awk helper to prepend sortable key, sort, then remove key
            awk -F, 'function ct(ts,...){gsub(/^[ \t]+|[ \t]+$/,"",ts);n=split(ts,p," ");if(n==5){m=p[2];dt=p[3];t=p[4];y=p[5]}else if(n==4){m=p[1];dt=p[2];t=p[3];y=p[4]}else{return 0}mths["Jan"]="01";mths["Feb"]="02";mths["Mar"]="03";mths["Apr"]="04";mths["May"]="05";mths["Jun"]="06";mths["Jul"]="07";mths["Aug"]="08";mths["Sep"]="09";mths["Oct"]="10";mths["Nov"]="11";mths["Dec"]="12";mn=mths[m];if(!mn)return 0;n=split(t,p,":");if(n!=3)return 0;h=p[1];mm=p[2];s=p[3];return sprintf("%04d%02d%02d%02d%02d%02d",y,mn,dt,h,mm,s)}{print ct($2)","$0}' "$tmp_file" | \
            sort -t, -k1,1n | \
            cut -d, -f2- >> "$output_file" # Append sorted data to final output
            ;;
        LineId)
            sort -t, -k"$ski"n "$tmp_file" >> "$output_file"
            ;;
        EventId)
            # Use standard alphanumeric sort for EventId (E1, E2...)
            sort -t, -k"$ski" "$tmp_file" >> "$output_file"
            ;;
        Level)
            sort -t, -k"$ski" "$tmp_file" >> "$output_file"
             ;;
        *)
            # Default: If sort key is unrecognized, sort by LineId (numeric)
             sort -t, -k1n "$tmp_file" >> "$output_file"
            ;;
    esac
fi

# --- Manual Cleanup of Temp File ---
rm -f "$tmp_file" # Remove the temporary file

exit 0