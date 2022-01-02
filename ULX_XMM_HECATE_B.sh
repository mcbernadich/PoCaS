#!/bin/bash
# This is the main pipeline for the 4XMM-DR9 survey. XMM yielded a surprisingly low amoun of ULX candidates, so I am repeating it with XMM data to see if this is a problem I may want to fix.
echo "------------------------------------------------------------------------------------"
echo "Correlate hecate and the list of point-like sources within 3 sigma."
echo "------------------------------------------------------------------------------------"
echo "For this, first split according to position angle."
echo "------------------------------------------------------------------------------------"
stilts tpipe \
	in=HECATE/HECATE_slim_2.1.fits \
	out=HECATE_knownEllipses \
	cmd='replaceval null 0. "PA"' \
	ofmt=fits-basic cmd='select "PA!=0."'
stilts tpipe \
	in=HECATE/HECATE_slim_2.1.fits \
	out=HECATE_unKnownEllipses \
	cmd='replaceval null 0. "PA"' \
	ofmt=fits-basic cmd='select "PA==0."'
echo "------------------------------------------------------------------------------------"
echo "Find all sources within galaxies with known position angle, give them flag 0."
echo "------------------------------------------------------------------------------------"
stilts tmatch2 \
	in1=4XMM-DR9/DR9_pointlikely \
	in2=HECATE_knownEllipses \
	find=all fixcols=dups suffix1=null suffix2=_HEC join=1and2 matcher=skyellipse \
	values1='SC_RA SC_DEC SC_POSERR 3*SC_POSERR 0' values2='RA DEC R1*60 R2*60 PA' params=10 \
	ocmd='addcol -after SC_POSERR MATCH_FLAG "toString(0.)"' \
	ocmd='addcol -after SRCID DET_PGC_ID concat(DETID,PGC)' \
	ocmd='addcol -after DET_PGC_ID SRC_PGC_ID concat(SRCID,PGC)' \
	ofmt=fits-basic omode=out out=allsources_inKnownEllipses
rm HECATE_knownEllipses
echo "------------------------------------------------------------------------------------"
echo "Find all sources within the minor circle of the remaining galaxies, give them flag 1."
echo "------------------------------------------------------------------------------------"
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
stilts tmatch2 \
	in1=4XMM-DR9/DR9_pointlikely \
	in2=HECATE_unKnownEllipses \
	find=all fixcols=dups suffix1=null suffix2=_HEC join=1and2 matcher=skyerr \
	values1='SC_RA SC_DEC SC_POSERR' values2='RA DEC R1*60' params=10 \
	ocmd='addcol -after SC_POSERR MATCH_FLAG "toString(2.)"' \
	ocmd='addcol -after SRCID DET_PGC_ID concat(DETID,PGC)' \
	ocmd='addcol -after DET_PGC_ID SRC_PGC_ID concat(SRCID,PGC)' \
	ofmt=fits-basic omode=out out=allsources_inUnKnownEllipses_major
stilts tmatch2 \
	in1=allsources_inUnKnownEllipses_major \
	in2=allsources_inUnKnownEllipses_minor \
	find=best fixcols=none join=1not2 matcher=exact \
	values1='DET_PGC_ID' values2='DET_PGC_ID' \
	ofmt=fits-basic omode=out out=allsources_inUnKnownEllipses_major
rm HECATE_unKnownEllipses
echo "------------------------------------------------------------------------------------"
echo "Join all of them into one single catalogue and compute luminosities."
echo "------------------------------------------------------------------------------------"
stilts tcat in='allsources_inKnownEllipses allsources_inUnKnownEllipses_minor allsources_inUnKnownEllipses_major' \
	ofmt=fits-basic omode=out out=XMM_allDetections_inGalaxies \
	ocmd='addcol -after MATCH_FLAG -units erg/s Luminosity "EP_8_FLUX*4*PI*square(MpcToM(D)*100)"' \
	ocmd='addcol -after Luminosity -units erg/s LuminosityErr "sqrt(square(EP_8_FLUX_ERR*4*PI*square(MpcToM(D)*100))+square(EP_8_FLUX*8*PI*MpcToM(D)*MpcToM(D_ERR)*10000))"' \
	ocmd='addcol -after LuminosityErr -units erg/s SC_Luminosity "SC_EP_8_FLUX*4*PI*square(MpcToM(D)*100)"' \
	ocmd='addcol -after SC_Luminosity -units erg/s SC_LuminosityErr "sqrt(square(SC_EP_8_FLUX_ERR*4*PI*square(MpcToM(D)*100))+square(SC_EP_8_FLUX*8*PI*MpcToM(D)*MpcToM(D_ERR)*10000))"' \
	ocmd='addcol -after MATCH_FLAG -units arcsec CenterDist "skyDistanceDegrees(RA,DEC,RA_HEC,DEC_HEC)*3600"' \
	ocmd='addcol -after CenterDist -units arcsec MinCenterDist "CenterDist-3*POSERR"' \
	ocmd='delcols "GroupID GroupSize"' \
	ocmd='addcol -after MinCenterDist -units arcsec SC_CenterDist "skyDistanceDegrees(SC_RA,SC_DEC,RA_HEC,DEC_HEC)*3600"' \
	ocmd='addcol -after SC_CenterDist -units arcsec SC_MinCenterDist "SC_CenterDist-3*SC_POSERR"'
