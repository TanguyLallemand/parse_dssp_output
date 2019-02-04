#! /bin/bash

################################################################################
# Creation of directories, store some paths in variables                       #
################################################################################

# Create directory to store dataset
mkdir -p ./dataset/
mkdir -p ./dataset/pdb_files
# Create directory to store DSSP output
mkdir -p ./dssp_output/raw_dssp
# Create directories to store DSSP parsed results
mkdir -p ./dssp_output/sequence
sequence="./dssp_output/sequence/"
mkdir -p ./dssp_output/solvent_accessibility
accessibility="./dssp_output/solvent_accessibility/"
mkdir -p ./dssp_output/angles
angles="./dssp_output/angles/"


################################################################################
# Get dataset gathering all PDB files with following characteristics:          #
# cut-off: 20% of sequence identity                                            #
# resolution cut-off of 1.6 angstrom                                           #
# R-factor cutoff of 0.25                                                      #
################################################################################

#  Get PDB id, remove header and remove chains identifier (last char of PDB ID)
list_of_id=`awk '{ print $1 }' ./dataset/cullpdb_pc20_res1.6_R0.25_d190117_chains3429 | tail -n +2 | cut -c1-4`
# Loop on every ID and wget it
for i in $list_of_id; do
	# If PDB file does not already exist
	[ ! -e ./dataset/pdb_files/$i.pdb ] &&  `wget https://files.rcsb.org/download/$i.pdb -P ./dataset/pdb_files/`
	# Wait time to avoid to send too muche request to PDB database
	sleep 0.1
done
# Compress files into one archive
zip ./dataset/all_pdb_files.zip ./dataset/pdb_files/*.pdb
# Delete temporary files
rm -f ./dataset/pdb_files/*.pdb

################################################################################
# Get Compute DSSP on every file of previoulsy constructed dataset             #
################################################################################

echo 'Compute DSSP'
# For every PDB ID
for i in $list_of_id; do
	# If PDB does not exist unzip it
	unzip -j "./dataset/all_pdb_files.zip" "dataset/pdb_files/$i.pdb" -d "./dataset/pdb_files/"
	# If PDB has not been computed using DSSP
	[ ! -e ./dssp_output/raw_dssp/$i.dssp ] && ./bin_dssp/dssp-2.0.4-linux-amd64 -i ./dataset/pdb_files/$i.pdb -o ./dssp_output/raw_dssp/$i.dssp
	# Delete pdb files, considered as a temporary file
	rm -f ./dataset/pdb_files/$i.pdb
done

################################################################################
# Parse DSSP results into three files:                                         #
# .seq file gathering sequence of protein                                      #
# .acc to store solvent accessibility of every structures                      #
# .ang to store every angles torsion (phi and psi angles) of structures        #
################################################################################

for i in `ls ./dssp_output/raw_dssp/*.dssp`; do
	# Get name of PDB
    name=$(basename $i)
    name=$(echo "$name" | cut -f 1 -d '.')
    echo 'Parsing DSSP results of: ' $name
	#Save Amino acid sequence from each DSSP result in a new file, this is done using following line. This line is pipe following this steps:
	# Tail is used to avoid to parse header, output without header is given to awk used to print a particular column, here column 14. To finish, all \n are deleted using tr -d. Result of this pipe is redirected in a particular directory with right name and with .seq extension
    tail -n +29 $i | awk -F "" '{print $14}' | tr -d '\n' > "$sequence$name.seq"
	#Save solvent accessibility informations (column 36,37 and 38 in DSSP result files) in a new file. This is done using following line. This line is pipe following this steps:
	# Tail is used to avoid to parse header, output without header is given to awk used to print particular columns (36, 37, 38). To finish, all \n are replaced by commas using tr. sed is used to delete spaces
	tail -n +29 $i | awk -F "" '{print $36 $37 $38}' | tr '\n' ',' | sed 's/\s//g' > "$accessibility$name.acc"
	# Save PHI and PSI values in a new file. This is done using following line. This line is pipe following this steps:
	# Tail is used to avoid to parse header, output without header is given to awk used to print particular columns (104 to 110 or 110 to 116). To finish, all \n are replaced by commas using tr. sed is used to delete spaces
	phi=$(tail -n +29 $i | awk -F "" '{print substr($0,104,6)}' | tr '\n' ',' | sed 's/\s//g')
	psi=$(tail -n +29 $i | awk -F "" '{print substr($0,110,6)}' | tr '\n' ',' | sed 's/\s//g')
	# Output these results in right directory with right filename with phi in first line, psi in seconde line
	echo $phi > "$angles$name.ang"
	echo $psi >> "$angles$name.ang"
	# Delete dssp file, considered as a temporary file
	rm $i
done
# Delete temporary directories
rmdir ./dssp_output/raw_dssp
rmdir ./dataset/pdb_files
