#!/bin/bash
#  Get PDB id, remove header and remove chains identifier (last char of PDB ID)
awk '{ print $1 }' cullpdb_pc20_res1.6_R0.25_d190117_chains3429 | tail -n +2 | cut -c1-4  > list_of_id.txt
# loop on every ID and wget it
for i in `cat list_of_id.txt`; do
	[ ! -e $i.pdb ] && `wget https://files.rcsb.org/download/$i.pdb`
	sleep 0.1
done

