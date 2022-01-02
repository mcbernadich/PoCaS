#!/bin/bash
# This is the main pipeline for the eRASS survey. ULXs are awaiting or you!
echo "------------------------------------------------------------------------"
echo "Select all point-like sources (source extension smaller equal to 0)."
echo "------------------------------------------------------------------------"
stilts tpipe \
	in=eRASS/all_e1_200427_poscorr_mpe_clean.fits.gz \
	out=eRASS/eRASS_pointlike ofmt=fits-basic \
	cmd='select "EXT<=15."'
echo "------------------------------------------------------------------------"
echo "Correlate hecate and the list of point-like sources within 3 sigma."
echo "------------------------------------------------------------------------"
echo "For this, first split according to position angle."
echo "------------------------------------------------------------------------"
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
echo "------------------------------------------------------------------------"
echo "Find all sources within galaxies with known position angle, give them flag 0."
echo "------------------------------------------------------------------------"
stilts tmatch2 \
	in1=eRASS/eRASS_pointlike \
	in2=HECATE_knownEllipses \
	find=best1 fixcols=dups suffix1=null suffix2=_HEC join=1and2 matcher=skyellipse \
	values1='RA_CORR DEC_CORR RADEC_ERR RADEC_ERR 0' values2='RA DEC R1*60 R2*60 PA' params=20 \
	ocmd='addcol -after RADEC_ERR MATCH_FLAG "toString(0.)"' \
	ofmt=fits-basic omode=out out=allsources_inKnownEllipses
rm HECATE_knownEllipses
echo "------------------------------------------------------------------------"
echo "Find all sources within the minor circle of the remaining galaxies, give them flag 1."
echo "------------------------------------------------------------------------"
stilts tmatch2 \
	in1=eRASS/eRASS_pointlike \
	in2=HECATE_unKnownEllipses \
	find=best1 fixcols=dups suffix1=null suffix2=_HEC join=1and2 matcher=skyerr \
	values1='RA_CORR DEC_CORR RADEC_ERR' values2='RA DEC R2*60' params=20 \
	ocmd='addcol -after RADEC_ERR MATCH_FLAG "toString(1.)"' \
	ofmt=fits-basic omode=out out=allsources_inUnKnownEllipses_minor
echo "------------------------------------------------------------------------"
echo "Find all sources within major circle of the remaining galaxies, give them flag 2, subtract the ones within the minor circle."
echo "------------------------------------------------------------------------"
stilts tmatch2 \
	in1=eRASS/eRASS_pointlike \
	in2=HECATE_unKnownEllipses \
	find=best1 fixcols=dups suffix1=null suffix2=_HEC join=1and2 matcher=skyerr \
	values1='RA_CORR DEC_CORR RADEC_ERR' values2='RA DEC R1*60' params=20 \
	ocmd='addcol -after RADEC_ERR MATCH_FLAG "toString(2.)"' \
	ofmt=fits-basic omode=out out=allsources_inUnKnownEllipses_major
stilts tmatch2 \
       in1=allsources_inUnKnownEllipses_major \
       in2=allsources_inUnKnownEllipses_minor \
       find=best fixcols=none join=1not2 matcher=exact \
       values1='DETUID' values2='DETUID' \
       ofmt=fits-basic omode=out out=allsources_inUnKnownEllipses_major
rm HECATE_unKnownEllipses
echo "------------------------------------------------------------------------"
echo "Join all of them into one single catalogue and compute luminosities."
echo "------------------------------------------------------------------------"
stilts tcat in='allsources_inKnownEllipses allsources_inUnKnownEllipses_minor allsources_inUnKnownEllipses_major' \
	ofmt=fits-basic omode=out out=eRASS_allDetections_inGalaxies \
	ocmd='addcol -after MATCH_FLAG -units erg/s Luminosity "ML_FLUX_0*4*PI*square(MpcToM(D)*100)"' \
	ocmd='addcol -after Luminosity -units erg/s LuminosityErr "sqrt(square(ML_FLUX_ERR_0*4*PI*square(MpcToM(D)*100))+square(ML_FLUX_0*8*PI*MpcToM(D)*MpcToM(D_ERR)*10000))"' \
	ocmd='addcol -after MATCH_FLAG -units arcsec CenterDist "skyDistanceDegrees(RA_CORR,DEC_CORR,RA_HEC,DEC_HEC)*3600"' \
	ocmd='addcol -after CenterDist -units arcsec MinCenterDist "CenterDist-3*RADEC_ERR"' \
	ocmd='delcols "GroupID GroupSize"'
