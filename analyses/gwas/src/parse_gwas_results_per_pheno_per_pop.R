# ==========================================================================================
# libraries
# ==========================================================================================
suppressPackageStartupMessages(library(dplyr, quietly = TRUE))
suppressPackageStartupMessages(library(ggplot2, quietly = TRUE))
suppressPackageStartupMessages(library(data.table, quietly = TRUE))
suppressPackageStartupMessages(library(here, quietly = TRUE))
suppressPackageStartupMessages(library(optparse, quietly = TRUE))
#suppressPackageStartupMessages(library(svglite, quietly = TRUE)) ## for saving SVG format graphics
suppressPackageStartupMessages(library(methods, quietly = TRUE)) ## for saving SVG format graphics


# parse command line variables
option_list = list(
    make_option(
        c("-r", "--results-file"),
        type    = "character",
        default = NULL,
        help    = "The file path to one gzipped GWAS results file", 
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
        c("-e", "--set-R-environment"),
        type    = "character",
        default = "~/Git/gala2-ROH/analyses/roh/src/R/set_R_environment.R",
        help    = "Path to R environment script [default: %default]",
        metavar = "character"
    ),
    make_option(
        c("-p", "--plotting-routines"),
        type    = "character",
        default = "~/Git/gala2-ROH/analyses/roh/src/R/plotting_routines.R",
        help    = "Path to R environment script [default: %default]",
        metavar = "character"
    ),
    make_option(
        c("-f", "--plot-filetype"),
        type    = "character",
        default = "pdf",
        help    = "Filetype for producing plots, e.g. 'pdf' or 'png' [default: %default]",
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

# use these dictionaries to translate phenotype and pop names for plotting
phenotype.names = list(
    "Asthma_Status" = "Asthma Status",
    "Pre_FEV1"      = "Pre-FEV1",
    "Post_FEV1"     = "Post-FEV1",
    "BDR"           = "BDR",
    "Pre_FVC"       = "Pre-FVC",
    "FVC"           = "Pre-FVC"
)

pop.names = list(
    "AA" = "African Americans",
    "MX" = "Mexican Americans",
    "PR" = "Puerto Ricans"
)

# taken from ggplot2 cookbook: http://www.cookbook-r.com/Graphs/Colors_(ggplot2)/
# AA is reddish purple 
# MX is orange
# PR is bluish green
plot.colors = list(
    "AA" = "#CC79A7",
    "MX" = "#E69F00",
    "PR" = "#009E73"
)

# parse options
results.file  = opt$results_file 
output.dir    = opt$output_directory
plot.filetype = opt$plot_filetype 
R.environment = opt$set_R_environment
plot.routines = opt$plotting_routines

# read source code (environment script and plotting routines)
source(R.environment)
source(plot.routines)

# read results from results.file path
x = fread(results.file)

# ensure linear ordering: sort by chr, then by base pair
setkey(x, CHR, BP)
setorder(x, CHR, BP)

# parse phenotype name and population code from file path
results.filename = dplyr::last(unlist(strsplit(results.file, split = "/", fixed = TRUE)))
results.filename.parts = strsplit(x = results.filename, split = ".", fixed = TRUE)

# phenotype name is 1st part of file path
# population code is the 3rd
pheno.name = results.filename.parts[[1]][1]
pop.code   = results.filename.parts[[1]][3]

# get plotting color based on population code
secondary.plot.color = plot.colors[[pop.code]] 

# purge any rows with missing values
# cannot compute summary stats on NA
x = na.omit(x)

# add column of -log10(P)
x$logP = -log10(x$P)

# results files are generally too big to run through coda in one go
# can parse by chromosome and incrementally count total number of effective tests
effective.number.of.tests = 0
for (chr in c(1:22)){
    #x.chr = x %>% dplyr::filter(CHR == chr);
    #effective.number.of.tests = effective.number.of.tests + as.numeric(effectiveSize(x.chr$logP));
    log.p = x %>%
        dplyr::filter(CHR == chr) %>%
        dplyr::select(logP) %>%
        unlist

    effective.number.of.tests = effective.number.of.tests + as.numeric(effectiveSize(log.p));
}

# clean up to keep memory banks free
rm(log.p)
gc()

# Bonferroni correction: divide alpha level(0.05) by the number of independent test
significance.threshold = 0.05/effective.number.of.tests

# -log10 transform the Bonferroni threshold
#transformation = -log10(significance.threshold)

# compute the suggestive threshold
suggestive.threshold = 1/(2*effective.number.of.tests)

# compile summary statistics and save to file
# file will be 1 row, no header
# easy to concatenate them later
summstats.name = paste(pheno.name, pop.code, "summstats", sep = ".")
summstats.file = file.path(output.dir, paste(summstats.name, "txt", sep = "."))
summstats = as.data.table(t(c(pheno.name, pop.code, nrow(x), effective.number.of.tests, significance.threshold, suggestive.threshold)))
fwrite(summstats, file = summstats.file, row.names = FALSE, col.names = FALSE, sep = "\t", quote = FALSE)

# assign memorable name for summary stats table
assign(summstats.name, summstats)

# create manhattan plot
manhattan.plot.filepath = paste(pheno.name, pop.code, "manhattan", plot.filetype, sep = ".")
g1 = CreateManhattanPlot(x,
    ylims  = c(0,10),
    color  = c("black", secondary.plot.color),
    x.drop = c(15,17,19,21),
    title  = paste(phenotype.names[[pheno.name]], "in", pop.names[[pop.code]] , sep = " "),
    significance.threshold = significance.threshold,
    suggestive.threshold   = suggestive.threshold,
    label.threshold        = 1e-16,
    save.as     = manhattan.plot.filepath,
    plot.width  = 11,
    plot.height = 8,
    plot.units  = "in"
)

# make memorable name for plot, using pheno and pop to make it unique
g1.plot.name = paste(pheno.name, pop.code, "manhattan", sep = ".")
assign(g1.plot.name, g1)

# make QQ plot
qq.plot.filepath = paste(pheno.name, pop.code, "qq", plot.filetype, sep = ".")
g2 = CreateQQPlot(x,
    title = paste(phenotype.names[[pheno.name]], "in", pop.names[[pop.code]] , sep = " "),
    save.as     = qq.plot.filepath,
    plot.width  = 7,
    plot.height = 7,
    plot.units  = "in"
)

# need memorable name for qq plot
g2.plot.name = paste(pheno.name, pop.code, "qq", sep = ".")
assign(g2.plot.name, g2)

# save plots and summary stats to Rdata object
# this allows us to manipulate and replot later
# nota bene: Rdata saving function here uses a character vector to refer to objects
# this is jerryrigged way of programmatically writing something like:
# > save(Asthma_Stats.AA.manhattan, Asthma_Status.AA.qq, Asthma_Status.AA.summstats, file = "Asthma_Status.AA.plots.Rdata")
rdata.filepath = paste(pheno.name, pop.code, "plots", "Rdata", sep = ".")
save(list = c(g1.plot.name, g2.plot.name, summstats.name), file = rdata.filepath) 
