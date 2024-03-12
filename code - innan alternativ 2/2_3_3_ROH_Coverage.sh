
#!/bin/bash -l

# Start the timer 
start=$(date +%s)

# Change working directory
HOME=/home/jonathan

cd $HOME


# Activate conda environment
source /home/martin/anaconda3/etc/profile.d/conda.sh  # Source Conda initialization script
conda activate bedtools
# /home/martin/anaconda3/envs/bedtools/bin/bedtools --version: bedtools v2.30.0  

# bedtools merge -h  # Documentation about the merge function

echo "conda activated?"


#����������������������������������������������������������������������������
# Defining the input files.
# Example input-file: 418_ROH_merged_ROH.bed
#����������������������������������������������������������������������������

# Defining path to the output directory
bedtools_output_dir=$HOME/results/Bedtools
#individual_merged_overlapping_rohs_dir=$bedtools_output_dir/empirical/doi_10_5061_dryad_h44j0zpkf__v20210813/per_indiv_overlapping_rohs_merged
individual_merged_overlapping_rohs_dir=$bedtools_output_dir/empirical/doi_10_5061_dryad_h44j0zpkf__v20210813/small_scale_20_indv_per_indiv_overlapping_rohs_merged

coverage_output_dir = $bedtools_output_dir/coverage_of_rohs

# Creating a directory to store the .BED-files in, if it does not already exist.
mkdir -p $coverage_output_dir


#����������������������������������������������������������������������������
# Function: bedtools coverage
#
# Calculating the population-based frequency of ROH-segments
#����������������������������������������������������������������������������


# Running merge command for merging together overlapping ROH-segments, for each individual
for bed_file inindividual_merged_overlapping_rohs_dir/*.bed; do
    individual_id=$(basename "$bed_file" .bed) # Extracting individual ID from the file name (In other words: extracting everything that is not "bed_file" or the .bed-file extension, from the file name)
    output_file="$individual_merged_overlapping_rohs_dir/${individual_id}_merged_ROH.bed"
    
    # Create and save a header for the output file (its only the 3 first columns of chr,pos1,pos2 that will remain in the output file in the first place)
    header=$(head -n 1 "$bed_file" | awk -v OFS='\t' '{print $1, $2, $3}') 
   
    # Run bedtools merge-function 
    # Process substitution is used on the input file, to feed a headerless version of the current $bed_file in the iteration, to meet .bed-file standards   
    bedtools merge\
    -i <(tail -n +2 "$bed_file")\
    > "$output_file.tmp"
    
    
    # Adding a header to the outputfile
    { echo "$header"; cat "$output_file.tmp"; } > "$output_file"    
    rm "$output_file.tmp" # Clean up temporary file      
    
done


# Ending the timer 
end=$(date +%s)
# Calculating the runtime of the script
runtime=$((end-start))

echo "Merging of overlapping ROH-segments completed,for each individual"
echo "Outputfiles are stored in: $individual_merged_overlapping_rohs_dir"
echo "Runtime: $runtime seconds"