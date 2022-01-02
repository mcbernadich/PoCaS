#!/bin/bash
# All ULX candidates.
stilts tpipe in=eRASS_nonNuclear_Catalogue \
	ofmt=fits-basic omode=out out=eRASS_ULXcandidateDetections \
	cmd='select "Luminosity+LuminosityErr>exp10(39)"'
# Only the brightest ones.
stilts tpipe in=eRASS_nonNuclear_Catalogue \
	ofmt=fits-basic omode=out out=eRASS_BrightDetections \
	cmd='select "Luminosity+LuminosityErr>5*exp10(40)"'

