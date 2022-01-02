import numpy as np
import astropy.io.fits as fits
# === This function reads the columns from a file. ======================
# --- Arguments. --------------------------------------------------------
# --- nom_fitxer: the name of the file (string).
# --- marcador: the separator between the elements of the lines (string).
# --- columna: the column you want to read
def munta_columnes(nom_fitxer,marcador,columna):
  file=open(nom_fitxer,'r')
  column=[]
  file.readline()
  for line in file:
    line=line.split(marcador)    
    column.append(line[columna])
  file.close
  return column
# =======================================================================
# --- #
# ===  This function averages quantities from the y column that have the
# same label in the x column ============================================
def extremes_columns(x_column,y_column,extra):
  reduced_x=[]
  reduced_y=[]
  reduced_extra=[]
  lower_y=[]
  higher_y=[]
  lower_extra=[]
  higher_extra=[]
  i=0
  for element in x_column:
    if i==0:
      reduced_x.append(int(element))
      reduced_y.append(float(0))
      reduced_extra.append(float(0))
      lower_y.append(y_column[i]/10e10)
      higher_y.append(y_column[i]/10e10)
      lower_extra.append(extra[i])
      higher_extra.append(extra[i])
      j=0
    else:  
      if element in reduced_x:
        ind=reduced_x.index(element)
        if y_column[i]/10e10>higher_y[ind]:
          higher_y[ind]=y_column[i]/10e10
          higher_extra[ind]=extra[i]       
        elif y_column[i]/10e10<lower_y[ind]:
          lower_y[ind]=y_column[i]/10e10
          higher_extra[ind]=extra[i]  
        reduced_y[ind]=100*(higher_y[ind]-lower_y[ind])/lower_y[ind]
        reduced_extra[ind]=100*(higher_extra[ind]-lower_extra[ind])/lower_extra[ind]
      else:
        reduced_x.append(element)
        reduced_y.append(float(0))
        reduced_extra.append(float(0))
        lower_y.append(y_column[i]/10e10)
        higher_y.append(y_column[i]/10e10)
        lower_extra.append(extra[i])
        higher_extra.append(extra[i])
      if int(i/500)==i/500:
        print(i)
    i=i+1
  return (reduced_x,lower_y,higher_y,reduced_y,lower_extra,higher_extra,reduced_extra)
# ========================================================================
# --- #
# --- Read the fits file containing the ULX candidates. Make a column with SRCID, and another with Luminosity.
hFITS=fits.open('XMM_ULXcandidateDetectionsVariableClean')
dFITS=hFITS[1].data
SRCID=[]
Luminosity=[]
HR_1=[]
HR_2=[]
HR_3=[]
HR_4=[]
for row in dFITS:
  SRCID.append(int(row[1]))
  Luminosity.append(float(row[301]))
  HR_1.append(float(row[181]))
  HR_2.append(float(row[183]))
  HR_3.append(float(row[185]))
  HR_4.append(float(row[187]))
# --- Compute the total variability.
(names,minimum,maximum,difference,minimum1,maximum1,difference1)=extremes_columns(SRCID,Luminosity,HR_1)       
(names,minimum,maximum,difference,minimum2,maximum2,difference2)=extremes_columns(SRCID,Luminosity,HR_2)
(names,minimum,maximum,difference,minimum3,maximum3,difference3)=extremes_columns(SRCID,Luminosity,HR_3)
(names,minimum,maximum,difference,minimum4,maximum4,difference4)=extremes_columns(SRCID,Luminosity,HR_4)
# --- Write a fit table with the two new columns.
print('Writing .fits table.')
newColumn1=fits.Column(name='ID', array=names, format='20A')
newColumn2=fits.Column(name='LowerLuminosity', array=minimum, format='E')
newColumn3=fits.Column(name='MaxLuminosity', array=maximum, format='E')
newColumn4=fits.Column(name='Variability', array=difference, format='E')
newColumn5=fits.Column(name='EP_HR1_min', array=minimum1, format='E')
newColumn6=fits.Column(name='EP_HR1_max', array=maximum1, format='E')
newColumn7=fits.Column(name='EP_HR1_var', array=difference1, format='E')
newColumn8=fits.Column(name='EP_HR2_min', array=minimum2, format='E')
newColumn9=fits.Column(name='EP_HR2_max', array=maximum2, format='E')
newColumn10=fits.Column(name='EP_HR2_var', array=difference2, format='E')
newColumn11=fits.Column(name='EP_HR3_min', array=minimum3, format='E')
newColumn12=fits.Column(name='EP_HR3_max', array=maximum3, format='E')
newColumn13=fits.Column(name='EP_HR3_var', array=difference3, format='E')
newColumn14=fits.Column(name='EP_HR4_min', array=minimum4, format='E')
newColumn15=fits.Column(name='EP_HR4_max', array=maximum4, format='E')
newColumn16=fits.Column(name='EP_HR4_var', array=difference4, format='E')
newColumns=fits.ColDefs([newColumn1,newColumn2,newColumn3,newColumn4,newColumn5,newColumn6,newColumn7,newColumn8,newColumn9,newColumn10,newColumn11,newColumn12,newColumn13,newColumn14,newColumn15,newColumn16])      
table=fits.BinTableHDU.from_columns(newColumns)
print('Saving table.')
table.writeto('Variability.fits')
print('Table saved.')
print('Buh bye!')

