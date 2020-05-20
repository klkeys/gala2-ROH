#!/usr/bin/env bash
# ==============================================================================
# Copyright 2020, Asthma Collaboratory
# authors:
# -- Kevin L. Keys
#
# This script contains file paths pertinent to ROH analysis.
# Modify this script according to local filepaths and then save as ".env.sh".
# All variables with empty values "" require arguments for the pipeline to run. 
# ==============================================================================


set -u
set -o
set -e

# binaries
RSCRIPT="/usr/bin/Rscript"
PLINK=""

# directories
MYHOME="" ## set to absolute path of user $HOME
thisdir="$(readlink -f .)"
repodir="${thisdir}/../.."
ROHdir="${repodir}/.."
analysisdir="${thisdir}/../analysis"
resultsdir="${analysisdir}/results"
scratchdir="${analysisdir}/scratch"
datadir="${analysisdir}/data"
codedir="${thisdir}/R"

# directories for imputed genotype data
genodir_aa=""
genodir_mx=""
genodir_pr=""

genodirs=(${genodir_aa} ${genodir_mx} ${genodir_pr})

# directories for genotype array data
genodir_gala=""
genodir_sage=""
genodir_gala_pfx=""
genodir_sage_pfx=""

# assuming that these are already made...
gala_roh_dir="${datadir}/GALA_ROH"
sage_roh_dir="${datadir}/SAGE_ROH"
phenofile="${datadir}/GALA_SAGE_ROH_merged_phenotypes.txt"

mkdir ${scratchdir} ${analysisdir} ${datadir} ${resultsdir}

# file paths
gala_data_file="" # we used CSV format, though any delimited file should work seamlessly
sage_data_file="" # same as above
gala_bmi_file="" # ibid
gala_pca_file="" # PCs produced by PLINK or (much better) GENESIS
sage_pca_file="" # same as above
gala_ancestry_file="" # 3-way ancestry components (CEU + YRI + NAM) from ADMIXTURE
sage_ancestry_file="" # 2-way ancestry components (CEU + YRI) from ADMIXTURE

# variables
pops=("AA" "MX" "PR")
phenos=("Pre_FEV1" "Post_FEV1" "Asthma_Status" "BDR" "FVC")
glm_types=("gaussian" "gaussian" "binomial" "gaussian" "gaussian")
covariate_lists=("Age,Sex,Asthma_Status,Obesity_Status,Height,PC1,PC2,PC3" "Age,Sex,Obesity_Status,Height,PC1,PC2,PC3" "Age,Sex,Obesity_Status,Height,PC1,PC2,PC3" "Age,Sex,Obesity_Status,Height,PC1,PC2,PC3" "Age,Sex,Asthma_Status,Obesity_Status,Height,PC1,PC2,PC3")
outdirpfx="${resultsdir}/phenotypes"
outdirs=("${outdirpfx}/pre-fev1" "${outdirpfx}/post-fev1" "${outdirpfx}/asthma" "${outdirpfx}/bdr" "${outdirpfx}/fvc")

# make the output directories
for d in ${outdirs[@]}; do
    mkdir -p ${d} ${d}/results ${d}/figures
done

# ---
# These are variables for association analysis
# these values correspond to defaults for function PerformAssociationAnalyses
# modify them here as needed 

# suffix for output files
outsfx="ROH.R.out"

# point R to the right directory when loading packages
# in R this should be the first entry of .libPaths()
library_path=""

# number of parallel cores to use in association analysis; sufficient to use 1 per chromosome
# BE VERY CAREFUL WITH THIS. with 3 pops, this can ask for ncores*3 processing cores 
# to avoid overburdening server when running multiple analyses, try ncores=10 
ncores=22

# The minimum samples with an ROH at a probe should be set at 8
# probes where only 2-8 people with a ROH segment at that probe will yield unrealistic p-values
# probes with < 2 people with a ROH segument have no variance and can yield numeric errors 
min_samples_at_probe=8

# file prefixes for GALA, SAGE genotype files
galapfx=""
sagepfx=""
# ---
