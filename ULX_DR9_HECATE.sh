#!/bin/bash
# Erase all existing files.
# Correlate galaxies with list of XMM observations.
stilts tmatch2 \
 	in1=HECATE/HECATE_slim_2.1.fits \
	in2=4XMM-DR9/4xmmdr9_obslist.fits \
	find=best1 fixcols=dups suffix1=_HEC suffix2=_summ join=1and2 matcher=sky \
	values1='RA DEC' values2='RA DEC' params=900 \
	icmd1='select "R1<15"' \
	ofmt=fits-basic omode=out out=Good_RC3_CNG_5sec_NED_30sec_KnownDist_minDlt25min_summaryDR9_30min
# Split the list of observations according to whether the shape of galaxies is known or not.
stilts tpipe \
	in=Good_RC3_CNG_5sec_NED_30sec_KnownDist_minDlt25min_summaryDR9_30min \
	out=Good_RC3_CNG_5sec_NED_30sec_KnownDist_minDlt25min_summaryDR9_30min_knownEllipses \
	ofmt=fits-basic cmd='select "PA!=0."'
stilts tpipe \
	in=Good_RC3_CNG_5sec_NED_30sec_KnownDist_minDlt25min_summaryDR9_30min \
	out=Good_RC3_CNG_5sec_NED_30sec_KnownDist_minDlt25min_summaryDR9_30min_unKnownEllipses \
	cmd='replaceval null 0. "PA"' \
	ofmt=fits-basic cmd='select "PA==0."'
rm Good_RC3_CNG_5sec_NED_30sec_KnownDist_minDlt25min_summaryDR9_30min
# Correlate galaxies with Detections.
# All sources within the known ellipse of a galaxy are flagged as "MATCH_FLAG=0".
stilts tmatch2 \
	in1=4XMM-DR9/DR9_pointlikely \
	in2=Good_RC3_CNG_5sec_NED_30sec_KnownDist_minDlt25min_summaryDR9_30min_knownEllipses \
	find=best1 fixcols=dups suffix1=null suffix2=_summ join=1and2 matcher=skyellipse \
	values1='SC_RA SC_DEC SC_POSERR SC_POSERR 0' values2='RA_HEC DEC_HEC R1*60 R2*60 PA' params=1 \
	ocmd='addcol -after SC_POSERR MATCH_FLAG "toString(0.)"' \
	ofmt=fits-basic omode=out out=DR9AllDetections_inKnownEllipses
rm Good_RC3_CNG_5sec_NED_30sec_KnownDist_minDlt25min_summaryDR9_30min_knownEllipses
# For galaxies without a listed position angle, sources inside of the minor circle are flagged
# as "MATCH_FLAG=1". Sources in the ring between the minor and minor radius are
# flagged with "MATCH_FLAG=2"
stilts tmatch2 \
	in1=4XMM-DR9/DR9_pointlikely \
	in2=Good_RC3_CNG_5sec_NED_30sec_KnownDist_minDlt25min_summaryDR9_30min_unKnownEllipses \
	find=best1 fixcols=dups suffix1=null suffix2=_summ join=1and2 matcher=skyellipse \
	values1='SC_RA SC_DEC SC_POSERR SC_POSERR 0' values2='RA_HEC DEC_HEC R2*60 R2*60 0' params=1 \
	ocmd='addcol -after SC_POSERR MATCH_FLAG "toString(1.)"' \
	ofmt=fits-basic omode=out out=DR9AllDetections_inUnKnownEllipses_minor
stilts tmatch2 \
	in1=4XMM-DR9/DR9_pointlikely \
	in2=Good_RC3_CNG_5sec_NED_30sec_KnownDist_minDlt25min_summaryDR9_30min_unKnownEllipses \
	find=best1 fixcols=dups suffix1=null suffix2=_summ join=1and2 matcher=skyellipse \
	values1='SC_RA SC_DEC SC_POSERR SC_POSERR 0' values2='RA_HEC DEC_HEC R1*60 R1*60 0' params=1 \
	ocmd='addcol -after SC_POSERR MATCH_FLAG "toString(2.)"' \
	ofmt=fits-basic omode=out out=DR9AllDetections_inUnKnownEllipses_major
stilts tmatch2 \
       in1=DR9AllDetections_inUnKnownEllipses_major \
       in2=DR9AllDetections_inUnKnownEllipses_minor \
       find=best fixcols=none  join=1not2 matcher=exact \
       values1='DETID' values2='DETID' \
       ofmt=fits-basic omode=out out=DR9AllDetections_inUnKnownEllipses_major
