import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt
import numpy as np
# === This script plots the distributions of the amount of matches. ===== |
# --- #
# === This function reads the columns from a file.
# --- Arguments:
# ---- nom_fitxer: the name of the file (string).
# ---- marcador: the separator between the elements of the lines (string).
def munta_columnes(nom_fitxer,marcador):
  file=open(nom_fitxer,'r')
  cumulativeBest=[]
  cumulativeAll=[]
  differentialBest=[]
  differentialAll=[]
  for line in file:
    line=line.split(marcador)    
    cumulativeBest.append(int(line[0]))
    cumulativeAll.append(int(line[1]))
  file.close()
  differentialBest.append(cumulativeBest[0])
  differentialAll.append(cumulativeAll[0])
  i=1
  for element in cumulativeBest[1:len(cumulativeBest)]:
    differentialBest.append(cumulativeBest[i]-cumulativeBest[i-1])
    differentialAll.append(cumulativeAll[i]-cumulativeAll[i-1])
    i=i+1
  return cumulativeBest,cumulativeAll,differentialBest,differentialAll
# --- #
# --- Read the columns from the file.
(cumBest,cumAll,diffBest,diffAll)=munta_columnes("cumulative.txt",",")
# --- Initialize the abcissa axis.
abcs=np.arange(len(cumBest))
# --- Plot the distribution.
plt.plot(abcs,cumBest,"b",label="Cumulative Best")
plt.plot(abcs,cumAll,"r",label="Cumulative All")
plt.plot(abcs,diffBest,"b--",label="Differential Best")
plt.plot(abcs,diffAll,"r--",label="Differentail All")
plt.xlabel("search radius (arcsec)")
#plt.xscale("log")
plt.ylabel("# matches")
plt.legend()
plt.show()
# --- Wish the best farewell to the user.
print("Done, buh bye!")
# --- DONE.