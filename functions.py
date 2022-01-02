import astropy.io.ascii as ascii
import astropy.table.table as Table
from astropy.coordinates import SkyCoord
import astropy.units as u
import astropy.time
import astropy.io.fits as fits
import urllib.request
import sys
import glob
import os
import datetime
import subprocess as sub
import re
import numpy as np
from scipy.stats import kurtosis, skew
from PIL import Image

"""
Still to check:
apass_to_reg
fitz_to_fits
date_to_date_obs
fix_exptime

Still to add:
get_sdss_spectra from csh srcipt
"""

class object:
	def __init__(self, name, RA, DEC):
		self.name = name
		self.RA = RA
		self.DEC = DEC

class data:
	def __init__(self, srcfile, fformat):
		self.path = srcfile
		self.format = fformat
		if self.format == 'fits':
			data = fits.open(self.path)
			self.header = data[1].header
			self.data = data[1].data
		else:
			self.data = ascii.read(self.path)
		data.close()
		self.length = len(self.data)
		
def apass_to_reg(srcpath, destpath=''):
	"""
	Converts apass to reg file.

	Function takes:
	path to infile
	path to outfile
	"""
	if not despath:
		destpath = srcpath
	elif destpath[-1] != '/':
		destpath += '/'
	destpath += srcpath.split('/')[-1].replace(srcpath.split('.')[-1], 'reg')
	try:
		infile = open(srcpath, "r")
	except:
		print("Could not open {}".format(srcpath))
		exit()
	lines = [line for line in infile.read().split('\n')[1:] if len(line)]  #read all the input lines except the first, which is headings, and possibly the last, which might just be an empty line	
	outfile = open(destpath, "w")
	outfile.write("# Region file format: DS9 version 4.1\n")
	outfile.write('global color=green dashlist=8 3 width=1 font="helvetica 10 normal roman" select=1 highlite=1 dash=0 fixed=0 edit=1 move=1 delete=1 include=1 source=1\nfk5\n')
	for line in lines:
		ra_raw = float(line.split(',')[0])
		dec_raw = float(line.split(',')[2])
		vmag = line.split(',')[5]
		bmag = line.split(',')[7]
		try:
			bminusv = float(bmag)-float(vmag)
		except:
			bminusv = "NA"
		ra_hour = int(ra_raw/15)	  #this is ugly, but easy to understand
		ra_min  = int( (ra_raw/15-ra_hour)*60 )
		ra_sec  = "%2.1f"%( ((ra_raw/15-ra_hour)*60-ra_min)*60 )
		ra_string = "%d:%d:%s"%(ra_hour, ra_min, ra_sec)
		dec_abs = abs(dec_raw)
		dec_deg = int(dec_abs)
		dec_min = int((dec_abs-dec_deg)*60)
		dec_sec = ((dec_abs-dec_deg)*60 - dec_min)*60
		if dec_raw<0:
			dec_string="-"
		else:
			dec_string="+"
		dec_string += "%d:%d:%2.1f"%(dec_deg, dec_min, dec_sec)
		regstring = "circle({},{},3.0\") # text={{V={}, B-V={}}}\n".format(ra_string, dec_string, vmag, bminusv)
		outfile.write(regstring)
	infile.close()
	outfile.close()
	
def fitz_to_fits(srcpath, destpath=''):
	"""
	Convert .fitz files to .fits files.
	
	Function takes:
	srcpath of folder with .fitz files
	destpath where to put .fits files
	"""
	if not srcpath:
		pass
	elif srcpath[-1] != '/':
		srcpath += '/'
	if not destpath:
			destpath = srcpath
	elif destpath[-1] != '/':
		destpath += '/'
	fitzlist = glob.glob('{}*.fitz'.format(srcpath)) # returns a list of all files that match the given srcpath
	if not os.path.exists(destpath):
		os.makedirs(destpath)
	for infile in fitzlist:
		outfile = destpath+infile.split('/')[-1][:-1]
		finalfile = '{}new_{}s'.format(destpath, infile.split('/')[-1][:-1])
		cmd = "/home/schwope/bin/imcopy {} {}".format(infile, outfile)
		sub.call(cmd, shell=True)
		# open outfile
		infits = fits.open(outfile)
		# store extension image
		image = infits[1]
		# save extension image as primary header of new file
		newhdu = fits.PrimaryHDU(data=image.data, header=image.header)
		hdulist = fits.HDUList([newhdu])
		hdulist.writeto(finalfile, overwrite=True)
		infits.close()
		print('{} processed'.format(infile.split('/')[-1]))
	print('Finished')
	
