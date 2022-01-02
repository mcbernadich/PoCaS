#!/bin/bash
# All detections of ULX candidates.
stilts tpipe in=XMM_nonNuclear_Catalogue \
	ofmt=fits-basic omode=out out=XMM_ULXcandidateDetections \
	cmd='select "Luminosity+LuminosityErr>exp10(39)"' \
	cmd='keepcols "SRC_PGC_ID"' \
	cmd='colmeta -name SRC_PGC_IDlist SRC_PGC_ID'
stilts tmatch2 \
	in1=XMM_nonNuclear_Catalogue \
	in2=XMM_ULXcandidateDetections \
	matcher=exact join=1and2 find=best1 \
	values1='SRC_PGC_ID' values2='SRC_PGC_IDlist' \
	ocmd='delcols SRC_PGC_IDlist' \
	ocmd='colmeta -name DET_PGC_ID DET_PGC_ID_1' \
	ofmt=fits-basic omode=out out=XMM_ULXcandidateDetections
stilts tpipe in=XMM_ULXcandidateDetections \
	ofmt=fits-basic omode=out out=XMM_ULXcandidateDetectionsCertain \
	cmd='select "SC_Luminosity-SC_LuminosityErr>exp10(39)"' \
	cmd='addcol -after "MATCH_FLAG" "CERT_FLAG" "1==1"'
stilts tpipe in=XMM_ULXcandidateDetections \
	ofmt=fits-basic omode=out out=XMM_ULXcandidateDetectionsNotCertain \
	cmd='select "SC_Luminosity-SC_LuminosityErr<exp10(39)"' \
	cmd='addcol -after "MATCH_FLAG" "CERT_FLAG" "0==1"'
stilts tcat in="XMM_ULXcandidateDetectionsCertain XMM_ULXcandidateDetectionsNotCertain" \
	ofmt=fits-basic omode=out out=XMM_ULXcandidateDetections
# Only the brightest ones.
stilts tpipe in=XMM_nonNuclear_Catalogue \
	ofmt=fits-basic omode=out out=XMM_BrightDetections \
	cmd='select "Luminosity+LuminosityErr>5*exp10(40)"' \
	cmd='keepcols "SRC_PGC_ID"' \
	cmd='colmeta -name SRC_PGC_IDlist SRC_PGC_ID'
stilts tmatch2 \
	in1=XMM_nonNuclear_Catalogue \
	in2=XMM_BrightDetections \
	matcher=exact join=1and2 find=best1 \
	values1='SRC_PGC_ID' values2='SRC_PGC_IDlist' \
	ocmd='delcols SRC_PGC_IDlist' \
	ocmd='colmeta -name DET_PGC_ID DET_PGC_ID_1' \
	ofmt=fits-basic omode=out out=XMM_BrightDetections
stilts tpipe in=XMM_BrightDetections \
	ofmt=fits-basic omode=out out=XMM_BrightDetectionsCertain \
	cmd='select "SC_Luminosity-SC_LuminosityErr>5*exp10(40)"' \
	cmd='addcol -after "MATCH_FLAG" "CERT_FLAG" "1==1"'
stilts tpipe in=XMM_BrightDetections \
	ofmt=fits-basic omode=out out=XMM_BrightDetectionsNotCertain \
	cmd='select "SC_Luminosity-SC_LuminosityErr<5*exp10(40)"' \
	cmd='addcol -after "MATCH_FLAG" "CERT_FLAG" "0==1"'
stilts tcat in="XMM_BrightDetectionsCertain XMM_BrightDetectionsNotCertain" \
	ofmt=fits-basic omode=out out=XMM_BrightDetections
# Leave only Sources
stilts tmatch1 in=XMM_nonNuclear_Catalogue \
	matcher=exact values='SRC_PGC_ID' action=keep1 \
	ofmt=fits-basic omode=out out=XMM_AllSources
# Only ULX candidate sources
stilts tmatch1 in=XMM_ULXcandidateDetections \
	matcher=exact values='SRC_PGC_ID' action=keep1 \
	ofmt=fits-basic omode=out out=XMM_ULXcandidateSources
# Only Bright Sources
stilts tmatch1 in=XMM_BrightDetections \
	matcher=exact values='SRC_PGC_ID' action=keep1 \
	ofmt=fits-basic omode=out out=XMM_BrightSources \
