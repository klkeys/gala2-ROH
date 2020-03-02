#!/usr/bin/env bash
# ================================================================================
# copyright Asthma Collaboratory (2020)
# coded by Kevin L. Keys 
#
# This BASH script collects association test results for 1 population and 1 phenotype,
# combining results across chromosomes. The expected file format is a modified
# PLINK association results file (see 02_run_add_A2_freq.sh).
#
#
# Call:
#
#     bash 03_combine_results.sh 
# ================================================================================

# load environment variables
source ../../../.env.sh

# loop over all populations
for j in ${!pops[@]}; do
    pop=${pops[$j]}

    for i in ${!phenos[@]}; do
        pheno=${phenos[$i]}           # phenotype name
        lm_type=${plink_lm_types[$i]} # either "linear" or "logistic"

        # output directory varies by pheno and pop
        outdir="${resultsdir}/${pheno}/${pop}"

        # point to chr1 results from previous script (02_run_add_A2_freq.sh)
        new_plink_result_file_chr1="${outdir}/${pheno}.maf001.${pop}.chr1.withA2freq.assoc.${lm_type}"

        # filepath for new results file with all chromosomes included 
        combined_result_file="${outdir}/${pheno}.maf001.${pop}.ALLCHR.withA2freq.assoc.${lm_type}"

        echo "Compiling results for ${pheno} in ${pop}..."

        # start with clean results file
        # this will clobber previously generated combined results file
        # seed file with results from chr1, but discard markers with missing values 
        sed '/NA/d' ${new_plink_result_file_chr1} > ${combined_result_file} 

        echo -e "\tchr1..."

        # loop over all chromosomes
        for ((k=2;k<=22;k++)); do

            # append results for each chromosome to file
            new_plink_result_file="${outdir}/${pheno}.maf001.${pop}.chr${k}.withA2freq.assoc.${lm_type}"

            # when appending, discard the header (colnames) and any rows with missing values
            sed '1d' ${new_plink_result_file} | sed '/NA/d' >> ${combined_result_file}

            echo -e "\tchr${k}..."
        done

        echo -e "...done."
    done
done

echo "Results compilation complete."
