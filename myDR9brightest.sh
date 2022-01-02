#!/bin/bash
stilts tpipe in=/home/mbernardich/Desktop/Catalogues/XMM_BrightestPanSTARRS1 \
       cmd='keepcols "RA DEC DETID SRCID OBS_ID MATCH_FLAG RA_HEC DEC_HEC SC_RA SC_DEC SC_CenterDist SC_POSERR RA_CONT DEC_CONT"' \
       ofmt=fits-basic omode=out out=DetectionsList
stilts tpipe in=DetectionsList \
       ofmt=fits-basic omode=out out=SourcesList
stilts tmatch1 in=SourcesList \
       matcher=exact values='SRCID' action=keep1 \
       ofmt=fits-basic omode=out out=SourcesList
stilts tpipe in=SourcesList \
       ofmt=fits-basic omode=out out=ObsList
python3 drawBrightest.py DetectionsList SourcesList
rm DetectionsList
rm SourcesList
rm ObsList
