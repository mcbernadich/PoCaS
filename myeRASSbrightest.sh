#!/bin/bash

stilts tpipe in=/home/mbernardich/Desktop/Catalogues/eRASS_BrightestDetections \
       cmd='keepcols "DETUID RA_CORR DEC_CORR"' \
       ofmt=fits-basic omode=out out=DetectionsList
python3 drawBrightesteRASS.py DetectionsList
rm DetectionsList
