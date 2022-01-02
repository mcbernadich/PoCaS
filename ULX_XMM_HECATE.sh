#!/bin/bash
#|===============================================================================================|
#| This bash script was written by Miquel Colom Bernadich i la mare que el va parir.             |
#|-----------------------------------------------------------------------------------------------|
#| Sempre, qui fa la feina no té les eines que dónen treball.                                    |
#|                    -EINA (L'estat i la revolució, 2011)                                       |
#| Docs jo et dóno l'eina: ULX_XMM_HECATE.sh                                                     |
#|                    -Jo (Ultraluminous sources in the XMM-Newton and eROSITA Surveys, 2020)    |
#| (Date)                                                                                        |
#|-----------------------------------------------------------------------------------------------|
#| This is the main pipeline for the 4XMM-DR9 survey.                                            |
#| No extra inputs are needed.                                                                   |
#| The script should be called from the ULXscriptCompilation.sh motherscript                     |
#| The user should pay attention to the location of files before running it,                     |
#| as the STILTS commands will look for them.                                                    |
#|===============================================================================================|
echo "------------------------------------------------------------------------------------"
echo "Correlate hecate and the list of point-like sources within 3 sigma."
echo "------------------------------------------------------------------------------------"
echo "For this, first split according to position angle."
echo "------------------------------------------------------------------------------------"
# Divide galaxies in 3 files according to their available information.
#----------------------------------------------------------------------
# Make sure that galaxies with no listed PA values aren't excluded.
# Assigne them PA=0. 
# One list is made. HECATE_knownEllipses contains galaxies with PA!=0list.
stilts tpipe \
	in=HECATE/HECATE_slim_2.1.fits \
	out=HECATE_knownEllipses \
	cmd='replaceval null 0. "PA"' \
	ofmt=fits-basic cmd='select "PA!=0."'
# Among the reminding galaxies. Make sure that galaxies with no listed R2 values aren't excluded.
# Assign them R2=0.
# Two further lists are made. HECATE_unKnownEllipses contains galaxies with PA=0 and R2!=0.
stilts tpipe \
	in=HECATE/HECATE_slim_2.1.fits \
	out=HECATE_unKnownEllipses \
	cmd='replaceval null 0. "PA"' \
	cmd='replaceval null 0. "R2"' \
	ofmt=fits-basic cmd='select "PA==0&R2!=0."'
# HECATE_unKnownShapes contains galaxies with PA=0 and R2=0.
stilts tpipe \
	in=HECATE/HECATE_slim_2.1.fits \
	out=HECATE_unKnownShape \
	cmd='replaceval null 0. "PA"' \
	cmd='replaceval null 0. "R2"' \
	ofmt=fits-basic cmd='select "PA==0&R2==0."'
# The three created files contain all existing combinations of ellipse information in HECATE, as R1 is present in all entries.
echo "------------------------------------------------------------------------------------"
echo "Find all sources within galaxies with known position angle, give them flag 0."
echo "------------------------------------------------------------------------------------"
# Now the section where galaxy and sources are correlated begins. Create 4 lists.
# 1 for sources in galaxies with known PA (R1, R2, Pa ellipse), 1 for the inncer circle (R2 circle) of unknown PA, 1 for the outher circle (R1-R2 ring), and 1 for unknown R2 (just R1 ring).
# -----------------------------------------------------------------------------------------
# Start with known PA.
# Correlate point-like sources of high detection likelyhood (>8) with HECATE_knownEllipses.
# 1-sigma source positional uncertainty and the ispothal galaxy ellipses (R1,R2,PA) are used.
# Sources can be associated to ore than 1 galaxy. A detection in more than one galaxy has an entry for each galaxy.
# Create DET_PGC_ID and SRC_PGC_ID to distinguish between diferent entries of the same detection/source associated to diferent galaxies.
# This is done by concatenating the DETID and SRC numbers with the PGC number of the associated galaxy.
# DET_PGC_ID is unique to every entry of the catalogue.
# Assign MATCH_FLAG=0 (string) is given to all the sources here to indicate tha PA is known.
# Store sources + mathced galaceis in allsources_inKnownEllpises.
stilts tmatch2 \
	in1=4XMM-DR9/DR9_pointlikely \
	in2=HECATE_knownEllipses \
	find=all fixcols=dups suffix1=null suffix2=_HEC join=1and2 matcher=skyellipse \
	values1='SC_RA SC_DEC SC_POSERR SC_POSERR 0' values2='RA DEC R1*60 R2*60 PA' params=10 \
	ocmd='addcol -after SC_POSERR MATCH_FLAG "toString(0.)"' \
	ocmd='addcol -after SRCID DET_PGC_ID concat(DETID,PGC)' \
	ocmd='addcol -after DET_PGC_ID SRC_PGC_ID concat(SRCID,PGC)' \
	ofmt=fits-basic omode=out out=allsources_inKnownEllipses
rm HECATE_knownEllipses
echo "------------------------------------------------------------------------------------"
echo "Find all sources within the minor circle of the remaining galaxies, give them flag 1."
echo "------------------------------------------------------------------------------------"
# Continue with sources within R2 of galaxies with unknown PA.
# Monstly repeat the previous step, but with HECATE_unknownEllipses.
# Use only R2 as the radius of galaxies for the cross-match.
# Assign MATCH_FLAG=1.
# Store sources + matched galaxies in allsources_inUnKnownEllipses_minor.
stilts tmatch2 \
	in1=4XMM-DR9/DR9_pointlikely \
	in2=HECATE_unKnownEllipses \
	find=all fixcols=dups suffix1=null suffix2=_HEC join=1and2 matcher=skyerr \
	values1='SC_RA SC_DEC SC_POSERR' values2='RA DEC R2*60' params=10 \
	ocmd='addcol -after SC_POSERR MATCH_FLAG "toString(1.)"' \
	ocmd='addcol -after SRCID DET_PGC_ID concat(DETID,PGC)' \
	ocmd='addcol -after DET_PGC_ID SRC_PGC_ID concat(SRCID,PGC)' \
	ofmt=fits-basic omode=out out=allsources_inUnKnownEllipses_minor
echo "------------------------------------------------------------------------------------"
echo "Find all sources within major circle of the remaining galaxies, give them flag 2, subtract the ones within the minor circle."
echo "------------------------------------------------------------------------------------"
# Continue with sources within the R1-R2 of galaxies with unknown PA.
# Monstly repeat the previous step, but with HECATE_unknownEllipses.
# Use only R1 as the radius of galaxies for the cross-match.
# Assign MATCH_FLAG=2.
# Store sources + matched galaxies in allsources_inUnKnownEllipses_major
# allsources_inUnKnownEllipses_major overlaps with the entirety of allsources_inUnKnownEllipses_minor.
stilts tmatch2 \
	in1=4XMM-DR9/DR9_pointlikely \
	in2=HECATE_unKnownEllipses \
	find=all fixcols=dups suffix1=null suffix2=_HEC join=1and2 matcher=skyerr \
	values1='SC_RA SC_DEC SC_POSERR' values2='RA DEC R1*60' params=10 \
	ocmd='addcol -after SC_POSERR MATCH_FLAG "toString(2.)"' \
	ocmd='addcol -after SRCID DET_PGC_ID concat(DETID,PGC)' \
	ocmd='addcol -after DET_PGC_ID SRC_PGC_ID concat(SRCID,PGC)' \
	ofmt=fits-basic omode=out out=allsources_inUnKnownEllipses_major
# Subtract all the overlaping sources from allsources_inUnKnownEllipses_major.
# Perform the overlap search with DET_PGC_ID to treat the same detections in diferent galaxies independently. Otherwise, sources in the worng galaxy are deleted. 
# Keep the reduced version of allsources_inUnKnownEllipses_major.
# There are no overlapping entries anymore.
stilts tmatch2 \
	in1=allsources_inUnKnownEllipses_major \
	in2=allsources_inUnKnownEllipses_minor \
	find=best fixcols=none join=1not2 matcher=exact \
	values1='DET_PGC_ID' values2='DET_PGC_ID' \
	ofmt=fits-basic omode=out out=allsources_inUnKnownEllipses_major
echo "------------------------------------------------------------------------------------"
echo "Find all sources within the single circle of galaxies with unknown R2, give them flag 3."
echo "------------------------------------------------------------------------------------"
# Continue with sources within galaxies with unknown PA and R2.
# Monstly repeat the previous steps, but with HECATE_unknownShapes.
# Use only R1 as the radius of galaxies for the cross-match.
# Assign MATCH_FLAG=3.
stilts tmatch2 \
	in1=4XMM-DR9/DR9_pointlikely \
	in2=HECATE_unKnownShape \
	find=all fixcols=dups suffix1=null suffix2=_HEC join=1and2 matcher=skyerr \
	values1='SC_RA SC_DEC SC_POSERR' values2='RA DEC R1*60' params=10 \
	ocmd='addcol -after SC_POSERR MATCH_FLAG "toString(3.)"' \
	ocmd='addcol -after SRCID DET_PGC_ID concat(DETID,PGC)' \
	ocmd='addcol -after DET_PGC_ID SRC_PGC_ID concat(SRCID,PGC)' \
	ofmt=fits-basic omode=out out=allsources_inUnKnownShapes