def date_to_date_obs(srcpath, destpath='', fformat='fits'):
	"""
	Writes the DATE entry into the DATE-OBS entry, if the DATE-OBS entry does only contain the date but not the time of shutter open. This was the case for some data from Thinius.
	
	Function takes:
	srcpath to directory containt .fitz files
	"""
	if not srcpath:
		pass
	elif srcpath[-1] != '/':
		srcpath += '/'
	if not destpath:
		destpath = srcpath
	elif destpath[-1] != '/':
		destpath += '/'
	filelist = glob.glob(srcpath+'*.fits')
	if not os.path.exists(srcpath+'DATE-OBS_corrected/'):
		os.makedirs(srcpath+'DATE-OBS_corrected/')
	for infile in filelist:
		print('Processing '+infile.split('/')[-1]+'...', end='')
		hdulist = fits.open(infile)
		outfile = destpath+'out_'+infile.split('/')[-1]
		match = re.search(r'.*-.*-.*T.*:.*:.*\..*', hdulist[0].header['DATE-OBS'])
		if match:
			pass
		else:
			hdulist[0].header['DATE-OBS'] = (hdulist[0].header['DATE'], 'YYYY-MM-DDhh:mm:ss of observation start') 
		hdulist.writeto(outfile, overwrite=True) # writes the outputfiles
		print('...done')
	print('Finished.')

def fix_exptime(srcpath, destpath='', fformat='fits'):
	"""
	Fixes the exposure time header if given in milliseconds.
	
	Function takes:
	srcpath with FITS files
	destpath where to put the FITS files with corrected exptime header
	file format of the files
	"""
	if not srcpath:
		pass
	elif srcpath[-1] != '/':
		srcpath += '/'
	if not destpath:
			destpath = srcpath
	elif destpath[-1] != '/':
		destpath += '/'
	filelist = glob.glob('{}*.{}'.format(srcpath, fformat)) # creates list of .fit files inside the folder
	if not os.path.exists(destpath):
		os.makedirs(destpath)
	for infile in filelist:
		hdulist = fits.open(infile)
		hdulist[0].header['EXPTIME'] = (hdulist[0].header['EXPTIME']/1000.0, 'exposure time [s]') # accesses the header with EXPTIME, divides it by 1000 and changes the desrciption from [ms] to [s]
		outfile = '{}/out_{}'.format(destpath, infile.split('/')[-1])
		hdulist.writeto( outfile, overwrite=True ) # writes the outputfiles
		print('{} processed'.format(infile.split('/')[-1]))
		
	print('Finished.')

def download_crts_data(name, RA, DEC, destpath='', r=2.):
	"""
	Download CRTS data as '.csv' file.

	Function takes:
	name of object (identifier)
	RA coordinate (degrees)
	DEC coordinate (degrees)
	radius (in arcsec, default = 2")
	path to dump the data
	"""
	print('Trying to retrieve CRTS lightcurve (.csv) for object {}...'.format(name), end='')
	#sys.path.append('/net/syntron/work1/emmerich/srcipts/')
	import crts4_csv
	if not destpath:
			destpath += name.replace(' ','_')
	elif destpath[-1] != '/':
		destpath += '/'
	if destpath[-1] == '/':
		destpath += name.replace(' ','_')

	r = r/3600.*60. # must be given in arcmin, thus need to convert from arcsec to arcmin
	if not os.path.exists(destpath+'.csv'):
		try:
			return crts4_csv.get_lightcurve('{} {}'.format(RA, DEC), r, '{}.csv'.format(destpath))
			data = ascii.read(destpath+'.csv')
			if len(data) == 0:
				print('no data available.')
				os.remove(destpath+'.csv')
			else:
				print('done.')
		except timeout:
			print('timed out.')
	else:
		print('already available.')

