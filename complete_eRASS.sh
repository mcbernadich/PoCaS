#!/bin/bash
#Make three complete samples (38,39,40) from a threshold flux of -13.5.
#Build the threshold columns.
stilts tpipe \
	in=eRASS_nonNuclear_Catalogue \
	out=eRASS_thresholdDistances ofmt=fits-basic \
	cmd='addcol -after D -units Mpc D38 "mToMpc(sqrt(exp10(38)/(4*PI*5*exp10(-14))))/100"' \
	cmd='addcol -after D38 -units Mpc D39 "mToMpc(sqrt(exp10(39)/(4*PI*5*exp10(-14))))/100"' \
	cmd='addcol -after D39 -units Mpc D5x40 "mToMpc(sqrt((5*exp10(40))/(4*PI*5*exp10(-14))))/100"' \
	cmd='replaceval none null CONT_FLAG' \
	cmd='replaceval none(PanSTARRS1) null CONT_FLAG' \
	cmd='select Luminosity>LuminosityErr'
#Select those detections whose galaxies survive the thresholds.
stilts tpipe \
	in=eRASS_thresholdDistances \
	out=eRASS_complete38 ofmt=fits-basic omode=out \
	cmd='select D<D38' \
	cmd='select SC_Luminosity>SC_LuminosityErr' \
	cmd='select abs(DEC_HEC_GAL)>25' \
	cmd="select toString(MATCH_FLAG)==toString(0.)" \
	cmd='select n_Galaxies==1' \
	cmd='select CONT_FLAG==null'
stilts tpipe \
	in=eRASS_thresholdDistances \
	out=eRASS_complete39 ofmt=fits-basic omode=out \
	cmd='select D<D39' \
	cmd='select SC_Luminosity>SC_LuminosityErr' \
	cmd='select abs(DEC_HEC_GAL)>25' \
	cmd="select toString(MATCH_FLAG)==toString(0.)" \
	cmd='select n_Galaxies==1' \
	cmd='select CONT_FLAG==null'
stilts tpipe \
	in=eRASS_thresholdDistances \
	out=eRASS_complete40 ofmt=fits-basic omode=out \
	cmd='select D<D5x40' \
	cmd='select SC_Luminosity>SC_LuminosityErr' \
	cmd='select abs(DEC_HEC_GAL)>25' \
	cmd="select toString(MATCH_FLAG)==toString(0.)" \
	cmd='select n_Galaxies==1' \
	cmd='select CONT_FLAG==null'
rm eRASS_thresholdDistances
#Build the ULX and Bright ULX subsample.

