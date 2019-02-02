#! /bin/bash

mkdir -p ./dataset/
mkdir -p ./dataset/pdb_files
#  Get PDB id, remove header and remove chains identifier (last char of PDB ID)
list_of_id=`awk '{ print $1 }' ./dataset/cullpdb_pc20_res1.6_R0.25_d190117_chains3429 | tail -n +2 | cut -c1-4`
# Loop on every ID and wget it
# for i in $list_of_id; do
# 	[ ! -e ./dataset/pdb_files/$i.pdb ] &&  `wget https://files.rcsb.org/download/$i.pdb -P ./dataset/pdb_files/`
# 	sleep 0.1
# done
# Compress files into one archive
# zip ./dataset/all_pdb_files.zip ./dataset/pdb_files/*.pdb
# Delete temporary files
rm ./dataset/pdb_files/*.pdb
# Create directory to store DSSP output
mkdir -p ./dssp_output/raw_dssp
echo 'COmpute DSSP'
for i in $list_of_id; do
	[ ! -e ./dataset/pdb_files/$i.pdb ] && unzip -j "./dataset/all_pdb_files.zip" "dataset/pdb_files/$i.pdb" -d "./dataset/pdb_files/"
	[ ! -e ./dssp_output/raw_dssp/$i.dssp ] && ./bin_dssp/dssp-2.0.4-linux-amd64 -i ./dataset/pdb_files/$i.pdb -o ./dssp_output/raw_dssp/$i.dssp
	rm -f ./dataset/pdb_files/$i.pdb
done

# Create directories to store DSSP parsed results
mkdir -p ./dssp_output/sequence
sequence="./dssp_output/sequence/"
mkdir -p ./dssp_output/solvent_accessibility
accessibility="./dssp_output/solvent_accessibility/"
mkdir -p ./dssp_output/angles
angles="./dssp_output/angles/"

for i in `ls ./dssp_output/raw_dssp/*.dssp`; do
	# Get name of PDB
    name=$(basename $i)
    name=$(echo "$name" | cut -f 1 -d '.')
    echo 'Parsing DSSP results of: ' $name
	#Save Amino acid sequence from each DSSP result in a new file
    tail -n +29 $i | awk -F "" '{print $14}' | tr -d '\n' > "$sequence$name.seq"
	#Save solvent accessibility informations (column 36,37 and 38 in DSSP result files) in a new file
	tail -n +29 $i | awk -F "" '{print $36 $37 $38}' | tr '\n' ',' | sed 's/\s//g' > "$accessibility$name.acc"
	# Save PHI and PSI values in a new file
	phi=$(tail -n +29 $i | awk -F "" '{print substr($0,104,6)}' | tr '\n' ',' | sed 's/\s//g')
	psi=$(tail -n +29 $i | awk -F "" '{print substr($0,110,6)}' | tr '\n' ',' | sed 's/\s//g')
	# store those informations, phi in first line, psi in seconde line
	echo $phi > "$angles$name.ang"
	echo $psi >> "$angles$name.ang"
	rm $i
done
