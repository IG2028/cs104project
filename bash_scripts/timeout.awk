{   
    i=$1
    if(i==1){
        $1 = "Mon";       ;
        }
    else if(i==2){
            $1="Tue";
        }
    else if(i==3){
            $1="Wed";
        }
    else if(i==4){
           $1="Thu";
        }
    else if(i==5){
            $1="Fri";
        }
    else if(i==6){
            $1="Sat";
        }
    else $1="Sun";
    hours=int($4/3600)
    mins=int(($4%3600)/60)
    sec=$4%60
    printf "%s %s %02d %02d:%02d:%02d %d\n", $1,$2,$3,hours,mins,sec,$5;
 }