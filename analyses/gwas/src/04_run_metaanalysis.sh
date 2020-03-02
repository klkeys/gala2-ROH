#!/usr/bin/env bash
# ================================================================================
# copyright Asthma Collaboratory (2020)
# coded by Kevin L. Keys 
#
# This BASH script runs METAL to meta-analyze population-specific GWAS results. 
# METAL is called once for each phenotype, using all 3 populations (AA, MX, PR).
# Each phenotype is run in serial, so analysis can take awhile.
#
# Call:
#
#     bash 04_run_metaanalysis.sh 
# ================================================================================

# load environment variables
source ../../../.env.sh

# binary executables
METAL=${METAL}

# METAL parameters
metal_scheme="STDERR"
metal_verbose="OFF"
metal_genomiccontrol="ON"

# loop over phenotypes
# will run once per pheno
# breaking convention here: will not indent within loop in order to preserve here-doc segments
for i in ${!phenos[@]}; do

pheno=${phenos[$i]}
lm_type=${plink_lm_types[$i]}

# store metaanalysis results in their own directory
metaldir="${resultsdir}/${pheno}/meta"
mkdir -p ${metaldir}

# create a prefix for METAL output
metalpfx="${metaldir}/${pheno}.metaanalysis"

# give a name to the METAL command file
metal_commandfile="${metalpfx}.metal"

# METAL effect argument differs for linear/logistic regression
effect="BETA"
if [[ "${lm_type}" == "logistic" ]]; then
    effect="log(OR)"
fi

# seed METAL control file with an appropriate header
# this clobbers any previous METAL file for the phenotype
cat << nothingelsematters > ${metal_commandfile}
SCHEME ${metal_scheme} 
OUTFILE ${metalpfx} txt
VERBOSE ${metal_verbose} 
GENOMICCONTROL ${metal_genomiccontrol} 
nothingelsematters

for j in ${!pops[@]}; do
pop=${pops[$j]}

combined_result_file="${resultsdir}/${pheno}/${pop}/${pheno}.maf001.${pop}.ALLCHR.withA2freq.assoc.${lm_type}"

cat << sadbuttrue >> ${metal_commandfile}

MARKER SNP
ALLELE A1 A2
EFFECT ${effect} 
STDERR SE
PVALUE P
FREQLABEL Freq
PROCESS ${combined_result_file}
sadbuttrue

done # end loop over pops

# finish control file
cat << entersandman >> ${metal_commandfile}

ANALYZE HETEROGENEITY

QUIT
entersandman

# now execute metal
${METAL} ${metal_commandfile}

done # end loop over phenos