def download_sdss_fits(plate, mjd, fiberID, destpath=''):
	"""
	Download FITS spectrum of corresponding SDSS object.
	
	Function takes:
	Plate ID
	MJD
	Fiber ID
	destination path to put the .fits file
	"""
	plate = str(plate)
	mjd = str(mjd)
	fiberID = str(fiberID)
	if not destpath:
		pass
	elif destpath[-1] != '/':
		destpath += '/'
	fits_spec = 'http://dr12.sdss.org/optical/spectrum/view/data/format=fits?plate={}&mjd={}&fiberID={}&reduction2d=v5_7_0'.format(plate, mjd, fiberID)
	#if fiber id is XXX, then file name must me ...-0XXX, if XX then ...-00XX etc.
	if len(fiberID) == 3:
		fiberID = '0'+fiberID
	elif len(fiberID) == 2:
		fiberID = '00'+fiberID
	elif len(fiberID) == 1:
		fiberID = '00'+fiberID
	if len(plate) == 3:
		plate = '0'+plate
	elif len(fiberID) == 2:
		plate = '00'+plate
	elif len(fiberID) == 1:
		plate = '00'+plate
	destpath += 'spec-{}-{}-{}.fits'.format(plate, mjd, fiberID)
	if not os.path.exists(destpath):
		try:
			urllib.request.urlretrieve(fits_spec, destpath)
			print('successful.')
		except urllib.error.HTTPError:
			print('not available.')
	else:
		print('already available.')

def download_panstarrs_fits(name, RA, DEC, destpath=''):
	"""
	Download the PanSTARRS image as '.fits' file.

	Function takes:
	name of object (identifier)
	RA coordinate (degrees)
	DEC coordinate (degrees)
	path to dump FITS
	"""
	print('Trying to retrieve PanSTARRS FITS image for object {}...'.format(name), end='')
	if not destpath:
			destpath += name.replace(' ','_')
	elif destpath[-1] != '/':
		destpath += '/'
	if destpath[-1] == '/':
		destpath += name.replace(' ','_')

	if not os.path.exists(destpath+'.fits'):
		url = 'https://ps1images.stsci.edu/cgi-bin/ps1cutouts?pos={}+{}&filter=g&filetypes=stack&auxiliary=data&size=500&output_size=0&verbose=0&autoscale=99.500000&catlist='.format(RA, DEC)
		try:
			website = urllib.request.urlopen(url)
			for line in website.readlines():
				line = str(line, 'UTF-8') 
				if 'FITS-cutout' in line:
					url = re.findall(r'<a title="Download FITS cutout" href="//(.*?)">FITS-cutout',line)
					print('downloading...', end='')
					urllib.request.urlretrieve('http://{}'.format(url[0]), '{}.fits'.format(destpath))
					print('done.')
		except urllib.error.HTTPError: 
			print('nothing found.')
	else:
		print('already available.')

def download_panstarrs_png(name, RA, DEC, destpath=''):
	"""
	Download the PanSTARRS image as '.png' file.

	Function takes:
	name of object (identifier)
	RA coordinate (degrees)
	DEC coordinate (degrees)
	path to dump the data
	"""
	print('Trying to retrieve PanSTARRS PNG image for object {}...'.format(name), end='')
	if not destpath:
			destpath += name.replace(' ','_')
	if destpath[-1] != '/':
		destpath += '/'
	if destpath[-1] == '/':
		destpath += name.replace(' ','_')
	
	if not os.path.exists(destpath+'.png'):
		url = 'https://ps1images.stsci.edu/cgi-bin/ps1cutouts?pos={}+{}&filter=g&filetypes=stack&auxiliary=data&size=500&output_size=0&verbose=0&autoscale=99.500000&catlist='.format(RA, DEC)
		try:
			website = urllib.request.urlopen(url)
			for line in website.readlines():
				line = str(line, 'UTF-8') 
				if '<td><img' in line:
					url = re.findall(r'"//(.*?)"', line)
					print('downloading...', end='')
					urllib.request.urlretrieve('http://{}'.format(url[0]), '{}.jpg'.format(destpath))
					# need to convert to png for srceening
					im = Image.open('{}.jpg'.format(destpath))
					im.save('{}.png'.format(destpath))
					os.remove('{}.jpg'.format(destpath))
					print('done.')
		except urllib.error.HTTPError: 
			print('nothing found.')
	else:
		print('already available.')