rm allsources_inKnownEllipses
rm allsources_inUnKnownEllipses_minor
rm allsources_inUnKnownEllipses_major
echo "------------------------------------------------------------------------"
echo "Remove all central sources."
echo "------------------------------------------------------------------------"
stilts tpipe in=eRASS_allDetections_inGalaxies \
	ofmt=fits-basic omode=out out=eRASS_noNuclear \
	cmd='select "MinCenterDist>10"'
stilts tmatch2 \
	in1=eRASS_allDetections_inGalaxies \
	in2=eRASS_noNuclear \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='DETUID' values2='DETUID' \
	ofmt=fits-basic omode=out out=eRASS_Nuclear \
	icmd1='addcol "DETUID" "DETUID"' \
	icmd1='addcol "CONT_FLAG" "toString(1.)"' \
	icmd1='replaceval "1" "central" "CONT_FLAG"' \
	icmd1='addcol "CONT_ID" "DETUID"' \
	icmd1='addcol "RA_CONT" "1."' \
	icmd1='replaceval "1." "null" "RA_CONT"' \
	icmd1='addcol "DEC_CONT" "RA_CONT"' \
	icmd1='addcol "OBJ_TYPE" "CONT_FLAG"' \
	icmd1='addcol "MatchDist" "CenterDist"'
rm eRASS_allDetections_inGalaxies
echo "------------------------------------------------------------------------"
echo "We check with Gaia for known contaminants, using a similar Technique to that in Freund et al. 2018. We use the limit log(fx/fbol)=-2.2, and the formula from Maccacaro et al 1988."
echo "------------------------------------------------------------------------"
stilts cdsskymatch \
	in=eRASS_noNuclear \
	ofmt=fits-basic omode=out out=eRASS_noNuclear_Gaia \
	find=all fixcols=dups suffixin=null suffixremote=_GDR2 \
	ra='RA_CORR' dec='DEC_CORR' radius=20 cdstable='I/345/gaia2' \
	ocmd='select "phot_g_mean_mag<=16-2.5*log10(ML_FLUX_0/(1.1*exp10(-14)))"' \
	ocmd='addcol "CONT_FLAG" "toString(1.)"' \
	ocmd='replaceval "1" "GaiaDR2" "CONT_FLAG"' \
	ocmd='addcol "OBJ_TYPE" "toString(1.)"' \
	ocmd='replaceval "1" "Star" "OBJ_TYPE"' \
	ocmd='addcol "MatchDist" "skyDistanceDegrees(RA_CORR,DEC_CORR,RA_GDR2,DEC_GDR2)*3600"' \
	ocmd='select "3*RADEC_ERR>MatchDist"' \
	ocmd='keepcols "DETUID CONT_FLAG source_id RA_GDR2 DEC_GDR2 OBJ_TYPE MatchDist"' \
	ocmd='colmeta -name "CONT_ID" "source_id"' \
	ocmd='replacecol "CONT_ID" "toString(CONT_ID)"' \
	ocmd='colmeta -name "RA_CONT" "RA_GDR2"' \
	ocmd='colmeta -name "DEC_CONT" "DEC_GDR2"'
stilts tmatch1 \
	in=eRASS_noNuclear_Gaia \
	icmd='sort MatchDist' \
	ofmt=fits-basic omode=out out=eRASS_noNuclear_Gaia \
	values='DETUID' action=keep1 matcher=exact
stilts tmatch2 \
	in1=eRASS_noNuclear \
	in2=eRASS_noNuclear_Gaia \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='DETUID' values2='DETUID' \
	ofmt=fits-basic omode=out out=eRASS_noNuclear_noGaia
stilts tmatch2 \
	in1=eRASS_noNuclear \
	in2=eRASS_noNuclear_Gaia \
	find=all fixcols=none join=1and2 matcher=exact \
	values1='DETUID' values2='DETUID' \
	ofmt=fits-basic omode=out out=eRASS_noNuclear_Gaia
