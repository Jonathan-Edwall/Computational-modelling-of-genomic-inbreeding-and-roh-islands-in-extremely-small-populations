
#!/bin/bash -l

# Start the timer 
start=$(date +%s)

####################################  
# Defining the working directory
#################################### 

HOME=/home/jonathan
cd $HOME

pipeline_script_dir=$HOME/code/pipeline_scripts


# Function to handle user interruption
handle_interrupt() {
    echo "Pipeline interrupted. Exiting."
    # Could potentially clean up the files created up until the script termination here
    exit 1
}

# Trap the SIGINT signal (Ctrl+C) and call the handle_interrupt function
trap 'handle_interrupt' SIGINT

#################################### 
# Defining Simulation parameters
#################################### 
output_dir_selection_simulation=$HOME/data/raw/simulated/selection_model
#mkdir -p $output_dir_selection_simulation
mkdir -p $output_dir_selection_simulation/variant_freq_plots # Also creating a subdirectory for storing the images of the simulation runs
mkdir -p $output_dir_selection_simulation/pruned_counts  # Creating a subdirectory for storing the disappearance counter values
mkdir -p $output_dir_selection_simulation/variant_position  # Creating a subdirectory for storing the position of the selected causative variant



n_generations_selection_sim=40 # 40 default
n_ind_per_selection_sim_generation=50
# selection_coefficient_list=(0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8)
selection_coefficient_list=(0.05 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8)

# selection_coefficient_list=(0.6 0.7)
# selection_coefficient_list=(0.8)

#¤¤¤¤¤¤¤¤¤¤¤ If running this script outside of run_pipeline.sh, then define these variables below: ¤¤¤¤¤¤¤¤¤¤¤ 
# n_simulation_replicates=1
# chr_simulated="chr3"
# selected_chr_snp_density_mb=56.21







#����������������������������������������������������������������������������
# Function: 
# Selection Scenario simulation for Dogs in AlphaSimR
#
###Input: 
# 
###Output: 
#����������������������������������������������������������������������������
cd $output_dir_selection_simulation


disappearance_threshold_value_to_terminate_script=20   # After 20 failed tries, the script gets rerun

# Running the simulation n_simulation_replicates (20) times to create 20 technical replicates
for ((counter=1; counter<="$n_simulation_replicates"; counter++))
do
    
    # Loop over each selection coefficient
    for selection_coefficient in "${selection_coefficient_list[@]}"
    do
        export output_sim_files_basename="sim_${counter}_selection_model_s$(echo "$selection_coefficient" | sed 's/\.//')_${chr_simulated}"
        export selection_coefficient="$selection_coefficient"
        export output_dir_selection_simulation="$output_dir_selection_simulation"
        export chr_simulated="$chr_simulated"
        export n_generations_selection_sim="$n_generations_selection_sim"
        export selection_coefficient="$selection_coefficient"
        export n_ind_per_selection_sim_generation="$n_ind_per_selection_sim_generation"
        export selected_chr_snp_density_mb="$selected_chr_snp_density_mb" # Variable defined in run_pipeline.sh
        export simulation_prune_count_file="$output_dir_selection_simulation/pruned_counts/pruned_replicates_count_s$(echo "$selection_coefficient" | sed 's/\.//')_${chr_simulated}.tsv"
        export variant_positions_file="$output_dir_selection_simulation/variant_position/variant_position_s$(echo "$selection_coefficient" | sed 's/\.//')_${chr_simulated}.tsv"        
        export disappearance_threshold_value_to_terminate_script="$disappearance_threshold_value_to_terminate_script" 

        # Loop until the R script completes successfully
        while true
        do
            Rscript -e "rmarkdown::render('$pipeline_script_dir/2-5_1_dogs_founder_pop_sim_selection_model.Rmd')"
            exit_status=$?

            if [ $exit_status -eq 0 ]; then
                echo "Simulation $counter with selection coefficient $selection_coefficient completed successfully"
                break
            else
                echo -e  "\n Simulation $counter with selection coefficient $selection_coefficient didn't fixate after $disappearance_threshold_value_to_terminate_script tries"
                echo -e "\n Rerunning the script.."

                # Update the prune count file
                if [ -f "$simulation_prune_count_file" ]; then
                    # Read the file contents
                    temp_file=$(mktemp)
                    updated=0
                    while IFS=$'\t' read -r basename count; do
                        if [[ "$basename" == "$output_sim_files_basename" ]]; then
                            count=$((count + $disappearance_threshold_value_to_terminate_script))
                            updated=1
                        fi
                        echo -e "$basename\t$count" >> "$temp_file"
                    done < "$simulation_prune_count_file"

                    # If not updated, add a new row
                    if [ $updated -eq 0 ]; then
                        echo -e "$output_sim_files_basename\t$disappearance_threshold_value_to_terminate_script" >> "$temp_file"
                    fi

                    # Replace the original file with the updated file
                    mv "$temp_file" "$simulation_prune_count_file"
                else
                    # File does not exist, create it and add the new row
                    echo -e "$output_sim_files_basename\t$disappearance_threshold_value_to_terminate_script" > "$simulation_prune_count_file"
                fi
            fi

        echo "Exit status of R Markdown script: $exit_status"
        echo "Contents of prune count file after update:"
        cat "$simulation_prune_count_file"
        done

        echo "Simulation $counter with selection coefficient $selection_coefficient completed"
    done
done




# Ending the timer 
end=$(date +%s)
# Calculating the runtime of the script
runtime=$((end-start))

echo "selection model simulations of dogs completed"
echo "The outputfiles are stored in: $output_dir_selection_simulation"
echo "Runtime: $runtime seconds"