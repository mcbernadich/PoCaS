#!/bin/bash
# This is just a repetition of the last operation in \textbf{ULX_eRASS_HECATEjoiner.sh}, in case something went wrong and you don't want to repeat all that came before.
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
	ofmt=fits-basic omode=out out=eRASS_nonNuclear_Catalogue
