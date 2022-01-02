import sys
import numpy as np
import astropy.io.fits as fits
# --------------------------------------------------------
# - Arg1: fits table
# - Arg2: column index
# - Arg3: desired file name
# - Out: file with elements of column as lines
# --------------------------------------------------------
hFITS=fits.open(sys.argv[1])
dFITS=hFITS[1].data
file=open(sys.argv[3],"w")
a=[]
for row in dFITS:
  if row[int(sys.argv[2])] not in a:
    file.write(str(row[int(sys.argv[2])])+"\n")
    a.append(row[int(sys.argv[2])])
# ESO ES TODO AMIGOS AHAJAHJAJAJAJHAJAHAHAJHAJAAHAHJAHAJ mateu-me siusplau.
