BEGIN {
    OFS = ","
    RS="\n"
    print "LineId", "Time", "Level", "Content", "EventId", "EventTemplate"
}
{
    time_part1 = substr($1, 2) #remove the [
    time_part2 = $2
    time_part3 = $3
    time_part4 = $4
    time_part5 = substr($5, 1, length($5) - 1) #remove the ]
    time_stamp = time_part1 " " time_part2 " " time_part3 " " time_part4 " " time_part5

    level = substr($6, 2, length($6) - 2) #remove the []

    #take the rest of the text in the line and make it content
    Content = ""
    for (i = 7; i <= NF; i++) {
        Content = Content $i " "
    }

    Content = substr(Content, 1, length(Content) - 1)

    Eventid = ""
    EventTemp = ""

    #check the event field of line by matching Content
    if (Content ~ /^workerEnv.init\(\) ok .*/) {
        Eventid = "E2"
        EventTemp = "workerEnv.init() ok <*>"
    } else if (Content ~ /^mod_jk child workerEnv in error state [0-9]+/) {
        Eventid = "E3"
        EventTemp = "mod_jk child workerEnv in error state <*>"
    } else if (Content ~ /^jk2_init\(\) Found child [0-9]+ in scoreboard slot [0-9]+/) {
        Eventid = "E1"
        EventTemp = "jk2_init() Found child <*> in scoreboard slot <*>"
    } else if (Content ~ /mod_jk child init .* .*/) {
        Eventid = "E6"
        EventTemp = "mod_jk child init <*> <*>"
    } else if (Content ~ /jk2_init\(\) Can't find child [0-9]+ in scoreboard$/) {
        Eventid = "E5"
        EventTemp = "jk2_init() Can't find child <*> in scoreboard"
    } else if (Content ~ /\[client .*\] Directory index forbidden by rule: .*/) {
        Eventid = "E4"
        EventTemp = "[client <*>] Directory index forbidden by rule: <*>"
    }

    print NR, time_stamp, level,Content,Eventid,EventTemp;
}
