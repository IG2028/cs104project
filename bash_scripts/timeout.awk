{   
#    i=$1
#    if(i==1){
#        $1 = "Mon";       ;
#        }
#    else if(i==2){
#            $1="Tue";
#        }
#    else if(i==3){
#            $1="Wed";
#        }
#   else if(i==4){
#          $1="Thu";
#       }
#    else if(i==5){
#            $1="Fri";
#        }
#    else if(i==6){
#            $1="Sat";
#        }
#   else $1="Sun";
    hours=int($3/3600)
    mins=int(($3%3600)/60)
    sec=$3%60
    printf "%s %s %02d %02d:%02d:%02d ", $1,$2,hours,mins,sec;
    for(i=4;i<= NF;i++){
        if(i==NF){
            printf"%s\n",$i;
            break;
        }
        printf"%s ",$i;
    }
 }