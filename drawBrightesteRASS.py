import numpy as np
import astropy.io.fits as fits
import sys
import os
# ----------------------------------------------------------------------------
# This script takes:
# - A list of detections.
# All in fits tables with columns:
# DETUID RA_CORR DEC_CORR
# - And a name for the galaxy.
# It will download X-ray images for all present observations and draw them
# with their detections. It will also download a visible image and draw all
# sources on it.
# Not thought to be used independently, but called by myDR9brightest.sh
# ----------------------------------------------------------------------------
# Create directory where to store the images
directory="/home/mbernardich/Desktop/Images/eRASS1brightest/"
# Open the .fits files with source and galaxy info.
hDETECTIONS=fits.open(sys.argv[1])
dDETECTIONS=hDETECTIONS[1].data
# See how many observations do we have.
amountDETS=len(dDETECTIONS)
print("MESSAGE: there is a total of "+str(amountDETS)+" images to download.")
# Stablish the size of the image
i=0
size=3
while i<amountDETS:
    print("MESSAGE: writting the visible objects file for source "+str(dDETECTIONS[i][0])+".")
    filename="objects{}.ascii".format(dDETECTIONS[i][0])
    file=open(filename,"w")
    file.write("SRC="+str(dDETECTIONS[i][0])+", optical\n")
    file.write(str(dDETECTIONS[i][1])+" "+str(dDETECTIONS[i][2])+" ")
    file.close()
    os.system("python3 imageV.py {} {} {} g /home/mbernardich/Desktop/Images".format(dDETECTIONS[i][0],dDETECTIONS[i][1],dDETECTIONS[i][2]))
    # Draw the image
    print("MESSAGE: drawing visible light picture of source "+str(dDETECTIONS[i][0])+".")
    print("creating directory")
    os.system("mkdir "+directory+str(dDETECTIONS[i][0]))
    print("directory created")
    os.system("python3 fc_tool.py "+str(dDETECTIONS[i][0])+"g.fits "+filename+" "+str(size)+" "+directory+str(dDETECTIONS[i][0])+"/"+str(dDETECTIONS[i][0]))
    os.system("python3 fc_tool.py "+str(dDETECTIONS[i][0])+"g.fits "+filename+" 0.5 "+directory+str(dDETECTIONS[i][0])+"/"+str(dDETECTIONS[i][0])+"closeup")
    # Erase the downloaded and created file.
    os.system("rm "+filename)
    os.system("rm "+str(dDETECTIONS[i][0])+"g.fits")
    i=i+1
# Eso es todo amigos, Déu vos guard.

