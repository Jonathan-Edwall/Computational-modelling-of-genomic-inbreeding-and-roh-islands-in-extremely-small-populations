
#!/bin/bash -l

# Start the timer 
start=$(date +%s)


# Activate conda environment
source /home/martin/anaconda3/etc/profile.d/conda.sh  # Source Conda initialization script
conda activate bedtools
# /home/martin/anaconda3/envs/bedtools/bin/bedtools --version: bedtools v2.30.0  

# bedtools intersect -h  # Documentation about the merge function

####################################  
# Defining the working directory
#################################### 

HOME=/home/jonathan
cd $HOME
######################################  
####### Defining parameter values #######
######################################
header="#CHR\tPOS1\tPOS2\tSNP\tA1\tA2\tMAF\tNCHROBS"



####################################  
# Defining the input files
#################################### 

results_dir=$HOME/results
# results_dir=$HOME/results_No_MAF_pruning_50_N_e


PLINK_allele_freq_dir=$results_dir/PLINK/allele_freq
ROH_hotspots_results_dir=$results_dir/ROH-Hotspots

#�������������
#� Empirical �
#�������������
###### Allele frequency file ###### 
german_shepherd_allele_freq_plink_output_dir=$PLINK_allele_freq_dir/empirical/german_shepherd
empirical_allele_freq_w_positions_file="$german_shepherd_allele_freq_plink_output_dir/german_shepherd_filtered_allele_freq.bed"
###### ROH-hotspot window-files ######
german_shepherd_roh_hotspots_dir=$ROH_hotspots_results_dir/empirical/german_shepherd

#�������������
#� Simulated � 
#�������������
###### Allele frequency file ###### 
simulated_allele_freq_plink_output_dir=$PLINK_allele_freq_dir/simulated
selection_model_allele_freq_plink_output_dir=$simulated_allele_freq_plink_output_dir/selection_model

###### Causative Variant window-files ######
selection_model_causative_variant_windows_dir=$results_dir/causative_variant_windows


#################################### 
# Defining the output dirs
#################################### 

#�������������
#� Empirical �
#�������������
hotspots_allele_freq_output_dir=$german_shepherd_roh_hotspots_dir/hotspots_allele_freq
# Creating a directory to store the .BED-files in, if it does not already exist.
mkdir -p $hotspots_allele_freq_output_dir
#�������������
#� Simulated � 
#�������������
causative_windows_allele_freq_output_dir=$selection_model_causative_variant_windows_dir/allele_freq
# Creating a directory to store the .BED-files in, if it does not already exist.
mkdir -p $causative_windows_allele_freq_output_dir

#����������������������������������������������������������������������������
# Function: bedtools intersect
#
###Input:
# 
###Output:
#����������������������������������������������������������������������������

#¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤
#¤¤¤¤ Empirical Data (German Shepherd) ¤¤¤¤ 
#¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤



# Running intersect command for every ROH-hotspot file.
for roh_hotspot_file in "$german_shepherd_roh_hotspots_dir"/*.bed; do
    prefix=$(basename "$roh_hotspot_file" .bed) # Extracting basename without the .bed extension
    # Counter for ROH hotspot windows
    counter=1    
   
    # Loop through each ROH hotspot window for the current file
    while IFS= read -r line; do
        output_file="${hotspots_allele_freq_output_dir}/${prefix}_${counter}_allele_freq.bed"
        # Create a temporary BED file for the current genomic interval
        echo -e "$line" > temp.bed
        
        # Run bedtools intersect-function        
        bedtools intersect \
            -wa -header \
            -a <(tail -n +2 "$empirical_allele_freq_w_positions_file") \
            -b temp.bed \
            | sed '1i'"$header" >> "$output_file"  # Append output to the file instead of overwriting
        
        ((counter++))
    done < "$roh_hotspot_file"
done

#¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤
#¤¤¤¤ Selection Model (Simulated) ¤¤¤¤ 
#¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤


for causative_variant_file in "$selection_model_causative_variant_windows_dir/"*.bed; do
    basename=$(basename "$causative_variant_file" .bed) # Extracting basename without the .bed extension
    prefix=$(basename "$causative_variant_file" | sed 's/_causative_variant_window.*//')

    allele_freq_w_positions_file=$(ls "$selection_model_allele_freq_plink_output_dir"/*"$prefix"*.bed)
    output_file="${causative_windows_allele_freq_output_dir}/${basename}_allele_freq.bed"
    rm -f "$output_file"  # Remove the output file if it already exists

    # Create the output file with header
    echo -e "$header" > "$output_file"

    # Loop through each ROH hotspot window for the current file
    while IFS= read -r line; do
        # Create a temporary BED file for the current genomic interval
        echo -e "$line" > temp.bed
        
        # Run bedtools intersect-function        
        bedtools intersect \
            -wa -header \
            -a <(tail -n +2 "$allele_freq_w_positions_file") \
            -b temp.bed \
            >> "$output_file"  # Append output to the file instead of overwriting
        
        ((counter++))
    done < "$causative_variant_file"
done








# Ending the timer 
end=$(date +%s)
# Calculating the runtime of the script
runtime=$((end-start))

echo "Mapping of ROH-hotspots to markers completed"
echo "The outputfiles are stored in: $hotspots_allele_freq_output_dir  & $causative_windows_allele_freq_output_dir  "
echo "Runtime: $runtime seconds"