rm HECATE_unKnownEllipses
echo "------------------------------------------------------------------------------------"
echo "Join all of them into one single catalogue and compute luminosities."
echo "------------------------------------------------------------------------------------"
# Concatenates the four list of sources built in the previous steps.
# Compute luminosity parameters from the EPIC fluxes for detections and sources, and galaxy distances. Propagate uncertainties too.
# Compute distances from detection/source postions to the center of host galaxies in arcsec.
# Delete columns GroupID, GroupSize and Separation from the previous matches.
stilts tcat in='allsources_inKnownEllipses allsources_inUnKnownEllipses_minor allsources_inUnKnownEllipses_major allsources_inUnKnownShapes' \
	ofmt=fits-basic omode=out out=XMM_allDetections_inGalaxies \
	ocmd='addcol -after MATCH_FLAG -units erg/s Luminosity "EP_8_FLUX*4*PI*square(MpcToM(D)*100)"' \
	ocmd='addcol -after Luminosity -units erg/s LuminosityErr "sqrt(square(EP_8_FLUX_ERR*4*PI*square(MpcToM(D)*100))+square(EP_8_FLUX*8*PI*MpcToM(D)*MpcToM(D_ERR)*10000))"' \
	ocmd='addcol -after LuminosityErr -units erg/s SC_Luminosity "SC_EP_8_FLUX*4*PI*square(MpcToM(D)*100)"' \
	ocmd='addcol -after SC_Luminosity -units erg/s SC_LuminosityErr "sqrt(square(SC_EP_8_FLUX_ERR*4*PI*square(MpcToM(D)*100))+square(SC_EP_8_FLUX*8*PI*MpcToM(D)*MpcToM(D_ERR)*10000))"' \
	ocmd='addcol -after MATCH_FLAG -units arcsec CenterDist "skyDistanceDegrees(RA,DEC,RA_HEC,DEC_HEC)*3600"' \
	ocmd='addcol -after CenterDist -units arcsec MinCenterDist "CenterDist-3*POSERR"' \
	ocmd='delcols "GroupID GroupSize"' \
	ocmd='addcol -after MinCenterDist -units arcsec SC_CenterDist "skyDistanceDegrees(SC_RA,SC_DEC,RA_HEC,DEC_HEC)*3600"' \
	ocmd='addcol -after SC_CenterDist -units arcsec SC_MinCenterDist "SC_CenterDist-3*SC_POSERR"' \
	ocmd='delcols "Separation"'
rm allsources_inKnownEllipses
rm allsources_inUnKnownEllipses_minor
rm allsources_inUnKnownEllipses_major
echo "------------------------------------------------------------------------------------"
echo "Create a column counting in how manygalaxies has a source been found"
echo "------------------------------------------------------------------------------------"
# Look for detections/sources found in more than one galaxy and count their host galaxies.
# DETID is a unique indicator for each detection, but not for every host galaxy.
# Group and count repeated DETIDs to count host galaxies.
# Store this information in the n_Galaxies column.
stilts tmatch1 in=XMM_allDetections_inGalaxies \
	matcher=exact values="DETID" action="identify" \
	ofmt=fits-basic omode=out out=XMM_allDetections_inGalaxies \
	ocmd='replaceval "null" "1" "GroupSize"' \
	ocmd='addcol -after MATCH_FLAG n_Galaxies "GroupSize"' \
	ocmd='delcols "GroupID GroupSize"'
echo "------------------------------------------------------------------------------------"
echo "Remove all central sources."
echo "------------------------------------------------------------------------------------"
# This section looks for central (nuclear) sources and flags them.
# For sources in more than one galaxy, they will have their own distinct flag.
# ------------------------------------------------------------------------------------------
# Select all surces at a distance+3-sigma positional uncertainty from their galactic center larger than 3 arcsec.
# Store them in the XMM_noNuclear file. The name is straightforward.
stilts tpipe in=XMM_allDetections_inGalaxies \
	ofmt=fits-basic omode=out out=XMM_noNuclear \
	cmd='select "SC_MinCenterDist>3"'
# Store the reminder in XMM_Nuclear.
# Compare DET_PG_ID, and select all entries not present in XMM_noNuclear.
# Add the CONT_FLAG, CONT_ID, OBJ_TYPE and contminant position columns.
# The source-contaminant distance is equal to the distance to the center of the host galaxy.
# CONT_FLAG="central" OBJ_TYPE="central" CONT_ID=SRCID.
stilts tmatch2 \
	in1=XMM_allDetections_inGalaxies \
	in2=XMM_noNuclear \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='DET_PGC_ID' values2='DET_PGC_ID' \
	ofmt=fits-basic omode=out out=XMM_Nuclear \
	icmd1='addcol "DET_PGC_ID" "DET_PGC_ID"' \
	icmd1='addcol "CONT_FLAG" "toString(1.)"' \
	icmd1='replaceval "1" "central" "CONT_FLAG"' \
	icmd1='addcol "CONT_ID" "toString(SRCID)"' \
	icmd1='addcol "RA_CONT" "1."' \
	icmd1='replaceval "1." "null" "RA_CONT"' \
	icmd1='addcol "DEC_CONT" "RA_CONT"' \
	icmd1='addcol "OBJ_TYPE" "CONT_FLAG"' \
	icmd1='addcol "ContDist" "CenterDist"' \
	icmd1='addcol "SC_ContDist" "SC_CenterDist"'
rm XMM_allDetections_inGalaxies
echo "------------------------------------------------------------------------------------"
echo "Identify sources that are central in other galaxies."
echo "------------------------------------------------------------------------------------"
# Compare SRCID to see all entries realted to a source deemed as centrel in one of the galaxies.
# Select those entries in XMM_noNuclear whose SRCID does NOT appear in XMM_Nuclear.
# Store them in XMM_noPotentiallyNuclear.
stilts tmatch2 \
	in1=XMM_noNuclear \
	in2=XMM_Nuclear \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='SRCID' values2='SRCID' \
	ofmt=fits-basic omode=out out=XMM_noPotentiallyNuclear
# Select those entries in XMM_noNuclear whose SRCID does NOT appear in XMM_noPotentiallyNuclear.
# All selected entries share n_Galaxies>1, and are central in one of the other assigne host galaxies.
# Store them in XMM_PotentiallyNuclear.
# Create the contaminant columns.
# CONT_FLAG="central_candidate" OBJ_TYPE="central_Candidate" CONT_ID=SRCID
stilts tmatch2 \
	in1=XMM_noNuclear \
	in2=XMM_noPotentiallyNuclear \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='SRCID' values2='SRCID' \
	ofmt=fits-basic omode=out out=XMM_PotentiallyNuclear \
	icmd1='addcol "DET_PGC_ID" "DET_PGC_ID"' \
	icmd1='addcol "CONT_FLAG" "toString(1.)"' \
	icmd1='replaceval "1" "central_Candidate" "CONT_FLAG"' \
	icmd1='addcol "CONT_ID" "toString(SRCID)"' \
	icmd1='addcol "RA_CONT" "1."' \
	icmd1='replaceval "1." "null" "RA_CONT"' \
	icmd1='addcol "DEC_CONT" "RA_CONT"' \
	icmd1='addcol "OBJ_TYPE" "CONT_FLAG"' \
	icmd1='addcol "ContDist" "CenterDist"' \
	icmd1='addcol "SC_ContDist" "SC_CenterDist"'