rm Good_RC3_CNG_5sec_NED_30sec_KnownDist_minDlt25min_summaryDR9_30min_unKnownEllipses
# Concatenate the three tables and detect bad distance estimations.
stilts tcat in='DR9AllDetections_inKnownEllipses DR9AllDetections_inUnKnownEllipses_minor DR9AllDetections_inUnKnownEllipses_major' \
	ofmt=fits-basic omode=out out=DR9AllDetections_inGalaxies \
	ocmd='addcol -after MATCH_FLAG -units erg/s Luminosity "EP_8_FLUX*10000*(4*PI*square(MpcToM(D)))"' \
	ocmd='addcol -after Luminosity -units erg/s LuminosityErr "sqrt(square(EP_8_FLUX_ERR*10000*(4*PI*square(MpcToM(D))))+square(EP_8_FLUX*10000*(8*PI*MpcToM(D)*MpcToM(D_ERR))))"' \
	ocmd='addcol -after MATCH_FLAG -units arcsec CenterDist "skyDistanceDegrees(RA,DEC,RA_HEC,DEC_HEC)*3600"' \
	ocmd='addcol -after CenterDist -units arcsec MinCenterDist "CenterDist-3*POSERR"' \
	ocmd='addcol -after SC_POSERR -units erg/s SC_Luminosity "SC_EP_8_FLUX*10000*(4*PI*square(MpcToM(D)))"' \
	ocmd='addcol -after SC_Luminosity -units erg/s SC_LuminosityErr "sqrt(square(SC_EP_8_FLUX_ERR*10000*(4*PI*square(MpcToM(D))))+square(SC_EP_8_FLUX*10000*(8*PI*MpcToM(D)*MpcToM(D_ERR))))"' \
	ocmd='addcol -after SC_POSERR -units arcsec SC_CenterDist "skyDistanceDegrees(SC_RA,SC_DEC,RA_HEC,DEC_HEC)*3600"' \
	ocmd='addcol -after SC_CenterDist -units arcsec SC_MinCenterDist "SC_CenterDist-3*SC_POSERR"'
rm DR9AllDetections_inKnownEllipses
rm DR9AllDetections_inUnKnownEllipses_minor
rm DR9AllDetections_inUnKnownEllipses_major
# Eradicate duplicate detections by keeping the version that is closest to the center of their home.
stilts tmatch1 \
	in=DR9AllDetections_inGalaxies \
	matcher=exact values='DETID' action=keep1\
	ofmt=fits-basic omode=out out=DR9AllDetections_inGalaxies
# Eradicate all central Detections.
stilts tpipe in=DR9AllDetections_inGalaxies \
	ofmt=fits-basic omode=out out=DR9AllDetections_inGalaxies_nonCentral \
	cmd='select "SC_MinCenterDist>3"' \
	cmd='sort SC_CenterDist'
# Identify all detections of the same (assumed) source
rm DR9AllDetections_inGalaxies
stilts tmatch1 \
	in=DR9AllDetections_inGalaxies_nonCentral \
	matcher=exact values='SRCID' action=identify\
	ofmt=fits-basic omode=out out=DR9AllDetections_inGalaxies_nonCentral
# Eradicate Detections found in catalogues of known stars and QSO.
stilts tmatch2 \
	in1=DR9AllDetections_inGalaxies_nonCentral \
	in2=VeronQSO/VeronQSO \
	matcher=sky join=1not2 find=best2 \
	values1='SC_RA SC_DEC' values2='_RAJ2000 _DEJ2000' params=10 \
	ofmt=fits-basic omode=out out=DR9AllDetections_inGalaxies_nonCentral_noQSO
rm DR9AllDetections_inGalaxies_nonCentral
stilts tmatch2 \
	in1=DR9AllDetections_inGalaxies_nonCentral_noQSO \
	in2=Tycho2/Tycho2 \
	matcher=sky join=1not2 find=best2 \
	values1='SC_RA SC_DEC' values2='_RAJ2000 _DEJ2000' params=10 \
	ofmt=fits-basic omode=out out=DR9AllDetections_inGalaxies_nonCentral_noQSOnoSO
rm DR9AllDetections_inGalaxies_nonCentral_noQSO
# Identify all detections of the same (assumed) source and eradicate those that have had one source erased.
stilts tmatch1 \
	in=DR9AllDetections_inGalaxies_nonCentral_noQSOnoSO \
	matcher=exact values='SRCID' action=identify\
	ofmt=fits-basic omode=out out=DR9AllDetections_inGalaxies_nonCentral_noQSOnoSO \
	ocmd='replaceval null 1 "GroupSize_olda GroupSize"' \
	ocmd='addcol GroupDifference "GroupSize_olda-GroupSize"' \
 	ocmd='select "GroupDifference==0"'
# Eradicate Detections with a high Flag and order by SRCID.
stilts tpipe in=DR9AllDetections_inGalaxies_nonCentral_noQSOnoSO \
	ofmt=fits-basic omode=out out=DR9AllDetections_inGalaxies_nonCentral_noQSOnoSO_lowFlag \
	cmd='select SUM_FLAG<=1' cmd='sort SRCID'
rm DR9AllDetections_inGalaxies_nonCentral_noQSOnoSO

