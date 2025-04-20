#!/bin/bash
FILE="$1"
FROM_DATE="$2"
TO_DATE="$3"
SORT_BY="$4"
#Jan 18 23:59:59 2005
#Purpose is to filter and sort by timestamps for the data given. In flask we also have to implement a filter and sort wrt other fields like level and event
#Put a tag in the html for the format of input acceptible
#Also if the date given is less than the minimum entry or larger than the maximum, then print an error message showing the current format and the range available

awk -f bash_scripts/timestamp.awk "$1"|awk -v FROM_DATE=$FROM_DATE -v TO_DATE=$TO_DATE '
# BEGIN{
#     FROM_HOURS=substr(FROM_DATE,8,2)
#     FROM_MINS=substr(FROM_DATE,11,2)
#     FROM_SECS=substr(FROM_DATE,14,2)
#     TO_HOURS=substr(TO_DATE,8,2)
#     TO_MINS=substr(TO_DATE,11,2)
#     TO_SECS=substr(TO_DATE,14,2)
#     FROM_TIME= FROM_HOURS*3600 + FROM_MINS*60 + FROM_SECS
#     TO_TIME= TO_HOURS*3600 + TO_MINS*60+ TO_SECS
    printf "%d %s\n", 1 , FROM_DATE;
    printf "%d %s\n", 2, TO_DATE;
}
{
    print;   
}'|
awk -f bash_scripts/timesort.sh |
awk '
BEGIN{
    FROM_TIME=0;
    FROM_MONTH=0;
    TO_TIME=0;
    TO_MONTH=0;
}
{
    if(NR==1){
        FROM_MONTH=$1
        FROM_TIME=$4
    }
    if(NR==2){
        TO_MONTH=$1
        TO_TIME=$4    
    }
    for(i=3;i<=NR;i++){
        if($1>=FROM_MONTH && $1<=TO_MONTH)
            if($4>=FROM_TIME && $4<=TO_TIME)
                print $0;
    }
}' |
awk -f bash_scripts/timeout.awk 




