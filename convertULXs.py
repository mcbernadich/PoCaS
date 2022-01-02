import numpy as np
import astropy.io.fits as fits
def munta_columnes(nom_fitxer,marcador,columna):
  file=open(nom_fitxer,'r')
  column=[]
  for line in file:
    print(line)
    line=line.split(marcador)    
    column.append(line[columna])
  file.close
  return column
names=munta_columnes("FamousULXs"," ",0)
right_ascensions=munta_columnes("FamousULXs"," ",1)
declinations=munta_columnes("FamousULXs"," ",2)
obj_type=munta_columnes("FamousULXs"," ",3)
print(names)
newColumn1=fits.Column(name='Name', array=names, format='20A')
newColumn2=fits.Column(name='RA', array=right_ascensions, format='E')
newColumn3=fits.Column(name='DEC', array=declinations, format='E')
newColumn4=fits.Column(name='type', array=obj_type, format='20A')
newColumns=fits.ColDefs([newColumn1,newColumn2,newColumn3,newColumn4])
table=fits.BinTableHDU.from_columns(newColumns)
table.writeto('FamousULXs.fits')

