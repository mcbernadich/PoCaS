#!/bin/bash
# This script takes the XMM_nonNuclear_Catalogue file and adds extra boolean columns that say wether the entries contain information on ULXs or not. It also performs the cross-match with the Stacks catalogue. The script looks cumbersome from afar due to the stiff nature of some stilts commands, but the flow concepts are rather simple.
#-----------------------------------------------------------------------------------------------
echo "------------------------------------------------------------------------------------"
echo "Flagging sources of quality."
echo "------------------------------------------------------------------------------------"
#This first section looks for sources of quality.
#-----------------------------------------------------------------------------------------------
# Select all sources that classify as high quality.
# Erase all columns except for SRCID.
# Add the QUALITY column, which has a value of True.
# Rename SRCID to SRCIDlist to avoid confusion later on.
# Store their entries in XMM_Quality.
stilts tpipe in=XMM_nonNuclear_Catalogue \
	ofmt=fits-basic omode=out out=XMM_Quality \
	cmd='replaceval "none" "1" CONT_FLAG' \
	cmd='replaceval "none(PanSTARRS1)" "1" CONT_FLAG' \
	cmd='replaceval "none(NED)" "1" CONT_FLAG' \
	cmd='select "(CONT_FLAG==toString(1.)&SC_SUM_FLAG<=1&SC_Luminosity>SC_LuminosityErr&n_Galaxies==1)|(SRCID==203008001010008L|SRCID==203008001010028L|SRCID==200559902010008L|SRCID==206517409010009L|SRCID==200852202010008L|SRCID==205000702010002L|SRCID==200852202010026L)"' \
	cmd='keepcols "SRCID"' \
	cmd='addcol "QUALITY" "1==1"' \
	cmd='colmeta -name SRCIDlist SRCID'
# Select all the entries in XMM_nonNuclear_Catalogue that are not present in XMM_QUality.
# Erase all columns except for SRCID.
# Add the QUALITY column, which has a value of False.
# Rename SRCID to SRCIDlist to avoid confusion later on.
# Store their entries in XMM_noQUality
stilts tmatch2 in1=XMM_nonNuclear_Catalogue in2=XMM_Quality \
	ofmt=fits-basic omode=out out=XMM_noQuality \
	icmd1='keepcols "SRCID"' \
	icmd1='addcol "QUALITY" "1==0"' \
	icmd1='colmeta -name SRCIDlist SRCID' \
	matcher=exact join=1not2 find=best1 \
	values1='SRCIDlist' values2='SRCIDlist'
# Concatenate XMM_Quality and XMM_noQuality into XMM_QualityList.
stilts tcat in="XMM_Quality XMM_noQuality" \
	ofmt=fits-basic omode=out out=XMM_QualityList
rm XMM_Quality
rm XMM_noQuality
# Match all columns in XMM_nonNuclear_CatalogueXMM_QualityList
stilts tmatch2 \
	in1=XMM_nonNuclear_Catalogue \
	in2=XMM_QualityList \
	matcher=exact join=1and2 find=best1 \
	values1='SRCID' values2='SRCIDlist' \
	ocmd='delcols "SRCIDlist GroupID GroupSize"' \
	ofmt=fits-basic omode=out out=XMM_nonNuclear_Catalogue
rm XMM_QualityList
# This can be done in a quicker way by not erasing the columns in XMM_Quality and XMM_noQuality, and then concatenating them and naming the resulting file XMM_nonNuclear_Catalogue.
# However, this would arbitrarily change the order of entries in XMM_nonNuclear_Catalogue, which are nicelly gropued according to their CONT_FLAG values.
echo "------------------------------------------------------------------------------------"
echo "Flagging ULXs candidates."
echo "------------------------------------------------------------------------------------"
# This first section looks only for objects within the ULX luminosity regime.
# The procedure is analogous to the previous section, just with different file and column names.
# Comments are spared.
#-----------------------------------------------------------------------------------------------
# This time, instead of storing the SRCID column, it stores the SRC_OGC_ID one, because objects with more than one host galaxy have more than one luminosity value. They are treated independently.
stilts tpipe in=XMM_nonNuclear_Catalogue \
	ofmt=fits-basic omode=out out=XMM_ULXcandidateDetections \
	cmd='select "Luminosity+LuminosityErr>exp10(39)"' \
	cmd='keepcols "SRC_PGC_ID"' \
	cmd='addcol "ULX_REGIME" "1==1"' \
	cmd='colmeta -name SRC_PGC_IDlist SRC_PGC_ID'
stilts tmatch2 in1=XMM_nonNuclear_Catalogue in2=XMM_ULXcandidateDetections \
	ofmt=fits-basic omode=out out=XMM_noULXcandidateDetections \
	icmd1='keepcols "SRC_PGC_ID"' \
	icmd1='addcol "ULX_REGIME" "1==0"' \
	icmd1='colmeta -name SRC_PGC_IDlist SRC_PGC_ID' \
	matcher=exact join=1not2 find=best1 \
	values1='SRC_PGC_IDlist' values2='SRC_PGC_IDlist'
