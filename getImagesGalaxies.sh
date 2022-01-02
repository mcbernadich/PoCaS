#!/bin/bash
#Initialize the variables.
#---------------------------------------------------------------
name="NGC0253"
RA_HECATE=11.88797
DEC_HECATE=-25.2884
RA_NED=11.888
DEC_NED=-25.28822
RA_RC3=11.88792
DEC_RC3=-25.28833
size=5
directory="/home/mbernardich/Desktop/Images/NGC0253"
#---------------------------------------------------------------
#Create the directory where they have to go.
mkdir $directory
#Loop over the colors and get the fit files.
colors=( "b" "g" "r" )
for color in ${colors[@]} ; do
    python3 imageV.py $name $RA_HECATE $DEC_HECATE $color $directory
done
#Write the ascii file for fc_tool.py
python3 writeObjects.py $name $RA_HECATE $DEC_HECATE $RA_NED $DEC_NED $RA_RC3 $DEC_RC3
imageIn="${directory}/${name}g.fits"
imageOut="${directory}/${name}"
#Produce the astrometric chart.
python3 fc_tool.py $imageIn "objects.ascii" $size $imageOut
rm objects.ascii
