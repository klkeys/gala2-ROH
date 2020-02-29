#!/usr/bin/env bash

source ../../../.env.sh

# binaries
PLINK=${PLINK}

# script variables
multithread_commandfile="${thisdir}/list_multithread_commands_plink.sh"
plink_phenofile="${datadir}/GALA_SAGE_ROH_merged_phenotypes_plink.txt"

ci_level="0.95" # Confidence Interval level
nthreads=1
mem=2000
vif=1000

# set up multithread command file
rm -f ${multithread_commandfile}
touch ${multithread_commandfile}

# reformat phenotype file manually to PLINKy standards
# in particular, PLINK cannot handle nonnumeric phenotypes or covariates
# this sets the Sex phenotype to 0(Male)/1(Female)
# and the pop categories to 0(AA)/1(MX)/2(PR)
# lastly, it reformats all missing values to -9
# note that the expected file style for "NA" is actually a blank "", not an explicit "NA"
paste <(cut -f 1 ${phenofile}) ${phenofile}| sed -e 's/SubjectID/FID/' | sed -e 's/SubjectID/IID/' | sed -e 's/Male/0/g' -e 's/Female/1/g' | sed -e 's/African_American/0/g' -e 's/AA/0/g' | sed -e 's/Mexican_American/1/g' -e 's/MX/1/g' | sed -e 's/Puerto_Rican/2/' -e 's/PR/2/g' | perl -pe 's/\t\t/\t-9\t/g' | perl -pe 's/\t\t/\t-9\t/g' | perl -pe 's/\t\t/\t-9\t/g' > ${plink_phenofile}

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
            bfile="${genodir_pop}/out.maf001.${i}"
            a2_allele_ref="${genodir_pop}/out.${i}.genomeREF.txt"

            outdir="${resultsdir}/${pheno}/${pop}"
            mkdir -p ${outdir}
            outpfx="${outdir}/${pheno}.maf001.${pop}.chr${i}"

        # this runs association test in PLINK for 1 pop, 1 chr, 1 pheno at a time 
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

# now run all jobs
nthreads=16
python2 ${thisdir}/multithread_commands.py --file ${multithread_commandfile} --jobs ${nthreads} 