rm allsources_inKnownEllipses
rm allsources_inUnKnownEllipses_minor
rm allsources_inUnKnownEllipses_major
echo "------------------------------------------------------------------------------------"
echo "Create a column counting in how manygalaxies has a source been found"
echo "------------------------------------------------------------------------------------"
stilts tmatch1 in=XMM_allDetections_inGalaxies \
	matcher=exact values="DETID" action="identify" \
	ofmt=fits-basic omode=out out=XMM_allDetections_inGalaxies \
	ocmd='replaceval "null" "1" "GroupSize"' \
	ocmd='addcol -after MATCH_FLAG n_Galaxies "GroupSize"' \
	ocmd='delcols "GroupID GroupSize"'
echo "------------------------------------------------------------------------------------"
echo "Remove all central sources."
echo "------------------------------------------------------------------------------------"
stilts tpipe in=XMM_allDetections_inGalaxies \
	ofmt=fits-basic omode=out out=XMM_noNuclear \
	cmd='select "SC_MinCenterDist>3"'
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
	icmd1='addcol "MatchDist" "CenterDist"' \
	icmd1='addcol "SC_MatchDist" "SC_CenterDist"'
rm XMM_allDetections_inGalaxies
echo "------------------------------------------------------------------------------------"
echo "Identify sources that are central in other galaxies."
echo "------------------------------------------------------------------------------------"
stilts tmatch2 \
	in1=XMM_noNuclear \
	in2=XMM_Nuclear \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='SRCID' values2='SRCID' \
	ofmt=fits-basic omode=out out=XMM_noPotentiallyNuclear
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
	icmd1='addcol "MatchDist" "CenterDist"' \
	icmd1='addcol "SC_MatchDist" "SC_CenterDist"'
rm XMM_noNuclear
echo "------------------------------------------------------------------------------------"
echo "We check with Gaia for known contaminants, using a similar Technique to that in Freun et al. 2018. We use the limit log(fx/fbol)=-2.2, and the formula from Maccaro et al 1988."
echo "------------------------------------------------------------------------------------"
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
	ocmd='addcol "SC_MatchDist" "skyDistanceDegrees(SC_RA,SC_DEC,RA_GDR2,DEC_GDR2)*3600"' \
	ocmd='select "3*(SC_POSERR+max(ra_error,dec_error)/1000)>SC_MatchDist"' \
	ocmd='addcol "MatchDist" "skyDistanceDegrees(RA,DEC,RA_GDR2,DEC_GDR2)*3600"' \
	ocmd='keepcols "DET_PGC_ID CONT_FLAG source_id RA_GDR2 DEC_GDR2 OBJ_TYPE MatchDist SC_MatchDist"' \
	ocmd='colmeta -name "CONT_ID" "source_id"' \
	ocmd='replacecol "CONT_ID" "toString(CONT_ID)"' \
	ocmd='colmeta -name "RA_CONT" "RA_GDR2"' \
	ocmd='colmeta -name "DEC_CONT" "DEC_GDR2"'
stilts tmatch1 \
	in=XMM_noNuclear_Gaia \
	icmd='sort MatchDist' \
	ofmt=fits-basic omode=out out=XMM_noNuclear_Gaia \
	values='DET_PGC_ID' action=keep1 matcher=exact
stilts tmatch2 \
	in1=XMM_noPotentiallyNuclear \
	in2=XMM_noNuclear_Gaia \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='DET_PGC_ID' values2='DET_PGC_ID' \
	ofmt=fits-basic omode=out out=XMM_noNuclear_noGaia
stilts tmatch2 \
	in1=XMM_noPotentiallyNuclear \
	in2=XMM_noNuclear_Gaia \
	find=all fixcols=none join=1and2 matcher=exact \
	values1='DET_PGC_ID' values2='DET_PGC_ID' \
	ofmt=fits-basic omode=out out=XMM_noNuclear_Gaia
