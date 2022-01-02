#!/bin/bash
# All detections of ULX candidates.
stilts tpipe in=DR4AllDetections_inGalaxies_nonCentral_noQSOnoSO_lowFlag_noNED_noSIMBAD \
	ofmt=fits-basic omode=out out=DR4_ULXcandidateDetections \
	cmd='select "Luminosity+LuminosityErr>exp10(39)"' \
	cmd='keepcols "SRCID"' \
	cmd='colmeta -name SRCIDlist SRCID'
stilts tmatch2 \
	in1=DR4AllDetections_inGalaxies_nonCentral_noQSOnoSO_lowFlag_noNED_noSIMBAD \
	in2=DR4_ULXcandidateDetections \
	matcher=exact join=1and2 find=best1 \
	values1='SRCID' values2='SRCIDlist' \
	ocmd='delcols SRCIDlist' \
	ofmt=fits-basic omode=out out=DR4_ULXcandidateDetections
# Only the brightest ones.
stilts tpipe in=DR4AllDetections_inGalaxies_nonCentral_noQSOnoSO_lowFlag_noNED_noSIMBAD \
	ofmt=fits-basic omode=out out=DR4_BrightDetections \
	cmd='select "Luminosity+LuminosityErr>5*exp10(40)"' \
	cmd='keepcols "SRCID"' \
	cmd='colmeta -name SRCIDlist SRCID'
stilts tmatch2 \
	in1=DR4AllDetections_inGalaxies_nonCentral_noQSOnoSO_lowFlag_noNED_noSIMBAD \
	in2=DR4_BrightDetections \
	matcher=exact join=1and2 find=best1 \
	values1='SRCID' values2='SRCIDlist' \
	ocmd='delcols SRCIDlist' \
	ofmt=fits-basic omode=out out=DR4_BrightDetections
# Leave only Sources
stilts tmatch1 in=DR4AllDetections_inGalaxies_nonCentral_noQSOnoSO_lowFlag_noNED_noSIMBAD \
	matcher=exact values='SRCID' action=keep1 \
	ofmt=fits-basic omode=out out=DR4AllSources
# Only ULX candidate sources
stilts tmatch1 in=DR4_ULXcandidateDetections \
	matcher=exact values='SRCID' action=keep1 \
	ofmt=fits-basic omode=out out=DR4_ULXcandidateSources
# Only Bright Sources
stilts tmatch1 in=DR4_BrightDetections \
	matcher=exact values='SRCID' action=keep1 \
	ofmt=fits-basic omode=out out=DR4_BrightSources \