rm XMM_noNuclear
# XMM_PotentiallyNuclear is stored and ignored until the end.
# XMM_noPotentiallyNuclear is passed down to the next filtering step.
echo "------------------------------------------------------------------------------------"
echo "We check with Gaia for known contaminants, using a similar Technique to that in Freun et al. 2018. We use the limit log(fx/fbol)=-2.2, and the formula from Maccacaro et al 1988."
echo "------------------------------------------------------------------------------------"
# This stection takes all non-nuclear sources and looks for contaminants in GaiaDR2.
# The thresholds from Freun et al. 2018 and Maccacaro et al 1988 are used besides from the 3-sigma cone-search.
#--------------------------------------------------------------------------------------------
# Perform a cds cross-match of XMM_noPotentiallyNuclear with the external Gaia database.
# The crossmatch requires a fixed radius. Do a selection of all sources closer than their 3-sigma positional uncertainty to the potential contaminant.
# Use phot_g_mean_mag from gaia as an estimate for bolometric magnitude.
# Sources with no listed phot_g_mean_mag are given a value of 9999999.
# Select matched sources that hold log(fx/fbol)<-2.2 holds in a extra step.
# Add contaminant columns, and keep OMLY the contaminat clumns plus DET_PGC_ID.
# CONT_FLAG="GaiaDR2" OBJ_TYPE="GaiaDR_Obj" CONT_ID=source_id
# Single source may have been matched to more than 1 contaminant
stilts cdsskymatch \
	in=XMM_noPotentiallyNuclear \
	ofmt=fits-basic omode=out out=XMM_noNuclear_Gaia \
	find=all fixcols=dups suffixin=null suffixremote=_GDR2 \
	ra='SC_RA' dec='SC_DEC' radius=10 cdstable='I/345/gaia2' \
	ocmd='replaceval null 9999999 phot_g_mean_mag' \
	ocmd='select "phot_g_mean_mag<=-18.925-2.5*log10(SC_EP_8_FLUX)"' \
	ocmd='addcol "CONT_FLAG" "toString(1.)"' \
	ocmd='replaceval "1" "GaiaDR2" "CONT_FLAG"' \
	ocmd='addcol "OBJ_TYPE" "toString(1.)"' \
	ocmd='replaceval "1" "Star" "OBJ_TYPE"' \
	ocmd='addcol "SC_ContDist" "skyDistanceDegrees(SC_RA,SC_DEC,RA_GDR2,DEC_GDR2)*3600"' \
	ocmd='select "3*(SC_POSERR+max(ra_error,dec_error)/1000)>SC_ContDist"' \
	ocmd='addcol "ContDist" "skyDistanceDegrees(RA,DEC,RA_GDR2,DEC_GDR2)*3600"' \
	ocmd='keepcols "DET_PGC_ID CONT_FLAG source_id RA_GDR2 DEC_GDR2 OBJ_TYPE ContDist SC_ContDist"' \
	ocmd='colmeta -name "CONT_ID" "source_id"' \
	ocmd='replacecol "CONT_ID" "toString(CONT_ID)"' \
	ocmd='colmeta -name "RA_CONT" "RA_GDR2"' \
	ocmd='colmeta -name "DEC_CONT" "DEC_GDR2"'
# Select only the nearest gaia counterpart for each source. POINT OF CONCERN?
# Sort the entries of the catalogue by increasing order of SC_Match1 dist.
# Do a match1 filtering with action=keep1 and DET_PGC_ID.
# Only the first entry of each DET_PGC_ID is kept.
stilts tmatch1 \
	in=XMM_noNuclear_Gaia \
	icmd='sort SC_ContDist' \
	ofmt=fits-basic omode=out out=XMM_noNuclear_Gaia \
	values='DET_PGC_ID' action=keep1 matcher=exact
# Select the entries in XMM_XMM_noPotentiallyNuclear that do NOT appear in XMM_noNuclear_Gaia
# Do so by comparing DET_PGC_ID.
# Store the, in XMM_noNuclear_noGaia. The meaning of the name is straightforward.
stilts tmatch2 \
	in1=XMM_noPotentiallyNuclear \
	in2=XMM_noNuclear_Gaia \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='DET_PGC_ID' values2='DET_PGC_ID' \
	ofmt=fits-basic omode=out out=XMM_noNuclear_noGaia
# Give XMM_noNuclear_Gaia back the columns not realated to the contaminants.
# Concatenate the columns of all entries in XMM_noPotentiallyNuclear appearing in XMM_noNuclear_Gaia.
# XMM_noNuclear_Gaia and XMM_noNuclear_noGaia have now the same dimensions.
stilts tmatch2 \
	in1=XMM_noPotentiallyNuclear \
	in2=XMM_noNuclear_Gaia \
	find=all fixcols=none join=1and2 matcher=exact \
	values1='DET_PGC_ID' values2='DET_PGC_ID' \
	ofmt=fits-basic omode=out out=XMM_noNuclear_Gaia
rm XMM_noPotentiallyNuclear
# XMM_noNuclear_Gaia is stored and ignored until the end.
# XMM_noNuclear_noGaia is passed down to the folowing filtering steps.
echo "------------------------------------------------------------------------------------"
echo "We repeat with Tycho2."
echo "------------------------------------------------------------------------------------"
#This section repeats the steps from the previous section, but using Tycho2 instead of Gaia, and using a normal tmatch2 query instead of the cds tool. That's because this catalogue is stored locally in /mbernardich's folders, so we don't need to use it. This also allows for a direct query with 3-sigma positional errors. Other than that, the steps are the exacte same, so coments are spared to a minimun.
#--------------------------------------------------------------------------------------------
# Use VTmag as an estimate for the bolometric magnitude.
# CONT_FLAG="Tycho2" OBJ_TYPE="Star" CONT_ID=TYC1
stilts tmatch2 \
	in1=XMM_noNuclear_noGaia \
	in2=Tycho2/Tycho2 \
	ofmt=fits-basic omode=out out=XMM_noNuclear_noGaia_Tycho2 \
	find=all fixcols=dups suffix1=null suffix2=_T2 join=1and2 matcher=skyerr \
	values1='SC_RA SC_DEC 3*SC_POSERR' values2='_RAJ2000 _DEJ2000 0' params=10 \
	ocmd='select "VTmag<=-18.925-2.5*log10(SC_EP_8_FLUX)"' \
	ocmd='addcol "DET_PGC_ID" "DET_PGC_ID"' \
	ocmd='addcol "CONT_FLAG" "toString(1.)"' \
	ocmd='replaceval "1" "Tycho2" "CONT_FLAG"' \
	ocmd='addcol "OBJ_TYPE" "toString(1.)"' \
	ocmd='replaceval "1" "Star" "OBJ_TYPE"' \
	ocmd='addcol "SC_ContDist" "skyDistanceDegrees(SC_RA,SC_DEC,_RAJ2000,_DEJ2000)*3600"' \
	ocmd='addcol "ContDist" "skyDistanceDegrees(RA,DEC,_RAJ2000,_DEJ2000)*3600"' \
	ocmd='keepcols "DET_PGC_ID CONT_FLAG TYC1 _RAJ2000 _DEJ2000 OBJ_TYPE ContDist SC_ContDist"' \
	ocmd='colmeta -name "CONT_ID" "TYC1"' \
	ocmd='colmeta -name "RA_CONT" "_RAJ2000"' \
	ocmd='colmeta -name "DEC_CONT" "_DEJ2000"'
stilts tmatch1 \
	in=XMM_noNuclear_noGaia_Tycho2 \
	icmd='sort SC_ContDist' \
	ofmt=fits-basic omode=out out=XMM_noNuclear_noGaia_Tycho2 \
	values='DET_PGC_ID' action=keep1 matcher=exact
stilts tmatch2 \
	in1=XMM_noNuclear_noGaia \
	in2=XMM_noNuclear_noGaia_Tycho2 \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='DET_PGC_ID' values2='DET_PGC_ID' \
	ofmt=fits-basic omode=out out=XMM_noNuclear_noGaia_noTycho2
stilts tmatch2 \
	in1=XMM_noNuclear_noGaia \
	in2=XMM_noNuclear_noGaia_Tycho2 \
	find=all fixcols=none join=1and2 matcher=exact \
	values1='DET_PGC_ID' values2='DET_PGC_ID' \
	ofmt=fits-basic omode=out out=XMM_noNuclear_noGaia_Tycho2
