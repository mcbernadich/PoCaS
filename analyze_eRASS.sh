#!/bin/bash
#This script will make all of the necessary plots.
#This loop runs over all the hardness ratios.
for i in `seq 1 1` ; do
#First, build the list of objects I want to plot.
#First, build the list of objects I want to plot.
stilts tmatch2 \
	in1=eRASS_ULXcandidateDetections \
	in2=eRASS_complete39 \
	out=eRASS_completeULXs ofmt=fits-basic \
	find=best fixcols=dups suffix1=null suffix2=_dummy join=1and2 matcher=exact \
	values1='DETUID' values2='DETUID' \
	ocmd="select HR_${i}_ERR<0.4&&HR_$[${i}+1]_ERR<0.4"
stilts tmatch2 \
	in1=eRASS_BrightDetections \
	in2=eRASS_complete40 \
	out=eRASS_completeBrightULXs ofmt=fits-basic \
	find=best fixcols=dups suffix1=null suffix2=_dummy join=1and2 matcher=exact \
	values1='DETUID' values2='DETUID' \
	ocmd="select HR_${i}_ERR<0.4&&HR_$[${i}+1]_ERR<0.4"
stilts tpipe \
	in=eRASS_complete38 \
	out=eRASS_complete38modified ofmt=fits-basic \
	cmd="select HR_${i}_ERR<0.4&&HR_$[${i}+1]_ERR<0.4&&Luminosity>exp10(38)&&Luminosity<exp10(39)"
stilts tpipe \
	in=eRASS_complete38 \
	out=eRASS_complete38modifiedtolower ofmt=fits-basic \
	cmd="select HR_${i}_ERR<0.4&&Luminosity<exp10(38)"
stilts tpipe \
	in=eRASS_nonNuclear_Catalogue \
	out=eRASS_NuclearContaminants ofmt=fits-basic \
	cmd='addcol OBJ_TYPE_2 toString(98.)' \
	cmd='replaceval "98" "AGN" OBJ_TYPE_2' \
	cmd='addcol OBJ_TYPE_3 toString(99.)' \
	cmd='replaceval "99" "QSO" OBJ_TYPE_3' \
	cmd='select OBJ_TYPE==OBJ_TYPE_2||OBJ_TYPE==OBJ_TYPE_3'
stilts tpipe \
	in=eRASS_nonNuclear_Catalogue \
	out=eRASS_SNcontaminants ofmt=fits-basic \
	cmd='addcol OBJ_TYPE_2 toString(97.)' \
	cmd='replaceval "97" "SN" OBJ_TYPE_2' \
	cmd='select OBJ_TYPE==OBJ_TYPE_2'
stilts tpipe \
	in=eRASS_nonNuclear_Catalogue \
	out=eRASS_StellarContaminants ofmt=fits-basic \
	cmd='addcol OBJ_TYPE_2 toString(96.)' \
	cmd='replaceval "96" "Star" OBJ_TYPE_2' \
	cmd='select OBJ_TYPE==OBJ_TYPE_2'
#Now plot, you bastard.
#First go with the HR diagram plots.
stilts plot2plane \
	layer_99=contour in_99=eRASS_complete38modifiedtolower color_99=yellow x_99="HR_${i}" y_99="HR_$[${i}+1]" \
	nlevel_99=30 smooth_99=100 \
	layer_0=contour in_0=eRASS_complete38modified color_0=green x_0="HR_${i}" y_0="HR_$[${i}+1]" \
	nlevel_0=5 smooth_0=100 \
	layer_1=mark in_1=eRASS_completeULXs color_1=blue size_1=1 x_1="HR_${i}" y_1="HR_$[${i}+1]" \
	layer_2=mark in_2=eRASS_completeBrightULXs color_2=red shape_2=filled_diamond size_2=3 x_2="HR_${i}" y_2="HR_$[${i}+1]" \
	omode=out ofmt=png out=eRASSplots/HRplots/HRpopPlot${i}.png \
	xmin=-1 xmax=1 ymin=-1 ymax=1 legend=false
