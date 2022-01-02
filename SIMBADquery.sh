#!/bin/bash
stilts tmatch1 in=DR9AllDetections_inGalaxies_nonCentral_noQSOnoSO_lowFlag \
	matcher=exact values='SRCID' action=keep1 \
	ofmt=fits-basic omode=out out=dummySources
#Correlate it with NED.
stilts coneskymatch find=best \
	in=dummySources out=dummySources_NED \
	ofmt=fits-basic \
	ra=SC_RA dec=SC_DEC \
	sr=0.0028 \
	serviceurl="http://ned.ipac.caltech.edu/cgi-bin/NEDobjsearch?search_type=Near+Position+Search&of=xml_main&" \
	fixcols=all suffix0="" suffix1="_NEDdummy" \
	parallel=1 compress=true verb=3 \

