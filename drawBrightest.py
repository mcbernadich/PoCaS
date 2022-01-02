import numpy as np
import astropy.io.fits as fits
import sys
import os
# ----------------------------------------------------------------------------
# This script takes:
# - A list of detections.
# - A list of sources.
# - A list of observations.
# All in fits tables with columns:
# RA DEC DETID SRCID OBS_ID MATCH_FLAG RA_HEC DEC_HEC SC_RA SC_DEC SC_CenterDist
# - And a name for the galaxy.
# It will download X-ray images for all present observations and draw them
# with their detections. It will also download a visible image and draw all
# sources on it.
# Not thought to be used independently, but called by myDR9brightest.sh
# ----------------------------------------------------------------------------
# Create directory where to store the images
directory="/home/mbernardich/Desktop/Images/myDR9PanSTARRS1/"
# Open the .fits files with source and galaxy info.
hDETECTIONS=fits.open(sys.argv[1])
dDETECTIONS=hDETECTIONS[1].data
hSOURCES=fits.open(sys.argv[2])
dSOURCES=hSOURCES[1].data
# See how many observations do we have.
amountDETS=len(dDETECTIONS)
amountSRC=len(dSOURCES)
print("MESSAGE: there is a total of "+str(amountDETS)+" X-ray images to download.")
# Stablish the size of the image
size=3
print("MESSAGE: the images will have a size of "+str(size)+" arcmin.")
# Open and write many objects.ascii files as needed.
i=0
while i<amountDETS:
    print("MESSAGE: writting the X-ray object file for detection "+str(dDETECTIONS[i][2])+".")
#    os.system("mkdir "+directory+str(dDETECTIONS[i][3]))
    filename="objects{}.ascii".format(dDETECTIONS[i][2])
#    file=open(filename,"w")
    # Write the necessary info into the objects.ascii file.
#    file.write("OBS="+str(dDETECTIONS[i][4])+", DET="+str(dDETECTIONS[i][2])+"\n")
#    file.write(str(dDETECTIONS[i][0])+" "+str(dDETECTIONS[i][1])+"  ")
#    file.close()
    # Download the X-ray image.
#    os.system("bash imageXargument.sh "+str(dDETECTIONS[i][4]))
    # Draw the image.
    print("MESSAGE: drawing detection "+str(dDETECTIONS[i][2])+" of source "+str(dDETECTIONS[i][3])+".")
#    os.system("python3 fc_tool.py image"+str(dDETECTIONS[i][4])+".ftz "+filename+" "+str(size)+" "+directory+str(dDETECTIONS[i][3])+"/"+str(dDETECTIONS[i][2]))
    # Erase the downloaded and created files.
#    os.system("rm "+filename)
#    os.system("rm image"+str(dDETECTIONS[i][4])+".ftz")
    i=i+1
#Now repeat for the sources instead. Draw two of them, one has to be a close-up.
i=0
size=3
while i<amountSRC:
    print("MESSAGE: writting the visible objects file for source "+str(dSOURCES[i][3])+".")
    filename="objects{}.ascii".format(dSOURCES[i][3])
    file=open(filename,"w")
    file.write("SRC="+str(dSOURCES[i][3])+", 3*SC_POSERR="+str(round(3*dSOURCES[i][11],1))+" arcsec\n")
    file.write(str(dSOURCES[i][8])+" "+str(dSOURCES[i][9])+" \n")
    file.write(str(dSOURCES[i][12])+" "+str(dSOURCES[i][13])+" ")
    file.close()
    os.system("python3 imageV.py {} {} {} g /home/mbernardich/Desktop/Images".format(dSOURCES[i][3],dSOURCES[i][8],dSOURCES[i][9]))
    # Draw the image
    print("MESSAGE: drawing visible light picture of source "+str(dSOURCES[i][3])+".")
    os.system("python3 fc_tool.py "+str(dSOURCES[i][3])+"g.fits "+filename+" "+str(size)+" "+directory+str(dSOURCES[i][3])+"/"+str(dSOURCES[i][3]))
    os.system("python3 fc_tool.py "+str(dSOURCES[i][3])+"g.fits "+filename+" 0.5 "+directory+str(dSOURCES[i][3])+"/"+str(dSOURCES[i][3])+"closeup")
    # Erase the downloaded and created file.
    os.system("rm "+filename)
    os.system("rm "+str(dSOURCES[i][3])+"g.fits")
    i=i+1
# Eso es todo amigos, Déu vos guard.

