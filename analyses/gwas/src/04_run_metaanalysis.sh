#!/usr/bin/env bash

source ../../../.env.sh

METAL=${METAL}

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

# seed METAL control file
# this clobbers any previous METAL file for the phenotype
cat << nothingelsematters > ${metal_commandfile}
SCHEME STDERR
OUTFILE ${metalpfx} txt
VERBOSE OFF
GENOMICCONTROL ON
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