rm eRASS_noNuclear
echo "------------------------------------------------------------------------"
echo "We repeat with Tycho2."
echo "------------------------------------------------------------------------"
stilts tmatch2 \
	in1=eRASS_noNuclear_noGaia \
	in2=Tycho2/Tycho2 \
	ofmt=fits-basic omode=out out=eRASS_noNuclear_noGaia_Tycho2 \
	find=all fixcols=dups suffix1=null suffix2=_T2 join=1and2 matcher=skyerr \
	values1='RA_CORR DEC_CORR 3*RADEC_ERR' values2='_RAJ2000 _DEJ2000 0' params=10 \
	ocmd='select "VTmag<=16-2.5*log10(ML_FLUX_0/(1.1*exp10(-14)))"' \
	ocmd='addcol "CONT_FLAG" "toString(1.)"' \
	ocmd='replaceval "1" "Tycho2" "CONT_FLAG"' \
	ocmd='addcol "OBJ_TYPE" "toString(1.)"' \
	ocmd='replaceval "1" "Star" "OBJ_TYPE"' \
	ocmd='addcol "MatchDist" "skyDistanceDegrees(RA_CORR,DEC_CORR,_RAJ2000,_DEJ2000)*3600"' \
	ocmd='keepcols "DETUID CONT_FLAG TYC1 _RAJ2000 _DEJ2000 OBJ_TYPE MatchDist"' \
	ocmd='colmeta -name "CONT_ID" "TYC1"' \
	ocmd='colmeta -name "RA_CONT" "_RAJ2000"' \
	ocmd='colmeta -name "DEC_CONT" "_DEJ2000"'
stilts tmatch1 \
	in=eRASS_noNuclear_noGaia_Tycho2 \
	icmd='sort MatchDist' \
	ofmt=fits-basic omode=out out=eRASS_noNuclear_noGaia_Tycho2 \
	values='DETUID' action=keep1 matcher=exact
stilts tmatch2 \
	in1=eRASS_noNuclear_noGaia \
	in2=eRASS_noNuclear_noGaia_Tycho2 \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='DETUID' values2='DETUID' \
	ofmt=fits-basic omode=out out=eRASS_noNuclear_noGaia_noTycho2
stilts tmatch2 \
	in1=eRASS_noNuclear_noGaia \
	in2=eRASS_noNuclear_noGaia_Tycho2 \
	find=all fixcols=none join=1and2 matcher=exact \
	values1='DETUID' values2='DETUID' \
	ofmt=fits-basic omode=out out=eRASS_noNuclear_noGaia_Tycho2
rm eRASS_noNuclear_noGaia
echo "------------------------------------------------------------------------"
echo "We do a correlation with SDSS-DR14 to find QSO contaminants."
echo "------------------------------------------------------------------------"
stilts tmatch2 \
	in1=eRASS_noNuclear_noGaia_noTycho2 \
	in2=SDSSDR14/DR14Q_v4_4.fits \
	ofmt=fits-basic omode=out out=eRASS_SDSSQSO \
	find=best1 fixcols=dups suffix1=null suffix2=_SDSS join=1and2 matcher=skyerr \
	values1='RA_CORR DEC_CORR 3*RADEC_ERR' values2='RA DEC 0' params=10 \
	ocmd='addcol "CONT_FLAG" "toString(1.)"' \
	ocmd='replaceval "1" "SDSS_DR14" "CONT_FLAG"' \
	ocmd='addcol "OBJ_TYPE" "toString(1.)"' \
	ocmd='replaceval "1" "QSO" "OBJ_TYPE"' \
	ocmd='addcol "MatchDist" "skyDistanceDegrees(RA_CORR,DEC_CORR,RA,DEC)*3600"' \
	ocmd='keepcols "DETUID CONT_FLAG SDSS_NAME RA DEC OBJ_TYPE MatchDist"' \
	ocmd='colmeta -name "CONT_ID" "SDSS_NAME"' \
	ocmd='colmeta -name "RA_CONT" "RA"' \
	ocmd='colmeta -name "DEC_CONT" "DEC"'
stilts tmatch2 \
	in1=eRASS_noNuclear_noGaia_noTycho2 \
	in2=eRASS_SDSSQSO \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='DETUID' values2='DETUID' \
	ofmt=fits-basic omode=out out=eRASS_noSDSSQSO
stilts tmatch2 \
	in1=eRASS_noNuclear_noGaia_noTycho2 \
	in2=eRASS_SDSSQSO \
	find=all fixcols=none join=1and2 matcher=exact \
	values1='DETUID' values2='DETUID' \
	ofmt=fits-basic omode=out out=eRASS_SDSSQSO
