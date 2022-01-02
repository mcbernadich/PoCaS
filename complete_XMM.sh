#!/bin/bash
# This script creates the luminosity subsamples.
echo "------------------------------------------------------------------------------------"
echo "Building the luminosity subsamples."
echo "------------------------------------------------------------------------------------"
# Add three new columns with D_max for each luminosity subsample.
# The thresholds are computed with a sensitivity of exp10(-14) through the inverse squared law.
stilts tpipe \
	in=XMM_nonNuclear_Catalogue \
	out=XMM_thresholdDistances ofmt=fits-basic \
	cmd='addcol -after D -units Mpc D38 "mToMpc(sqrt(exp10(38)/(4*PI*exp10(-14))))/100"' \
	cmd='addcol -after D38 -units Mpc D39 "mToMpc(sqrt(exp10(39)/(4*PI*exp10(-14))))/100"' \
	cmd='addcol -after D39 -units Mpc D5x40 "mToMpc(sqrt((5*exp10(40))/(4*PI*exp10(-14))))/100"' \
	cmd='replaceval none null CONT_FLAG' \
	cmd='replaceval none(PanSTARRS1) null CONT_FLAG' \
	cmd='replaceval none(NED) null CONT_FLAG'
# Select the entries with galaxies whithin the threshold and other quality constraints.
# Keep only the SRCID column. Turn it into SRCIDlist38 to avoid future confusion.
# Create column ss38, with a value of True.
# Store them in XMM_complete38.
stilts tpipe \
	in=XMM_thresholdDistances \
	out=XMM_complete38 ofmt=fits-basic omode=out \
	cmd='select D<D38' \
	cmd='select SC_Luminosity>SC_LuminosityErr' \
	cmd='select abs(DEC_HEC_GAL)>25' \
	cmd="select toString(MATCH_FLAG)==toString(0.)" \
	cmd='select CONT_FLAG==null' \
	cmd='select n_Galaxies==1' \
	cmd='select SC_SUM_FLAG<=1' \
	cmd='addcol ss38 "1==1"' \
	cmd='colmeta -name SRCIDlist38 SRCID' \
	cmd='keepcols "SRCIDlist38 ss38"'
# Select entries not appearing in XMM_complete38.
# Keep only the SRCID column. Turn it into SRCIDlist38 to avoid future confusion.
# Create column ss38, with a value of False.
# Store them in XMM_noComplete38.
stilts tmatch2 \
	in1=XMM_nonNuclear_Catalogue in2=XMM_complete38 \
	ofmt=fits-basic omode=out out=XMM_noComplete38 \
	matcher=exact join=1not2 find=best1 \
	values1=SRCIDlist38 values2=SRCIDlist38 \
	icmd1='keepcols SRCID' \
	icmd1='addcol ss38 "1==0"' \
	icmd1='colmeta -name "SRCIDlist38" "SRCID"'
# Concatenate XMM_Complete38 and XMM_noComplete38 into XMM_complete38
stilts tcat in="XMM_complete38 XMM_noComplete38" \
	ofmt=fits-basic omode=out out=XMM_complete38
rm XMM_noComplete38
# Repeat with the other subsamples.
stilts tpipe \
	in=XMM_thresholdDistances \
	out=XMM_complete39 ofmt=fits-basic omode=out \
	cmd='select D<D39' \
	cmd='select SC_Luminosity>SC_LuminosityErr' \
	cmd='select abs(DEC_HEC_GAL)>25' \
	cmd="select toString(MATCH_FLAG)==toString(0.)" \
	cmd='select CONT_FLAG==null' \
	cmd='select n_Galaxies==1' \
	cmd='select SC_SUM_FLAG<=1' \
	cmd='addcol ss39 "1==1"' \
	cmd='colmeta -name SRCIDlist39 SRCID' \
	cmd='keepcols "SRCIDlist39 ss39"'
stilts tmatch2 \
	in1=XMM_nonNuclear_Catalogue in2=XMM_complete39 \
	ofmt=fits-basic omode=out out=XMM_noComplete39 \
	matcher=exact join=1not2 find=best1 \
	values1=SRCIDlist39 values2=SRCIDlist39 \
	icmd1='keepcols SRCID' \
	icmd1='addcol ss39 "1==0"' \
	icmd1='colmeta -name "SRCIDlist39" "SRCID"'