rm XMM_noNuclear_noGaia
# XMM_noNuclear_noGaia_Tycho2 is stored and ignored until the end.
# XMM_noNuclear_noGaia_noTycho2 is passed down to the folowing filtering steps.
echo "------------------------------------------------------------------------------------"
echo "We do a correlation with SDSS-DR14 to find QSO contaminants."
echo "------------------------------------------------------------------------------------"
# The procedure is repeated with SDSS-DR14 to look for QSO. The difference this time is that there is no extra luminosity threshold (no Freun et al. 2018 and Maccacaro et al 1988 thresholds), and all matched objects within their 3-sigma positional uncertainty are labelled as contaminants.
# --------------------------------------------------------------------------------------------
# CONT_FLAG="SDSS_DR14" OBJ_TYPE="QSO" CONT_ID=SDSS_NAME
stilts tmatch2 \
	in1=XMM_noNuclear_noGaia_noTycho2 \
	in2=SDSSDR14/DR14Q_v4_4.fits \
	ofmt=fits-basic omode=out out=XMM_SDSSQSO \
	find=best1 fixcols=dups suffix1=null suffix2=_SDSS join=1and2 matcher=skyerr \
	values1='SC_RA SC_DEC 3*SC_POSERR' values2='RA DEC 0' params=20 \
	ocmd='addcol "CONT_FLAG" "toString(1.)"' \
	ocmd='replaceval "1" "SDSS_DR14" "CONT_FLAG"' \
	ocmd='addcol "OBJ_TYPE" "toString(1.)"' \
	ocmd='replaceval "1" "QSO" "OBJ_TYPE"' \
	ocmd='addcol "SC_ContDist" "skyDistanceDegrees(SC_RA,SC_DEC,RA_SDSS,DEC_SDSS)*3600"' \
	ocmd='addcol "ContDist" "skyDistanceDegrees(RA,DEC,RA_SDSS,DEC_SDSS)*3600"' \
	ocmd='keepcols "DET_PGC_ID CONT_FLAG SDSS_NAME RA DEC OBJ_TYPE ContDist SC_ContDist"' \
	ocmd='colmeta -name "CONT_ID" "SDSS_NAME"' \
	ocmd='colmeta -name "RA_CONT" "RA"' \
	ocmd='colmeta -name "DEC_CONT" "DEC"'
# Since no source is matched with more than 1 contaminant, the match1 step is skipped.
stilts tmatch2 \
	in1=XMM_noNuclear_noGaia_noTycho2 \
	in2=XMM_SDSSQSO \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='DET_PGC_ID' values2='DET_PGC_ID' \
	ofmt=fits-basic omode=out out=XMM_noSDSSQSO
stilts tmatch2 \
	in1=XMM_noNuclear_noGaia_noTycho2 \
	in2=XMM_SDSSQSO \
	find=all fixcols=none join=1and2 matcher=exact \
	values1='DET_PGC_ID' values2='DET_PGC_ID' \
	ofmt=fits-basic omode=out out=XMM_SDSSQSO
rm XMM_noNuclear_noGaia_noTycho2
# XMM_SDSSQSO is stored and ignored until the end.
# XMM_noSDSSQSO is passed down to the folowing filtering steps.
# The naming convention is slightly different because this step was introduced later than the rest.
echo "------------------------------------------------------------------------------------"
echo "We repeat with Veron QSOs."
echo "------------------------------------------------------------------------------------"
# The procedure is repeated with SDSS-DR14 to look for QSO. For insight on the meaning of every step, check the previous sections.
#---------------------------------------------------------------------------------------------
# CONT_FLAG="VeronQSO" OBJ_TYPE="QSO" CONT_ID=Name
stilts tmatch2 \
	in1=XMM_noSDSSQSO \
	in2=VeronQSO/VeronQSO \
	ofmt=fits-basic omode=out out=XMM_noNuclear_noGaia_noTycho2_VeronQSO \
	find=best1 fixcols=dups suffix1=null suffix2=_Veron join=1and2 matcher=skyerr \
	values1='SC_RA SC_DEC 3*SC_POSERR' values2='_RAJ2000 _DEJ2000 0' params=10 \
	ocmd='addcol "CONT_FLAG" "toString(1.)"' \
	ocmd='replaceval "1" "VeronQSO" "CONT_FLAG"' \
	ocmd='addcol "OBJ_TYPE" "toString(1.)"' \
	ocmd='replaceval "1" "QSO" "OBJ_TYPE"' \
	ocmd='addcol "SC_ContDist" "skyDistanceDegrees(SC_RA,SC_DEC,_RAJ2000,_DEJ2000)*3600"' \
	ocmd='addcol "ContDist" "skyDistanceDegrees(RA,DEC,_RAJ2000,_DEJ2000)*3600"' \
	ocmd='keepcols "DET_PGC_ID CONT_FLAG Name _RAJ2000 _DEJ2000 OBJ_TYPE ContDist SC_ContDist"' \
	ocmd='colmeta -name "CONT_ID" "Name"' \
	ocmd='colmeta -name "RA_CONT" "_RAJ2000"' \
	ocmd='colmeta -name "DEC_CONT" "_DEJ2000"'
stilts tmatch2 \
	in1=XMM_noSDSSQSO \
	in2=XMM_noNuclear_noGaia_noTycho2_VeronQSO \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='DET_PGC_ID' values2='DET_PGC_ID' \
	ofmt=fits-basic omode=out out=XMM_noNuclear_noGaia_noTycho2_noVeronQSO
stilts tmatch2 \
	in1=XMM_noSDSSQSO \
	in2=XMM_noNuclear_noGaia_noTycho2_VeronQSO \
	find=all fixcols=none join=1and2 matcher=exact \
	values1='DET_PGC_ID' values2='DET_PGC_ID' \
	ofmt=fits-basic omode=out out=XMM_noNuclear_noGaia_noTycho2_VeronQSO
# XMM_noNuclear_noGaia_noTycho2_VeronQSO is stored and ignored until the end.
# XMM_noNuclear_noGaia_noTycho2_noVeronQSO is passed down to the folowing filtering steps.
# The file names miss the SDSS_DR14 step because that one was introduced later than the others.
# The user should imagine "noSDSS" or similar between "noTycho2" and "VeronQSO"/"noVeronQSO" 
rm XMM_noSDSSQSO
echo "------------------------------------------------------------------------------------"
echo "We now go with SIMBAD to remove al remaining Stars (following the same method as before), AGNs, and SNs."
echo "------------------------------------------------------------------------------------"
# This section performs a cds cross-match with SIMBAD to find a variety of objects.
# Stellar objects will once again follow the restriction from Freun et al. 2018 with the method of Maccacaro et al 1988.
# Others just follow a simple 3-sigma match.
#----------------------------------------------------------------------------------------------
# Find al matched objects within a fixed radius, then select those that are closer thant the 3-sigma uncertainty.
# Keep the contaminant columns plus DET_PGC_ID, the X-ray flux and the V magnitude,
# dummy_type=main_type, dummy_character=1. OBJ_TYPE not created yet.
# CONT_FLAG="SIMBAD", CONT_ID=main_id., OBJ_TYPE==main_type
# Sources with no listed V are given a value of 9999999.
# Store them in XMM_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBAD.
stilts cdsskymatch \
	in=XMM_noNuclear_noGaia_noTycho2_noVeronQSO \
	ofmt=fits-basic omode=out out=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBAD \
	find=all fixcols=dups suffixin=null suffixremote=_SIMBAD \
	ra='SC_RA' dec='SC_DEC' radius='10' cdstable='SIMBAD' \
	ocmd='addcol "CONT_FLAG" "toString(1.)"' \
	ocmd='replaceval "1" "SIMBAD" "CONT_FLAG"' \
	ocmd='addcol "SC_ContDist" "skyDistanceDegrees(SC_RA,SC_DEC,ra_SIMBAD,dec_SIMBAD)*3600"' \
	ocmd='replaceval null 0 coo_err_maj' \
	ocmd='select "3*(SC_POSERR+coo_err_maj)>SC_ContDist"' \
	ocmd='addcol "ContDist" "skyDistanceDegrees(RA,DEC,ra_SIMBAD,dec_SIMBAD)*3600"' \
	ocmd='addcol "dummy_type" "main_type"' \
	ocmd='addcol "dummy_character" "toString(1.)"' \
	ocmd='keepcols "DET_PGC_ID CONT_FLAG main_id ra_SIMBAD dec_SIMBAD main_type SC_EP_8_FLUX V ContDist SC_ContDist dummy_type dummy_character"' \
	ocmd='replaceval null 9999999 V' \
	ocmd='colmeta -name "CONT_ID" "main_id"' \
	ocmd='colmeta -name "RA_CONT" "ra_SIMBAD"' \
	ocmd='colmeta -name "DEC_CONT" "dec_SIMBAD"' \
	ocmd='colmeta -name "OBJ_TYPE" "main_type"'
# XMM_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBAD is used in the two following steps to extract contaminants two times.
echo "------------------------------------------------------------------------------------"
echo "Finding stars in SIMBAD."
echo "------------------------------------------------------------------------------------"
# Extract stellar objects from XMM_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBAD
# Select only objects with dummy_type="Star" or that contain dummy_character ("*") in OBJ_TYPE.
# Select object that hold log(fx/fbol)<-2.2
# Use V for the estimate of absolute magnitude.
# Sort by ascending SC_ContDist.
# Keep the contaminant columns.
# Store them in XMM_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBADstars.
stilts tmatch1 in=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBAD \
	ofmt=fits-basic omode=out out=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBADstars \
	icmd='replaceval "Star" "1" dummy_type' \
	icmd='replaceval "1" "*" dummy_character' \
	icmd='select "dummy_type==toString(1.)||contains(OBJ_TYPE,toString(dummy_character))&&V<=-18.925-2.5*log10(SC_EP_8_FLUX)"' \
	icmd='keepcols "DET_PGC_ID CONT_FLAG CONT_ID RA_CONT DEC_CONT OBJ_TYPE ContDist SC_ContDist"' \
	icmd='sort SC_ContDist' \
	values='DET_PGC_ID' action=keep1 matcher=exact
