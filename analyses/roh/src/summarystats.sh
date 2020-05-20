#!/usr/bin/env bash
# ========================================================================================
# copyright Asthma Collaboratory (2020)
# coded by Kevin L. Keys 
#
# This BASH script computes various summary statistics of interest for the manuscript.
#
# Call:
#
#     bash summarystats.sh 
# ========================================================================================

# load environment variables
source ../../../.env.sh


# ========================================================================================
# number of genotypes per population
# ========================================================================================

# get array data counts
echo "Number of array genotypes"
echo "AA: $(wc -l ${genodir_sage}/${genodir_sage_pfx}.bim | awk '{ print $1 }')"
echo "MX: $(wc -l ${genodir_gala}/${genodir_gala_pfx}.bim | awk '{ print $1 }')"
echo "PR: $(wc -l ${genodir_gala}/${genodir_gala_pfx}.bim | awk '{ print $1 }')"
echo ""

# some of these numbers can be pulled from the PLINK log files from the imputed data. the steps are:
# 1. pull the relevant line from the log file: "X markers and Y people pass filters and QC"
# 2. grab X, which is the first word in the line
# 3. sum(X) across the chromosomes
# relevant: https://stackoverflow.com/questions/450799/shell-command-to-sum-integers-one-per-line
echo "Number of raw imputed genotypes"
echo "AA: $(grep -h "pass filters and QC" ${genodir_aa}/out.[0123456789]*.log | cut -f 1 -d ' ' | awk '{s+=$1} END {printf "%.0f\n", s}')"
echo "MX: $(grep -h "pass filters and QC" ${genodir_mx}/out.[0123456789]*.log | cut -f 1 -d ' ' | awk '{s+=$1} END {printf "%.0f\n", s}')"
echo "PR: $(grep -h "pass filters and QC" ${genodir_pr}/out.[0123456789]*.log | cut -f 1 -d ' ' | awk '{s+=$1} END {printf "%.0f\n", s}')"
echo ""

echo "Number of imputed genotypes with MAF > 0.01"
echo "AA: $(grep -h "pass filters and QC" ${genodir_aa}/out.maf001.*.log | cut -f 1 -d ' ' | awk '{s+=$1} END {printf "%.0f\n", s}')"
echo "MX: $(grep -h "pass filters and QC" ${genodir_mx}/out.maf001.*.log | cut -f 1 -d ' ' | awk '{s+=$1} END {printf "%.0f\n", s}')"
echo "PR: $(grep -h "pass filters and QC" ${genodir_pr}/out.maf001.*.log | cut -f 1 -d ' ' | awk '{s+=$1} END {printf "%.0f\n", s}')"
echo ""


# ========================================================================================
# number of samples per population
# ========================================================================================
echo "Number of samples per population:
echo "AA: $(grep -c "African_American" ${phenofile})
echo "MX: $(grep -c "Mexican_American" ${phenofile})
echo "PR: $(grep -c "Puerto_Rican" ${phenofile})
echo "Total: $(wc -l ${phenofile})