stilts tcat in="XMM_ULXcandidateDetections XMM_noULXcandidateDetections" \
	ofmt=fits-basic omode=out out=XMM_ULXcandidateList
rm XMM_ULXcandidateDetections
rm XMM_noULXcandidateDetections
stilts tmatch2 \
	in1=XMM_nonNuclear_Catalogue \
	in2=XMM_ULXcandidateList \
	matcher=exact join=1and2 find=best1 \
	values1='SRC_PGC_ID' values2='SRC_PGC_IDlist' \
	ocmd='delcols "SRC_PGC_IDlist GroupID GroupSize"' \
	ofmt=fits-basic omode=out out=XMM_nonNuclear_Catalogue
rm XMM_ULXcandidateList
# In this case it is necessary to reatach the columns with XMM_nonNuclear_Catalogue insted of concatienating the two tables. Different detections exist with have the same SRC_PGC_ID value, but only those that hold Luminosity+LuminosityErr>exp10(39) have been chosen.
# However, since the final match2 command oly looks at SRC_PGC_ID, entries with Luminosity+LuminosityErr<exp10(39) are still highlighted as ULX_REGIME=True if other detections of the same source they represent present Luminosity+LuminosityErr>exp10(39).
echo "------------------------------------------------------------------------------------"
echo "Flagging certain ULXs candidates"
echo "------------------------------------------------------------------------------------"
# Same as in the previous section, but the condition is now that the objects are ULXs for sure.
# Comments are spared.
# -------------------------------------------------------------------------------------------
stilts tpipe in=XMM_nonNuclear_Catalogue \
	ofmt=fits-basic omode=out out=XMM_ULXcandidateDetectionsCertain \
	cmd='select "SC_Luminosity-SC_LuminosityErr>exp10(39)"' \
	cmd='keepcols "SRC_PGC_ID"' \
	cmd='colmeta -name SRC_PGC_IDlist SRC_PGC_ID' \
	cmd='addcol "ULX_CERT" "1==1"'
stilts tpipe in=XMM_nonNuclear_Catalogue \
	ofmt=fits-basic omode=out out=XMM_ULXcandidateDetectionsNotCertain \
	cmd='select "SC_Luminosity-SC_LuminosityErr<exp10(39)"' \
        cmd='keepcols "SRC_PGC_ID"' \
	cmd='colmeta -name SRC_PGC_IDlist SRC_PGC_ID' \
	cmd='addcol "ULX_CERT" "0==1"'
stilts tcat in="XMM_ULXcandidateDetectionsCertain XMM_ULXcandidateDetectionsNotCertain" \
	ofmt=fits-basic omode=out out=XMM_ULXcandidateDetectionsCertainty
rm XMM_ULXcandidateDetectionsCertain
rm XMM_ULXcandidateDetectionsNotCertain
stilts tmatch2 \
	in1=XMM_nonNuclear_Catalogue \
	in2=XMM_ULXcandidateDetectionsCertainty \
	matcher=exact join=1and2 find=best1 \
	values1='SRC_PGC_ID' values2='SRC_PGC_IDlist' \
	ocmd='delcols "SRC_PGC_IDlist GroupID GroupSize"' \
	ofmt=fits-basic omode=out out=XMM_nonNuclear_Catalogue
rm XMM_ULXcandidateDetectionsCertainty
echo "------------------------------------------------------------------------------------"
echo "Flagging ULXs candidates of quality"
echo "------------------------------------------------------------------------------------"
# This section is completelly analogous to the very first one, but with the necessary conditions for ULXs of quality.
# Comments are spared.
# -----------------------------------------------------------------------------------------------
stilts tpipe in=XMM_nonNuclear_Catalogue \
	ofmt=fits-basic omode=out out=XMM_ULXcandidateQuality \
	cmd='replaceval "none" "1" CONT_FLAG' \
	cmd='replaceval "none(PanSTARRS1)" "1" CONT_FLAG' \
	cmd='replaceval "none(NED)" "1" CONT_FLAG' \
	cmd='select "(CONT_FLAG==toString(1.)&SC_SUM_FLAG<=1&SC_Luminosity>SC_LuminosityErr&n_Galaxies==1&Luminosity+LuminosityErr>exp10(39))|(SRCID==203008001010008L|SRCID==203008001010028L|SRCID==200559902010008L|SRCID==206517409010009L|SRCID==200852202010008L|SRCID==205000702010002L|SRCID==200852202010026L)"' \
	cmd='keepcols "SRCID"' \
	cmd='addcol "ULX_QUALITY" "1==1"' \
	cmd='colmeta -name SRCIDlist SRCID'