def download_ztf_data(name, RA, DEC, destpath='', r = 2.):
	"""
	Download ZTF data of desired object as '.tbl' file.
	
	Function takes:
	name of object (identifier)
	RA coordinates (degrees)
	DEC coordinates (degrees)
	radius (in arcsec, default = 2")
	path to dump the data
	"""
	print('Trying to retrieve ZTF lightcurve (.tbl) for object {}...'.format(name), end='')
	today = '-'.join(str(datetime.datetime.now()).split(',')).replace(' ', 'T')
	t = astropy.time.Time(today)
	t.format = 'mjd'
	MJD_start = 57754.0
	MJD_end = t.value
	N_obs = 3
	r /= 3600.
	if not destpath:
			destpath += name.replace(' ','_')
	elif destpath[-1] != '/':
		destpath += '/'
	if destpath[-1] == '/':
		destpath += name.replace(' ','_')
	if not os.path.exists(destpath+'.tbl'):
		cmd = """wget -q "https://irsa.ipac.caltech.edu/cgi-bin/ZTF/nph_light_curves?POS=CIRCLE+{}+{}+{}&BANDNAME=r&NOBS_MIN={}&TIME={}+{}&BAD_CATFLAGS_MASK=32768&FORMAT=ipac_table" -O {}.tbl""".format(RA, DEC, r, N_obs, MJD_start, MJD_end, destpath)
		sub.call(cmd, shell=True)
		data = ascii.read(destpath+'.tbl')
		if len(data) == 0:
			print('no data available...', end='')
			os.remove(destpath+'.tbl')
		print('done.')
	else:
		print('already available.')

def get_sdss_spectra(name, objID, spobjID, destpath=''):
	"""
	Download SDSS FITS spectra or images of the spectra from the SDSS server.
	
	Function takes:
	name of object (identifier)
	SDSS Object ID
	SDSS Spectral Object ID
	destpath to put spectra and images
	"""
	if not destpath:
		pass
	elif destpath[-1] != '/':
		destpath += '/'
	found = False
	print('Trying to download SDSS FITS spectrum (.fits) for {}...'.format(name), end='')
	try:
		url = 'https://skyserver.sdss.org/dr12/en/tools/explore/Summary.aspx?id={}'.format(objID)
		website = urllib.request.urlopen(url)
		# need to search for plate, mjd and fiberID to download spectrum
		for line in website:
			line = str(line, 'UTF-8')
			if '<span>plate</span>' in line:
				plate = re.findall(r'>([0-9]*)<', str(website.readline(), 'UTF-8'))[0]
			elif '<span>mjd</span>' in line: 
				mjd = re.findall(r'>([0-9]*)<',str(website.readline(), 'UTF-8'))[0]
			elif '<span>fiberid</span>' in line:
				fiberID = re.findall(r'>([0-9]*)<',str(website.readline(), 'UTF-8'))[0]
				download_sdss_fits(plate, mjd, fiberID, destpath)
				found = True
				break
		if not found:
			print('nothing found.')
	except urllib.error.HTTPError:
		print('nothing found.')
	print('Trying to download SDSS spectrum image (.png) for {}...'.format(name), end='')
	if not os.path.exists('{}{}.png'.format(destpath, name.replace(' ','_'))):
		try:
			#Download corresponding png of the spectrum
			urllib.request.urlretrieve('https://skyserver.sdss.org/dr12/en/get/SpecById.ashx?id={}'.format(spobjID), '{}{}.png'.format(destpath, name.replace(' ','_')))
			print('done.')
		except urllib.error.HTTPError:
			print('nothing found.')
	else:
		print('already available.')

