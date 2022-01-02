#!/bin/bash
#Eliminate all galaxy detections without redshift or with flags.
stilts tpipe in=RC3_CNG_NED_30sec_NED_1min \
	ofmt=fits-basic omode=out out=RC3_CNG_NED_30sec_NED_1min_filtered \
	cmd='replaceval null -1. "Velocity_NED Redshift_NED"' \
	cmd='select "Redshift_NED>0. & $79==null"' \
	cmd='sort Redshift_NED'
#Pick the lowest redshift galaxy for every case.
stilts tmatch1 in=RC3_CNG_NED_30sec_NED_1min_filtered \
	ofmt=fits-basic omode=out out=RC3_CNG_NED_30sec_NED_1min_filtered \
	matcher=exact values='PGC' action=keep1 \
	ocmd='select minDiam<25'
#Correlate with the NED distance database.
stilts tmatch2 in1=RC3_CNG_NED_30sec_NED_1min_filtered in2=NED-D/NEDD.fits \
	ofmt=fits-basic omode=out out=RC3_CNG_NED_30sec_NED_1min_Distances \
	matcher=exact values1='$73' values2='$1' join=1and2 find=best \
	ocmd='colmeta -name "NEDDgalaxyID" "$90"' \
	ocmd='colmeta -name "FinalDist" "$91"'
#Make a list of the ones without counterpart and calculate distances from redshift.
stilts tmatch2 in1=RC3_CNG_NED_30sec_NED_1min_filtered in2=NED-D/NEDD.fits \
	ofmt=fits-basic omode=out out=RC3_CNG_NED_30sec_NED_1min_Distances_NED \
	matcher=exact values1='$73' values2='$1' join=1not2 find=best \
	ocmd='select "Velocity_NED>1000."' \
	ocmd='addcol -after Separation NEDDgalaxyID "PGC"' \
	ocmd='addcol -after NEDDgalaxyID FinalDist "toFloat(Velocity_NED/75.)"'
#Concatenate them for the final output
rm RC3_CNG_NED_30sec_NED_1min_filtered
stilts tcat in='RC3_CNG_NED_30sec_NED_1min_Distances RC3_CNG_NED_30sec_NED_1min_Distances_NED' \
	ofmt=fits-basic omode=out out=RC3_CNG_Distances
rm RC3_CNG_NED_30sec_NED_1min_Distances
rm RC3_CNG_NED_30sec_NED_1min_Distances_NED
