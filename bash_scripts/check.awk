BEGIN{
    #VALUE THAT WILL BE ASSIGNED TO VALID
    i=1;
    nonEmpty=0;
}
{
    nonEmpty=1;
    time_stamp= $1 " " $2 " " $3 " " $4 " " $5
#Timestamp check
if (time_stamp !~ /\[[A-Z][a-z]{2} [A-Z][a-z]{2} [0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} ((19|20)[0-9]{2})\]/)
    i=0;
if ($6 !~ /\[.*\]/)
    i=0;
}
END{
    if (nonEmpty==1)
        print i;
}
