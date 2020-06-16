#!/usr/bin/env bash

set -o
set -u

RSCRIPT="/Library/Frameworks/R.framework/Resources/bin/Rscript"
R_parse_gwas_results="./parse_gwas_results_per_pheno_per_pop.R"
R_parse_metaanalysis_results="./parse_gwas_metaanalysis_results_per_pheno.R"

plot_filetype="png"
plot_routine_script="~/Git/gala2-ROH/analyses/roh/src/R/plotting_routines.R"
environment_script="~/Git/gala2-ROH/analyses/roh/src/R/set_R_environment.R"
output_dir="~/Box/gala_sage_roh/gwas/results"

pop_codes=("AA" "MX" "PR")
pheno_codes=("Asthma_Status" "BDR" "FVC" "Post_FEV1" "Pre_FEV1")
regression_types=("logistic" "linear" "linear" "linear" "linear")

#gwas_results="${output_dir}/clean/Asthma_Status.maf001.AA.ALLCHR.withA2freq.assoc.logistic.gz"
#pop_codes=("AA")
#pheno_codes=("Asthma_Status")

### these are done!!!!
#for i in ${!pheno_codes[@]}; do
#    pheno=${pheno_codes[$i]}
#    regtype=${regression_types[$i]}
#    for pop in ${pop_codes[@]}; do 
#        results_file="${output_dir}/clean/${pheno}.maf001.${pop}.ALLCHR.withA2freq.assoc.${regtype}.gz"
#
#        echo "Processing results for ${pheno} in ${pop} stored in ${results_file}..."
#
#        $RSCRIPT $R_parse_gwas_results \
#            --results-file ${results_file} \
#            --output-directory ${output_dir} \
#            --set-R-environment ${environment_script} \
#            --plotting-routines ${plot_routine_script} \
#            --plot-filetype ${plot_filetype}
#
#        echo "...done.\n\n"
#    done
#done

# METAL strips the chr/bp position information that we need for plotting manhattan plots
# will jerryrig a way to put them back using a separate script for meta-analysis results
# to do this, first parse the marker information from the results files for each phenotype
#pheno_codes=("Asthma_Status") 
for pheno in ${pheno_codes[@]}; do
#    zcat ${output_dir}/clean/${pheno}.maf001.*.gz  | cut -f 1-5 | grep -v "BP" | sort --key=1 --key=3 --numeric-sort | uniq | gzip -9 > ${output_dir}/clean/${pheno}.markers.txt.gz 
    results_file="${output_dir}/clean/${pheno}.GWAS.metaanalysis.txt.gz"
    marker_file="${output_dir}/clean/${pheno}.markers.txt.gz"

    $RSCRIPT $R_parse_metaanalysis_results \
        --results-file ${results_file} \
        --marker-file ${marker_file} \
        --output-directory ${output_dir} \
        --set-R-environment ${environment_script} \
        --plotting-routines ${plot_routine_script} \
        --plot-filetype ${plot_filetype}
done
