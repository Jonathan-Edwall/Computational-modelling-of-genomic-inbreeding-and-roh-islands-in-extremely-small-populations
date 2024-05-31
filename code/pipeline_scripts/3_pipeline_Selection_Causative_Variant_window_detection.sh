
#!/bin/bash -l

# Start the timer 
start=$(date +%s)


# Function to handle user interruption
handle_interrupt() {
    echo "Pipeline interrupted. Exiting."
    # Could potentially clean up the files created up until the script termination here
    exit 1
}

# Trap the SIGINT signal (Ctrl+C) and call the handle_interrupt function
trap 'handle_interrupt' SIGINT


####################################  
# Defining the working directory
#################################### 

HOME=/home/jonathan


script_dir=$HOME/code/pipeline_scripts

cd $script_dir


######################################  
####### Defining the INPUT files #######
######################################  
results_dir=$HOME/results
bedtools_results_dir=$results_dir/Bedtools/coverage
raw_data_dir=$HOME/data/raw
#�������������
#� Selection Model (Simulated) � 
#�������������
raw_selection_data_dir=$raw_data_dir/simulated/selection_model

variant_position_dir=$raw_selection_data_dir/variant_position
variant_freq_plots_dir=$raw_selection_data_dir/variant_freq_plots

selection_pop_roh_freq_dir=$bedtools_results_dir/simulated/selection_model/pop_roh_freq

######################################  
####### Defining the OUTPUT files #######
######################################  

output_dir=$results_dir/causative_variant_windows

mkdir -p $output_dir # Creating subdirectory if it doesn't already exist

######################################  
####### Defining parameter values #######
######################################




##############################################################################################  
############ RESULTS ###########################################################################
############################################################################################## 

#¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤
#¤¤¤¤ Selection Model (Simulated) ¤¤¤¤ 
#¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤
# Generate the list of .bed files in the directory
bed_files_list=("$selection_pop_roh_freq_dir"/*_ROH_freq.bed)

readarray -t simulation_scenarios < <(find "$selection_pop_roh_freq_dir" -maxdepth 1 -type f -name "*.bed" | sed -E 's/.*sim_[0-9]+_(.*)\.bed/\1/' | sort -u)



# Loop over each input bed file
for bed_file in "${bed_files_list[@]}"; do
    # Extract the selection coefficient by finding "s" followed by any number of digits, from the filename of the current bed_file
    # then extract everything to the right, excluding "_ROH_freq.bed
    selection_scenario_type=$(basename "$bed_file" | grep -oP 's\d+.*(?=_ROH_freq.bed)')
    echo "$bed_file"
    echo "$selection_scenario_type"


    # Construct the params list
    export input_pop_roh_freq_file="$bed_file"
    export chr_simulated="chr3"
    export input_selection_coefficient_variant_positions_file="$variant_position_dir/variant_position_${selection_scenario_type}.tsv"
    export output_dir=$output_dir
    export output_variant_window_lengths_file="$output_dir/causative_variant_window_lengths_${selection_scenario_type}.tsv"
       
    # Render the R Markdown document with the current input bed file
    Rscript -e "rmarkdown::render('$script_dir/3 - Selection_Causative_Variant_window_detection.Rmd')"
done

echo "Causative variant windows defined for the Selection Model Simulations"
echo "The results are stored in: $output_dir"




# Ending the timer 
end=$(date +%s)
# Calculating the runtime of the script
runtime=$((end-start))

echo "Runtime: $runtime seconds"

