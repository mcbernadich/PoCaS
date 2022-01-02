import os, sys
import sys
import numpy as np
import astropy.io.fits as fits
# --------------------------------------------------------
# - Arg1: fits table
# - Out: file with elements of column as lines
# --------------------------------------------------------
hFITS=fits.open(sys.argv[1])
dFITS=hFITS[1].data
file=open(sys.argv[1]+".ascii","w")
file.write(str(dFITS[0][0])+"\n")
file.write(str(dFITS[1][0])+"\n")
file.write(str(np.sqrt((np.sin(dFITS[1][0])*dFITS[0][1]*3600/np.sqrt(dFITS[11][0]))**2+(dFITS[1][1]*3600/np.sqrt(dFITS[11][0]))**2+dFITS[2][0]**2))+"\n")
index=[3,5,7,9]
for i in index:
  file.write(str(dFITS[i][0])+"\n")
  file.write(str(np.sqrt((dFITS[i][1]/np.sqrt(dFITS[11][0]))**2+dFITS[i+1][0]**2))+"\n")
file.close()
# ESO ES TODO AMIGOS AHAJAHJAJAJAJHAJAHAHAJHAJAAHAHJAHAJ mateu-me siusplau.
