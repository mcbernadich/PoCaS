#version: 1.0
#author: Jan Kurpas
#
#
#Tool to create finding charts, with objects marked.
#Start script with: 
#
#python fctool.py IMAGE OBJECTS WINDOWSIZE
#
#
#IMAGE: FITS IMAGE showing the sky
#OBJECTS: ASCII File, where the first row gives the plots title, and the following rows give the objects position and name. Write each object in one row, that shall be marked by giving RA DEC STRING
#The Image will be centered on the first object.
#WINDOWSIZE: number, giving the size of the skyarea that will be plotted in arcmin=(1/60 degree)
#FILENAME: string, telling the name of the output file.
#
#Additional options can be defined below
#
#


#Additional Options
cv = 0.99  #Set Cut for percentile
obj_sep = ' ' #Set Seperator in objectlist
#colmap = 'gray' #Set Colormap (black background, white stars: gray; white background, black stars: Greys) 
colmap = 'Greys' #Set Colormap (black background, white stars: gray; white background, black stars: Greys) 
nr_hdu = 0 # Fits File extension number, where Image is at.
axis_hms = True #Set False if axis labels should be in degree
#arcol = 'white' #Set color of compass
arcol = 'black' #Set color of compass

#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

import sys
#Janbrauchte die folgende Zeile, wofuer auch immer
# reload(sys)
# brauchen wir fue Iris' komische Symbole (Ref J Kurpas)
#sys.setdefaultencoding('utf8')
import numpy as np    
import matplotlib.pyplot as plt
from matplotlib import colors
from matplotlib.patches import Polygon
from matplotlib.collections import PatchCollection
from astropy.visualization import simple_norm 
from astropy.visualization import SqrtStretch
from astropy.visualization import PercentileInterval
from astropy.io import fits
from astropy import wcs
from astropy.nddata import Cutout2D
from astropy.coordinates import Angle

#Function calculates Angular Distance on Sky
def ang_dist(x1,x2):
    return 180*np.arccos(np.sin(x1[1]*np.pi/180)*np.sin(x2[1]*np.pi/180)+np.cos(x1[1]*np.pi/180)*np.cos(x2[1]*np.pi/180)*np.cos((x1[0]-x2[0])*np.pi/180))/np.pi

# Function calculates Percentile value
def perc(Array,lim):
    #2d Array in 1d Array umwandeln und Grenzwert fuer Percentile finden
    Lst = Array.flatten()
    Lst.sort()
    l = len(Lst)    
    n = int(round(lim*l))
    
    #Element, dass bei Grenze
    k = Lst[n]
    
    #Sicherstellen, dass Normierung durchgefuerht werden kann durch Typanpassung und durchfueren der Normierung, sowie des Ersetzens aller Werte ueber dem Grenzwert durch 1
    Array = np.asarray(Array, dtype=np.float64)
    Array = Array/k
    Array[Array>1] = 1 

    #Array zurueckgeben, sowie den Grenzwert an der Perzentile
    return Array,k

#Function checks string for bad characters
def cl_str(x):
    if '\r' in x:
        return x.replace('\r','')
    else:
        return x
            
#Control whether enough parameters are given
if len(sys.argv) >1:
    inp = sys.argv[1:]
else:
    print('Not enough arguments given.')
    exit()
if len(inp)==1 and (inp[0] == '-h' or inp[0] == '--help'):
    print('Tool to create finding charts, with objects marked.\nStart script with:\n\npython fctool.py IMAGE OBJECTS WINDOWSIZE\n\nIMAGE: FITS image showing the sky\nOBJECTS: ASCII File, where the first row gives the plots title, and the following rows give the objects position and name. Write each object in one row, that shall be marked by giving RA DEC STRING\nThe Image will be centered on the first object.\nWINDOWSIZE: number, giving the size of the skyarea that will be plotted in arcmin=(1/60 degree)\nFILENAME: string, telling the name of the output file.\n\nAdditional options can be defined in the top part of the script.')
    exit()
