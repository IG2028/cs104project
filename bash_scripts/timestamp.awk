BEGIN{
    FS=",";
}

{
    if(NR>1)
    print $2;
}