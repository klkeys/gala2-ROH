library(data.table)
library(dplyr)
library(optparse)


# parse command line variables
option_list = list(
    make_option(
        c("-a", "--ROH-file"),
        type    = "character",
        default = NULL, 
        help    = "The directory path to the ROH dosages for one pop and one chr", 
        metavar = "character"
    ),
    make_option(
        c("-b", "--output-directory"),
        type    = "character",
        default = NULL, 
        help    = "Directory where output files will be stored.", 
        metavar = "character"
    ),
    make_option(
        c("-c", "--local-ancestry-file"),
        type    = "character",
        default = NULL, 
        help    = "The directory path to the local ancestry estimates for one pop and one chr", 
        metavar = "character"
    ),
    make_option(
        c("-d", "--results-file"),
        type    = "character",
        default = NULL, 
        help    = "The directory path where results will be saved", 
        metavar = "character"
    ),
    make_option(
        c("-e", "--chromosome"),
        type    = "numeric",
        default = NULL, 
        help    = "Chromosome number for current file (e.g. '1')",
        metavar = "numeric"
    ),
    make_option(
        c("-f", "--population"),
        type    = "character",
        default = NULL, 
        help    = "Population acronym (e.g. 'AA', 'MX', or 'PR') for current file",
        metavar = "numeric"
    )
)

opt_parser = OptionParser(option_list = option_list)
opt = parse_args(opt_parser, convert_hyphens_to_underscores = TRUE)

#cat("Parsed options:\n\n")
#print(opt)

roh.file  = opt$ROH_file 
outdir    = opt$output_directory 
lanc.file = opt$local_ancestry_file
outfile   = opt$results_file 
chr       = as.numeric(opt$chromosome)
pop       = opt$population 



# load ROH file
# need to rejigger some columns; in particular, chr/pos are misspecified, and pos contains a bunch of missing values
roh = fread(roh.file) %>%
    dplyr::select(-pos) %>%
    rename(Chromosome = "V1", Position = "chr") %>%
    mutate(
        Chromosome = as.integer(Chromosome),
        Position  = as.integer(Position)
    ) %>%
    as.data.table %>%
    melt(., id.vars = c("Chromosome", "Position"), variable.name = "SubjectID", value.name = "ROH_Dosage") %>%
    dplyr::select(Chromosome, Position, SubjectID, ROH_Dosage) %>%
    as.data.table

# load local ancestry file
# need to adjust header since column names are misspecified
lanc = fread(lanc.file, header = TRUE) %>%
    melt(., id.vars = "pos", variable.name = "position", value.name = "Local_Ancestry_Value") %>%
    rename(SubjectID = "pos") %>%
    mutate(
        Chromosome = chr,
        Position = type.convert(position)
    ) %>% 
    dplyr::select(Chromosome, Position, SubjectID, Local_Ancestry_Value) %>%
    as.data.table

# merge results and add pop label
roh.lanc = merge(roh, lanc, by = c("Chromosome", "Position", "SubjectID")) %>%
    mutate(Population = pop) %>%
    dplyr::select(Chromosome, Position, Population, SubjectID, ROH_Dosage, Local_Ancestry_Value) %>%
    as.data.table

# save result to file
# nixing header will allow for easy concatenation at command line
fwrite(roh.lanc, file = outfile, sep = "\t", quote = FALSE, col.names = FALSE)