# Leave only the sources of quality
stilts tpipe in=XMM_AllSources \
	cmd='replaceval "none" "1" CONT_FLAG' \
	cmd='replaceval "none(PanSTARRS1)" "1" CONT_FLAG' \
	cmd='select "CONT_FLAG==toString(1.)&SC_SUM_FLAG<=1&SC_Luminosity>SC_LuminosityErr&n_Galaxies==1"' \
	ofmt=fits-basic omode=out out=XMM_AllSourcesQuality
stilts tpipe in=XMM_ULXcandidateSources \
	cmd='replaceval "none" "1" CONT_FLAG' \
	cmd='replaceval "none(PanSTARRS1)" "1" CONT_FLAG' \
	cmd='select "CONT_FLAG==toString(1.)&SC_SUM_FLAG<=1&SC_Luminosity>SC_LuminosityErr&n_Galaxies==1"' \
	ofmt=fits-basic omode=out out=XMM_ULXcandidateSourcesQuality
stilts tpipe in=XMM_BrightSources \
	cmd='replaceval "none" "1" CONT_FLAG' \
	cmd='replaceval "none(PanSTARRS1)" "1" CONT_FLAG' \
	cmd='select "CONT_FLAG==toString(1.)&SC_SUM_FLAG<=1&SC_Luminosity>SC_LuminosityErr&n_Galaxies==1"' \
	ofmt=fits-basic omode=out out=XMM_BrightSourcesQuality
# Correlate with 4XMM-DR9s
stilts tmatch2 in2=XMM_ULXcandidateSourcesQuality \
	in1=/net/konraid/xray/XMMcat/xmmstack_v2.0_4xmmdr9s.fits.gz \
	icmd1='select N_CONTRIB>1' \
	find=best fixcols=dups suffix1=_stacks suffix2=null join=1and2 matcher=skyerr \
	values1='RA DEC 3*RADEC_ERR' values2='SC_RA SC_DEC 3*SC_POSERR' params=5 \
	ofmt=fits-basic omode=out out=XMM_ULXstacksClean \
	ocmd='delcols "Separation"'
# This part of the code is now left as a relique. It was used to get the list of sources for manual inspection. These sources have already been inspected and therefore it is not useful to run over this part of the code.
# Leave the ones detected by PanSTARRS, but of quality. We want to make sure that all the discarted sources are correctly excluded.
#stilts tpipe in=XMM_AllSources \
#	cmd='replaceval "PanSTARRS1" "1" CONT_FLAG' \
#	cmd='select "CONT_FLAG==toString(1.)&SC_SUM_FLAG<=1&SC_Luminosity>SC_LuminosityErr&n_Galaxies==1"' \
#	ofmt=fits-basic omode=out out=XMM_AllSourcesPanSTARRS
#stilts tpipe in=XMM_ULXcandidateSources \
#	cmd='replaceval "PanSTARRS1" "1" CONT_FLAG' \
#	cmd='select "CONT_FLAG==toString(1.)&SC_SUM_FLAG<=1&SC_Luminosity>SC_LuminosityErr&n_Galaxies==1"' \
#	ofmt=fits-basic omode=out out=XMM_ULXcandidateSourcesPanSTARRS
#stilts tpipe in=XMM_BrightSources \
#	cmd='replaceval "PanSTARRS1" "1" CONT_FLAG' \
#	cmd='select "CONT_FLAG==toString(1.)&SC_SUM_FLAG<=1&SC_Luminosity>SC_LuminosityErr&n_Galaxies==1"' \
#	ofmt=fits-basic omode=out out=XMM_BrightSourcesPanSTARRS
# Correlate with 4XMM-DR9s
#stilts tmatch2 in2=XMM_ULXcandidateSourcesPanSTARRS \
#	in1=/net/konraid/xray/XMMcat/xmmstack_v2.0_4xmmdr9s.fits.gz \
#	icmd1='select N_CONTRIB>1' \
#	find=best fixcols=dups suffix1=_stacks suffix2=null join=1and2 matcher=skyerr \
#	values1='RA DEC 3*RADEC_ERR' values2='SC_RA SC_DEC 3*SC_POSERR' params=5 \
#	ofmt=fits-basic omode=out out=XMM_ULXstacksPanSTARRS \
#	ocmd='delcols "Separation"'


