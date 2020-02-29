#!/usr/bin/env bash

source ../../../.env.sh

# loop over all populations
for j in ${!pops[@]}; do
    pop=${pops[$j]}

    for i in ${!phenos[@]}; do
        pheno=${phenos[$i]}
        lm_type=${plink_lm_types[$i]}
        outdir="${resultsdir}/${pheno}/${pop}"
        combined_result_file="${outdir}/${pheno}.maf001.${pop}.ALLCHR.withA2freq.assoc.${lm_type}"
        new_plink_result_file_chr1="${outdir}/${pheno}.maf001.${pop}.chr1.withA2freq.assoc.${lm_type}"

        echo "Compiling results for ${pheno} in ${pop}..."

        # start with clean results file
        # this will clobber previously generated combined results file
        # seed file with results from chr1 
        sed '/NA/d' ${new_plink_result_file_chr1} > ${combined_result_file} 

        echo -e "\tchr1..."

        # loop over all chromosomes
        for ((k=2;k<=22;k++)); do

            # append results for each chromosome to file
            new_plink_result_file="${outdir}/${pheno}.maf001.${pop}.chr${k}.withA2freq.assoc.${lm_type}"

            sed '1d' ${new_plink_result_file} | sed '/NA/d' >> ${combined_result_file}

            echo -e "\tchr${k}..."
        done

        echo -e "...done."
    done
done

echo "Results compilation complete."
