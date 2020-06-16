#!/usr/bin/env bash

set -o
set -u

RSCRIPT="/Library/Frameworks/R.framework/Resources/bin/Rscript"
R_compute_pval_corr="./compute_pval_corr_gwas_roh.R"

environment_script="~/Git/gala2-ROH/analyses/roh/src/R/set_R_environment.R"
output_dir="~/Box/gala_sage_roh/gwas/results"

gwas_results_dir="~/Box/gala_sage_roh/gwas/results"
roh_results_dir="~/Box/gala_sage_roh/roh/results"

pop_codes=("AA" "MX" "PR")
pheno_codes=("Asthma_Status" "BDR" "FVC" "Post_FEV1" "Pre_FEV1")
regression_types=("logistic" "linear" "linear" "linear" "linear")

#pop_codes=("AA")
#pheno_codes=("Asthma_Status")

# download hg19 to hg38 liftOver map
liftover_map="hg19ToHg38.over.chain.gz"
curl http://hgdownload.soe.ucsc.edu/goldenPath/hg19/liftOver/hg19ToHg38.over.chain.gz --output ${liftover_map} 

# loop over phenotypes and populations
for i in ${!pheno_codes[@]}; do
    pheno=${pheno_codes[$i]}
    regtype=${regression_types[$i]}

    for pop in ${pop_codes[@]}; do 
        gwas_results_file="${gwas_results_dir}/clean/${pheno}.maf001.${pop}.ALLCHR.withA2freq.assoc.${regtype}.gz"
        roh_results_file="${roh_results_dir}/${pheno}/${pop}.${pheno}.2019-03-26.ALLCHR.txt"

        echo "Processing results for ${pheno} in ${pop}"
        echo -e "\t GWAS results: ${gwas_results_file}"
        echo -e "\t ROH results: ${roh_results_file}"
        echo -e "\t liftOver map: ${liftover_map}"

        $RSCRIPT $R_compute_pval_corr \
            --GWAS-results-file ${gwas_results_file} \
            --ROH-results-file ${roh_results_file} \
            --output-directory ${output_dir} \
            --liftover-map ${liftover_map} \
            --phenotype-name ${pheno} \
            --population-code ${pop} \
            --set-R-environment ${environment_script} \

        echo -e "...done.\n\n"
    done
done

## METAL strips the chr/bp position information that we need for plotting manhattan plots
## will jerryrig a way to put them back using a separate script for meta-analysis results
## to do this, first parse the marker information from the results files for each phenotype
##pheno_codes=("Asthma_Status") 
#for pheno in ${pheno_codes[@]}; do
##    zcat ${output_dir}/clean/${pheno}.maf001.*.gz  | cut -f 1-5 | grep -v "BP" | sort --key=1 --key=3 --numeric-sort | uniq | gzip -9 > ${output_dir}/clean/${pheno}.markers.txt.gz 
#    results_file="${output_dir}/clean/${pheno}.GWAS.metaanalysis.txt.gz"
#    marker_file="${output_dir}/clean/${pheno}.markers.txt.gz"
#
#    $RSCRIPT $R_parse_metaanalysis_results \
#        --results-file ${results_file} \
#        --marker-file ${marker_file} \
#        --output-directory ${output_dir} \
#        --set-R-environment ${environment_script} \
#done