rm eRASS_noNuclear_noGaia_noTycho2
echo "------------------------------------------------------------------------"
echo "We repeat with Veron QSOs."
echo "------------------------------------------------------------------------"
stilts tmatch2 \
	in1=eRASS_noSDSSQSO \
	in2=VeronQSO/VeronQSO \
	ofmt=fits-basic omode=out out=eRASS_noNuclear_noGaia_noTycho2_VeronQSO \
	find=best1 fixcols=dups suffix1=null suffix2=_Veron join=1and2 matcher=skyerr \
	values1='RA_CORR DEC_CORR 3*RADEC_ERR' values2='_RAJ2000 _DEJ2000 0' params=10 \
	ocmd='addcol "CONT_FLAG" "toString(1.)"' \
	ocmd='replaceval "1" "VeronQSO" "CONT_FLAG"' \
	ocmd='addcol "OBJ_TYPE" "toString(1.)"' \
	ocmd='replaceval "1" "QSO" "OBJ_TYPE"' \
	ocmd='addcol "MatchDist" "skyDistanceDegrees(RA_CORR,DEC_CORR,_RAJ2000,_DEJ2000)*3600"' \
	ocmd='keepcols "DETUID CONT_FLAG Name _RAJ2000 _DEJ2000 OBJ_TYPE MatchDist"' \
	ocmd='colmeta -name "CONT_ID" "Name"' \
	ocmd='colmeta -name "RA_CONT" "_RAJ2000"' \
	ocmd='colmeta -name "DEC_CONT" "_DEJ2000"'
stilts tmatch2 \
	in1=eRASS_noSDSSQSO \
	in2=eRASS_noNuclear_noGaia_noTycho2_VeronQSO \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='DETUID' values2='DETUID' \
	ofmt=fits-basic omode=out out=eRASS_noNuclear_noGaia_noTycho2_noVeronQSO
stilts tmatch2 \
	in1=eRASS_noSDSSQSO \
	in2=eRASS_noNuclear_noGaia_noTycho2_VeronQSO \
	find=all fixcols=none join=1and2 matcher=exact \
	values1='DETUID' values2='DETUID' \
	ofmt=fits-basic omode=out out=eRASS_noNuclear_noGaia_noTycho2_VeronQSO
rm eRASS_noSDSSQSO
echo "------------------------------------------------------------------------"
echo "We now go with SIMBAD to remove al remaining Stars (following the same method as before) and AGNs, but also SNs, CV and Cepheids."
echo "------------------------------------------------------------------------"
stilts cdsskymatch \
	in=eRASS_noNuclear_noGaia_noTycho2_noVeronQSO \
	ofmt=fits-basic omode=out out=eRASS_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBAD \
	find=all fixcols=dups suffixin=null suffixremote=_SIMBAD \
	ra='RA_CORR' dec='DEC_CORR' radius='20' cdstable='SIMBAD' \
	ocmd='addcol "CONT_FLAG" "toString(1.)"' \
	ocmd='replaceval "1" "SIMBAD" "CONT_FLAG"' \
	ocmd='addcol "MatchDist" "skyDistanceDegrees(RA_CORR,DEC_CORR,ra_SIMBAD,dec_SIMBAD)*3600"' \
	ocmd='select "3*RADEC_ERR>MatchDist"' \
	ocmd='keepcols "DETUID CONT_FLAG main_id ra_SIMBAD dec_SIMBAD main_type ML_FLUX_0 V MatchDist"' \
	ocmd='replaceval null 9999999 V' \
	ocmd='colmeta -name "CONT_ID" "main_id"' \
	ocmd='colmeta -name "RA_CONT" "ra_SIMBAD"' \
	ocmd='colmeta -name "DEC_CONT" "dec_SIMBAD"' \
	ocmd='colmeta -name "OBJ_TYPE" "main_type"'
echo "------------------------------------------------------------------------"
echo "All done, opening topcat to continue."
echo "------------------------------------------------------------------------"
topcat eRASS_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBAD &
echo "You may want to define the following subset upon opening eRASS_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBAD:"
echo 'OBJ_TYPE=="Star"||OBJ_TYPE=="RRLyr"||OBJ_TYPE=="deltaCep"||OBJ_TYPE=="Cepheid"||contains(OBJ_TYPE,"*")&&V<=16-2.5*log10(ML_FLUX_0/(1.1*exp10(-14)))'
echo "Once you have done so, please save it as eRASS_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBADstars"
echo "same for:"
echo 'OBJ_TYPE=="QSO"||OBJ_TYPE=="QSO_Candidate"||OBJ_TYPE=="AGN"||OBJ_TYPE=="AGN_Candidate"||OBJ_TYPE=="SN"'
echo "eRASS_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBADagn"
read -p "Press [Enter] to continue once this is done."
rm eRASS_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBAD
echo "------------------------------------------------------------------------"
echo "Removing SIMBAD stars."
echo "------------------------------------------------------------------------"
stilts tmatch1 \
	in=eRASS_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBADstars \
	icmd='sort MatchDist' \
	ocmd='keepcols "DETUID CONT_FLAG CONT_ID RA_CONT DEC_CONT OBJ_TYPE MatchDist"' \
	ofmt=fits-basic omode=out out=eRASS_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBADstars \
	values='DETUID' action=keep1 matcher=exact
