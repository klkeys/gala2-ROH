#!/usr/bin/env Rscript --vanilla
# =======================================================================================
# copyright Asthma Collaboratory (2020)
# coded by Donglei Hu and Kevin L. Keys
#
# This script adds the A2 allele frequency to PLINK association test results 
# It uses 2 input files
# Input file 1: a plink output file for allele frequency (.frq)
# Input file 2: a plink linear or logistic regression result file
# =======================================================================================

# =======================================================================================
# load libraries
# =======================================================================================
library(data.table)
library(optparse)

# parse command line arguments
option_list = list(
    make_option(
        c("-a", "--allele-frequency-file"),
        type    = "character",
        default = NULL,
        help    = "File path for allele frequency file (PLINK .FRQ) for 1 chromosome",
        metavar = "character"
    ),
    make_option(
        c("-b", "--result-file"),
        type    = "character",
        default = NULL,
        help    = "File path for association test results (PLINK .ASSOC) for 1 chromosome",
        metavar = "character"
    ),
    make_option(
        c("-c", "--output-file"),
        type    = "character",
        default = NULL,
        help    = "File name for new result file with allele freq added",
        metavar = "character"
    )
)

opt_parser = OptionParser(option_list = option_list)
opt = parse_args(opt_parser, convert_hyphens_to_underscores = TRUE)



freq.file    = opt$allele_frequency_file
results.file = opt$result_file
output.file  = opt$output_file


# =======================================================================================
# load data
# =======================================================================================

freq   = fread(freq.file)
result = fread(results.file)


# =======================================================================================
# add allele frequency to association test results
# =======================================================================================

if ( ( sum(freq$SNP==result$SNP) == nrow(freq) ) & ( sum(freq$A1==result$A1) == nrow(result) ) ) {
   result.final = data.table(cbind(result[,1:4], freq[,4:5], result[,7:12]))
   colnames(result.final)[6] = "Freq"
   fwrite(x = result.final, file = output.file, quote = FALSE, sep="\t")
}