rm XMM_noPotentiallyNuclear
echo "------------------------------------------------------------------------------------"
echo "We repeat with Tycho2."
echo "------------------------------------------------------------------------------------"
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
	ocmd='addcol "SC_MatchDist" "skyDistanceDegrees(SC_RA,SC_DEC,_RAJ2000,_DEJ2000)*3600"' \
	ocmd='addcol "MatchDist" "skyDistanceDegrees(RA,DEC,_RAJ2000,_DEJ2000)*3600"' \
	ocmd='keepcols "DET_PGC_ID CONT_FLAG TYC1 _RAJ2000 _DEJ2000 OBJ_TYPE MatchDist SC_MatchDist"' \
	ocmd='colmeta -name "CONT_ID" "TYC1"' \
	ocmd='colmeta -name "RA_CONT" "_RAJ2000"' \
	ocmd='colmeta -name "DEC_CONT" "_DEJ2000"'
stilts tmatch1 \
	in=XMM_noNuclear_noGaia_Tycho2 \
	icmd='sort MatchDist' \
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
echo "------------------------------------------------------------------------------------"
echo "We do a correlation with SDSS-DR14 to find QSO contaminants."
echo "------------------------------------------------------------------------------------"
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
	ocmd='addcol "SC_MatchDist" "skyDistanceDegrees(SC_RA,SC_DEC,RA_SDSS,DEC_SDSS)*3600"' \
	ocmd='addcol "MatchDist" "skyDistanceDegrees(RA,DEC,RA_SDSS,DEC_SDSS)*3600"' \
	ocmd='keepcols "DET_PGC_ID CONT_FLAG SDSS_NAME RA DEC OBJ_TYPE MatchDist SC_MatchDist"' \
	ocmd='colmeta -name "CONT_ID" "SDSS_NAME"' \
	ocmd='colmeta -name "RA_CONT" "RA"' \
	ocmd='colmeta -name "DEC_CONT" "DEC"'
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
echo "------------------------------------------------------------------------------------"
echo "We repeat with Veron QSOs."
echo "------------------------------------------------------------------------------------"
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
	ocmd='addcol "SC_MatchDist" "skyDistanceDegrees(SC_RA,SC_DEC,_RAJ2000,_DEJ2000)*3600"' \
	ocmd='addcol "MatchDist" "skyDistanceDegrees(RA,DEC,_RAJ2000,_DEJ2000)*3600"' \
	ocmd='keepcols "DET_PGC_ID CONT_FLAG Name _RAJ2000 _DEJ2000 OBJ_TYPE MatchDist SC_MatchDist"' \
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
rm XMM_noSDSSQSO
echo "------------------------------------------------------------------------------------"
echo "We now go with SIMBAD to remove al remaining Stars (following the same method as before), AGNs, and SNs."
echo "------------------------------------------------------------------------------------"
stilts cdsskymatch \
	in=XMM_noNuclear_noGaia_noTycho2_noVeronQSO \
	ofmt=fits-basic omode=out out=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBAD \
	find=all fixcols=dups suffixin=null suffixremote=_SIMBAD \
	ra='SC_RA' dec='SC_DEC' radius='10' cdstable='SIMBAD' \
	ocmd='addcol "CONT_FLAG" "toString(1.)"' \
	ocmd='replaceval "1" "SIMBAD" "CONT_FLAG"' \
	ocmd='addcol "SC_MatchDist" "skyDistanceDegrees(SC_RA,SC_DEC,ra_SIMBAD,dec_SIMBAD)*3600"' \
	ocmd='replaceval null 0 coo_err_maj' \
	ocmd='select "3*(SC_POSERR+coo_err_maj)>SC_MatchDist"' \
	ocmd='addcol "MatchDist" "skyDistanceDegrees(RA,DEC,ra_SIMBAD,dec_SIMBAD)*3600"' \
	ocmd='addcol "dummy_type" "main_type"' \
	ocmd='addcol "dummy_character" "toString(1.)"' \
	ocmd='keepcols "DET_PGC_ID CONT_FLAG main_id ra_SIMBAD dec_SIMBAD main_type SC_EP_8_FLUX V MatchDist SC_MatchDist dummy_type dummy_character"' \
	ocmd='replaceval null 9999999 V' \
	ocmd='colmeta -name "CONT_ID" "main_id"' \
	ocmd='colmeta -name "RA_CONT" "ra_SIMBAD"' \
	ocmd='colmeta -name "DEC_CONT" "dec_SIMBAD"' \
	ocmd='colmeta -name "OBJ_TYPE" "main_type"'
