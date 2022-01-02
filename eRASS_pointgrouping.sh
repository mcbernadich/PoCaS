#!/bin/bash
# Select all point-like sources (source extension smaller than 20").
stilts tpipe \
	in=eRASS/eRASS1_corr_clean \
	out=eRASS/eRASS_pointlike ofmt=fits-basic \
	cmd='select "EXT==0."'
# Group all detections according to their overlap.
stilts tmatch1 \
	in=eRASS/eRASS_pointlike \
	matcher=skyerr values='RA_CORR DEC_CORR RADEC_ERR' params=1 action=identify\
	ofmt=fits-basic omode=out out=eRASS/eRASS_pointlike






