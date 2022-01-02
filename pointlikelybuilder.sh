#!/bin/bash
stilts tpipe in=4XMM-DR9/4XMM_DR9cat_v1.0.fits.gz out=4XMM-DR9/DR9_pointlikely ofmt=fits-basic \
	cmd='select "SC_DET_ML>8 & SC_EXTENT<6"'
stilts tpipe in=3XMM-DR4/xmm3r4.fit.gz out=3XMM-DR4/DR4_pointlikely ofmt=fits-basic \
	cmd='select "SC_DET_ML>8 & SC_EXTENT<6"'
#This should erase extended sources and sources with a likelyhood of being real smaller than 8.