# Select all entries from XMM_noNuclear_noGaia_noTycho2_noVeronQSO appearing in XMM_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBADstars.
# Do so by comparing DET_PGC_ID.
# Store them in XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBADstars.
stilts tmatch2 \
	in1=XMM_noNuclear_noGaia_noTycho2_noVeronQSO \
	in2=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBADstars \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='DET_PGC_ID' values2='DET_PGC_ID' \
	ofmt=fits-basic omode=out out=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBADstars
# Concatenate the columns of entries in XMM_noNuclear_noGaia_noTycho2_noVeronQSO apearing in XMM_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBADstars to give the fale the same dimensionality as the rest of the catalogue.
stilts tmatch2 \
	in1=XMM_noNuclear_noGaia_noTycho2_noVeronQSO \
	in2=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBADstars \
	find=all fixcols=none join=1and2 matcher=exact \
	values1='DET_PGC_ID' values2='DET_PGC_ID' \
	ofmt=fits-basic omode=out out=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBADstars
rm XMM_noNuclear_noGaia_noTycho2_noVeronQSO
# XMM_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBADstars is stored and ignored until the end.
# XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBADstars is passed down to the folowing filtering steps.
echo "------------------------------------------------------------------------------------"
echo "Finding stars and AGNs in SIMBAD."
echo "------------------------------------------------------------------------------------"
# Extract other contaminants XMM_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBAD
# Repeat the steps, but look for objects with dummy_type="QSO","QSO_Candidate","AGN","AGN_Candidate" and "SN" instead.
# Ignore the Freun et al. 2018 threshold this time.
# It follows identically as the previous step. Comments spared.
stilts tmatch1 in=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBAD \
	ofmt=fits-basic omode=out out=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBADagn \
	icmd='replaceval "QSO" "1" dummy_type' \
	icmd='replaceval "QSO_Candidate" "1" dummy_type' \
	icmd='replaceval "AGN" "1" dummy_type' \
	icmd='replaceval "AGN_Candidate" "1" dummy_type' \
	icmd='replaceval "SN" "1" dummy_type' \
	icmd='select "dummy_type==toString(1.)"' \
	icmd='keepcols "DET_PGC_ID CONT_FLAG CONT_ID RA_CONT DEC_CONT OBJ_TYPE ContDist SC_ContDist"' \
	icmd='sort SC_ContDist' \
	values='DET_PGC_ID' action=keep1 matcher=exact
stilts tmatch2 \
	in1=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBADstars \
	in2=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBADagn \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='DET_PGC_ID' values2='DET_PGC_ID' \
	ofmt=fits-basic omode=out out=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBAD
stilts tmatch2 \
	in1=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBADstars \
	in2=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBADagn \
	find=all fixcols=none join=1and2 matcher=exact \
	values1='DET_PGC_ID' values2='DET_PGC_ID' \
	ofmt=fits-basic omode=out out=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBADagn
rm XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBADstars
rm XMM_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBAD
# XMM_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBADagn is stored and ignored until the following section.
# XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBAD is passed down to the following filtering steps.
echo "------------------------------------------------------------------------------------"
echo "Finding counterparts in PanStarrs1 DR1. We use the g magnitude here."
echo "We use once againg the formula from Maccacaro et al 1988, but this time we select all objects that are brighter in the optical (g magnitude) than in the X-ray, as we are not certain of the nature of the counterparts."
echo "------------------------------------------------------------------------------------"
# This section performs the search for objects in the PanSTARRS1 survey.
# The limit this time is log(fx/fbol)<0. The formula from Maccacaro et al 1988 is used though.
#---------------------------------------------------------------------------------------------
# Perform a fixed radius cds search with the PanSTARRS1 external database.
# Select objects within the 3-sigma uncertainty overlap.
# Keep the contaminant columns plus DET_PGC_ID and gmag.
# Sources with no listed gmag are given a value of 9999999.
# CONT_FLAG="PanSTARRS1", CONT_ID=f_objID.
# Store them in PanSTARRS1.
stilts cdsskymatch \
	in=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBAD \
	ofmt=fits-basic omode=out \
	out=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBAD_PanSTARRS1 \
	find=all fixcols=dups suffixin=null suffixremote=_PanSTARRS1 \
	ra='SC_RA' dec='SC_DEC' radius='10' cdstable='PanSTARRS DR1' \
	ocmd='addcol "CONT_FLAG" "toString(1.)"' \
	ocmd='replaceval "1" "PanSTARRS1" "CONT_FLAG"' \
	ocmd='addcol "SC_ContDist" "skyDistanceDegrees(SC_RA,SC_DEC,RAJ2000,DEJ2000)*3600"' \
	ocmd='select "3*(SC_POSERR+errHalfMaj)>SC_ContDist"' \
	ocmd='addcol "ContDist" "skyDistanceDegrees(RA,DEC,RAJ2000,DEJ2000)*3600"' \
	ocmd='addcol "CONT_ID" "toString(f_objID)"' \
	ocmd='keepcols "DET_PGC_ID CONT_FLAG CONT_ID RAJ2000 DEJ2000 SC_EP_8_FLUX gmag ContDist SC_ContDist"' \
	ocmd='replaceval null 9999999 gmag' \
	ocmd='colmeta -name "RA_CONT" "RAJ2000"' \
	ocmd='colmeta -name "DEC_CONT" "DEJ2000"'
# Select entries with log(fx/fbol)<0.
# OBJ_TYPE="PanSTARRS1_Obj".
# Sort by ascending order of SC_ContDist.
# Perform a tmatch1 search of DET_PGC_ID with action=keep1 to keep only the closest match. 
stilts tmatch1 in=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBAD_PanSTARRS1 \
	ofmt=fits-basic omode=out \
	out=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBAD_PanSTARRS1 \
	icmd='select "gmag<=-13.425-2.5*log10(SC_EP_8_FLUX)"' \
	icmd='addcol -after DEC_CONT OBJ_TYPE "toString(1.)"' \
	icmd='replaceval "1" "PanSTARRS1_Obj" OBJ_TYPE' \
	icmd='keepcols "DET_PGC_ID CONT_FLAG CONT_ID RA_CONT DEC_CONT OBJ_TYPE ContDist SC_ContDist"' \
	icmd='sort SC_ContDist' \
	values='DET_PGC_ID' action=keep1 matcher=exact
# Subtract all entries in XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBAD_PanSTARRS1 from XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBAD.
# Store the reminder in XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBAD_noPanSTARRS1.
stilts tmatch2 \
	in1=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBAD \
	in2=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBAD_PanSTARRS1 \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='DET_PGC_ID' values2='DET_PGC_ID' \
	ofmt=fits-basic omode=out \
	out=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBAD_noPanSTARRS1
# Concatenate the columns of XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBAD_PanSTARRS1 with the entries appearing in XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBAD to give the same dimesionality to the file.
stilts tmatch2 \
	in1=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBAD \
	in2=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBAD_PanSTARRS1 \
	find=all fixcols=none join=1and2 matcher=exact \
	values1='DET_PGC_ID' values2='DET_PGC_ID' \
	ofmt=fits-basic omode=out out=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBAD_PanSTARRS1
rm XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBAD
# XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBAD_PanSTARRS1 is stored to the next step.
# XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBAD_noPanSTARRS1 is stored to the next step.
echo "------------------------------------------------------------------------------------"
echo "Now joining all remaining sources with contaminants, keeping rellevant info of the matched contaminants"
echo "------------------------------------------------------------------------------------"
# This section FINALLY concatenates the reminding unmatched entries with all the tables of contaminants.
#--------------------------------------------------------------------------------------------
# Concatenate all the tables.
# But before create the contaminant columns in the clean table so all files have the same dimensionality.
# CONT_FLAG="none", OBJ_TYPE="clean", CONT_IDE="clean.
# Add the galactic coordinates of source and galactic center positions.
# Store all the entries in the *drumroll...* XMM_nonNuclear_Catalogue file. 
stilts tcatn \
	nin=10 \
	in1=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBAD_noPanSTARRS1 \
	in2=XMM_Nuclear \
	in3=XMM_PotentiallyNuclear \
	in4=XMM_noNuclear_Gaia \
	in5=XMM_noNuclear_noGaia_Tycho2 \
	in6=XMM_SDSSQSO \
	in7=XMM_noNuclear_noGaia_noTycho2_VeronQSO \
	in8=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBADstars \
	in9=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBADagn \
	in10=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBAD_PanSTARRS1 \
	icmd1='addcol "DET_PGC_ID" "DET_PGC_ID"' \
	icmd1='addcol "CONT_FLAG" "toString(1.)"' \
	icmd1='replaceval "1" "none" "CONT_FLAG"' \
	icmd1='addcol "CONT_ID" "toString(1.)"' \
	icmd1='replaceval "1" "clean" "CONT_ID"' \
	icmd1='addcol "RA_CONT" "1."' \
	icmd1='replaceval "1." "null" "RA_CONT"' \
	icmd1='addcol "DEC_CONT" "RA_CONT"' \
	icmd1='addcol "OBJ_TYPE" "toString(1.)"' \
	icmd1='replaceval "1" "clean" "OBJ_TYPE"' \
	icmd1='addcol "ContDist" "RA_CONT"' \
	icmd1='addcol "SC_ContDist" "RA_CONT"' \
	ofmt=fits-basic omode=out out=XMM_nonNuclear_Catalogue
