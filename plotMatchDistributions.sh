#!/bin/bash
#Start a loop.
for i in `seq 1 20` ; do
#Using the best match. 
stilts tmatch2 \
	in1=RC3/RC3 in2=CNG/CNG \
	find=best join=1and2 matcher=sky \
	values1='RA_RC3 DE_RC3' values2='RA_CNG DE_CNG' params=$i \
	ofmt=fits-basic omode=out out=matchBest
#Using all the matches.
stilts tmatch2 \
	in1=RC3/RC3 in2=CNG/CNG \
	find=all join=1and2 matcher=sky \
	values1='RA_RC3 DE_RC3' values2='RA_CNG DE_CNG' params=$i \
	ofmt=fits-basic omode=out out=matchAll
#Write the amount of matched rows on to the file
python3 rowCounter.py
#Erase the matched tables
rm matchBest
rm matchAll
done
#Plot the result
python3 plotMatchDistributions.py
rm "cumulative.txt"