def evaluate_data_plot_lightcurve(name, RA, DEC, srcpath, fformat, plot=False, destpath='', **columns):
	"""
	Evaluate all data in the lightcurve and plots it.

	Function takes:
	name = name of object (identifier)
	RA = RA coordinate (degrees)
	DEC = DEC coordinate (degrees)
	srcpath = path to file containing the data
	fformat = file format of the source file
	destpath = path where to save the results
	AND
	dictionary containing the column names.
	Required keywords:
	MJD
	Magnitude
	Magnitude_error
	Possible:
	ExposureID
	ObjectID
	"""
	if not srcpath:
		srcpath += '{}.{}'.format(name.replace(' ','_'), fformat)
	elif srcpath[-1] != '/':
		srcpath += '/'
	if srcpath[-1] == '/':	
		srcpath += '{}.{}'.format(name.replace(' ','_'), fformat)
	if not destpath:
		destpath = '/'.join(srcpath.split('/')[:-1])+'/'
	elif destpath[-1] != '/':
		destpath += '/'
	print('Evaluating data for {}...'.format(name), end='')
	if os.path.exists(srcpath):
		data = ascii.read(srcpath)
		mag = []
		mag_err = []
		MJD = []
		MasterID = []
		ObjectID = []
		brightness_change = []
		if len(data) == 0:
			print("no data available.")
			return
		else:
			for i in range(len(data)):
				MJD.append(int(data[i][columns['MJD']]))
				mag.append(float(data[i][columns['Magnitude']]))
				mag_err.append(float(data[i][columns['Magnitude_error']]))
				if columns['ObjectID']:
					ObjectID.append(int(data[i][columns['ObjectID']]))
				else:
					ObjectID.append(0)
				if columns['ExposureID']:	
					MasterID.append(int(data[i][columns['ObjectID']]))
				else:
					MasterID.append(0)
		# if data points in lightcurve
		standarddev = np.std(mag)
		mean = np.mean(mag)
		median = np.median(mag)
		skewness = skew(mag)
		kurt = kurtosis(mag)
		mag_sum = 0
		i = 0
		# calulate brightness changes between each data point
		while i < len(mag)-1:
			if MJD[i] == MJD[i+1]:
				pass
			else:
				brightness_change.append([(mag[i]-mag[i+1])/((MJD[i]-MJD[i+1])*24*60),((MJD[i]+MJD[i+1])/2)])
			i += 1
		amplitude = max(mag) - min(mag)
		# gaussian error propagation
		amplitude_err = np.sqrt(mag_err[mag.index(max(mag))]**2+mag_err[mag.index(min(mag))]**2)
		# plot with topcat
		magerr = []
		magerr2 = []
		for i in range(len(mag)):
				magerr.append(mag[i]+mag_err[i])
				magerr2.append(mag[i]-mag_err[i])
		X_MAX = round(1.001*max(MJD))
		X_MIN = round(0.999*min(MJD))
		Y_MAX = 1.01*max(magerr)
		Y_MIN = 0.99*min(magerr2)
		MEAN = np.mean(mag)
		MEDIAN = np.median(mag)
		brightness_change_arr = np.array(brightness_change)
		FASTEST_INCREASE = brightness_change[brightness_change_arr.argmax(axis=0)[0]][1]
		FASTEST_DECREASE = brightness_change[brightness_change_arr.argmin(axis=0)[0]][1]
		if fformat == 'tbl':
			fformat = 'ipac'
		OUTFILE =  '{}{}.png'.format(destpath, name.replace(' ','_'))
		# stilts command to make the appropriate plots with all stataistical data included
		command = "stilts plot2plane xpix=1900 ypix=680 yflip=true xlabel=MJD ylabel='magnitude [mag]' \
		xmin={} xmax={} ymin={} ymax={} title='{} ({} {})' legend=true ifmt={} in={} x={} \
		y={} shading=auto layer_1=Mark layer_2=XYError yerrhi_2=Magerr layer_3=Function \
		fexpr_3={} color_3=black leglabel_3=mean layer_4=Function fexpr_4={} color_4=black \
		dash_4=3,3 leglabel_4=median layer_5=Function axis_5=Vertical fexpr_5={} \
		color_5=light_grey dash_5=8,4 leglabel_5='fastest brightness increase (vert.)' \
		layer_6=Function axis_6=Vertical fexpr_6={} color_6=light_grey dash_6=12,3,3,3 \
		leglabel_6='fastest brightness DECrease (vert.)' layer_7=Function fexpr_7={} \
		color_7=light_grey dash_7=8,4 leglabel_7=5-/95-percentile layer_8=Function \
		fexpr_8={} color_8=light_grey dash_8=8,4 layer_9=Function fexpr_9={} color_9=grey \
		dash_9=12,3,3,3 leglabel_9=25-/75-percentile layer_10=Function fexpr_10={} \
		color_10=grey dash_10=12,3,3,3 legseq=_3,_4,_9,_7,_5,_6, out={}".format(\
			X_MIN, X_MAX, Y_MIN, Y_MAX, name, RA, DEC, fformat, srcpath, columns['MJD'], \
			columns['Magnitude'], MEAN, MEDIAN, FASTEST_INCREASE, FASTEST_DECREASE, \
			np.percentile(mag,5.), np.percentile(mag,95.), np.percentile(mag,75.), \
			np.percentile(mag,25.), OUTFILE)
		if plot:
			print('plotting lightcurve...', end='')
			sub.call(command,shell=True)
		print('done.')
		return {'object name' : name,
					'object ID' : ObjectID[0],
					'RA' : RA,
					'DEC' : DEC,
					'number of data points' : len(mag),
					'mean magnitude' : mean,
					'standarddeviation' : standarddev,
					'variance' : standarddev**2,
					'skewness' : skewness,
					'kurtosis' : kurt,
					'median magnitude' : median,
					'5-percentile' : np.percentile(mag,5.),
					'25-percentile' : np.percentile(mag,25.),
					'75-percentile' : np.percentile(mag,75.),
					'95-percentile' : np.percentile(mag,95.),
					'5-95-percentle difference' : np.percentile(mag,95.)-np.percentile(mag,5.),
					'25-75-percentile difference' : np.percentile(mag,75.)-np.percentile(mag,25.),
					'amplitude' : amplitude,
					'amplitude error' : amplitude_err,
					'fastest brightness increase' : np.amax(brightness_change,axis=0)[0],
					'fastest brightness increase MJD' : np.amax(brightness_change,axis=0)[1],
					'fastest brightness decrease' : np.amin(brightness_change,axis=0)[0],
					'fastest brightness decrease MJD' : np.amin(brightness_change,axis=0)[1]}
	else:
		print('no data available.')
		return {}

