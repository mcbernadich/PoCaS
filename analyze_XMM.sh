#!/bin/bash
#This script will make all of the necessary plots.
#This loop runs over all the hardness ratios.
#if false; then
stilts tmatch1 \
	in=XMM_nonNuclear_Catalogue \
	out=XMM_nonNuclear_Sources ofmt=fits-basic omode=out \
	values='SRCID' action=keep1 matcher=exact \
	ocmd='addcol True "1==1"' \
	ocmd='addcol False "1==0"'
for i in `seq 1 3` ; do
#First, build the list of objects I want to plot.
#First, build the list of objects I want to plot.
stilts tpipe \
	in=XMM_nonNuclear_Sources \
	out=XMM_completeULXs ofmt=fits-basic omode=out \
	cmd='select ULX_QUALITY==True' \
	cmd='select True==ss39' \
	cmd="select SC_HR${i}_ERR<0.2&&SC_HR$[${i}+1]_ERR<0.2"
stilts tpipe \
	in=XMM_nonNuclear_Sources \
	out=XMM_completeBrightULXs ofmt=fits-basic omode=out \
	cmd='select brightULX_QUALITY==True' \
	cmd='select ss5x40==True' \
	cmd="select SC_HR${i}_ERR<0.2&&SC_HR$[${i}+1]_ERR<0.2"
stilts tpipe \
	in=XMM_nonNuclear_Sources \
	out=XMM_complete38modified ofmt=fits-basic omode=out \
	cmd='select ss38==True' \
	cmd="select SC_HR${i}_ERR<0.2&&SC_HR$[${i}+1]_ERR<0.2&&SC_Luminosity>exp10(38)&&SC_Luminosity<exp10(39)"
stilts tpipe \
	in=XMM_nonNuclear_Sources \
	out=XMM_complete38modifiedtolower ofmt=fits-basic omode=out \
	cmd='select ss38==True' \
	cmd="select SC_HR${i}_ERR<0.2&&SC_HR$[${i}+1]_ERR<0.2&&SC_Luminosity<exp10(38)"
stilts tpipe \
	in=XMM_nonNuclear_Sources \
	out=XMM_NuclearContaminants ofmt=fits-basic \
	cmd='addcol OBJ_TYPE_2 toString(98.)' \
	cmd='replaceval "98" "AGN" OBJ_TYPE_2' \
	cmd='addcol OBJ_TYPE_3 toString(99.)' \
	cmd='replaceval "99" "QSO" OBJ_TYPE_3' \
	cmd='addcol OBJ_TYPE_4 toString(98.)' \
	cmd='replaceval "98" "AGN_Candidate" OBJ_TYPE_4' \
	cmd='addcol OBJ_TYPE_5 toString(99.)' \
	cmd='replaceval "99" "QSO_Candidate" OBJ_TYPE_5' \
	cmd="select OBJ_TYPE==OBJ_TYPE_2||OBJ_TYPE==OBJ_TYPE_3||OBJ_TYPE==OBJ_TYPE_4||OBJ_TYPE==OBJ_TYPE_5&&SC_HR${i}_ERR<0.2&&SC_HR$[${i}+1]_ERR<0.2"
stilts tpipe \
	in=XMM_nonNuclear_Sources \
	out=XMM_SNcontaminants ofmt=fits-basic \
	cmd='addcol OBJ_TYPE_2 toString(97.)' \
	cmd='replaceval "97" "SN" OBJ_TYPE_2' \
	cmd="select OBJ_TYPE==OBJ_TYPE_2&&SC_HR${i}_ERR<0.2&&SC_HR$[${i}+1]_ERR<0.2"
stilts tpipe \
	in=XMM_nonNuclear_Sources \
	out=XMM_StellarContaminants ofmt=fits-basic \
	cmd='addcol OBJ_TYPE_2 toString(96.)' \
	cmd='replaceval "96" "Star" OBJ_TYPE_2' \
	cmd='addcol OBJ_TYPE_3 toString(95.)' \
	cmd='replaceval "95" "GaiaDR2_Obj" OBJ_TYPE_3' \
	cmd="select OBJ_TYPE==OBJ_TYPE_2||OBJ_TYPE==OBJ_TYPE_3&&SC_HR${i}_ERR<0.2&&SC_HR$[${i}+1]_ERR<0.2"
