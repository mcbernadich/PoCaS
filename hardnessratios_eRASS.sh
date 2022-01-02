#!/bin/bash
#This script computes the hardness ratios for sources appearing in the eRASS catalogues. It is to be provisional, as the HR comlumns already exist, they all just have a value of 0.
stilts tpipe in=eRASS_nonNuclear_Catalogue \
	ofmt=fits-basic omode=out out=eRASS_nonNuclear_Catalogue \
	cmd='replacecol HR_1 "(ML_RATE_2-ML_RATE_1)/(ML_RATE_2+ML_RATE_1)"' \
	cmd='replacecol HR_2 "(ML_RATE_3-ML_RATE_2)/(ML_RATE_3+ML_RATE_2)"' \
	cmd='replacecol HR_1_ERR "sqrt((square(ML_RATE_ERR_2)+square(ML_RATE_ERR_1))/square(ML_RATE_ERR_2+ML_RATE_1)+(square(ML_RATE_ERR_2)+square(ML_RATE_ERR_1))*square((ML_RATE_2-ML_RATE_1)/square(ML_RATE_2+ML_RATE_1)))"' \
	cmd='replacecol HR_2_ERR "sqrt((square(ML_RATE_ERR_3)+square(ML_RATE_ERR_2))/square(ML_RATE_ERR_3+ML_RATE_2)+(square(ML_RATE_ERR_3)+square(ML_RATE_ERR_2))*square((ML_RATE_3-ML_RATE_2)/square(ML_RATE_3+ML_RATE_2)))"'