stilts tmatch2 in1=XMM_nonNuclear_Catalogue in2=XMM_ULXcandidateQuality \
	ofmt=fits-basic omode=out out=XMM_noULXcandidateQuality \
	icmd1='keepcols "SRCID"' \
	icmd1='addcol "ULX_QUALITY" "1==0"' \
	icmd1='colmeta -name SRCIDlist SRCID' \
	matcher=exact join=1not2 find=best1 \
	values1='SRCIDlist' values2='SRCIDlist'
stilts tcat in="XMM_ULXcandidateQuality XMM_noULXcandidateQuality" \
	ofmt=fits-basic omode=out out=XMM_ULXcandidateQualityList
rm XMM_ULXcandidateQuality
rm XMM_noULXcandidateQuality
stilts tmatch2 \
	in1=XMM_nonNuclear_Catalogue \
	in2=XMM_ULXcandidateQualityList \
	matcher=exact join=1and2 find=best1 \
	values1='SRCID' values2='SRCIDlist' \
	ocmd='delcols "SRCIDlist GroupID GroupSize"' \
	ofmt=fits-basic omode=out out=XMM_nonNuclear_Catalogue
rm XMM_ULXcandidateQualityList
echo "------------------------------------------------------------------------------------"
echo "Flagging bright ULXs candidates."
echo "------------------------------------------------------------------------------------"
# These three following sections repeats the three previous ones, but substituting exp10(39) for 5*exp10(40).
# Comments are spared.
#----------------------------------------------------------------------------------------------
stilts tpipe in=XMM_nonNuclear_Catalogue \
	ofmt=fits-basic omode=out out=XMM_brightULXcandidateDetections \
	cmd='select "Luminosity+LuminosityErr>5*exp10(40)"' \
	cmd='keepcols "SRC_PGC_ID"' \
	cmd='addcol "brightULX_REGIME" "1==1"' \
	cmd='colmeta -name SRC_PGC_IDlist SRC_PGC_ID'
stilts tmatch2 in1=XMM_nonNuclear_Catalogue in2=XMM_brightULXcandidateDetections \
	ofmt=fits-basic omode=out out=XMM_nobrightULXcandidateDetections \
	icmd1='keepcols "SRC_PGC_ID"' \
	icmd1='addcol "brightULX_REGIME" "1==0"' \
	icmd1='colmeta -name SRC_PGC_IDlist SRC_PGC_ID' \
	matcher=exact join=1not2 find=best1 \
	values1='SRC_PGC_IDlist' values2='SRC_PGC_IDlist'
stilts tcat in="XMM_brightULXcandidateDetections XMM_nobrightULXcandidateDetections" \
	ofmt=fits-basic omode=out out=XMM_brightULXcandidateList
rm XMM_brightULXcandidateDetections
rm XMM_nobrightULXcandidateDetections
stilts tmatch2 \
	in1=XMM_nonNuclear_Catalogue \
	in2=XMM_brightULXcandidateList \
	matcher=exact join=1and2 find=best1 \
	values1='SRC_PGC_ID' values2='SRC_PGC_IDlist' \
	ocmd='delcols "SRC_PGC_IDlist GroupID GroupSize"' \
	ofmt=fits-basic omode=out out=XMM_nonNuclear_Catalogue
rm XMM_brightULXcandidateList
echo "------------------------------------------------------------------------------------"
echo "Flagging bright certain ULXs candidates."
echo "------------------------------------------------------------------------------------"
stilts tpipe in=XMM_nonNuclear_Catalogue \
	ofmt=fits-basic omode=out out=XMM_brightULXcandidateDetectionsCertain \
	cmd='select "SC_Luminosity-SC_LuminosityErr>5*exp10(40)"' \
	cmd='keepcols "SRC_PGC_ID"' \
	cmd='colmeta -name SRC_PGC_IDlist SRC_PGC_ID' \
	cmd='addcol "brightULX_CERT" "1==1"'
stilts tpipe in=XMM_nonNuclear_Catalogue \
	ofmt=fits-basic omode=out out=XMM_brightULXcandidateDetectionsNotCertain \
	cmd='select "SC_Luminosity-SC_LuminosityErr<5*exp10(40)"' \
        cmd='keepcols "SRC_PGC_ID"' \
	cmd='colmeta -name SRC_PGC_IDlist SRC_PGC_ID' \
	cmd='addcol "brightULX_CERT" "0==1"'
stilts tcat in="XMM_brightULXcandidateDetectionsCertain XMM_brightULXcandidateDetectionsNotCertain" \
	ofmt=fits-basic omode=out out=XMM_brightULXcandidateDetectionsCertainty
