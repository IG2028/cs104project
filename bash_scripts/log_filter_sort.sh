#!/bin/bash
FILE="$1"
FROM_DATE="$2"
TO_DATE="$3"
SORT_BY="$4"
FILTER_LEVEL="$5" 
FILTER_EVENT="$6"

awk -v FROM="$FROM_DATE" -v TO="$TO_DATE" -v SORT="$SORT_BY" -v LEVEL="$FILTER_LEVEL" -v EVENT="$FILTER_EVENT" '
BEGIN{  
        OFS=",";FS=",";
        split("Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec",months," ");
        for(i=1;i<=12;i++)
            Month_map[months[i]]=i;
}
{   
    if(NR==1){
        head=$0;
        next;
        }
}
function getSortedForm(timestamp,  year,month,date,hh,mm,ss){
    split(timestamp,timeFields," ");
    year=timeFields[5]
    month=timeFields[2]
    date=int(timeFields[3])
    split(timeFields[4],time,":");
    hh=int(time[1])
    mm=int(time[2])
    ss=int(time[3])
    return sprintf("%04d%s%02d%02d%02d%02d", year,month,date,hh,mm,ss);
    }
{   
    entryTime=getSortedForm($2)
    fromTime=getSprtedForm(FROM)
    toTime=getSortedForm(TO)

    if((fromTime != "" || entryTime<fromTime) && ())


}