#Then with the HR contaminants plots.
stilts plot2plane \
	layer_i=contour in_i=eRASS_NuclearContaminants color_i=green x_i="HR_${i}" y_i="HR_$[${i}+1]" \
	nlevel_i=5 smooth_i=100 \
	layer_2i=contour in_2i=eRASS_SNcontaminants color_2i=grey x_2i="HR_${i}" y_2i="HR_$[${i}+1]" \
	nlevel_2i=5 smooth_2i=100 \
	layer_3i=contour in_3i=eRASS_StellarContaminants color_3i=orange x_3i="HR_${i}" y_3i="HR_$[${i}+1]" \
	nlevel_3i=5 smooth_3i=100 \
	layer_1=mark in_1=eRASS_completeULXs color_1=blue size_1=1 x_1="HR_${i}" y_1="HR_$[${i}+1]" \
	layer_2=mark in_2=eRASS_completeBrightULXs color_2=red shape_2=filled_diamond size_2=3 x_2="HR_${i}" y_2="HR_$[${i}+1]" \
	omode=out ofmt=png out=eRASSplots/HRplots/HRcontPlot${i}.png \
	xmin=-1 xmax=1 ymin=-1 ymax=1 legend=false
#Then with the HR morphology plots.
stilts plot2plane \
	layer_1=mark in_1=eRASS_completeULXs color_1=blue size_1=1 x_1="HR_${i}" y_1="HR_$[${i}+1]" icmd_1='select "T>=0"' \
	layer_3=mark in_3=eRASS_completeULXs color_3=red size_3=1 x_3="HR_${i}" y_3="HR_$[${i}+1]" icmd_3='select "T<0"' \
	layer_2=mark in_2=eRASS_completeBrightULXs color_2=cyan shape_2=filled_diamond size_2=3 x_2="HR_${i}" y_2="HR_$[${i}+1]" icmd_2='select "T>=0"' \
	layer_4=mark in_4=eRASS_completeBrightULXs color_4=orange shape_4=filled_diamond size_4=3 x_4="HR_${i}" y_4="HR_$[${i}+1]" icmd_4='select "T<0"' \
	omode=out ofmt=png out=eRASSplots/HRplots/HRmorphPlot${i}.png \
	xmin=-1 xmax=1 ymin=-1 ymax=1 legend=false
rm eRASS_completeULXs
rm eRASS_completeBrightULXs
rm eRASS_complete38modified
rm eRASS_complete38modifiedtolower
rm eRASS_NuclearContaminants
rm eRASS_SNcontaminants
rm eRASS_StellarContaminants
done
#Now, do individual Luminosity-HR plots.
for i in `seq 1 2` ; do
stilts tmatch2 \
	in1=eRASS_ULXcandidateDetections \
	in2=eRASS_complete39 \
	out=eRASS_completeULXs ofmt=fits-basic \
	find=best fixcols=dups suffix1=null suffix2=_dummy join=1and2 matcher=exact \
	values1='DETUID' values2='DETUID' \
	ocmd="select HR_${i}_ERR<0.4"
stilts tmatch2 \
	in1=eRASS_BrightDetections \
	in2=eRASS_complete40 \
	out=eRASS_completeBrightULXs ofmt=fits-basic \
	find=best fixcols=dups suffix1=null suffix2=_dummy join=1and2 matcher=exact \
	values1='DETUID' values2='DETUID' \
	ocmd="select HR_${i}_ERR<0.4"
stilts tpipe \
	in=eRASS_complete38 \
	out=eRASS_complete38modified ofmt=fits-basic \
	cmd="select HR_${i}_ERR<0.4&&Luminosity>exp10(38)&&Luminosity<exp10(39)"