rm XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBAD_noPanSTARRS1
rm XMM_noNuclear_Gaia
rm XMM_noNuclear_noGaia_Tycho2
rm XMM_noNuclear_noGaia_noTycho2_VeronQSO
rm XMM_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBADstars
rm XMM_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBADagn
rm XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBAD_PanSTARRS1
rm XMM_Nuclear
rm XMM_SDSSQSO
rm XMM_PotentiallyNuclear
# But if you think this is over, uh boi you are wrong.
echo "------------------------------------------------------------------------------------"
echo "Now select manually observed contaminants. These guys have been observed in the PANSTARRS1, and from the images they are deemed to have wrognfully survived the filtering steps."
echo "------------------------------------------------------------------------------------"
# This section labells entries of clean sources from XMM_nonNuclear_Catalogue that are deemed as contaminants upon manual instpection with the PanSTARRS1 survey or the NASA/IPAC Extragalactic Database (NED).
#------------------------------------------------------------------------------------------------
# Select source that that have been classified as a blend of 2 or more other.
# CONT_FLAG="manual(PanSTARRS1)", OBJ_TYPE="blend"
# Store their entries in manual_double.
stilts tpipe in=XMM_nonNuclear_Catalogue \
	ofmt=fits-basic omode=out out=manual_double \
	cmd="select SRCID==200559905010001L|SRCID==206701401010002L" \
	cmd='replaceval "none" "manual(PanSTARRS1)" CONT_FLAG' \
	cmd='replaceval "clean" "blend" OBJ_TYPE'
# Subtract their entries from XMM_nonNuclear_Catalogue.
stilts tmatch2 in1=XMM_nonNuclear_Catalogue in2=manual_double \
	ofmt=fits-basic omode=out out=XMM_nonNuclear_Catalogue \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='SRCID' values2='SRCID'
# Select sources that that have been classified as located in a background galaxy.
# CONT_FLAG="manual(PanSTARRS1)", OBJ_TYPE="back. galaxy"
# Store their entries in manual_galaxy.
stilts tpipe in=XMM_nonNuclear_Catalogue \
	ofmt=fits-basic omode=out out=manual_galaxy \
	cmd="select SRCID==201389514010019L" \
	cmd='replaceval "none" "manual(PanSTARRS1)" CONT_FLAG' \
	cmd='replaceval "clean" "back. galaxy" OBJ_TYPE'
# Subtract their entries from XMM_nonNuclear_Catalogue.
stilts tmatch2 in1=XMM_nonNuclear_Catalogue in2=manual_galaxy \
	ofmt=fits-basic omode=out out=XMM_nonNuclear_Catalogue \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='SRCID' values2='SRCID'
# Select sources that that have been classified as located in a background galaxy.
# CONT_FLAG="manual(PanSTARRS1)", OBJ_TYPE="spurious"
# Store their entries in manual_octahedron (because they constitute 8 detection entries). 
stilts tpipe in=XMM_nonNuclear_Catalogue \
	ofmt=fits-basic omode=out out=manual_octahedron \
	cmd="select SRCID==201365407010002L|SRCID==201365410010001L|SRCID==201504987010002L|SRCID==201589702010003L|SRCID==201589707010003L|SRCID==201589712010001L|SRCID==204110819010002L" \
	cmd='replaceval "none" "manual(PanSTARRS1)" CONT_FLAG' \
	cmd='replaceval "clean" "spurious" OBJ_TYPE'
# Subtract their entries from XMM_nonNuclear_Catalogue.
stilts tmatch2 in1=XMM_nonNuclear_Catalogue in2=manual_octahedron \
	ofmt=fits-basic omode=out out=XMM_nonNuclear_Catalogue \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='SRCID' values2='SRCID'
# Select sources that that have been seen as central in the NED database.
# CONT_FLAG="manual(NED)", OBJ_TYPE="central"
# Store their entries in manual_NEDIPACcentral. 
stilts tpipe in=XMM_nonNuclear_Catalogue \
	ofmt=fits-basic omode=out out=manual_NEDIPACcentral \
	cmd="select SRCID==200936502010001L|SRCID==200029702010002L" \
	cmd='replaceval "none" "manual(NED)" CONT_FLAG' \
	cmd='replaceval "clean" "central" OBJ_TYPE'
# Subtract their entries from XMM_nonNuclear_Catalogue. 
stilts tmatch2 in1=XMM_nonNuclear_Catalogue in2=manual_NEDIPACcentral \
	ofmt=fits-basic omode=out out=XMM_nonNuclear_Catalogue \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='SRCID' values2='SRCID'
# Select sources that that have been identified as QSOs in the NED database.
# CONT_FLAG="manual(NED)", OBJ_TYPE="QSO"
# Store their entries in manual_NEDIPACcentral.
stilts tpipe in=XMM_nonNuclear_Catalogue \
	ofmt=fits-basic omode=out out=manual_NEDIPACqso \
	cmd="select SRCID==201241101010001L" \
	cmd='replaceval "none" "manual(NED)" CONT_FLAG' \
	cmd='replaceval "clean" "QSO" OBJ_TYPE'
# Subtract their entries from XMM_nonNuclear_Catalogue. 
stilts tmatch2 in1=XMM_nonNuclear_Catalogue in2=manual_NEDIPACqso \
	ofmt=fits-basic omode=out out=XMM_nonNuclear_Catalogue \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='SRCID' values2='SRCID'
# Select sources that that have been identified as background galaxies in the NED database.
# CONT_FLAG="manual(NED)", OBJ_TYPE="back. galaxy"
# Store their entries in manual_NEDIPACcentral.
stilts tpipe in=XMM_nonNuclear_Catalogue \
	ofmt=fits-basic omode=out out=manual_NEDIPACagn \
	cmd="select SRCID==202036901010002L|SRCID==202060901010021L|SRCID==206035007010032L|SRCID==208039522010013L" \
	cmd='replaceval "none" "manual(NED)" CONT_FLAG' \
	cmd='replaceval "clean" "back. galaxy" OBJ_TYPE'
# Subtract their entries from XMM_nonNuclear_Catalogue. 
stilts tmatch2 in1=XMM_nonNuclear_Catalogue in2=manual_NEDIPACagn \
	ofmt=fits-basic omode=out out=XMM_nonNuclear_Catalogue \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='SRCID' values2='SRCID'
# Concaenate all the entries.
# Store them in XMM_nonNuclear_Catalogue
stilts tcatn \
	nin=7 \
	in1=XMM_nonNuclear_Catalogue \
	in2=manual_double \
	in3=manual_galaxy \
	in4=manual_octahedron \
	in5=manual_NEDIPACcentral \
	in6=manual_NEDIPACqso \
	in7=manual_NEDIPACagn \
	ofmt=fits-basic omode=out out=XMM_nonNuclear_Catalogue