stilts tmatch2 \
	in1=eRASS_noNuclear_noGaia_noTycho2_noVeronQSO \
	in2=eRASS_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBADstars \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='DETUID' values2='DETUID' \
	ofmt=fits-basic omode=out out=eRASS_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBADstars
stilts tmatch2 \
	in1=eRASS_noNuclear_noGaia_noTycho2_noVeronQSO \
	in2=eRASS_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBADstars \
	find=all fixcols=none join=1and2 matcher=exact \
	values1='DETUID' values2='DETUID' \
	ofmt=fits-basic omode=out out=eRASS_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBADstars
rm eRASS_noNuclear_noGaia_noTycho2_noVeronQSO
echo "------------------------------------------------------------------------"
echo "Removing SIMBAD AGNs and SN."
echo "------------------------------------------------------------------------"
stilts tmatch1 \
	in=eRASS_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBADagn \
	icmd='sort MatchDist' \
	ocmd='keepcols "DETUID CONT_FLAG CONT_ID RA_CONT DEC_CONT OBJ_TYPE MatchDist"' \
	ofmt=fits-basic omode=out out=eRASS_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBADagn \
	values='DETUID' action=keep1 matcher=exact
stilts tmatch2 \
	in1=eRASS_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBADstars \
	in2=eRASS_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBADagn \
	find=all fixcols=none join=1not2 matcher=exact \
	values1='DETUID' values2='DETUID' \
	ofmt=fits-basic omode=out out=eRASS_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBAD
stilts tmatch2 \
	in1=eRASS_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBADstars \
	in2=eRASS_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBADagn \
	find=all fixcols=none join=1and2 matcher=exact \
	values1='DETUID' values2='DETUID' \
	ofmt=fits-basic omode=out out=eRASS_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBADagn
rm eRASS_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBADstars
echo "-------------------------------------------------------------------------"
echo "Now joining all remaining sources with contaminants, keeping rellevant info of the matched contaminants"
echo "-------------------------------------------------------------------------"
stilts tcatn \
	nin=8 \
	in1=eRASS_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBAD \
	in2=eRASS_Nuclear \
	in3=eRASS_noNuclear_Gaia \
	in4=eRASS_noNuclear_noGaia_Tycho2 \
	in5=eRASS_SDSSQSO \
	in6=eRASS_noNuclear_noGaia_noTycho2_VeronQSO \
	in7=eRASS_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBADstars \
	in8=eRASS_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBADagn \
	icmd1='addcol "DETUID" "DETUID"' \
	icmd1='addcol "CONT_FLAG" "toString(1.)"' \
	icmd1='replaceval "1" "none" "CONT_FLAG"' \
	icmd1='addcol "CONT_ID" "toString(1.)"' \
	icmd1='replaceval "1" "null" "CONT_ID"' \
	icmd1='addcol "RA_CONT" "1."' \
	icmd1='replaceval "1." "null" "RA_CONT"' \
	icmd1='addcol "DEC_CONT" "RA_CONT"' \
	icmd1='addcol "OBJ_TYPE" "toString(1.)"' \
	icmd1='replaceval "1" "null" "OBJ_TYPE"' \
	icmd1='addcol "MatchDist" "RA_CONT"' \
	ocmd='addskycoords fk5 galactic RA_CORR DEC_CORR RA_CORR_GAL DEC_CORR_GAL' \
	ocmd='addskycoords fk5 galactic RA_HEC DEC_HEC RA_HEC_GAL DEC_HEC_GAL' \
	ofmt=fits-basic omode=out out=eRASS_nonNuclear_Catalogue
rm eRASS_noNuclear_noGaia_noTycho2_noVeronQSO_noSIMBAD
rm eRASS_noNuclear_Gaia
rm eRASS_noNuclear_noGaia_Tycho2
rm eRASS_noNuclear_noGaia_noTycho2_VeronQSO
rm eRASS_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBADstars
rm eRASS_noNuclear_noGaia_noTycho2_noVeronQSO_SIMBADagn
rm eRASS_Nuclear
echo "-------------------------------------------------------------------------"






















