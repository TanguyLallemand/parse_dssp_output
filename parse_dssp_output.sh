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

mkdir -p ./dssp_output/dssp_without_header
header="./dssp_output/dssp_without_header/"
mkdir -p ./dssp_output/sequence
sequence="./dssp_output/sequence/"
mkdir -p ./dssp_output/solvent_accessibility
accessibility="./dssp_output/solvent_accessibility/"
mkdir -p ./dssp_output/angles
angles="./dssp_output/angles/"
mkdir -p ./dssp_output/secondary_structures
secondary="./dssp_output/secondary_structures/"
#Delete header from DSSP result files
for i in `ls ./dssp_output/raw_dssp/*.pdb.ds`; do
    j=".dssp"
    echo $i
    name=$(basename $i)
    name=$(echo "$name" | cut -f 1 -d '.')
    echo 'Processing to deletion of header of: ' $name
    grep -A 1000 "#" $i > $header$name$j
done


#Save Amino acid sequence from each DSSP result in a new file
for i in `ls ./dssp_output/dssp_without_header/*.dssp`; do #la colone 14 est vire
    j=".seq"
    echo $i
    name=$(basename $i)
    name=$(echo "$name" | cut -f 1 -d '.')
    echo 'Processing to save Amino acid sequence of: ' $name
    tail -n +2 $i | awk -F "" '{print $14}' | tr -d '\n' > $sequence$name$j
done

#Save solvent accessibility informations (column 36,37 and 38 in DSSP result files) in a new file
for i in `ls ./dssp_output/dssp_without_header/*.dssp`; do
    j=".acc"
    echo $i
    name=$(basename $i)
    name=$(echo "$name" | cut -f 1 -d '.')
    echo 'Processing to save solvent accessibility informations of: ' $name
    tail -n +2 $i | awk -F "" '{print $36 $37 $38}' | tr '\n' ',' | sed 's/\s//g' > $accessibility$name$j
done


#Save PHI and PSI values in a new file
# for i in `ls ./dssp_output/dssp_without_header/*.dssp`; do
#     j=".acc"
#     echo $i
#     name=$(basename $i)
#     name=$(echo "$name" | cut -f 1 -d '.')
#     cat $i | awk -F "" '{print substr($0,104,6)}' | tail -n +2 | tr '\n' ',' | sed 's/\s//g' > $angles$name$j
#     cat $i | awk -F "" '{print substr($0,110,6)}' | tail -n +2 | tr '\n' ',' | sed 's/\s//g' > $angles$name$j
# done
#Save secondary structure informations from column 17 in a new file

for i in `ls ./dssp_output/dssp_without_header/*.dssp`; do
    j=".ss"
    echo $i
    name=$(basename $i)
    name=$(echo "$name" | cut -f 1 -d '.')
    echo 'Processing to save secondary structure informations of: ' $name
    cat $i  |tail -n +2 | awk -F "" '{print $17}' | tr '\n' ',' | sed 's/\s/L/g' | sed 's/,//g' > $secondary$name$j
done