elif len(inp) ==3 or len(inp) ==2 or (len(inp) ==1 and (inp[0] != '-h' and inp[0] != '--help')):
    print('Not enough arguments given.')
    exit()
    # (M.C.B): I erased "len(inp) ==3". 
else:
    #Get parameters
    imlnk = inp[0]
    objfl = inp[1]
    wsz = float(inp[2])
    print('Start fctool\n')
    print('Image: '+imlnk)
    print('Objectfile: '+objfl)
    print('Image Size: '+str(wsz)+' arcmin\n')
    
    #Get Objectinformation
    info = open(objfl, 'r')
    t = info.read()
    info.close()
    t = t.split('\n')
    title = cl_str(t[0])
    obj = []
    for g in t[1:]:
        tmp = g.split(obj_sep)
        if len(g)>2:
            if (":" in tmp[0]):
                v = tmp[0].split(':')
                RA = Angle(v[0]+'h'+v[1]+'m'+v[2]+'s', unit= 'hourangle')
                DEC = Angle(tmp[1]+'d')
            else:
                RA = Angle(tmp[0]+'d')
                DEC = Angle(tmp[1]+'d')
            s = cl_str(tmp[2])
            obj.append([RA,DEC,s])

    #Get Image
    hdu = fits.open(imlnk)
    hdr = hdu[nr_hdu].header
    dat = hdu[nr_hdu].data
    w = wcs.WCS(hdr)
    
    print('')
    #Get Central Object Pixelposition:
    print('Central Object Coordinates [deg]: '+str(obj[0][0].deg)+', '+str(obj[0][1].deg))
    objpix_x,objpix_y=w.wcs_world2pix(obj[0][0].deg,obj[0][1].deg,0)
    print('objpix_x,objpix_y:',objpix_x,objpix_y)
    objcoox,obcooy = w.wcs_pix2world(objpix_x,objpix_y,0)
    
    #Round Object Pixelcoordinates to closest Integer
    print (type(objpix_x))
    xcoord = int(round(float(objpix_x),0))
    ycoord = int(round(float(objpix_y),0))
    
    #Get subpixel resol.
    spgx = objpix_x-xcoord
    spgy = objpix_y-ycoord    
    
    #print('Central Object Pixel Coordinates: '+str(objpix_x)+', '+str(objpix_y))
    
    #Initialize Image
    fig = plt.figure()
    
    #Normierung und Skalierungvornehmen
    naxisx = hdr['NAXIS1']-1
    naxisy = hdr['NAXIS2']-1
    
    #Determine Pixelsize:
    tpix_x1,ydum1 = w.wcs_pix2world(0,0,0,ra_dec_order = True)
    tpix_x2,ydum2 = w.wcs_pix2world(1,0,0,ra_dec_order = True)
    dx1 = ang_dist([tpix_x1,ydum1],[tpix_x2,ydum2])
    tpix_x1,ydum1 = w.wcs_pix2world(naxisx-1,naxisy,0,ra_dec_order = True)
    tpix_x2,ydum2 = w.wcs_pix2world(naxisx,naxisy,0,ra_dec_order = True)
    dx2 = ang_dist([tpix_x1,ydum1],[tpix_x2,ydum2])
    dx = (dx1+dx2)/2
    
    xdum1,tpix_y1 = w.wcs_pix2world(0,0,0,ra_dec_order = True)
    xdum2,tpix_y2 = w.wcs_pix2world(0,1,0,ra_dec_order = True)
    dy1 = ang_dist([xdum1,tpix_y1],[xdum2,tpix_y2])
    xdum1,tpix_y1 = w.wcs_pix2world(naxisx,naxisy-1,0,ra_dec_order = True)
    xdum2,tpix_y2 = w.wcs_pix2world(naxisx,naxisy,0,ra_dec_order = True)
    dy2 = ang_dist([xdum1,tpix_y1],[xdum2,tpix_y2])
    dy = (dy1+dy2)/2
    
    dx = dx #Pixelsize in deg
    dy = dy #Pixelsize in deg
    nxpix = int(round((wsz)/(60*dx),0))
    nypix = int(round(wsz/(60*dy),0))
    
    if nxpix%2 == 1:
        nrmwx = nxpix/2+1
    else:
        nrmwx = nxpix/2
    
    if nypix%2 == 1:
        nrmwy = nypix/2+1
    else:
        nrmwy = nypix/2
    
    gr = [0,0,0,0]  # Array mit Grenzen der Normierung
    
    #x-Achse
    su = 0
    so = 0
    if xcoord - nrmwx < 0:
        gr[0] = 0
        su = abs(xcoord - nrmwx)
    else :
        gr[0] = xcoord-nrmwx
        
    gr[1] = xcoord+ nrmwx
    if gr[1] > naxisx:
        so = gr[1]-naxisx
        gr[1] = naxisx
        gr[0] = gr[0]-so
    else:
        gr[1] = gr[1]+su
    
    #y-Achse
    su = 0
    so = 0
    if ycoord - nrmwy < 0:
        gr[2] = 0
        su = abs(ycoord - nrmwy)
    else :
        gr[2] = ycoord-nrmwy
        
    gr[3] = ycoord+ nrmwy
    if gr[3] > naxisy:
        so = gr[3]-naxisy
        gr[3] = naxisy
        gr[2] = gr[2]-so
    else:
        gr[3] = gr[3]+su
    
    #Fall, dass Bild kleiner als eingegebene doppelte Normierungsbreite nrmwx/nrmwy
    if naxisx <= 2*nrmwx:
        gr[0] = 0
        gr[1] = naxisx
    if naxisy <= 2*nrmwy:
        gr[2] = 0
        gr[3] = naxisy
        
    
    stretch = SqrtStretch()
    dat = np.asarray(dat, dtype=np.float64)
    
    #Correct for not a number values, by setting them to -100
    dat[np.isnan(dat)] = -100
    
    #Trail Cut-Out to get shape of cutout area, in order to normalize right
    cutout = Cutout2D(dat, (xcoord,ycoord), (nypix,nxpix), wcs = w)
    spx = int(cutout.shape[1])/2 #Get x shape of cutout area
    spy = int(cutout.shape[0])/2 #Get y shape of cutout area

    gr[0] = int(gr[0])
    gr[1] = int(gr[1])
    gr[2] = int(gr[2])
    gr[3] = int(gr[3])
    print ('gr[0]:gr[1],gr[2]:gr[3]:',gr[0],gr[1],gr[2],gr[3])
    a,p1 = perc(dat[gr[0]:gr[1],gr[2]:gr[3]],cv)
