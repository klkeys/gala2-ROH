# ==========================================================================================
# libraries
# ==========================================================================================
suppressPackageStartupMessages(library(dplyr, quietly = TRUE))
suppressPackageStartupMessages(library(ggplot2, quietly = TRUE))
suppressPackageStartupMessages(library(data.table, quietly = TRUE))
suppressPackageStartupMessages(library(optparse, quietly = TRUE))
suppressPackageStartupMessages(library(methods, quietly = TRUE)) ## for saving SVG format graphics

# ==========================================================================================
# command line options 
# ==========================================================================================

# parse command line variables
option_list = list(
    make_option(
        c("-g", "--GWAS-results-file"),
        type    = "character",
        default = NULL,
        help    = "The file path to one gzipped GWAS results file", 
        metavar = "character"
    ),
    make_option(
        c("-r", "--ROH-results-file"),
        type    = "character",
        default = NULL,
        help    = "File path to list of markers used in GWAS",
        metavar = "character"
    ),
    make_option(
        c("-o", "--output-directory"),
        type    = "character",
        default = NULL,
        help    = "Directory where output files are stored",
        metavar = "character"
    ),
    make_option(
        c("-l", "--liftover-map"),
        type    = "character",
        default = NULL,
        help    = "Path to a liftOver map, e.g. 'hg19ToHg38.over.chain.gz' for hg19 to hg38",
        metavar = "character"
    ),
    make_option(
        c("-p", "--phenotype-name"),
        type    = "character",
        default = NULL,
        help    = "Name of the phenotype to analyze",
        metavar = "character"
    ),
    make_option(
        c("-P", "--population-code"),
        type    = "character",
        default = NULL,
        help    = "Code for the population to analyze (e.g. AA for African American)",
        metavar = "character"
    ),
    make_option(
        c("-e", "--set-R-environment"),
        type    = "character",
        default = "~/Git/gala2-ROH/analyses/roh/src/R/set_R_environment.R",
        help    = "Path to R environment script [default: %default]",
        metavar = "character"
    )
)

opt_parser = OptionParser(option_list = option_list)
opt = parse_args(opt_parser, convert_hyphens_to_underscores = TRUE)

cat("Parsed options:\n\n")
print(opt)


# ==========================================================================================
# script variables
# ==========================================================================================
gwas.results.file = opt$GWAS_results_file
roh.results.file  = opt$ROH_results_file
output.dir        = opt$output_directory
liftover.map.path = opt$liftover_map
pheno.name        = opt$phenotype_name
pop.code          = opt$population_code
R.environment     = opt$set_R_environment

# read source code (environment script and plotting routines)
source(R.environment)
 
# read the two results files from disk
gwas.results = fread(gwas.results.file)
roh.results  = fread(roh.results.file)

# rename some column names
# a CHR:BP combo constitutes column "Probe", can use this as key (but keep hg19/hg38 separate)
# rename the p-value column to distinguish from GWAS p-value
roh.results = roh.results %>% rename(CHR = "chr", BP = "position", P.ROH = "p")

gwas.results = gwas.results %>%
    rename(P.GWAS = "P") %>%
    mutate(Probe.hg38 = paste(CHR, BP, sep = ":"))

#gwas.results$Probe.hg38 = paste(gwas.results$CHR, gwas.results$BP, sep = ":")

# UCSC BED files are 0-indexed
# this means that BP corresponds to END
# and that START is the base position prior to BP
roh.bed = data.table(
    "CHR" = paste0("chr", roh.results$CHR),
    "START" = roh.results$BP - 1,
    "END" = roh.results$BP,
    "NAME" = roh.results$Probe
)

# will finagle ROH basepair positions from hg19 to hg38
# entails creating a BED file from ROH results
# then sending it to CrossMap (a Python tool)
# and reading the result back into R for processing

# start with file names
hg19.bedfile.path = file.path(output.dir, paste(pheno.name, pop.code, "roh.markers.hg19.bed", sep = "."))
hg38.bedfile.path = file.path(output.dir, paste(pheno.name, pop.code, "roh.markers.hg38.bed", sep = "."))

# write hg19 BED file to disk, with no header
fwrite(roh.bed, file = hg19.bedfile.path, sep = "\t", col.names = FALSE, quote = FALSE)

# make a system call for CrossMap
crossmap.command = paste(
    "CrossMap.py bed",
    liftover.map.path,
    hg19.bedfile.path,
    hg38.bedfile.path,
    sep = " "
) 

# run CrossMap and wait for it to finish
system(crossmap.command)

# read CrossMap'd coordinates
# need to strip the BED format for chromosome
# the regular expression parses the V1 col into "chr", "##", and "other" groups and keeps just the numbers
roh.markers.hg38.bed = fread(hg38.bedfile.path) %>%
    mutate(CHR = as.integer(gsub(x=V1, perl = TRUE, pattern = "(chr)([0-9]{1,2})(.*)", replacement = "\\2"))) %>%
    rename(BP = "V3", Probe = "V4") %>%
    dplyr::select(CHR, BP, Probe) %>%
    as.data.table

# add hg38 coordinates to roh.results
roh.results = roh.results %>%
    rename(BP.hg19 = "BP") %>%
    merge(., roh.markers.hg38.bed, by = c("CHR", "Probe"))

cat("roh.results\n\n")
print(head(roh.results))
cat("roh.markers.hg38.bed\n\n")
print(head(roh.markers.hg38.bed))
# merge GWAS, ROH p-values
roh.gwas.results = roh.results %>%
    rename(Probe.hg19 = "Probe") %>%
    mutate(Probe = paste(CHR, BP, sep = ":")) %>%
    merge(., gwas.results, by = c("CHR", "BP"))

# perform correlation test
roh.gwas.cortest = cor.test(x = roh.gwas.results$P.ROH, y = roh.gwas.results$P.GWAS, method = "spearman")

output = data.table(
    "Phenotype" = pheno.name,
    "Population" = pop.code,
    "Correlation" = roh.gwas.cortest$estimate,
    "P_value" = roh.gwas.cortest$p.value
)

output.file = file.path(output.dir, paste(pheno.name, pop.code, "roh.gwas.corrtest.txt", sep = "."))
fwrite(output, file = output.file, sep = "\t", quote = FALSE) 
