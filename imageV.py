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
import sys

def download_panstarrs_fits(name, RA, DEC, color, destpath=''):
	"""
	Download the PanSTARRS image as '.fits' file.

	Function takes:
	name of object (identifier)
	RA coordinate (degrees)
	DEC coordinate (degrees)
	path to dump FITS
	"""
	name=name+color
	print('Trying to retrieve PanSTARRS FITS image for object {}...'.format(name), end='')
	if not destpath:
			destpath += name.replace(' ','_')
	elif destpath[-1] != '/':
		destpath += '/'
	if destpath[-1] == '/':
		destpath += name.replace(' ','_')

	if not os.path.exists(destpath+'.fits'):
		url = 'https://ps1images.stsci.edu/cgi-bin/ps1cutouts?pos={}+{}&filter={}&filetypes=stack&auxiliary=data&size=500&output_size=0&verbose=0&autoscale=99.500000&catlist='.format(RA, DEC, color)
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

download_panstarrs_fits(sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4],sys.argv[5])