rm manual_double
rm manual_galaxy
rm manual_octahedron
rm manual_NEDIPACcentral
rm manual_NEDIPACqso
rm manual_NEDIPACagn
echo "------------------------------------------------------------------------------------"
echo "Now rescue PanSTARRS1 objects. These guys have been observed in the PANSTARRS1, and from the images they are deemed to be structures or objects wrongly catalogued contaminants."
echo "------------------------------------------------------------------------------------"
# This section works the other way around as the previous. Sources highlighted as contaminants in PanSTARRS1 are "rescued" upon manual inspection.
#------------------------------------------------------------------------------------------------
# Select sources that look like structures or nebulae in PanSTARRS1 (most likelly HII regions).
# CONT_FLAG=none(PanSTARRS1)m OBJ_TYPE="Feature"
# Store them in manual_features.
stilts tpipe in=XMM_nonNuclear_Catalogue \
	ofmt=fits-basic omode=out out=manual_features \
	cmd="select SRCID==200931903010009L|SRCID==206553804010004L|SRCID==200082202015086L|SRCID==206024202010006L|SRCID==202033908010046L|SRCID==207437002010089L|SRCID==203035606010004L|SRCID==203009606350009L|SRCID==200852201010007L|SRCID==206776301370024L|SRCID==201521705010003L|SRCID==206039801010095L|SRCID==203009302010008L|SRCID==207814102010010L|SRCID==201109002010001L|SRCID==205000702010005L|SRCID==205036004010037L|SRCID==200255404010034L|SRCID==200617401015049L|SRCID==200255404010020L|SRCID==206939704010033L|SRCID==201475401010015L|SRCID==203008001010011L|SRCID==207413006010108L|SRCID==205562803010007L|SRCID==208007311010066L|SRCID==206035704010042L|SRCID==200255410010006L|SRCID==200943605010010L|SRCID==207851016010102L|SRCID==207413004010053L|SRCID==201503501010026L|SRCID==203008001010021L|SRCID==207003817010007L|SRCID==203060508010004L|SRCID==202044102010005L|SRCID==203008001010017L|SRCID==207413001010124L|SRCID==207225703010066L|SRCID==201503501010054L|SRCID==200936411010009L|SRCID==201038631010002L|SRCID==206582010010068L|SRCID==206923304010006L|SRCID==201042601010005L|SRCID==207413001010075L|SRCID==207231808010022L|SRCID==206553809010042L|SRCID==201496202010003L|SRCID==202046503010009L|SRCID==206022003015036L|SRCID==202046502010036L|SRCID==201415702010002L|SRCID==201125520010012L|SRCID==203008001010007L|SRCID==204050803010003L|SRCID==200852202015003L|SRCID==207207003010089L|SRCID==202036901010032L|SRCID==201109002010002L|SRCID==201038631010010L|SRCID==201122802010008L|SRCID==201125508010004L|SRCID==200709401010011L|SRCID==203024403010052L|SRCID==204042403010004L|SRCID==200211402010004L|SRCID==200205404010082L|SRCID==201095205010079L|SRCID==201125508010006L|SRCID==206776001320042L|SRCID==206923304010016L|SRCID==200856401010087L|SRCID==202033910010003L|SRCID==207931831010039L|SRCID==206939703010031L|SRCID==201486201010046L|SRCID==200052101010054L|SRCID==200589401010101L|SRCID==200931905010023L" \
	cmd='replaceval "PanSTARRS1" "none(PanSTARRS1)" CONT_FLAG' \
	cmd='replaceval "PanSTARRS1_Obj" "Feature" OBJ_TYPE'
# Subtract their entries from XMM_nonNuclear_Catalogue. 
stilts tmatch2 in1=XMM_nonNuclear_Catalogue in2=manual_features \
	ofmt=fits-basic omode=out out=XMM_nonNuclear_Catalogue \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='SRCID' values2='SRCID'
# Select sources that look like structures or nebulae in PanSTARRS1 (most likelly HII regions).
# CONT_FLAG="none(PanSTARRS1)" OBJ__TYPE="Feature"
# Store them in manual_features.
stilts tpipe in=XMM_nonNuclear_Catalogue \
	ofmt=fits-basic omode=out out=manual_galaxies \
	cmd="select SRCID==203002105010001L|SRCID==201122703010001L|SRCID==200029601010001L|SRCID==207845212010067L" \
	cmd='replaceval "PanSTARRS1_Obj" "back. galaxy" OBJ_TYPE'
# Subtract their entries from XMM_nonNuclear_Catalogue.
stilts tmatch2 in1=XMM_nonNuclear_Catalogue in2=manual_galaxies \
	ofmt=fits-basic omode=out out=XMM_nonNuclear_Catalogue \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='SRCID' values2='SRCID'
# Select sources that don't seem to have clear contaminating counterparts in NED, despite having an optical counterpart in PanSTARRS1.
# CONT_FLAG="none(NED)" OBJ_TYPE="Feature"
# Store them in manual_features.
stilts tpipe in=XMM_nonNuclear_Catalogue \
	ofmt=fits-basic omode=out out=manual_NEDIPAC \
	cmd="select SRCID==200052101010054L|SRCID==200589401010101L|SRCID==200931905010023L|SRCID==201038613010004L|SRCID==201038631010013L|SRCID==201117901010010L|SRCID==201125213010043L|SRCID==205051505010028L|SRCID==207843302010078L|SRCID==200852202010012L|SRCID==201530307010011L|SRCID==205024801010003L" \
	cmd='replaceval "PanSTARRS1" "none(NED)" CONT_FLAG' \
	cmd='replaceval "PanSTARRS1_Obj" "Feature" OBJ_TYPE'
# Subtract their entries from XMM_nonNuclear_Catalogue.
stilts tmatch2 in1=XMM_nonNuclear_Catalogue in2=manual_NEDIPAC \
	ofmt=fits-basic omode=out out=XMM_nonNuclear_Catalogue \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='SRCID' values2='SRCID'
# Select sources that have infrared counterparts in NED.
# CONT_FLAG="none(NED)" OBJ_TYPE="IrS"
# Store them in manual_features.
stilts tpipe in=XMM_nonNuclear_Catalogue \
	ofmt=fits-basic omode=out out=manual_IrS \
	cmd="select SRCID==205051505010033L|SRCID==206730202010049L|SRCID==207238011010065L|SRCID==207415816010016L|SRCID==207437002010067L|SRCID==200411804010099L|SRCID==202064903010019L|SRCID==203012901010042L|SRCID==205545008010057L|SRCID==206929307010023L|SRCID==207441006010049L" \
	cmd='replaceval "PanSTARRS1" "manual(NED)" CONT_FLAG' \
	cmd='replaceval "PanSTARRS1_Obj" "IrS" OBJ_TYPE'
# Subtract their entries from XMM_nonNuclear_Catalogue.
stilts tmatch2 in1=XMM_nonNuclear_Catalogue in2=manual_IrS \
	ofmt=fits-basic omode=out out=XMM_nonNuclear_Catalogue \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='SRCID' values2='SRCID'
# Select the one source that has two close-by X-ray matches in NED.
# CONT_FLAG="none(NED)" OBJ_TYPE="blend?".
# Store them in manual_features.
stilts tpipe in=XMM_nonNuclear_Catalogue \
	ofmt=fits-basic omode=out out=manual_NEDIPACblend \
	cmd="select SRCID==201109302010027L" \
	cmd='replaceval "PanSTARRS1" "none(NED)" CONT_FLAG' \
	cmd='replaceval "PanSTARRS1_Obj" "blend?" OBJ_TYPE'
# Subtract their entries from XMM_nonNuclear_Catalogue.
stilts tmatch2 in1=XMM_nonNuclear_Catalogue in2=manual_NEDIPACblend \
	ofmt=fits-basic omode=out out=XMM_nonNuclear_Catalogue \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='SRCID' values2='SRCID'
# Concaenate all the entries.
# Store them in XMM_nonNuclear_Catalogue.
stilts tcatn \
	nin=6 \
	in1=XMM_nonNuclear_Catalogue \
	in2=manual_features \
	in3=manual_galaxies \
	in4=manual_NEDIPAC \
	in5=manual_NEDIPACblend \
	in6=manual_IrS \
	ofmt=fits-basic omode=out out=XMM_nonNuclear_Catalogue
rm manual_features
rm manual_galaxies
rm manual_NEDIPAC
rm manual_NEDIPACblend
rm manual_IrS
We shall introduce a new search with GaiaDR2 to find a few extra sources.
echo "------------------------------------------------------------------------------------"
echo "Perform a super-final match with GaiaDR2 to find extragalactic objects, without breaking the previous work."
echo "------------------------------------------------------------------------------------"
# Firstly, select only clean sources.
stilts tpipe in=XMM_nonNuclear_Catalogue \
	ofmt=fits-basic omode=out out=XMM_CleanList \
	cmd='replaceval "none" "1" CONT_FLAG' \
	cmd='replaceval "none(PanSTARRS1)" "1" CONT_FLAG' \
	cmd='replaceval "none(NED)" "1" CONT_FLAG' \
	cmd='select "CONT_FLAG==toString(1.)"' \
	cmd='keepcols "SRCID"' \
	cmd='colmeta -name SRCIDlist SRCID'
stilts tmatch2 \
	in1=XMM_nonNuclear_Catalogue \
	in2=XMM_CleanList \
	matcher=exact join=1and2 find=best1 \
	values1='SRCID' values2='SRCIDlist' \
	ocmd='delcols "SRCIDlist GroupID GroupSize"' \
	ocmd='colmeta -name DET_PGC_ID DET_PGC_ID_1' \
	ocmd='colmeta -name DET_PGC_ID DET_PGC_ID_1a' \
	ofmt=fits-basic omode=out out=XMM_Clean
