import numpy as np
import astropy.io.fits as fits
# === This scripts counts the amount of rows in two fit tables and appends|
# them in two separate files. These two fit files are suposed to be the   |
# result of matching (correlating) two fit files with the "best" and the  |
# "all" options using topcat or stilts. ================================= |
print("Counting the amount of rows in the tables.")
# --- Open the two fit tables
matchBest=fits.open('matchBest')
BestArray=matchBest[1].data
matchAll=fits.open('matchAll')
AllArray=matchAll[1].data
# --- Write the amount of rows in the files.
file=open("cumulative.txt",'a')
file.write(str(len(BestArray))+","+str(len(AllArray))+"\n")
file.close()
# --- Done.
print("Done.")
# --- DONE.