#!/usr/bin/env bash
# ========================================================================================
# copyright Asthma Collaboratory (2020)
# coded by Kevin L. Keys 
#
# This BASH script runs METAL to meta-analyze population-specific ROH association results. 
# METAL is called once for each phenotype, using all 3 populations (AA, MX, PR).
# Each phenotype is run in serial, so analysis can take awhile.
#
# Call:
#
#     bash 03_run_metaanalysis.sh 
# ========================================================================================

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

# store metaanalysis results in their own directory
metaldir="${resultsdir}/${pheno}/meta"
mkdir -p ${metaldir}

# create a prefix for METAL output
metalpfx="${metaldir}/${pheno}.metaanalysis"

# give a name to the METAL command file
metal_commandfile="${metalpfx}.metal"

# METAL control parameters
metal_marker_name="Probe"
metal_allele_name_a1="eff_allele"
metal_allele_name_a2="alt_allele"
metal_effect_name="beta"
metal_pvalue_name="p"
metal_stderr_name="stderr"
metal_weight_name="nsamples"
metal_separator="COMMA"

# seed METAL control file with an appropriate header
# this clobbers any previous METAL file for the phenotype
cat << nothingelsematters > ${metal_commandfile}
SCHEME ${metal_scheme} 
OUTFILE ${metalpfx}_ .txt
VERBOSE ${metal_verbose} 
GENOMICCONTROL ${metal_genomiccontrol} 
nothingelsematters

echo ${plink_lm_types[0]}

for j in ${!pops[@]}; do
pop=${pops[$j]}
#lm_type=${plink_lm_types[$j]}
lm_type="gaussian"

combined_result_file="${resultsdir}/${pheno}/results/${pop}.${pheno}.ALLCHR.txt"

cat << sadbuttrue >> ${metal_commandfile}

MARKER ${metal_marker_name}
ALLELE ${metal_allele_name_a1} ${metal_allele_name_a2} 
EFFECT ${metal_effect_name}
STDERR ${metal_stderr_name} 
PVALUE ${metal_pvalue_name} 
WEIGHT ${metal_weight_name}
SEPARATOR ${metal_separator}
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
