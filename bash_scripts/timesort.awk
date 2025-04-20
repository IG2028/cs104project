BEGIN{
        time=0;
}
{
#        if($1 == "Mon"){
#                i=1;
#        }
#        else if($1=="Tue"){
#                i=2;
#        }
#        else if($1=="Wed"){
#                i=3;
#        }
#        else if($1=="Thu"){
#                i=4;
#        }
#        else if($1=="Fri"){
#                i=5;
#        }
#        else if($1=="Sat"){
#                i=6;
#        }
        hours=substr($3,1,2)
        min=substr($3,4,2)
        sec=substr($3,7,2)
        time=hours*3600 + min*60 + sec
        for(i=1;i<=NF;i++){
                if(i==NF){
                        printf"%s\n",$i;
                        break;
                }
                if(i==3){
                        printf"%d ",time;
                        continue;
                }
                printf"%s ",$i;
        }
}