echo "------------------------------------------------------------------------------------"
echo "Finding stars in SIMBAD."
echo "------------------------------------------------------------------------------------"
stilts tmatch1 in=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBAD \
	ofmt=fits-basic omode=out out=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBADstars \
	icmd='replaceval "Star" "1" dummy_type' \
	icmd='replaceval "1" "*" dummy_character' \
	icmd='select "dummy_type==toString(1.)||contains(OBJ_TYPE,toString(dummy_character))&&V<=-18.925-2.5*log10(SC_EP_8_FLUX)"' \
	icmd='keepcols "DET_PGC_ID CONT_FLAG CONT_ID RA_CONT DEC_CONT OBJ_TYPE MatchDist SC_MatchDist"' \
	icmd='sort MatchDist' \
	values='DET_PGC_ID' action=keep1 matcher=exact
stilts tmatch2 \
	in1=XMM_noNuclear_noGaia_noTycho2_noVeronQSO \
	in2=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBADstars \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='DET_PGC_ID' values2='DET_PGC_ID' \
	ofmt=fits-basic omode=out out=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBADstars
stilts tmatch2 \
	in1=XMM_noNuclear_noGaia_noTycho2_noVeronQSO \
	in2=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBADstars \
	find=all fixcols=none join=1and2 matcher=exact \
	values1='DET_PGC_ID' values2='DET_PGC_ID' \
	ofmt=fits-basic omode=out out=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBADstars
rm XMM_noNuclear_noGaia_noTycho2_noVeronQSO
echo "------------------------------------------------------------------------------------"
echo "Finding stars and AGNs in SIMBAD."
echo "------------------------------------------------------------------------------------"
stilts tmatch1 in=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBAD \
	ofmt=fits-basic omode=out out=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBADagn \
	icmd='replaceval "QSO" "1" dummy_type' \
	icmd='replaceval "QSO_Candidate" "1" dummy_type' \
	icmd='replaceval "AGN" "1" dummy_type' \
	icmd='replaceval "AGN_Candidate" "1" dummy_type' \
	icmd='replaceval "SN" "1" dummy_type' \
	icmd='select "dummy_type==toString(1.)"' \
	icmd='keepcols "DET_PGC_ID CONT_FLAG CONT_ID RA_CONT DEC_CONT OBJ_TYPE MatchDist SC_MatchDist"' \
	icmd='sort MatchDist' \
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
echo "------------------------------------------------------------------------------------"
echo "Finding counterparts in PanStarrs1 DR1. We use the g magnitude here."
echo "We use once againg the formula from Maccacaro et al 1988, but this time we select all objects that are brighter in the optical (g magnitude) than in the X-ray, as we are not certain of the nature of the counterparts."
echo "------------------------------------------------------------------------------------"
stilts cdsskymatch \
	in=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBAD \
	ofmt=fits-basic omode=out \
	out=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBAD_PanSTARRS1 \
	find=all fixcols=dups suffixin=null suffixremote=_PanSTARRS1 \
	ra='SC_RA' dec='SC_DEC' radius='10' cdstable='PanSTARRS DR1' \
	ocmd='addcol "CONT_FLAG" "toString(1.)"' \
	ocmd='replaceval "1" "PanSTARRS1" "CONT_FLAG"' \
	ocmd='addcol "SC_MatchDist" "skyDistanceDegrees(SC_RA,SC_DEC,RAJ2000,DEJ2000)*3600"' \
	ocmd='select "3*(SC_POSERR+errHalfMaj)>SC_MatchDist"' \
	ocmd='addcol "MatchDist" "skyDistanceDegrees(RA,DEC,RAJ2000,DEJ2000)*3600"' \
	ocmd='addcol "CONT_ID" "toString(f_objID)"' \
	ocmd='keepcols "DET_PGC_ID CONT_FLAG CONT_ID RAJ2000 DEJ2000 SC_EP_8_FLUX gmag MatchDist SC_MatchDist"' \
	ocmd='replaceval null 9999999 gmag' \
	ocmd='colmeta -name "RA_CONT" "RAJ2000"' \
	ocmd='colmeta -name "DEC_CONT" "DEJ2000"'
stilts tmatch1 in=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBAD_PanSTARRS1 \
	ofmt=fits-basic omode=out \
	out=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBAD_PanSTARRS1 \
	icmd='select "gmag<=-13.425-2.5*log10(SC_EP_8_FLUX)"' \
	icmd='addcol -after DEC_CONT OBJ_TYPE "toString(1.)"' \
	icmd='replaceval "1" "Bright Counterpart" OBJ_TYPE' \
	icmd='keepcols "DET_PGC_ID CONT_FLAG CONT_ID RA_CONT DEC_CONT OBJ_TYPE MatchDist SC_MatchDist"' \
	icmd='sort MatchDist' \
	values='DET_PGC_ID' action=keep1 matcher=exact
