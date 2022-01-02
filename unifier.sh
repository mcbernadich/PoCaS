#!/bin/bash
fmerge "RC3_CNG_Set1_NED_30sec RC3_CNG_Set2_NED_30sec" RC3_CNG_Full2_NED_30sec "-"
for i in `seq 3 20` ; do
	fmerge "RC3_CNG_Full$[${i}-1]_NED_30sec RC3_CNG_Set${i}_NED_30sec" RC3_CNG_Full${i}_NED_30sec "-"
done