#Now plot, you bastard.
#First go with the HR diagram plots.
stilts plot2plane \
	xlabel="HR${i}" ylabel="HR$[${i}+1]" \
	layer_99=contour in_99=XMM_complete38modifiedtolower color_99=yellow x_99="SC_HR${i}" y_99="SC_HR$[${i}+1]" \
	nlevel_99=30 smooth_99=100 leglabel_99="log10(Lx)<38" \
	layer_0=contour in_0=XMM_complete38modified color_0=green x_0="SC_HR${i}" y_0="SC_HR$[${i}+1]" \
	nlevel_0=5 smooth_0=100 leglabel_0="38<log10(Lx)<39" \
	layer_1=mark in_1=XMM_completeULXs color_1=blue size_1=1 x_1="SC_HR${i}" y_1="SC_HR$[${i}+1]" leglabel_1="cULXss" \
	layer_2=mark in_2=XMM_completeBrightULXs color_2=red shape_2=filled_diamond size_2=3 x_2="SC_HR${i}" y_2="SC_HR$[${i}+1]" leglabel_2="cbULXss" \
	omode=out ofmt=png out=XMMplots/HRplots/HRpopPlot${i}.png \
	xmin=-1 xmax=1 ymin=-1 ymax=1 legend=true legpos="0.1,0.95"
#Then with the HR contaminants plots.
echo 'Helooooooou wi ar goin trú'
echo $i
stilts plot2plane \
	xlabel="HR${i}" ylabel="HR$[${i}+1]" \
	layer_i=contour in_i=XMM_NuclearContaminants color_i=green x_i="SC_HR${i}" y_i="SC_HR$[${i}+1]" \
	nlevel_i=5 smooth_i=100 leglabel_i="AGN/QSO" \
	layer_2i=contour in_2i=XMM_SNcontaminants color_2i=grey x_2i="SC_HR${i}" y_2i="SC_HR$[${i}+1]" \
	nlevel_2i=5 smooth_2i=100 leglabel_2i="Supernovae" \
	layer_3i=contour in_3i=XMM_StellarContaminants color_3i=orange x_3i="SC_HR${i}" y_3i="SC_HR$[${i}+1]" \
	nlevel_3i=5 smooth_3i=100 leglabel_3i="Stellar objs." \
	layer_1=mark in_1=XMM_completeULXs color_1=blue size_1=1 x_1="SC_HR${i}" y_1="SC_HR$[${i}+1]" leglabel_1="cULXss" \
	layer_2=mark in_2=XMM_completeBrightULXs color_2=red shape_2=filled_diamond size_2=3 x_2="SC_HR${i}" y_2="SC_HR$[${i}+1]" leglabel_2="cbULXss" \
	omode=out ofmt=png out=XMMplots/HRplots/HRcontPlot${i}.png \
	xmin=-1 xmax=1 ymin=-1 ymax=1 legend=true legpos="0.1,0.95"
#Then with the HR morphology plots.
stilts plot2plane \
	xlabel="HR${i}" ylabel="HR$[${i}+1]" \
	layer_1=mark in_1=XMM_completeULXs color_1=blue size_1=1 x_1="SC_HR${i}" y_1="SC_HR$[${i}+1]" icmd_1='select "T>=0"' leglabel_1="LTG-hosted" \
	layer_3=mark in_3=XMM_completeULXs color_3=red size_3=1 x_3="SC_HR${i}" y_3="SC_HR$[${i}+1]" icmd_3='select "T<0"' leglabel_3="ETG-hosted" \
	layer_2=mark in_2=XMM_completeBrightULXs color_2=cyan shape_2=filled_diamond size_2=3 x_2="SC_HR${i}" y_2="SC_HR$[${i}+1]" icmd_2='select "T>=0"' leglabel_2="LTG-hosted, bright" \
	layer_4=mark in_4=XMM_completeBrightULXs color_4=orange shape_4=filled_diamond size_4=3 x_4="SC_HR${i}" y_4="SC_HR$[${i}+1]" icmd_4='select "T<0"' leglabel_4="ETG-hosted, bright" \
	omode=out ofmt=png out=XMMplots/HRplots/HRmorphPlot${i}.png \
	xmin=-1 xmax=1 ymin=-1 ymax=1 legend=true legpos="0.1,0.95"
