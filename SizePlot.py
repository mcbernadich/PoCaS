import astropy.io.fits as fits
import numpy as np
import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt
import random
h=fits.open("/home/mbernardich/Desktop/Catalogues/HECATE/RC3_HECATE_myDR9")
data=h[1].data
R1RC3=[]
R2RC3=[]
R1HECATE=[]
R2HECATE=[]
for row in data:
  R1RC3.append(float(row[1]))
  R2RC3.append(float(row[2]))
  R1HECATE.append(float(row[3]))
  R2HECATE.append(float(row[4]))
R1HECATE=np.array(R1HECATE)
R2HECATE=np.array(R2HECATE)
R1RC3=np.array(R1RC3)
R2RC3=np.array(R2RC3)
#R2RC3=R2RC3[R1HECATE > 2.]
#R1RC3=R1RC3[R1HECATE > 2.]
#R2HECATE=R2HECATE[R1HECATE > 2.]
#R1HECATE=R1HECATE[R1HECATE > 2.]
print("The average fraction between major radiuses is:")
a=np.array(R1HECATE)/np.array(R1RC3)
print(np.mean(a[~np.isnan(a)]))
print("The median fraction between major radiuses is:")
print(np.median(a[~np.isnan(a)]))
plt.plot(R1RC3,R1HECATE,"o",markersize=2)
plt.plot(R1HECATE,R1HECATE,"-",label="y=x")
plt.ylabel("major radius HECATE (arcsec)")
plt.xlabel("major radius RC3 (arcsec)")
plt.xlim(0,4)
plt.ylim(0,4)
plt.legend()
plt.show()
print("The average fraction between minor radiuses is:")
a=np.array(R2HECATE)/np.array(R2RC3)
print(np.mean(a[~np.isnan(a)]))
print("The median fraction between minor radiuses is:")
print(np.median(a[~np.isnan(a)]))
plt.plot(R2RC3,R2HECATE,"o",markersize=2)
plt.plot(R2HECATE,R2HECATE,"-",label="y=x")
plt.ylabel("minor radius HECATE (arcsec)")
plt.xlabel("minor radius RC3 (arcsec)")
plt.xlim(0,4)
plt.ylim(0,4)
plt.legend()
plt.show()
a=(R1HECATE-R1RC3)
b=(R2HECATE-R2RC3)
plt.plot(b,a,"o",markersize=2)
plt.xlabel("R2HECATE-R2RC3(arcmin)")
plt.ylabel("R1HECATE-R1RC3(arcmin)")
plt.grid(True)
plt.axhline(0, color='grey')
plt.axvline(0, color='grey')
plt.show()
a=R1HECATE/R1RC3
b=R2HECATE/R2RC3
plt.plot(b,a,"o",markersize=2)
plt.xlabel("R2HECATE/R2RC3")
plt.ylabel("R1HECATE/R1RC3")
plt.grid(True)
plt.axhline(1, color='grey')
plt.axvline(1, color='grey')
plt.xscale("log")
plt.yscale("log")
plt.show()







