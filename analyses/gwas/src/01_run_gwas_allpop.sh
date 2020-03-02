#!/usr/bin/env bash
# =======================================================================
# copyright Asthma Collaboratory (2020)
# coded by Kevin L. Keys 
#
# This BASH script executes GWAS with PLINK on three populations:
# -- African Americans (AA)
# -- Mexican Americans (MX)
# -- Puerto Ricans (PR)
#
# The populations are taken from the GALA II and SAGE studies.
#
# This script points to locally-stored PLINK binary genotype files
# These files are split by chromosome.
# Adjust file names as appropriate for your use case.
# Set ${genodir} in the environment script (.env.sh).
#
# Association commands are writen to a file and then executed in parallel.
# The job scheduler runs all commands locally.
# Analyses were executed on a 120-core machine, but your resources may vary.
# Control the number of concurrent jobs with variable ${njobs} below.
#
# Call:
#
#     bash 01_run_gwas_allpop.sh 
# =======================================================================

# load environment variables
source ../../../.env.sh

# binaries
PLINK=${PLINK}

# script variables
multithread_commandfile="${resultsdir}/list_multithread_commands_plink.sh"
plink_phenofile="${datadir}/GALA_SAGE_ROH_merged_phenotypes_plink.txt"
PYTHON_run_multithread="${thisdir}/multithread_commands.py"

ci_level="0.95" # Confidence Interval level
nthreads=1      # number of threads to use in PLINK
mem=2000        # number of Kb of memory that PLINK can use
vif=1000        # Variance Inflation Factor for PLINK: https://www.cog-genomics.org/plink/1.9/assoc#linear

# set up multithread command file
rm -f ${multithread_commandfile}
touch ${multithread_commandfile}

# reformat phenotype file manually to PLINKy standards
# in particular, PLINK cannot handle nonnumeric phenotypes or covariates
# this sets the Sex phenotype to 0(Male)/1(Female)
# and the pop categories to 0(AA)/1(MX)/2(PR)
# lastly, it reformats all missing values to -9
# this command expects that ${phenofile} encodes missingness as a blank "", not an explicit "NA"
paste <(cut -f 1 ${phenofile}) ${phenofile}| sed -e 's/SubjectID/FID/' | sed -e 's/SubjectID/IID/' | sed -e 's/Male/0/g' -e 's/Female/1/g' | sed -e 's/African_American/0/g' -e 's/AA/0/g' | sed -e 's/Mexican_American/1/g' -e 's/MX/1/g' | sed -e 's/Puerto_Rican/2/' -e 's/PR/2/g' | perl -pe 's/\t\t/\t-9\t/g' | perl -pe 's/\t\t/\t-9\t/g' | perl -pe 's/\t\t/\t-9\t/g' > ${plink_phenofile}

# loop over all populations
for j in ${!pops[@]}; do
    pop=${pops[$j]}
    genodir_pop=${genodirs[$j]}

    # loop over all phenotypes
    for i in ${!phenos[@]}; do
        pheno=${phenos[$i]}            # this is the phenotype name
        lm_type=${plink_lm_types[$i]}  # either "linear" or "logistic" as appropriate
        covars=${covariate_lists[$i]}  # comma-delimited list of covariates for analysis

        # loop over all chromosomes
        for ((i=1;i<=22;i++)); do

            # point to PLINK genotype files and allele references (split by chr)
            bfile="${genodir_pop}/out.maf001.${i}"
            a2_allele_ref="${genodir_pop}/out.${i}.genomeREF.txt"

            # set output directory and file path
            outdir="${resultsdir}/${pheno}/${pop}"
            mkdir -p ${outdir}
            outpfx="${outdir}/${pheno}.maf001.${pop}.chr${i}"

            # this writes a command to run association analysis in PLINK for 1 pop, 1 chr, 1 pheno at a time 
            plink_cmd="${PLINK} --allow-no-sex --bfile ${bfile} --a2-allele ${a2_allele_ref}  --pheno ${plink_phenofile} --pheno-name ${pheno} --covar ${plink_phenofile} --${lm_type} hide-covar --covar-name ${covars} --ci ${ci_level} --out ${outpfx} --threads ${nthreads} --vif ${vif} --memory ${mem}"
            
            # add phenotype encoding flag for case-control pheno
            if [[ "${lm_type}" = "logistic" ]]; then
                plink_cmd="${plink_cmd} --1"
            fi

            # append command to file
            echo ${plink_cmd} >> ${multithread_commandfile} 

        done
    done
done

# now run all commands
# each command is one job
# use ${njobs} to control the number of concurrent jobs
njobs=16
python2 ${PYTHON_run_multithread} --file ${multithread_commandfile} --jobs ${njobs} 