rm XMM_completeULXs
rm XMM_completeBrightULXs
rm XMM_complete38modified
rm XMM_complete38modifiedtolower
rm XMM_NuclearContaminants
rm XMM_SNcontaminants
rm XMM_StellarContaminants
done
#Now, do individual Luminosity-HR plots.
for i in `seq 1 4` ; do
stilts tpipe \
	in=XMM_nonNuclear_Sources \
	out=XMM_completeULXs ofmt=fits-basic omode=out \
	cmd='select ULX_QUALITY==True' \
	cmd='select ss39==True' \
	cmd="select SC_HR${i}_ERR<0.2"
stilts tpipe \
	in=XMM_nonNuclear_Sources \
	out=XMM_completeBrightULXs ofmt=fits-basic \
	cmd='select brightULX_QUALITY==True' \
	cmd='select ss5x40==True' \
	cmd="select SC_HR${i}_ERR<0.2"
stilts tpipe \
	in=XMM_nonNuclear_Sources \
	out=XMM_complete38modified ofmt=fits-basic omode=out \
	cmd='select ss38==True' \
	cmd="select SC_HR${i}_ERR<0.2&&SC_Luminosity>exp10(38)&&SC_Luminosity<exp10(39)"
stilts tpipe \
	in=XMM_nonNuclear_Sources \
	out=XMM_complete38modifiedtolower ofmt=fits-basic omode=out \
	cmd='select ss38==True' \
	cmd="select SC_HR${i}_ERR<0.2&&SC_Luminosity<exp10(38)"
stilts tpipe \
	in=XMM_nonNuclear_Sources \
	out=XMM_NuclearContaminants ofmt=fits-basic \
	cmd='addcol OBJ_TYPE_2 toString(98.)' \
	cmd='replaceval "98" "AGN" OBJ_TYPE_2' \
	cmd='addcol OBJ_TYPE_3 toString(99.)' \
	cmd='replaceval "99" "QSO" OBJ_TYPE_3' \
	cmd='addcol OBJ_TYPE_4 toString(98.)' \
	cmd='replaceval "98" "AGN_Candidate" OBJ_TYPE_4' \
	cmd='addcol OBJ_TYPE_5 toString(99.)' \
	cmd='replaceval "99" "QSO_Candidate" OBJ_TYPE_5' \
	cmd="select OBJ_TYPE==OBJ_TYPE_2||OBJ_TYPE==OBJ_TYPE_3||OBJ_TYPE==OBJ_TYPE_4||OBJ_TYPE==OBJ_TYPE_5&&SC_HR${i}_ERR<0.2"
stilts tpipe \
	in=XMM_nonNuclear_Sources \
	out=XMM_SNcontaminants ofmt=fits-basic \
	cmd='addcol OBJ_TYPE_2 toString(97.)' \
	cmd='replaceval "97" "SN" OBJ_TYPE_2' \
	cmd="select OBJ_TYPE==OBJ_TYPE_2&&SC_HR${i}_ERR<0.2"
stilts tpipe \
	in=XMM_nonNuclear_Sources \
	out=XMM_StellarContaminants ofmt=fits-basic \
	cmd='addcol OBJ_TYPE_2 toString(96.)' \
	cmd='replaceval "96" "Star" OBJ_TYPE_2' \
	cmd='addcol OBJ_TYPE_3 toString(95.)' \
	cmd='replaceval "95" "GaiaDR2_Obj" OBJ_TYPE_3' \
	cmd="select OBJ_TYPE==OBJ_TYPE_2||OBJ_TYPE==OBJ_TYPE_3&&SC_HR${i}_ERR<0.2"
