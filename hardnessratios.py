import numpy as np
import astropy.io.fits as fits
# === This function reads the columns from a file. ======================
# --- Arguments. --------------------------------------------------------
# --- nom_fitxer: the name of the file (string).
# --- marcador: the separator between the elements of the lines (string).
# --- columna: integer, index of the column to be read
def munta_columnes(nom_fitxer,marcador,columna):
  file=open(nom_fitxer,'r')
  column=[]
  for line in file:
    line=line.split(marcador)
    print(line[columna])
    column.append(float(line[columna]))
  file.close
  return column
# =======================================================================
# --- #
# ===  This function calculates the ratio between two columns ====================================
def ratio_columns(x_column,y_column):
  x=np.array(x_column)
  y=np.array(y_column)
  return (y-x)/(y+x)
# ========================================================================
# --- #
# --- Read the columns from the file.
print('Reading columns from file.')
absorption=munta_columnes("hardness_ratio_models",",",0)
photonIndex=munta_columnes("hardness_ratio_models",",",1)
photonRate1thin=munta_columnes("hardness_ratio_models",",",2)
photonRate2thin=munta_columnes("hardness_ratio_models",",",3)
photonRate3thin=munta_columnes("hardness_ratio_models",",",4)
photonRate4thin=munta_columnes("hardness_ratio_models",",",5)
photonRate1thick=munta_columnes("hardness_ratio_models",",",10)
photonRate2thick=munta_columnes("hardness_ratio_models",",",11)
photonRate3thick=munta_columnes("hardness_ratio_models",",",12)
photonRate4thick=munta_columnes("hardness_ratio_models",",",13)
# --- Compute the hardness ratios
print('Computing hardness ratios.')
ratio1thin=ratio_columns(photonRate1thin,photonRate2thin)
ratio2thin=ratio_columns(photonRate2thin,photonRate3thin)
ratio3thin=ratio_columns(photonRate3thin,photonRate4thin)
ratio1thick=ratio_columns(photonRate1thick,photonRate2thick)
ratio2thick=ratio_columns(photonRate2thick,photonRate3thick)
ratio3thick=ratio_columns(photonRate3thick,photonRate4thick)
# --- Write a fit table with the two new columns.
print('Writing .fits table.')
newColumn1=fits.Column(name='Phot.Abs.', array=absorption, format='E')
newColumn2=fits.Column(name='Phot.Index.alpha', array=photonIndex, format='E')
newColumn3=fits.Column(name='Hard.Rat.1.tn', array=ratio1thin, format='E')
newColumn4=fits.Column(name='Hard.Rat.2.tn', array=ratio2thin, format='E')
newColumn5=fits.Column(name='Hard.Rat.3.tn', array=ratio3thin, format='E')
newColumn6=fits.Column(name='Hard.Rat.1.tk', array=ratio1thick, format='E')
newColumn7=fits.Column(name='Hard.Rat.2.tk', array=ratio2thick, format='E')
newColumn8=fits.Column(name='Hard.Rat.3.tk', array=ratio3thick, format='E')
newColumns=fits.ColDefs([newColumn1,newColumn2,newColumn3,newColumn4,newColumn5,newColumn6,newColumn7,newColumn8])
table=fits.BinTableHDU.from_columns(newColumns)
print('Saving table.')
table.writeto('hardness_ratios.fits')
print('Table saved.')
print('Buh bye!')




