#!/bin/bash
for i in `cat pdbid-lowercase.txt`;
do
#	echo $i
	[ ! -e $i.pdb ] && `wget https://files.rcsb.org/download/$i.pdb` #--header "Referer: https://files.rcsb.org"
	sleep .1
done