stilts tmatch2 \
	in1=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBAD \
	in2=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBAD_PanSTARRS1 \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='DET_PGC_ID' values2='DET_PGC_ID' \
	ofmt=fits-basic omode=out \
	out=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBAD_noPanSTARRS1
stilts tmatch2 \
	in1=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBAD \
	in2=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBAD_PanSTARRS1 \
	find=all fixcols=none join=1and2 matcher=exact \
	values1='DET_PGC_ID' values2='DET_PGC_ID' \
	ofmt=fits-basic omode=out out=XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBAD_PanSTARRS1
rm XMM_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBAD
echo "------------------------------------------------------------------------------------"
echo "Now joining all remaining sources with contaminants, keeping rellevant info of the matched contaminants"
echo "------------------------------------------------------------------------------------"
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
	icmd1='addcol "MatchDist" "RA_CONT"' \
	icmd1='addcol "SC_MatchDist" "RA_CONT"' \
	ocmd='addskycoords fk5 galactic SC_RA SC_DEC SC_RA_GAL SC_DEC_GAL' \
	ocmd='addskycoords fk5 galactic RA_HEC DEC_HEC RA_HEC_GAL DEC_HEC_GAL' \
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
exit
echo "------------------------------------------------------------------------------------"
echo "Now select manually observed contaminants. These guys have been observed in the PANSTARRS1, and from the images they are deemed to have wrognfully survived the filtering steps."
echo "------------------------------------------------------------------------------------"
stilts tpipe in=XMM_nonNuclear_Catalogue \
	ofmt=fits-basic omode=out out=manual_double \
	cmd="select SRCID==200559905010001L|SRCID==205000702010002L" \
	cmd='replaceval "none" "manual" CONT_FLAG' \
	cmd='replaceval "clean" "unresolved double, optical counterpart" OBJ_TYPE'
stilts tmatch2 in1=XMM_nonNuclear_Catalogue in2=manual_double \
	ofmt=fits-basic omode=out out=XMM_nonNuclear_Catalogue \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='SRCID' values2='SRCID'
stilts tpipe in=XMM_nonNuclear_Catalogue \
	ofmt=fits-basic omode=out out=manual_optical \
	cmd="select SRCID==201241101010001L|SRCID==200029601010001L|SRCID==206701401010002L|SRCID==200029702010002L|SRCID==201389514010019L|SRCID==202060901010021L|SRCID==203002105010001L|SRCID==206534502010033L|SRCID==206929307010023L|SRCID==208022001010013L|SRCID==200080302010044L|SRCID==201098601010018L|SRCID==201122703010001L|SRCID==202036102010005L|SRCID==202036901010002L|SRCID==202060901010021L|SRCID==202065801010017L|SRCID==203002105010001L|SRCID==203024601010002L|SRCID==203056904010017L|SRCID==205052304010032L|SRCID==205516001010107L" \
	cmd='replaceval "none" "manual" CONT_FLAG' \
	cmd='replaceval "clean" "optical counterpart" OBJ_TYPE'
stilts tmatch2 in1=XMM_nonNuclear_Catalogue in2=manual_optical \
	ofmt=fits-basic omode=out out=XMM_nonNuclear_Catalogue \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='SRCID' values2='SRCID'
stilts tpipe in=XMM_nonNuclear_Catalogue \
	ofmt=fits-basic omode=out out=manual_octahedron \
	cmd="select SRCID==201365407010002L|SRCID==201365410010001L|SRCID==201504987010002L|SRCID==201589702010003L|SRCID==201589707010003L|SRCID==201589712010001L|SRCID==202004308010001L|SRCID==204110819010002L" \
	cmd='replaceval "none" "manual" CONT_FLAG' \
	cmd='replaceval "clean" "spurious detection" OBJ_TYPE'
stilts tmatch2 in1=XMM_nonNuclear_Catalogue in2=manual_octahedron \
	ofmt=fits-basic omode=out out=XMM_nonNuclear_Catalogue \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='SRCID' values2='SRCID'
stilts tcatn \
	nin=4 \
	in1=XMM_nonNuclear_Catalogue \
	in2=manual_double \
	in3=manual_optical \
	in4=manual_octahedron \
	ofmt=fits-basic omode=out out=XMM_nonNuclear_Catalogue
rm manual_double
rm manual_optical
rm manual_octahedron


















