#!/bin/bash
# Erase all existing files.
# Correlate galaxies with list of XMM observations.
stilts tmatch2 \
 	in1=RC3_CNG_Distances \
	in2=4XMM-DR9/4xmmdr9_obslist.fits \
	find=best1 fixcols=dups suffix1=_gl suffix2=_summ join=1and2 matcher=sky \
	values1='RA_NED DEC_NED' values2='RA DEC' params=900 \
	ofmt=fits-basic omode=out out=Good_RC3_CNG_5sec_NED_30sec_KnownDist_minDlt25min_summaryDR9_30min
# Split the list of observations according to whether the shape of galaxies is known or not.
stilts tpipe \
	in=Good_RC3_CNG_5sec_NED_30sec_KnownDist_minDlt25min_summaryDR9_30min \
	out=Good_RC3_CNG_5sec_NED_30sec_KnownDist_minDlt25min_summaryDR9_30min_knownEllipses \
	ofmt=fits-basic cmd='select "PA>0"'
stilts tpipe \
	in=Good_RC3_CNG_5sec_NED_30sec_KnownDist_minDlt25min_summaryDR9_30min \
	out=Good_RC3_CNG_5sec_NED_30sec_KnownDist_minDlt25min_summaryDR9_30min_unKnownEllipses \
	ofmt=fits-basic cmd='select "PA<=0"'
rm Good_RC3_CNG_5sec_NED_30sec_KnownDist_minDlt25min_summaryDR9_30min
# Correlate galaxies with Detections.
stilts tmatch2 \
	in1=4XMM-DR9/DR9_pointlikely \
	in2=Good_RC3_CNG_5sec_NED_30sec_KnownDist_minDlt25min_summaryDR9_30min_knownEllipses \
	find=best1 fixcols=dups suffix1=null suffix2=_summ join=1and2 matcher=skyellipse \
	values1='RA DEC POSERR POSERR 0' values2='RA_NED DEC_NED majDiam*30 minDiam*30 PA' params=1 \
	ofmt=fits-basic omode=out out=DR9AllDetections_inKnownEllipses
rm Good_RC3_CNG_5sec_NED_30sec_KnownDist_minDlt25min_summaryDR9_30min_knownEllipses
stilts tmatch2 \
	in1=4XMM-DR9/DR9_pointlikely \
	in2=Good_RC3_CNG_5sec_NED_30sec_KnownDist_minDlt25min_summaryDR9_30min_unKnownEllipses \
	find=best1 fixcols=dups suffix1=null suffix2=_summ join=1and2 matcher=skyellipse \
	values1='RA DEC POSERR POSERR 0' values2='RA_NED DEC_NED minDiam*30 minDiam*30 0' params=1 \
	ofmt=fits-basic omode=out out=DR9AllDetections_inUnKnownEllipses
rm Good_RC3_CNG_5sec_NED_30sec_KnownDist_minDlt25min_summaryDR9_30min_unKnownEllipses
# Concatenate the two tables and detect bad distance esstimations.
stilts tcat in='DR9AllDetections_inKnownEllipses DR9AllDetections_inUnKnownEllipses' \
	ofmt=fits-basic omode=out out=DR9AllDetections_inGalaxies \
	ocmd='addcol -after POSERR -units erg/s Luminosity "EP_8_FLUX*10000*(4*PI*MpcToM(FinalDist)*MpcToM(FinalDist))"' \
	ocmd='addcol -after Luminosity -units erg/s LuminosityErr "EP_8_FLUX_ERR*10000*(4*PI*MpcToM(FinalDist)*MpcToM(FinalDist))"' \
	ocmd='addcol -after POSERR -units arcsec CenterDist "skyDistanceDegrees(RA,DEC,RA_NED,DEC_NED)*3600"' \
	ocmd='addcol -after CenterDist -units arcsec MinCenterDist "CenterDist-3*POSERR"' \
	ocmd='addcol -after SC_POSERR -units erg/s SC_Luminosity "SC_EP_8_FLUX*10000*(4*PI*MpcToM(FinalDist)*MpcToM(FinalDist))"' \
	ocmd='addcol -after SC_Luminosity -units erg/s SC_LuminosityErr "SC_EP_8_FLUX_ERR*10000*(4*PI*MpcToM(FinalDist)*MpcToM(FinalDist))"' \
	ocmd='addcol -after SC_POSERR -units arcsec SC_CenterDist "skyDistanceDegrees(SC_RA,SC_DEC,RA_NED,DEC_NED)*3600"' \
	ocmd='addcol -after SC_CenterDist -units arcsec SC_MinCenterDist "SC_CenterDist-3*SC_POSERR"' \
	ocmd='addcol -after FinalDist -units Mpc DeltaDist "abs(FinalDist-DistRC3)"'
rm DR9AllDetections_inKnownEllipses
rm DR9AllDetections_inUnKnownEllipses
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
	cmd='select SC_SUM_FLAG<=1' cmd='sort SRCID'
rm DR9AllDetections_inGalaxies_nonCentral_noQSOnoSO
# All detections of ULX candidates.
stilts tpipe in=DR9AllDetections_inGalaxies_nonCentral_noQSOnoSO_lowFlag \
	ofmt=fits-basic omode=out out=DR9_ULXcandidateDetections \
	cmd='select "Luminosity+LuminosityErr>exp10(39)"' \
	cmd='keepcols "SRCID"' \
	cmd='colmeta -name SRCIDlist SRCID'
stilts tmatch2 \
	in1=DR9AllDetections_inGalaxies_nonCentral_noQSOnoSO_lowFlag \
	in2=DR9_ULXcandidateDetections \
	matcher=exact join=1and2 find=best1 \
	values1='SRCID' values2='SRCIDlist' \
	ocmd='delcols SRCIDlist' \
	ofmt=fits-basic omode=out out=DR9_ULXcandidateDetections
# Only the brightest ones.
stilts tpipe in=DR9AllDetections_inGalaxies_nonCentral_noQSOnoSO_lowFlag \
	ofmt=fits-basic omode=out out=DR9_BrightDetections \
	cmd='select "Luminosity+LuminosityErr>5*exp10(40)"' \
	cmd='keepcols "SRCID"' \
	cmd='colmeta -name SRCIDlist SRCID'
stilts tmatch2 \
	in1=DR9AllDetections_inGalaxies_nonCentral_noQSOnoSO_lowFlag \
	in2=DR9_BrightDetections \
	matcher=exact join=1and2 find=best1 \
	values1='SRCID' values2='SRCIDlist' \
	ocmd='delcols SRCIDlist' \
	ofmt=fits-basic omode=out out=DR9_BrightDetections
# Leave only Sources
stilts tmatch1 in=DR9AllDetections_inGalaxies_nonCentral_noQSOnoSO_lowFlag \
	matcher=exact values='SRCID' action=keep1 \
	ofmt=fits-basic omode=out out=DR9AllSources \
# Only ULX candidate sources
stilts tmatch1 in=DR9_ULXcandidateDetections \
	matcher=exact values='SRCID' action=keep1 \
	ofmt=fits-basic omode=out out=DR9_ULXcandidateSources
# Only Bright Sources
stilts tmatch1 in=DR9_BrightDetections \
	matcher=exact values='SRCID' action=keep1 \
	ofmt=fits-basic omode=out out=DR9_BrightSources \
