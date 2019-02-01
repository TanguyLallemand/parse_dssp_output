#! /bin/bash

mkdir -p ./dataset/
mkdir -p ./dataset/pdb_files
#  Get PDB id, remove header and remove chains identifier (last char of PDB ID)
awk '{ print $1 }' ./dataset/cullpdb_pc20_res1.6_R0.25_d190117_chains3429 | tail -n +2 | cut -c1-4  > ./dataset/list_of_id.txt
# Loop on every ID and wget it
for i in `cat ./dataset/list_of_id.txt`; do
	[ ! -e $i.pdb ] && `wget https://files.rcsb.org/download/$i.pdb -P ./dataset/pdb_files`
	sleep 0.1
done
# Compress files inot one archive
zip ./dataset/all_pdb_files.zip ./dataset/pdb_files/*.pdb
rm ./dataset/pdb_files/*.pdb
rm ./dataset/list_of_id.txt


mkdir -p ./dssp_output/raw_dssp


mkdir -p ./dssp_output/sequence
sequence="./dssp_output/sequence/"
mkdir -p ./dssp_output/solvent_accessibility
accessibility="./dssp_output/solvent_accessibility/"
mkdir -p ./dssp_output/angles
angles="./dssp_output/angles/"

#Save Amino acid sequence from each DSSP result in a new file
for i in `ls ./dssp_output/raw_dssp/*.dssp`; do #la colone 14 est vire
    name=$(basename $i)
    name=$(echo "$name" | cut -f 1 -d '.')
    echo 'Processing to save Amino acid sequence of: ' $name
    tail -n +29 $i | awk -F "" '{print $14}' | tr -d '\n' > "$sequence$name.seq"
	#Save solvent accessibility informations (column 36,37 and 38 in DSSP result files) in a new file
	echo 'Processing to save solvent accessibility informations of: ' $name
	tail -n +29 $i | awk -F "" '{print $36 $37 $38}' | tr '\n' ',' | sed 's/\s//g' > "$accessibility$name.acc"
	# Save PHI and PSI values in a new file
	phi=$(tail -n +29 $i | awk -F "" '{print substr($0,104,6)}' | tr '\n' ',' | sed 's/\s//g')
	psi=$(tail -n +29 $i | awk -F "" '{print substr($0,110,6)}' | tr '\n' ',' | sed 's/\s//g')
	echo $phi > "$angles$name.ang"
	echo $psi > "$angles$name.ang"
	rm $i
done