#    dummyshow = plt.imshow(dat[xcoord-spx:xcoord+spx,ycoord-spy:ycoord+spy], norm = simple_norm(dat[gr[0]:gr[1],gr[2]:gr[3]], stretch = 'sqrt', min_cut=0, max_cut=p1), cmap=colmap)
    plt.clf()
    dat = dat/p1
    dat[dat>1] = 1
    dat = stretch(dat)
    
    #Bereich ausschneiden
    cutout = Cutout2D(dat, (xcoord,ycoord), (nypix,nxpix), wcs = w)

    #Koordinaten hinzufuegen
    ax = plt.subplot(projection = cutout.wcs)
    
    #Quellausdehnung berechnen:
    bx = cutout.input_position_cutout[0]+spgx #Get x position of central object in cutout
    by = cutout.input_position_cutout[1]+spgy #Get y position of central object in cutout
    spx = cutout.shape[1] #Get x shape of cutout area
    spy = cutout.shape[0] #Get y shape of cutout area
    mf = 3
    #ccol = '#009ee7'
    ccol = 'green'
    d = spx/80
    if spx/80 < 1:
        d = 1
    r1 = Polygon([[bx+d,by],[bx+mf*d,by]],closed= True, edgecolor = ccol,facecolor = 'none')
    r2 = Polygon([[bx-d,by],[bx-mf*d,by]],closed= True, edgecolor = ccol,facecolor = 'none')
    r3 = Polygon([[bx,by+d],[bx,by+mf*d]],closed= True, edgecolor = ccol,facecolor = 'none')
    r4 = Polygon([[bx,by-d],[bx,by-mf*d]],closed= True, edgecolor = ccol,facecolor = 'none')
    plt.text(bx+d,bx+d,obj[0][2],color =ccol, transform=ax.transData)

    for adob in obj[1:]:
        adobjpix_x,adobjpix_y=w.wcs_world2pix(adob[0].deg,adob[1].deg,0)
        adobjpix_x = adobjpix_x
        adobjpix_y = adobjpix_y
        xdif = adobjpix_x-objpix_x
        ydif = adobjpix_y-objpix_y
        aobx = xdif+ bx
        aoby = ydif+ by
        lwd = 0.8
        col = 'red'
        daob = d
        if aobx>=0 and aoby >= 0 and aobx < spx+5 and aoby < spy+5:
            ax.add_patch(Polygon([[aobx+daob,aoby],[aobx+mf*daob,aoby]],closed= True, edgecolor = col,facecolor = 'none',ls = '-'))#, lw = wsz*lwd))
            ax.add_patch(Polygon([[aobx-daob,aoby],[aobx-mf*daob,aoby]],closed= True, edgecolor = col,facecolor = 'none',ls = '-'))#, lw = wsz*lwd))
            ax.add_patch(Polygon([[aobx,aoby-daob],[aobx,aoby-mf*daob]],closed= True, edgecolor = col,facecolor = 'none',ls = '-'))#, lw = wsz*lwd))
            ax.add_patch(Polygon([[aobx,aoby+daob],[aobx,aoby+mf*daob]],closed= True, edgecolor = col,facecolor = 'none',ls = '-'))#, lw = wsz*lwd))
            plt.text(aobx+daob,aoby+daob,adob[2],color = col, transform=ax.transData)
        print('Plot Star: '+adob[2]+', at '+str(adob[0].deg)+', '+str(adob[1].deg))

    #Koordinateneinstellungen vornehmen
    ax.add_patch(r1)
    ax.add_patch(r2)
    ax.add_patch(r3)
    ax.add_patch(r4)
    
    
    if axis_hms == True:
        ax.coords[0].set_major_formatter('hh:mm:ss')
        ax.coords[1].set_major_formatter('dd:mm:ss')
    else:
        ax.coords[0].set_major_formatter('d.ddd')
        ax.coords[1].set_major_formatter('d.ddd')
    
    ax.coords[0].set_axislabel('Right Ascension')
    ax.coords[1].set_axislabel('Declination')
    
    #Bild erstellen
    plt.imshow(cutout.data , cmap = colmap, origin = 'lower',vmin = 0, vmax = 1)
    
    #Weitere anzuzeigende Objekte Plotten
    plt.title(title)    
        
    #Koordinatensystem
    xk = int(round(spx*0.975))
    yk = int(round(spy*0.9))
    txk1 = int(round(spx*0.9))
    txk2 = int(round(spx*0.86))
    tyk1 = int(round(spy*0.925))
    tyk2 = int(round(spy*0.95))
    
    q = int(round(spx*0.05))
    plt.arrow(xk,yk,(-1)*q,0,head_width=spx/50, head_length=spx/35, fc='white', ec=arcol) #x-Richtung
    plt.text(txk1,txk2,'E',color = arcol)
    
    plt.arrow(xk,yk,0,q,head_width=spx/50, head_length=spx/35, fc='white', ec=arcol) #Y-Richtung
    plt.text(tyk1,tyk2,'N',color = arcol)
    
    #Bild speichern (format with duch file extension festgelegt)
    plt.savefig(inp[3], dpi='figure', bbox_inches = 'tight')
    plt.close()
    hdu.close()
    print('Done')
    # (M.C.B): I changed inp[3] to inp[2].
