#!/bin/bash
stilts tpipe in=DR4AllDetections_inGalaxies_nonCentral_noQSOnoSO_lowFlag_noNED_noSIMBAD_wrongLuminosityErr \
	out=DR4AllDetections_inGalaxies_nonCentral_noQSOnoSO_lowFlag_noNED_noSIMBAD \
	ofmt=fits-basic omode=out \
	cmd='replacecol LuminosityErr "sqrt(square(EP_8_FLUX_ERR*10000*(4*PI*square(MpcToM(D))))+square(EP_8_FLUX*10000*(8*PI*MpcToM(D)*MpcToM(D_ERR))))"' \
	cmd='replacecol SC_LuminosityErr "sqrt(square(SC_EP_8_FLUX_ERR*10000*(4*PI*square(MpcToM(D))))+square(SC_EP_8_FLUX*10000*(8*PI*MpcToM(D)*MpcToM(D_ERR))))"'
stilts tpipe in=DR9AllDetections_inGalaxies_nonCentral_noQSOnoSO_lowFlag_noNED_noSIMBAD_wrongLuminosityErr \
	out=DR9AllDetections_inGalaxies_nonCentral_noQSOnoSO_lowFlag_noNED_noSIMBAD \
	ofmt=fits-basic omode=out \
	cmd='replacecol LuminosityErr "sqrt(square(EP_8_FLUX_ERR*10000*(4*PI*square(MpcToM(D))))+square(EP_8_FLUX*10000*(8*PI*MpcToM(D)*MpcToM(D_ERR))))"' \
	cmd='replacecol SC_LuminosityErr "sqrt(square(SC_EP_8_FLUX_ERR*10000*(4*PI*square(MpcToM(D))))+square(SC_EP_8_FLUX*10000*(8*PI*MpcToM(D)*MpcToM(D_ERR))))"'