stilts tcat in="XMM_complete39 XMM_noComplete39" \
	ofmt=fits-basic omode=out out=XMM_complete39
rm XMM_noComplete39
stilts tpipe \
	in=XMM_thresholdDistances \
	out=XMM_complete40 ofmt=fits-basic omode=out \
	cmd='select D<D5x40' \
	cmd='select SC_Luminosity>SC_LuminosityErr' \
	cmd='select abs(DEC_HEC_GAL)>25' \
	cmd="select toString(MATCH_FLAG)==toString(0.)" \
	cmd='select CONT_FLAG==null' \
	cmd='select n_Galaxies==1' \
	cmd='select SC_SUM_FLAG<=1' \
	cmd='addcol ss5x40 "1==1"' \
	cmd='colmeta -name SRCIDlist40 SRCID' \
	cmd='keepcols "SRCIDlist40 ss5x40"'
stilts tmatch2 \
	in1=XMM_nonNuclear_Catalogue in2=XMM_complete40 \
	ofmt=fits-basic omode=out out=XMM_noComplete40 \
	matcher=exact join=1not2 find=best1 \
	values1=SRCIDlist40 values2=SRCIDlist40 \
	icmd1='keepcols SRCID' \
	icmd1='addcol ss5x40 "1==0"' \
	icmd1='colmeta -name "SRCIDlist40" "SRCID"'
stilts tcat in="XMM_complete40 XMM_noComplete40" \
	ofmt=fits-basic omode=out out=XMM_complete40
rm XMM_noComplete40
echo "------------------------------------------------------------------------------------"
echo "Add the luminosity subsamples into XMM_nonNuclear_Catalogue."
echo "------------------------------------------------------------------------------------"
# Make a 4 sided cross-match of XMM_nonNuclear_Catalogue with the XMM_complete files.
# Use SRCID and the SRCIDlist columns all across.
# Join the later to the first table.
# Correct the names of the columns DET_PGC_ID.
stilts tmatchn in1=XMM_nonNuclear_Catalogue nin=4 \
	in2=XMM_complete38 in3=XMM_complete39 in4=XMM_complete40 \
	ofmt=fits-basic omode=out out=XMM_nonNuclear_Catalogue \
	join1=always matcher=exact multimode=pairs \
	values1="SRCID" values2="SRCIDlist38" values3="SRCIDlist39" values4="SRCIDlist40" \
	ocmd='delcols "SRCIDlist38 SRCIDlist39 SRCIDlist40"' \
	ocmd='colmeta -name DET_PGC_ID DET_PGC_ID_1' \
	ocmd='colmeta -name DET_PGC_ID DET_PGC_ID_1a'
echo "------------------------------------------------------------------------------------"
echo "Build the remaining subsamples"
echo "------------------------------------------------------------------------------------"
stilts tpipe in=XMM_nonNuclear_Catalogue \
	ofmt=fits-basic omode=out \
	out=XMM_nonNuclear_Catalogue \
	cmd='addcol cULXss "ss39&&ULX_QUALITY"' \
	cmd='addcol cbULXss "ss5x40&&brightULX_QUALITY"'
#rm XMM_thresholdDistances
# Build the ULX and bright ULX subsamples.
#stilts tmatch2 \
#	in1=XMM_ULXcandidateSources in2=XMM_complete39 \
#	ofmt=fits-basic omode=out out=XMM_ULXsubsample \
#	find=best1 fixcols=dups suffix1=null suffix2=_complete \
#	values1="SRCID" values2="SRCID" matcher=exact join=1and2
#stilts tmatch2 \
#	in1=XMM_BrightSources in2=XMM_complete40 \
#	ofmt=fits-basic omode=out out=XMM_BrightSubsample \
#	find=best1 fixcols=dups suffix1=null suffix2=_complete \
#	values1="SRCID" values2="SRCID" matcher=exact join=1and2