#Now plot, you bastard.
#Start with the L-HR population plots.
stilts plot2plane \
	xlabel="HR${i}" \
	layer_99=contour in_99=XMM_complete38modifiedtolower color_99=yellow x_99="SC_HR${i}" y_99="log10(SC_luminosity)" \
	nlevel_99=30 smooth_99=100 \
	layer_0=contour in_0=XMM_complete38modified color_0=green x_0="SC_HR${i}" y_0="log10(SC_luminosity)" \
	nlevel_0=5 smooth_0=100 \
	layer_1=mark in_1=XMM_completeULXs color_1=blue size_1=1 x_1="SC_HR${i}" y_1="log10(SC_luminosity)" \
	layer_2=mark in_2=XMM_completeBrightULXs color_2=red shape_2=filled_diamond size_2=3 x_2="SC_HR${i}" y_2="log10(SC_luminosity)" \
	omode=out ofmt=png out=XMMplots/L_HRplots/L_HRpopPlot${i}.png \
	xmin=-1 xmax=1 ymin=37 ymax=42 ylabel="log10( [Lx] / [erg/s] )" legend=false
#Go with the L-HR contaminants plots.
stilts plot2plane \
	xlabel="HR${i}" \
	layer_i=contour in_i=XMM_NuclearContaminants color_i=green x_i="SC_HR${i}" y_i="log10(SC_luminosity)" \
	nlevel_i=5 smooth_i=100 \
	layer_2i=contour in_2i=XMM_SNcontaminants color_2i=grey x_2i="SC_HR${i}" y_2i="log10(SC_luminosity)" \
	nlevel_2i=5 smooth_2i=100 \
	layer_3i=contour in_3i=XMM_StellarContaminants color_3i=orange x_3i="SC_HR${i}" y_3i="log10(SC_luminosity)" \
	nlevel_3i=5 smooth_3i=100 \
	layer_1=mark in_1=XMM_completeULXs color_1=blue size_1=1 x_1="SC_HR${i}" y_1="log10(SC_luminosity)" \
	layer_2=mark in_2=XMM_completeBrightULXs color_2=red shape_2=filled_diamond size_2=3 x_2="SC_HR${i}" y_2="log10(SC_luminosity)" \
	omode=out ofmt=png out=XMMplots/L_HRplots/L_HRcontPlot${i}.png \
	xmin=-1 xmax=1 ymin=37 ymax=42 ylabel="log10( [Lx] / [erg/s] )" legend=false
#Go with the L-HR morphology plots.
stilts plot2plane \
	xlabel="HR${i}" \
	layer_1i=contour in_1i=XMM_completeULXs color_1i=cyan x_1i="SC_HR${i}" y_1i="log10(SC_luminosity)" icmd_1i='select "T>=0"' nlevel_1i=5 smooth_1i=125 leglabel_1i="LTG-hosted" \
	layer_3i=contour in_3i=XMM_completeULXs color_3i=pink x_3i="SC_HR${i}" y_3i="log10(SC_luminosity)" icmd_3i='select "T<0"' nlevel_3i=5 smooth_3i=125 leglabel_3i="ETG-hosted" \
	layer_2i=contour in_2i=XMM_completeBrightULXs color_2i=gray x_2i="SC_HR${i}" y_2i="log10(SC_luminosity)" icmd_2i='select "T>=0"' nlevel_2i=5 smooth_2i=125 leglabel_2i="LTG-hosted, bright" \
	layer_4i=contour in_4i=XMM_completeBrightULXs color_4i=yellow x_4i="SC_HR${i}" y_4i="log10(SC_luminosity)" icmd_4i='select "T<0"' nlevel_4i=5 smooth_4i=125 leglabel_4i="ETG-hosted, bright"\
	layer_1=mark in_1=XMM_completeULXs color_1=blue size_1=1 x_1="SC_HR${i}" y_1="log10(SC_luminosity)" icmd_1='select "T>=0"' leglabel_1=null \
	layer_3=mark in_3=XMM_completeULXs color_3=red size_3=1 x_3="SC_HR${i}" y_3="log10(SC_luminosity)" icmd_3='select "T<0"' \
	layer_2=mark in_2=XMM_completeBrightULXs shape_2=filled_diamond color_2=cyan size_2=3 x_2="SC_HR${i}" y_2="log10(SC_luminosity)" icmd_2='select "T>=0"' \
	layer_4=mark in_4=XMM_completeBrightULXs shape_4=filled_diamond color_4=orange size_4=3 x_4="SC_HR${i}" y_4="log10(SC_luminosity)" icmd_4='select "T<0"' \
	omode=out ofmt=png out=XMMplots/L_HRplots/L_HRmorphPlot${i}.png \
	xmin=-1 xmax=1 ymin=37 ymax=42 ylabel="log10( [Lx] / [erg/s] )" legend=false
