#!/usr/bin/env bash
# ========================================================================================
# copyright Asthma Collaboratory (2020)
# coded by Kevin L. Keys 
#
# This BASH script compiles the METAL meta-analysis of ROH association results. 
# Results are compiled one phenotype at a time.
#
# Call:
#
#     bash 04_parse_metaanalysis_results.sh
# ========================================================================================

# load environment variables
source ../../../.env.sh

set -o
set -u

R_parse_metaanalysis_results="${thisdir}/parse_roh_metaanalysis_results_per_pheno.R"

plot_filetype="png"
plot_routine_script="${thisdir}/R/plotting_routines.R"
environment_script="${thisdir}/R/set_R_environment.R"

phenos=("Asthma_Status" "BDR" "FVC" "Post_FEV1" "Pre_FEV1")
#phenos=("Asthma_Status") 

# METAL strips the chr/bp position information that we need for plotting manhattan plots
# will jerryrig a way to put them back using a separate script for meta-analysis results
# to do this, first parse the marker information from the results files for each phenotype
for pheno in ${phenos[@]}; do
    output_dir="${resultsdir}/${pheno}/meta"
    results_file="${output_dir}/${pheno}.metaanalysis_1.txt"
    #marker_file="${output_dir}/${pheno}.markers.txt.gz"
    #cut -f 1 ${resultsdir}/${pheno}/meta/${metaanalysis_resultsfile} | tail -n +2 | sort --key=1 --version-sort | uniq | gzip -9 > ${marker_file}
    #results_file="${output_dir}/${pheno}.GWAS.metaanalysis.txt.gz"

    $RSCRIPT $R_parse_metaanalysis_results \
        --results-file ${results_file} \
        --output-directory ${output_dir} \
        --phenotype-name ${pheno} \
        --set-R-environment ${environment_script} \
        --plotting-routines ${plot_routine_script} \
        --plot-filetype ${plot_filetype}
#        --marker-file ${marker_file} \
done
