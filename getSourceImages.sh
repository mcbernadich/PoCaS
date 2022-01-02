#!/bin/bash
galaxyname=$1
pgcnumber=$2
stilts tpipe in=/home/mbernardich/Desktop/Catalogues/XMM_nonNuclear_Catalogue \
       cmd="select PGC==$pgcnumber" \
       cmd='keepcols "RA DEC SRCID OBS_ID MATCH_FLAG RA_HEC DEC_HEC SC_RA SC_DEC SC_CenterDist"' \
       ofmt=fits-basic omode=out out=DetectionsList
stilts tpipe in=DetectionsList \
       ofmt=fits-basic omode=out out=SourcesList
stilts tmatch1 in=SourcesList \
       matcher=exact values='SRCID' action=keep1 \
       ofmt=fits-basic omode=out out=SourcesList
stilts tpipe in=SourcesList \
       ofmt=fits-basic omode=out out=ObsList
stilts tmatch1 in=ObsList \
       matcher=exact values='OBS_ID' action=keep1 \
       ofmt=fits-basic omode=out out=ObsList
#mkdir /home/mbernardich/Desktop/Images/miscel·lània
python3 writeSources.py DetectionsList SourcesList ObsList $galaxyname
rm DetectionsList
rm SourcesList
rm ObsList