rm XMM_completeULXs
rm XMM_completeBrightULXs
rm XMM_complete38modified
rm XMM_complete38modifiedtolower
rm XMM_NuclearContaminants
rm XMM_SNcontaminants
rm XMM_StellarContaminants
done
#Now we do the radial plots, i.e, plotting the clean sources against the fraction of radius from the center of the galaxy.
#fi
stilts tpipe \
	in=XMM_nonNuclear_Sources \
	out=XMM_completeULXs ofmt=fits-basic omode=out \
	cmd='select ULX_QUALITY==True' \
	cmd='select ss39==True'
stilts tpipe \
	in=XMM_nonNuclear_Sources \
	out=XMM_completeBrightULXs ofmt=fits-basic omode=out \
	cmd='select brightULX_QUALITY==True' \
	cmd='select ss5x40==True'
#Show normal ULXs.
stilts plot2plane \
	layer_2=histogram in_2=XMM_completeULXs x_2="SC_CenterDist/(R1*60)" \
	icmd_2='select T>=0' binsize_2=0.1 color_2=blue leglabel_2="Spiral and irregular" \
	layer_1=histogram in_1=XMM_completeULXs x_1="SC_CenterDist/(R1*60)" \
	icmd_1='select T<0' binsize_1=0.1 color_1=red leglabel_1="Elliptical" \
	omode=out ofmt=png out=XMMplots/CDplots/CDmorph.png \
	xlabel="SC_CenterDist/R1" legend=true legpos="0.9,0.95"
#Show bright ULXs.
stilts plot2plane \
	layer_2=histogram in_2=XMM_completeBrightULXs x_2="SC_CenterDist/(R1*60)" \
	icmd_2='select T>=0' binsize_2=0.1 color_2=blue leglabel_2="Spiral and irregular" \
	layer_1=histogram in_1=XMM_completeBrightULXs x_1="SC_CenterDist/(R1*60)" \
	icmd_1='select T<0' binsize_1=0.1 color_1=red leglabel_1="Elliptical" \
	omode=out ofmt=png out=XMMplots/CDplots/CDmorphBright.png \
	xlabel="SC_CenterDist/R1" legend=true legpos="0.9,0.95"
#Do it by morphology.
stilts plot2plane \
	layer_2=histogram in_2=XMM_completeULXs x_2="T" \
	binsize_2=1 color_2=blue leglabel_2="cULXss" \
	layer_1=histogram in_1=XMM_completeBrightULXs x_1="T" \
	binsize_1=1 color_1=red leglabel_1="cbULXss" \
	omode=out ofmt=png out=XMMplots/CDplots/DistMorph.png \
	xlabel="Hubble Type" ylabel="" legend=true legpos="0.1,0.95"
rm XMM_completeULXs
rm XMM_completeBrightULXs
rm XMM_nonNuclear_Sources



