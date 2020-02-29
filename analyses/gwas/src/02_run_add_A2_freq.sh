#!/usr/bin/env bash
source ../../../.env.sh

# script variables
multithread_commandfile="${thisdir}/list_multithread_commands_R.sh"
R_add_A2_freq="${thisdir}/add_A2_freq.R"

# set up multithread command file
rm -f ${multithread_commandfile}
touch ${multithread_commandfile}

# loop over all populations
for j in ${!pops[@]}; do
    pop=${pops[$j]}
    genodir_pop=${genodirs[$j]}

    for i in ${!phenos[@]}; do
        pheno=${phenos[$i]}
        lm_type=${plink_lm_types[$i]}
        covars=${covariate_lists[$i]}

        # loop over all chromosomes
        for ((i=1;i<=22;i++)); do
            allele_freq_file="${genodir_pop}/freq.out.maf001.${i}.frq"

            outdir="${resultsdir}/${pheno}/${pop}"
            mkdir -p ${outdir}

            plink_result_file="${outdir}/${pheno}.maf001.${pop}.chr${i}.assoc.${lm_type}"
            new_plink_result_file="${outdir}/${pheno}.maf001.${pop}.chr${i}.withA2freq.assoc.${lm_type}"

            R_cmd="$RSCRIPT $R_add_A2_freq --allele-frequency-file ${allele_freq_file} --result-file ${plink_result_file} --output-file ${new_plink_result_file}"

            # append job to file
            echo "${R_cmd}" >> ${multithread_commandfile}

        done
    done
done

# now run all jobs
nthreads=16
python2 ${thisdir}/multithread_commands.py --file ${multithread_commandfile} --jobs ${nthreads} 
