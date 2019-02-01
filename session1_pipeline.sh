#bin/bash


#Get All the pdb files from a list with sequence identity under 30% and download the corresponding pdb files.

#Getting PDB IDs

list_ids=`cat $1 | awk '{print $1}'| tail -n +2 | cut -c 1-4`
echo $list_ids

#
#
# #Create the tar archive:
touch text.txt #Avoid empty archive issue
tar -cvf pdb_archive.tar text.txt

# #Download each PDB file
for name in $list_ids; do
    echo $name
    wget -qO- "https://files.rcsb.org/download/$name.pdb" > "$name.pdb"
    zip -ur pdb_archive..zip "$name.pdb"
    rm "$name.pdb"
done
#
#
# #Run DSSP on whole subset
mkdir results
 for i in $list_ids; do
    echo $i
    #tar xvzf "pdb_archive.tar.gz" "$i.pdb"
    unzip -j "pdb_archive.zip" "pdb_archive/$name.pdb" -d "./"| ./dssp-2.0.4-linux-amd64 "$i.pdb" > results/$i.dssp
    rm $i.pdb
 done

#DSSP parsing
#We want 3 output file: Solvent accessibility, Amino acid sequence, and dihedral angles (phi and psi).

################################################################################

# ACC = Accessibility of the residue (for a solvant)
#If it's high, this part is in contact with water/solvant
#
#
acc=".acc"
ang=".ang"
mkdir -p pipeline_results
ij="sp"
for i in `ls results/*.dssp`; do
    name=$(echo $i | cut -c 9-12)
	tail -n+29 $i| awk -F "" '{print$14}' | tr -d '\n' > "pipeline_results/$name.seq"
 	#Get the column 14 and put all the sequence in one line
    echo $file
    tail -n+29 $i | awk -F "" '{print$36, $37, $38}' | tr '\n' ',' | sed 's/\s//g' > "pipeline_results/$name$acc"
    # get all accessibility values, get them in one line and separated by comma and then save it in .pdb.dssp.acc
    #substr : $0 is the total line , 104 the starting column and 6 the 6 next columns
    #When there is a chain break,  there is an exclamation mark.
    #Get the column containg phi angle and put it in line into a file for each .dssp file
    echo "PHI:"
    echo `tail -n+29 $i | awk -F "" '{print substr($0,104,6)}' | tr '\n' ',' | sed 's/\s//g'` > "pipeline_results/$name$ang"
    # Get the column containing psi angle for each AA and create a file
    echo "PSI:"
    echo `tail -n+29 $i | awk -F "" '{print substr($0,110,6)}' | tr '\n' ',' | sed 's/\s//g'` >> "pipeline_results/$name$ang"
done