def get_speccy_url(plate, mjd, fiberID):
	"""
	Get speccy url to SDSS spectrum from T. Dewelly's speccy file.

	Function takes:
	Plate ID
	MJD
	Fiber ID
	"""
	plate = str(plate)
	mjd = str(mjd)
	fiberID = str(fiberID)
	with open('{}tdwelly_SPIDERS_speccy_file_index_speccy_file_index_latest.txt'.format('/net/syntron/work1/emmerich/xray-sources/data/')) as urllist:
		for line in urllist:
			linesplit = line.split()
			if plate == linesplit[0] and mjd == linesplit[1] and fiberID == linesplit[2]:
					specfile_url = re.findall(r'http://.*\.txt',line)[0]
					return specfile_url
			else:
				pass
	return ''

def remove_data_outside_region(name, RA_cen, DEC_cen, r, RA_col, DEC_col, srcpath, fformat, destpath=''):
	"""
	Remove data outside a defined region from a lightcurve.

	Function takes:
	name of object (identifier)
	RA coordinate (degrees)
	DEC coordinate (degrees)
	radius of region (arcsec)
	Name of RA column in input table
	Name of DEC column in input table
	srcpath to original data
	destpath to save the result
	"""
	print('Removing data outside of region for object {}...'.format(name), end='')
	if not srcpath:
		srcpath += '{}.{}'.format(name.replace(' ','_'), fformat)
	elif srcpath[-1] != '/':
		srcpath += '/'
	if srcpath[-1] == '/':	
		srcpath += '{}.{}'.format(name.replace(' ','_'), fformat)
	if not destpath:
			destpath = '/'.join(srcpath.split('/')[:-1])+'/'+'out_{}.{}'.format(name.replace(' ','_'), fformat)
	elif destpath[-1] != '/':
		destpath += '/'
	if destpath[-1] == '/':
		destpath += '{}.{}'.format(name.replace(' ','_'), fformat)

	data = ascii.read(srcpath)
	center = SkyCoord(RA_cen, DEC_cen, unit=(u.deg, u.deg))
	remove = []
	for i in range(len(data)):
		RA = data[i][RA_col]
		DEC = data[i][DEC_col]
		temp = SkyCoord(RA, DEC,unit=(u.deg, u.deg))
		if SkyCoord.separation(center, temp) < r/3600.*u.deg:
			pass
		else:
			remove.append(i)
	data.remove_rows(remove)
	ascii.write(table=data, output=destpath, delimiter=',', overwrite=True)
	print('done.')

def main():
	print('This srcipt only containts functions that can be imported into other python srcipts.')
	return
	
if __name__ == '__main__':
	main()
