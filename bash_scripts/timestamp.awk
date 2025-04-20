BEGIN{
    FS=",";
}

{
    if(NR>1)
    printf"%s,%s,%s,%s,%s\n",  substr($2,5,length($2)-4),$3,$4,$5,$6;
}