# Select those who remain otside of the search.
stilts tpipe in=XMM_nonNuclear_Catalogue \
	ofmt=fits-basic omode=out out=XMM_notCleanList \
	cmd='replaceval "none" "1" CONT_FLAG' \
	cmd='replaceval "none(PanSTARRS1)" "1" CONT_FLAG' \
	cmd='replaceval "none(NED)" "1" CONT_FLAG' \
	cmd='select "CONT_FLAG!=toString(1.)"' \
	cmd='keepcols "SRCID"' \
	cmd='colmeta -name SRCIDlist SRCID'
stilts tmatch2 \
	in1=XMM_nonNuclear_Catalogue \
	in2=XMM_notCleanList \
	matcher=exact join=1and2 find=best1 \
	values1='SRCID' values2='SRCIDlist' \
	ocmd='delcols "SRCIDlist GroupID GroupSize"' \
	ocmd='colmeta -name DET_PGC_ID DET_PGC_ID_1' \
	ocmd='colmeta -name DET_PGC_ID DET_PGC_ID_1a' \
	ofmt=fits-basic omode=out out=XMM_notClean
rm XMM_nonNuclear_Catalogue
# Same method as for stars, but with log(fx/fv)<0.
# The contaminant columns are erased to avoid duplicites, as they are were already created in previous steps.
stilts cdsskymatch \
	in=XMM_Clean \
	ofmt=fits-basic omode=out out=XMM_Clean_GaiaExtra \
	find=all fixcols=dups suffixin=null suffixremote=_GDR2 \
	ra='SC_RA' dec='SC_DEC' radius=10 cdstable='I/345/gaia2' \
	icmd='delcols "CONT_FLAG CONT_ID RA_CONT DEC_CONT OBJ_TYPE ContDist SC_ContDist"' \
	ocmd='replaceval null 9999999 phot_g_mean_mag' \
	ocmd='select "phot_g_mean_mag<=-13.425-2.5*log10(SC_EP_8_FLUX)"' \
	ocmd='addcol "CONT_FLAG" "toString(1.)"' \
	ocmd='replaceval "1" "GaiaDR2" "CONT_FLAG"' \
	ocmd='addcol "OBJ_TYPE" "toString(1.)"' \
	ocmd='replaceval "1" "GaiaDR2_Obj" "OBJ_TYPE"' \
	ocmd='addcol "SC_ContDist" "skyDistanceDegrees(SC_RA,SC_DEC,RA_GDR2,DEC_GDR2)*3600"' \
	ocmd='select "3*(SC_POSERR+max(ra_error,dec_error)/1000)>SC_ContDist"' \
	ocmd='addcol "ContDist" "skyDistanceDegrees(RA,DEC,RA_GDR2,DEC_GDR2)*3600"' \
	ocmd='keepcols "DET_PGC_ID CONT_FLAG source_id RA_GDR2 DEC_GDR2 OBJ_TYPE ContDist SC_ContDist"' \
	ocmd='colmeta -name "CONT_ID" "source_id"' \
	ocmd='replacecol "CONT_ID" "toString(CONT_ID)"' \
	ocmd='colmeta -name "RA_CONT" "RA_GDR2"' \
	ocmd='colmeta -name "DEC_CONT" "DEC_GDR2"' \
	ocmd='colmeta -name "DET_PGC_IDlist" "DET_PGC_ID"'
stilts tmatch1 \
	in=XMM_Clean_GaiaExtra \
	icmd='sort SC_ContDist' \
	ofmt=fits-basic omode=out out=XMM_Clean_GaiaExtra \
	values='DET_PGC_IDlist' action=keep1 matcher=exact
stilts tmatch2 \
	in1=XMM_Clean \
	in2=XMM_Clean_GaiaExtra \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='DET_PGC_ID' values2='DET_PGC_IDlist' \
	ofmt=fits-basic omode=out out=XMM_Clean_noGaiaExtra
stilts tmatch2 \
	in1=XMM_Clean \
	in2=XMM_Clean_GaiaExtra \
	find=all fixcols=none join=1and2 matcher=exact \
	values1='DET_PGC_ID' values2='DET_PGC_IDlist' \
	icmd1='delcols "CONT_FLAG CONT_ID RA_CONT DEC_CONT OBJ_TYPE ContDist SC_ContDist"' \
	ocmd='delcols DET_PGC_IDlist' \
	ofmt=fits-basic omode=out out=XMM_Clean_GaiaExtra
rm XMM_Clean
# Classify the objects with Gaia counterparts that would consistute ULXs otherwise.
stilts tpipe in=XMM_Clean_GaiaExtra \
	ofmt=fits-basic omode=out out=XMM_Clean_Clean \
	cmd="select SRCID==201125506010029L|SRCID==206731702010009L|SRCID==207227002010016L|SRCID==202080101010008L|SRCID==202036102010005L|SRCID==206728701010010L|SRCID==204055504010036L|SRCID==206777501340030L|SRCID==201491601010009L|SRCID==206017410015054L|SRCID==202028701010019L|SRCID==204017912010036L|SRCID==200217507010071L|SRCID==207813501010038L" \
	cmd='replaceval "GaiaDR2" "none(NED)" CONT_FLAG' \
	cmd='replaceval "GaiaDR2_Obj" "clean" OBJ_TYPE'
stilts tmatch2 in1=XMM_Clean_GaiaExtra in2=XMM_Clean_Clean \
	ofmt=fits-basic omode=out out=XMM_Clean_GaiaExtra \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='SRCID' values2='SRCID'
stilts tpipe in=XMM_Clean_GaiaExtra \
	ofmt=fits-basic omode=out out=XMM_Clean_IrS \
	cmd="select SRCID==204053802010031L|SRCID==206514602010033L|SRCID==201098601010018L|SRCID==204053809010009L|SRCID==203070019010006L|SRCID==205504608010004L|SRCID==204053809010007L" \
	cmd='replaceval "GaiaDR2" "manual(NED)" CONT_FLAG' \
	cmd='replaceval "GaiaDR2_Obj" "IrS" OBJ_TYPE'
stilts tmatch2 in1=XMM_Clean_GaiaExtra in2=XMM_Clean_IrS \
	ofmt=fits-basic omode=out out=XMM_Clean_GaiaExtra \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='SRCID' values2='SRCID'
stilts tpipe in=XMM_Clean_GaiaExtra \
	ofmt=fits-basic omode=out out=XMM_Clean_UVS \
	cmd="select SRCID==203049401010029L" \
	cmd='replaceval "GaiaDR2" "manual(NED)" CONT_FLAG' \
	cmd='replaceval "GaiaDR2_Obj" "UVS" OBJ_TYPE'
stilts tmatch2 in1=XMM_Clean_GaiaExtra in2=XMM_Clean_UVS \
	ofmt=fits-basic omode=out out=XMM_Clean_GaiaExtra \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='SRCID' values2='SRCID'
stilts tpipe in=XMM_Clean_GaiaExtra \
	ofmt=fits-basic omode=out out=XMM_Clean_Nuclear \
	cmd="select SRCID==207843705010011L" \
	cmd='replaceval "GaiaDR2" "manual(NED)" CONT_FLAG' \
	cmd='replaceval "GaiaDR2_Obj" "central" OBJ_TYPE'
stilts tmatch2 in1=XMM_Clean_GaiaExtra in2=XMM_Clean_Nuclear \
	ofmt=fits-basic omode=out out=XMM_Clean_GaiaExtra \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='SRCID' values2='SRCID'
# Now join all that is left.
stilts tcatn \
	nin=7 \
	in1=XMM_Clean_noGaiaExtra \
	in2=XMM_notClean \
	in3=XMM_Clean_GaiaExtra \
	in4=XMM_Clean_Clean\
	in5=XMM_Clean_IrS \
	in6=XMM_Clean_UVS \
	in7=XMM_Clean_Nuclear \
	ocmd='addskycoords fk5 galactic SC_RA SC_DEC SC_RA_GAL SC_DEC_GAL' \
	ocmd='addskycoords fk5 galactic RA_HEC DEC_HEC RA_HEC_GAL DEC_HEC_GAL' \
	ofmt=fits-basic omode=out out=XMM_nonNuclear_Catalogue
# Now we are done.
#|===============================================================================================|
#| This script is called from the ULXscriptCompilation.sh motherscript.                          |
#| The pipeline continues in the SourceDivisionXMM-sh bash script.                               |
#| Eso es todo amigos! Déu vos guard.                                                            |
#| Miquel Colom Bernadich i la mare que el va parir.                                            |
#|===============================================================================================|












