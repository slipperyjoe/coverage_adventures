#!/usr/bin/python

# -----------------------------------------------------------------------------
# DESCRIPTION:
#       Script to generate pie plots from coverage reports
#       Can pipe csv directly into it. example: 
#       cat results.csv | ./plot_pie_coverage.py --min '208, 66, 22' --max '208, 66, 98'

#
# AUTHOR:
#     slipperyjoe <contact@slipperyjoe.xyz>
#
# COPYRIGHT:      
#      Copyright © 2021 slipperyjoe. License GPLv3+: GNU GPL version 3
#      or later <https://gnu.org/licenses/gpl.html>.
#      This is free software: you are free to change and redistribute it. There
#      is NO WARRANTY, to the extent permitted by law.
#
# -----------------------------------------------------------------------------
# NOTES:
#     
# -----------------------------------------------------------------------------

import matplotlib.pyplot as plt
import numpy as np
import colorsys
import argparse
import sys
import pandas as pd

# Set matplotlib default text size to 15.0 ( for pie labels )
plt.rcParams['font.size'] = 15.0

parser = argparse.ArgumentParser(
        description=' Script to generate pie plots from coverage reports ',
        epilog="Example: ./plot_pie_coverage.py --min '208, 66, 22' --max '208, 66, 68'"
        )
parser.add_argument('--min', required=True, help="darkest shade in the colorscheme, tuple 'h,s,l'")
parser.add_argument('--max', required=True, help="brightest shade in the colorscheme, tuple h,s,l'")
#parser.add_argument('data_file',  required=True, help="csv data file")
parser.add_argument('data_file', nargs='?', type=argparse.FileType('r'), default=sys.stdin, help="csv data file (defaults to stdin")

args = parser.parse_args()

# parse stdin / filename argument as csv
data_file = parser.parse_args().data_file
csv_data = pd.read_csv(data_file,header=None)
mylabels = csv_data[0]
y = csv_data[1]
num_elems =  len(csv_data[0]) - 1


min_color =  tuple(map(int, args.min.split(', ')))
max_color =  tuple(map(int, args.max.split(', ')))
#print(min_color)
#print(min_color)

h = min_color[0]/360
s = min_color[1] / 100
start_lum = min_color[2] / 100
end_lum = max_color[2] / 100

#num_elems = y.size - 1
step = (end_lum - start_lum) / num_elems

# make an array of tuples with rgb values
#rgbs = [colorsys.hls_to_rgb(h,l,s) for l in np.arange(start_lum,end_lum,step)]

 
rgbs = [colorsys.hls_to_rgb(h,(i) * step + start_lum,s)  for i in range(y.size) ]
hexs = ['#%02x%02x%02x'%(round(rgb[0]*255),round(rgb[1]*255),round(rgb[2]*255)) for rgb in rgbs]
#hexs
#[(round(rgb[0]*255),round(rgb[1]*255),round(rgb[2]*255)) for rgb in rgbs]

print(h,s,start_lum)
print(rgbs)
print(hexs)
#quit()
plt.pie(
        y, 
        labels = mylabels, 
        colors = hexs, 
        startangle = 90
        )

plt.show() 
#plt.savefig('test.svg')


