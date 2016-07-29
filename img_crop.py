#!/usr/bin/python

import os
from os import path
import sys
import argparse
import glob
import Image
from PIL import ImageOps

parser = argparse.ArgumentParser()
parser.add_argument('directory')

args = parser.parse_args()

if not args.directory or not path.exists(args.directory) :
	print "Error: Invalid directory."
	sys.exit()

thumbs_path = path.join(args.directory, "thumbnails");
if path.exists(thumbs_path):
	print "Error: Thumbnails directory already exists."
	sys.exit()

thumb_resized = 308, 308
thumb_cropped = (0, 0, 308, 257)
files = glob.glob(path.join(args.directory, "*"))
os.mkdir(thumbs_path)
for infile in files:
	basename = path.basename(infile)
	print "Processing " + basename
	outfile = path.join(thumbs_path, basename)
	try:
		im = Image.open(infile)
		thumb = im.resize(thumb_resized, Image.ANTIALIAS)
		thumb = thumb.crop(thumb_cropped)
		thumb.save(outfile, format="JPEG", quality=90, optimize=True)
	except IOError:
		print "Error creating: " + outfile