stilts tpipe \
	in=eRASS_complete38 \
	out=eRASS_complete38modifiedtolower ofmt=fits-basic \
	cmd="select HR_${i}_ERR<0.4&&Luminosity<exp10(38)"
stilts tpipe \
	in=eRASS_nonNuclear_Catalogue \
	out=eRASS_NuclearContaminants ofmt=fits-basic \
	cmd='addcol OBJ_TYPE_2 toString(98.)' \
	cmd='replaceval "98" "AGN" OBJ_TYPE_2' \
	cmd='addcol OBJ_TYPE_3 toString(99.)' \
	cmd='replaceval "99" "QSO" OBJ_TYPE_3' \
	cmd='select OBJ_TYPE==OBJ_TYPE_2||OBJ_TYPE==OBJ_TYPE_3'
stilts tpipe \
	in=eRASS_nonNuclear_Catalogue \
	out=eRASS_SNcontaminants ofmt=fits-basic \
	cmd='addcol OBJ_TYPE_2 toString(97.)' \
	cmd='replaceval "97" "SN" OBJ_TYPE_2' \
	cmd='select OBJ_TYPE==OBJ_TYPE_2'
stilts tpipe \
	in=eRASS_nonNuclear_Catalogue \
	out=eRASS_StellarContaminants ofmt=fits-basic \
	cmd='addcol OBJ_TYPE_2 toString(96.)' \
	cmd='replaceval "96" "Star" OBJ_TYPE_2' \
	cmd='select OBJ_TYPE==OBJ_TYPE_2'
#Now plot, you bastard.
#Start with the L-HR population plots.
stilts plot2plane \
	layer_99=contour in_99=eRASS_complete38modifiedtolower color_99=yellow x_99="HR_${i}" y_99="log10(Luminosity)" \
	nlevel_99=30 smooth_99=100 \
	layer_0=contour in_0=eRASS_complete38modified color_0=green x_0="HR_${i}" y_0="log10(Luminosity)" \
	nlevel_0=5 smooth_0=100 \
	layer_1=mark in_1=eRASS_completeULXs color_1=blue size_1=1 x_1="HR_${i}" y_1="log10(Luminosity)" \
	layer_2=mark in_2=eRASS_completeBrightULXs color_2=red shape_2=filled_diamond size_2=3 x_2="HR_${i}" y_2="log10(Luminosity)" \
	omode=out ofmt=png out=eRASSplots/L_HRplots/L_HRpopPlot${i}.png \
	xmin=-1 xmax=1 ymin=37 ymax=42 ylabel="log10( [Lerass] / [erg/s] )" legend=false
#Go with the L-HR contaminants plots.
stilts plot2plane \
	layer_i=contour in_i=eRASS_NuclearContaminants color_i=green x_i="HR_${i}" y_i="log10(Luminosity)" \
	nlevel_i=5 smooth_i=100 \
	layer_2i=contour in_2i=eRASS_SNcontaminants color_2i=grey x_2i="HR_${i}" y_2i="log10(Luminosity)" \
	nlevel_2i=5 smooth_2i=100 \
	layer_3i=contour in_3i=eRASS_StellarContaminants color_3i=orange x_3i="HR_${i}" y_3i="log10(Luminosity)" \
	nlevel_3i=5 smooth_3i=100 \
	layer_1=mark in_1=eRASS_completeULXs color_1=blue size_1=1 x_1="HR_${i}" y_1="log10(Luminosity)" \
	layer_2=mark in_2=eRASS_completeBrightULXs color_2=red shape_2=filled_diamond size_2=3 x_2="HR_${i}" y_2="log10(Luminosity)" \
	omode=out ofmt=png out=eRASSplots/L_HRplots/L_HRcontPlot${i}.png \
	xmin=-1 xmax=1 ymin=37 ymax=42 ylabel="log10( [Lerass] / [erg/s] )" legend=false
