BEGIN{
        i=0;
        time=0;
}
{
        if($1 == "Mon"){
                i=1;
        }
        else if($1=="Tue"){
                i=2;
        }
        else if($1=="Wed"){
                i=3;
        }
        else if($1=="Thu"){
                i=4;
        }
        else if($1=="Fri"){
                i=5;
        }
        else if($1=="Sat"){
                i=6;
        }
        hours=substr($4,1,2)
        min=substr($4,4,2)
        sec=substr($4,7,2)
        time=hours*3600 + min*60 + sec
        print i,$2,$3,time,$5;
}