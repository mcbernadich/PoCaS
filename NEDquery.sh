#!/bin/bash
for file in `ls RC3_CNG_Set*` ; do
stilts coneskymatch find=all \
    in=${file} out=${file}_NED_30sec \
    ofmt=fits-basic \
    ra=RA_pre dec=DE_pre \
    sr=0.0084 \
serviceurl="http://ned.ipac.caltech.edu/cgi-bin/NEDobjsearch?search_type=Near+Position+Search&of=xml_main&" \
    fixcols=all suffix0="" suffix1="_NED" \
    parallel=1 compress=true verb=3
sleep 600
done

## to write comments
## stilts is the command-line version of topcat. look into google for more info
## for i in `seq 1 1000 24000` <-- this one to make a loop with a running varuable
## man sed <-- this one to get help
## j=$[${i}+1000] <-- this one to make calculations ONLY WITH INTEGERS
