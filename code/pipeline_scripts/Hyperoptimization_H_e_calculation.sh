
#!/bin/bash -l

# Start the timer 
script_start=$(date +%s)


####################################  
# Defining the working directory
#################################### 

HOME=/home/jonathan
#cd $HOME

script_directory=$HOME/code/pipeline_scripts

######################################  
####### Defining parameter values #######
######################################
# export use_MAF_pruning=TRUE # Imported from H_e_calc_for_multiple_MAF_HO.sh
# export min_MAF=0.01 # Imported from H_e_calc_for_multiple_MAF_HO.sh

# empirical_dog_breed="empirical_breed" # Variable Defined in run_pipeline_hyperoptimize_neutral_model.sh

# MAF_status_suffix="No_MAF" # Imported from H_e_calc_for_multiple_MAF_HO.sh
# MAF_status_suffix="MAF_0_01" # Imported from H_e_calc_for_multiple_MAF_HO.sh

# $results_dir/expected_heterozygosity_$MAF_status_suffix

######################################  
####### Defining the INPUT files #######
######################################  
results_dir=$HOME/results_HO # Variable Defined in run_pipeline_hyperoptimize_neutral_model.sh
PLINK_allele_freq_dir=$results_dir/PLINK/allele_freq

#�������������
#� Empirical �
#�������������
##### Genomewide Allele frequencies #####
Empirical_breed_allele_freq_dir=$PLINK_allele_freq_dir/empirical/$empirical_dog_breed
##### ROH-hotspot Allele frequencies #####
roh_hotspots_results_dir=$results_dir/ROH-Hotspots
empirical_roh_hotspots_dir=$roh_hotspots_results_dir/empirical/$empirical_dog_breed
Empirical_breed_roh_hotspots_allele_frequency_dir=$empirical_roh_hotspots_dir/hotspots_allele_freq

#�������������
#� Simulated � 
#�������������
simulated_allele_freq_plink_output_dir=$PLINK_allele_freq_dir/simulated
##### Neutral Model #####
neutral_model_allele_freq_dir=$simulated_allele_freq_plink_output_dir/neutral_model

######################################  
####### Defining the OUTPUT files #######
######################################  
# expected_heterozygosity_dir=$results_dir/expected_heterozygosity
export expected_heterozygosity_dir="$results_dir/expected_heterozygosity_$MAF_status_suffix"
mkdir -p $expected_heterozygosity_dir

#�������������
#� Empirical �
#�������������
export Empirical_breed_H_e_dir="$expected_heterozygosity_dir/empirical/$empirical_dog_breed"
mkdir -p $Empirical_breed_H_e_dir
##### Neutral Model #####
neutral_model_H_e_dir="$expected_heterozygosity_dir/simulated/neutral_model"
mkdir -p $neutral_model_H_e_dir

##############################################################################################  
############ RESULTS ###########################################################################
############################################################################################## 

#¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤
#¤¤¤¤ Neutral Model (Simulated) ¤¤¤¤ 
#¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤
# Extract unique simulation prefixes
# simulation_scenarios_neutral_model=$(find $neutral_model_allele_freq_dir -maxdepth 1 -type f -name "*.bed" | sed -E 's/.*sim_[0-9]+_(.*)_allele_freq\.bed/\1/' | sort -u)
readarray -t simulation_scenarios_neutral_model < <(find "$neutral_model_allele_freq_dir" -maxdepth 1 -type f -name "*.bed" | sed -E 's/.*sim_[0-9]+_(.*)_allele_freq\.bed/\1/' | sort -u)

# Loop over each input bed file
for simulation_scenario in "${simulation_scenarios_neutral_model[@]}"; do
    echo "$simulation_scenario"
    
    # Construct the params list
    export empirical_allele_frequency_dir="$Empirical_breed_allele_freq_dir"
    export simulated_model_allele_frequency_dir="$neutral_model_allele_freq_dir"
    export sim_scenario_id="$simulation_scenario"
    export output_empirical_H_e_dir="$Empirical_breed_H_e_dir"
    export output_simulated_model_H_e_dir="$neutral_model_H_e_dir"

    echo "empirical_allele_frequency_dir: $empirical_allele_frequency_dir "
    echo "simulated_model_allele_frequency_dir: $simulated_model_allele_frequency_dir "
    echo "sim_scenario_id: $sim_scenario_id "
    echo "output_empirical_H_e_dir: $Empirical_breed_H_e_dir "
    echo "output_simulated_model_H_e_dir: $neutral_model_H_e_dir "
    
    # Render the R Markdown document with the current input bed file
    Rscript -e "rmarkdown::render('$script_directory/Hyperoptimization_H_e_calculation.Rmd')"
    # Rscript -e "rmarkdown::render('$script_directory/4-4_3_selective_sweep_test_expected_heterozygosity.Rmd')"
    
done

echo "Sweep test done for selection testing."
echo "The results are stored in: $expected_heterozygosity_dir"



# Ending the timer 
script_end=$(date +%s)
# Calculating the script_runtime of the script
script_runtime=$((script_end-script_start))

echo "Sweep test done for all the datasets"
echo "Runtime: $script_runtime seconds"

