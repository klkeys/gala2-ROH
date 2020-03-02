#!/usr/bin/env bash
# ================================================================================
# copyright Asthma Collaboratory (2020)
# coded by Kevin L. Keys 
#
# This BASH script adds a reference allele frequency to PLINK association results. 
# It relies on previously generated PLINK output (01_run_gwas_allpop.sh),
# as well as a previously generated allele frequency reference. 
#
# The output of this script is a new result file with additional reference allele
# frequency information included.
#
# Call:
#
#     bash 02_run_add_A2_freq.sh 
# ================================================================================

# load environment variables
source ../../../.env.sh

# script variables
multithread_commandfile="${resultsdir}/list_multithread_commands_R.sh"
R_add_A2_freq="${thisdir}/add_A2_freq.R"
PYTHON_run_multithread="${thisdir}/multithread_commands.py"

# set up multithread command file
rm -f ${multithread_commandfile}
touch ${multithread_commandfile}

# loop over all populations
for j in ${!pops[@]}; do
    pop=${pops[$j]}
    genodir_pop=${genodirs[$j]}

    # loop over all phenotypes
    for i in ${!phenos[@]}; do
        pheno=${phenos[$i]}            # phenotype name
        lm_type=${plink_lm_types[$i]}  # either "linear" or "logistic"

        # loop over all chromosomes
        for ((i=1;i<=22;i++)); do

            # point R to reference allele frequency file
            # we assume PLINK format for this file (.FREQ)
            allele_freq_file="${genodir_pop}/freq.out.maf001.${i}.frq"

            # ensure that output directory exists
            outdir="${resultsdir}/${pheno}/${pop}"
            mkdir -p ${outdir}

            # point to existing PLINK association results file
            plink_result_file="${outdir}/${pheno}.maf001.${pop}.chr${i}.assoc.${lm_type}"

            # will write new results file (with +1 column) to this path
            new_plink_result_file="${outdir}/${pheno}.maf001.${pop}.chr${i}.withA2freq.assoc.${lm_type}"

            # this writes a command to add ref allele freq for 1 pop, 1 chr, 1 pheno at a time
            R_cmd="$RSCRIPT $R_add_A2_freq --allele-frequency-file ${allele_freq_file} --result-file ${plink_result_file} --output-file ${new_plink_result_file}"

            # append command to file
            echo "${R_cmd}" >> ${multithread_commandfile}

        done
    done
done

# now run all commands
# each command is one job
# use ${njobs} to control the number of concurrent jobs
njobs=16
python2 ${PYTHON_run_multithread} --file ${multithread_commandfile} --jobs ${njobs} 