rm XMM_brightULXcandidateDetectionsCertain
rm XMM_brightULXcandidateDetectionsNotCertain
stilts tmatch2 \
	in1=XMM_nonNuclear_Catalogue \
	in2=XMM_brightULXcandidateDetectionsCertainty \
	matcher=exact join=1and2 find=best1 \
	values1='SRC_PGC_ID' values2='SRC_PGC_IDlist' \
	ocmd='delcols "SRC_PGC_IDlist GroupID GroupSize"' \
	ofmt=fits-basic omode=out out=XMM_nonNuclear_Catalogue
rm XMM_brightULXcandidateDetectionsCertainty
echo "------------------------------------------------------------------------------------"
echo "Flagging bright ULXs candidates of quality."
echo "------------------------------------------------------------------------------------"
stilts tpipe in=XMM_nonNuclear_Catalogue \
	ofmt=fits-basic omode=out out=XMM_brightULXcandidateQuality \
	cmd='replaceval "none" "1" CONT_FLAG' \
	cmd='replaceval "none(PanSTARRS1)" "1" CONT_FLAG' \
	cmd='replaceval "none(NED)" "1" CONT_FLAG' \
	cmd='select "(CONT_FLAG==toString(1.)&SC_SUM_FLAG<=1&SC_Luminosity>SC_LuminosityErr&n_Galaxies==1&Luminosity+LuminosityErr>5*exp10(40))|(SRCID==206517409010009L)"' \
	cmd='keepcols "SRCID"' \
	cmd='addcol "brightULX_QUALITY" "1==1"' \
	cmd='colmeta -name SRCIDlist SRCID'
stilts tmatch2 in1=XMM_nonNuclear_Catalogue in2=XMM_brightULXcandidateQuality \
	ofmt=fits-basic omode=out out=XMM_nobrightULXcandidateQuality \
	icmd1='keepcols "SRCID"' \
	icmd1='addcol "brightULX_QUALITY" "1==0"' \
	icmd1='colmeta -name SRCIDlist SRCID' \
	matcher=exact join=1not2 find=best1 \
	values1='SRCIDlist' values2='SRCIDlist'
stilts tcat in="XMM_brightULXcandidateQuality XMM_nobrightULXcandidateQuality" \
	ofmt=fits-basic omode=out out=XMM_brightULXcandidateQualityList
rm XMM_brightULXcandidateQuality
rm XMM_nobrightULXcandidateQuality
stilts tmatch2 \
	in1=XMM_nonNuclear_Catalogue \
	in2=XMM_brightULXcandidateQualityList \
	matcher=exact join=1and2 find=best1 \
	values1='SRCID' values2='SRCIDlist' \
	ocmd='delcols "SRCIDlist GroupID GroupSize"' \
	ofmt=fits-basic omode=out out=XMM_nonNuclear_Catalogue
rm XMM_brightULXcandidateQualityList
echo "------------------------------------------------------------------------------------"
echo "Performing the cross-match with the 4XMM-DR9s catalogue."
echo "------------------------------------------------------------------------------------"
# Correlate XMM_nonNuclear_Catalogue with 4XMM-DR9s with a 3-sigma sky match.
# Select only 4XMM-DR9s sources with N_CONTRIB>1.
# Store SRCID (4XMM-DR9) and SRCID (4XMM-DR9s) the coordinates of the source in stakcs, N_OBS, N_CONTRIB and VAR_PROB FRATIO FRATIO_ERR FLUXVAR in XMM_stacks.
stilts tmatch2 in1=XMM_nonNuclear_Catalogue \
	in2=/net/konraid/xray/XMMcat/xmmstack_v2.0_4xmmdr9s.fits.gz \
	icmd2='select N_CONTRIB>1' \
	find=best fixcols=dups suffix2=_stacks suffix1=null join=1and2 matcher=skyerr \
	values2='RA DEC 3*RADEC_ERR' values1='SC_RA SC_DEC 3*SC_POSERR' params=5 \
	ocmd='keepcols "SRCID SRCID_stacks RA_stacks DEC_stacks RADEC_ERR_stacks N_OBS N_CONTRIB VAR_PROB FRATIO FRATIO_ERR FLUXVAR"' \
	ocmd='colmeta -name SRCIDlist SRCID' \
	ofmt=fits-basic omode=out out=XMM_stacks
# Join them with XMM_nonNuclear_Catalogue.
stilts tmatch2 \
	in1=XMM_nonNuclear_Catalogue \
	in2=XMM_stacks \
	matcher=exact join=all1 find=best1 \
	ofmt=fits-basic omode=out out=XMM_nonNuclear_Catalogue \
	values1='SRCID' values2='SRCIDlist' \
	ocmd='delcols "SRCIDlist GroupID GroupSize"'
rm XMM_stacks
# This part of the code is now left as a relique. It was used to get the list of sources for manual inspection. These sources have already been inspected and therefore it is not useful to run this part of the code again.
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