#Go with the L-HR morphology plots.
stilts plot2plane \
	layer_1=mark in_1=eRASS_completeULXs color_1=blue size_1=1 x_1="HR_${i}" y_1="log10(Luminosity)" icmd_1='select "T>=0"' \
	layer_3=mark in_3=eRASS_completeULXs color_3=red size_3=1 x_3="HR_${i}" y_3="log10(Luminosity)" icmd_3='select "T<0"' \
	layer_2=mark in_2=eRASS_completeBrightULXs shape_2=filled_diamond color_2=cyan size_2=3 x_2="HR_${i}" y_2="log10(Luminosity)" icmd_2='select "T>=0"' \
	layer_4=mark in_4=eRASS_completeBrightULXs shape_4=filled_diamond color_4=orange size_4=3 x_4="HR_${i}" y_4="log10(Luminosity)" icmd_4='select "T<0"' \
	omode=out ofmt=png out=eRASSplots/L_HRplots/L_HRmorphPlot${i}.png \
	xmin=-1 xmax=1 ymin=37 ymax=42 ylabel="log10( [Lerass] / [erg/s] )" legend=false
rm eRASS_completeULXs
rm eRASS_completeBrightULXs
rm eRASS_complete38modified
rm eRASS_complete38modifiedtolower
rm eRASS_NuclearContaminants
rm eRASS_SNcontaminants
rm eRASS_StellarContaminants
done
#Now we do the radial plots, i.e, plotting the clean sources against the fraction of radius from the center of the galaxy.
stilts tmatch2 \
	in1=eRASS_ULXcandidateDetections \
	in2=eRASS_complete39 \
	out=eRASS_completeULXs ofmt=fits-basic \
	find=best fixcols=dups suffix1=null suffix2=_dummy join=1and2 matcher=exact \
	values1='DETUID' values2='DETUID'
stilts tmatch2 \
	in1=eRASS_BrightDetections \
	in2=eRASS_complete40 \
	out=eRASS_completeBrightULXs ofmt=fits-basic \
	find=best fixcols=dups suffix1=null suffix2=_dummy join=1and2 matcher=exact \
	values1='DETUID' values2='DETUID'
#Show normal ULXs.
stilts plot2plane \
	layer_2=histogram in_2=eRASS_completeULXs x_2="CenterDist/(R1*60)" \
	icmd_2='select T>=0' binsize_2=0.1 color_2=blue leglabel_2="Spiral and irregular" \
	layer_1=histogram in_1=eRASS_completeULXs x_1="CenterDist/(R1*60)" \
	icmd_1='select T<0' binsize_1=0.1 color_1=red leglabel_1="Elliptical" \
	omode=out ofmt=png out=eRASSplots/CDplots/CDmorph.png \
	xlabel="SC_CenterDist/R1" legend=true legpos="0.9,0.95"
#Show bright ULXs.
stilts plot2plane \
	layer_2=histogram in_2=eRASS_completeBrightULXs x_2="CenterDist/(R1*60)" \
	icmd_2='select T>=0' binsize_2=0.1 color_2=blue leglabel_2="Spiral and irregular" \
	layer_1=histogram in_1=eRASS_completeBrightULXs x_1="CenterDist/(R1*60)" \
	icmd_1='select T<0' binsize_1=0.1 color_1=red leglabel_1="Elliptical" \
	omode=out ofmt=png out=eRASSplots/CDplots/CDmorphBright.png \
	xlabel="SC_CenterDist/R1" legend=true legpos="0.9,0.95"
#Do it by morphology.
stilts plot2plane \
	layer_2=histogram in_2=eRASS_completeULXs x_2="T" \
	binsize_2=1 color_2=blue leglabel_2="Complete ULX sub-sample" \
	layer_1=histogram in_1=eRASS_completeBrightULXs x_1="T" \
	binsize_1=1 color_1=red leglabel_1="Complete Bright ULX sub-sample" \
	omode=out ofmt=png out=eRASSplots/CDplots/DistMorph.png \
	xlabel="Hubble Type" legend=true legpos="0.1,0.95"

