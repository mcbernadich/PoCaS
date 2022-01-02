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
# RA DEC SRCID OBS_ID MATCH_FLAG RA_HEC DEC_HEC SC_RA SC_DEC
# - And a name for the galaxy.
# It will download X-ray images for all present observations and draw them
# with their detections. It will also download a visible image and draw all
# sources on it.
# Not thought to be used independently, but called by getSourceImages.sh
# ----------------------------------------------------------------------------
# Create directory where to store the images
directory="/home/mbernardich/Desktop/Images/miscel·lània/"
os.system("mkdir "+directory+sys.argv[4])
# Open the .fits files with source and galaxy info.
hDETECTIONS=fits.open(sys.argv[1])
dDETECTIONS=hDETECTIONS[1].data
hSOURCES=fits.open(sys.argv[2])
dSOURCES=hSOURCES[1].data
hOBS=fits.open(sys.argv[3])
dOBS=hOBS[1].data
# See how many observations do we have.
amountOBS=len(dOBS)
print("MESSAGE: there is a total of "+str(amountOBS)+" X-ray images to download.")
# Calculate the size of the image
a=[]
for element in dSOURCES:
    a.append(np.array(element[9]))
size=3*max(a)/60
#size=2
print("MESSAGE: the images will have a size of "+str(size)+" arcmin.")
# Open and write many objects.ascii files as needed.
i=0
while i<amountOBS:
    filename="objects{}.ascii".format(dOBS[i][3])
    file=open(filename,"w")
    file.write(sys.argv[4]+", OBS_ID="+str(dOBS[i][3])+"\n")
    file.write(str(dDETECTIONS[i][5])+" "+str(dDETECTIONS[i][6])+"  \n")
    # Write the necessary info into the objects.ascii file.
    print("MESSAGE: writting the X-ray object files for observation "+str(dOBS[i][3]))
    for line in dDETECTIONS:
        if line[3]==dOBS[i][3]:
            file.write(str(line[0])+" "+str(line[1])+"  \n")
    file.close()
    # Download the X-ray image
    os.system("bash imageXargument.sh "+str(dOBS[i][3]))
    # Draw the image.
    print("MESSAGE: drawing observation "+str(dOBS[i][3])+".")
    os.system("python3 fc_tool.py image"+str(dOBS[i][3])+".ftz "+filename+" "+str(size)+" "+directory+sys.argv[4]+"/"+str(dOBS[i][3]))
    # Erase the downloaded and created files.
    os.system("rm "+filename)
    os.system("rm image"+str(dOBS[i][3])+".ftz")
    i=i+1
# Write just the objests.ascii file for sources only
print("MESSAGE: writting the visible objects file for galaxy "+sys.argv[4])
filename="objects{}.ascii".format(sys.argv[4])
file=open(filename,"w")
file.write(sys.argv[4]+", visible\n")
file.write(str(dSOURCES[0][5])+" "+str(dSOURCES[0][6])+"  \n")
for line in dSOURCES:
    file.write(str(line[7])+" "+str(line[8])+"  \n")
file.close()
os.system("python3 imageV.py {} {} {} g /home/mbernardich/Desktop/Images".format(sys.argv[4],dSOURCES[0][5],dSOURCES[0][6]))
# Draw the image
print("MESSAGE: drawing galaxy "+sys.argv[4]+".")
os.system("python3 fc_tool.py "+sys.argv[4]+"g.fits "+filename+" "+str(size)+" "+directory+sys.argv[4]+"/"+sys.argv[4])
# Erase the downloaded and created file.
os.system("rm "+filename)
os.system("rm "+sys.argv[4]+"g.fits")

