# ==========================================================================================
# load libraries
# ==========================================================================================
library(data.table)
library(dplyr)
library(ggplot2)
library(cowplot)

# ==========================================================================================
# subroutines
# ==========================================================================================


# ==========================================================================================
# script variables 
# ==========================================================================================

aa.roh.file = "~/Box/gala_sage_roh/roh/results/ROH/SAGE_mergedLAT-LATP_030816.roh.coverage"
mx.roh.file = "~/Box/gala_sage_roh/roh/results/ROH/GALA2_mergedLAT-LATP_noParents_030816_MX.roh.coverage"
pr.roh.file = "~/Box/gala_sage_roh/roh/results/ROH/GALA2_mergedLAT-LATP_noParents_030816_PR.roh.coverage"

# Mbp is simply a synonym for 1e6
Mbp  = 1000000
seed = 2020

# fix random seed
set.seed(seed)

# taken from ggplot2 cookbook: http://www.cookbook-r.com/Graphs/Colors_(ggplot2)/
# AA is reddish purple
# MX is orange
# PR is bluish green
plot.colors = c(
    "AA" = "#CC79A7",
    "MX" = "#E69F00",
    "PR" = "#009E73"
)

line.types = c(
    "AA" = "solid",
    "MX" = "dashed",
    "PR" = "dotted"
)

# ==========================================================================================
# wrangle data 
# ==========================================================================================

# load ROH estimates
AA = fread(aa.roh.file)
MX = fread(mx.roh.file)
PR = fread(pr.roh.file)

# want to add more explicit names to results
# rescale ROH segment lengths to megabasepairs
AA = AA %>%
    rename(
        ID  = "V1",
    )%>%
    mutate(
        Pop = "AA",
        ROH_A = A / Mbp,
        ROH_B = B / Mbp,
        ROH_C = C / Mbp,
        ROH_TOTAL = TOTAL / Mbp
    ) %>%
	dplyr::select(ID, Pop, ROH_A, ROH_B, ROH_C, ROH_TOTAL) %>%
    as.data.table

MX = MX %>%
    rename(
        ID  = "V1",
    )%>%
    mutate(
        Pop = "MX",
        ROH_A = A / Mbp,
        ROH_B = B / Mbp,
        ROH_C = C / Mbp,
        ROH_TOTAL = TOTAL / Mbp
    ) %>%
	dplyr::select(ID, Pop, ROH_A, ROH_B, ROH_C, ROH_TOTAL) %>%
    as.data.table

PR = PR %>%
    rename(
        ID  = "V1",
    )%>%
    mutate(
        Pop = "PR",
        ROH_A = A / Mbp,
        ROH_B = B / Mbp,
        ROH_C = C / Mbp,
        ROH_TOTAL = TOTAL / Mbp
    ) %>%
	dplyr::select(ID, Pop, ROH_A, ROH_B, ROH_C, ROH_TOTAL) %>%
    as.data.table

# concatenate data tables together to make one table
roh = rbind(AA, MX, PR) %>%
	mutate(Pop = factor(Pop, levels = c("AA", "PR", "MX"))) %>%
	as.data.table

# ==========================================================================================
# create plots
# ==========================================================================================

y.range = range(roh$ROH_TOTAL)

g.total = ggplot(roh, aes(x = Pop, y = ROH_TOTAL)) + 
    geom_violin(aes(fill = Pop), color = "black", adjust = 5, scale = "width") +
    geom_boxplot(width = 0.1, fill = "white", outlier.shape = NA) +
    xlab("Population") +
    ylab("Total Genomic ROH (Mbps)") +
    coord_cartesian(ylim = y.range) +
    scale_fill_manual(name = "Pop", values = plot.colors, breaks = c("AA", "PR", "MX")) +
	theme(legend.position = "none")

g.a = ggplot(roh, aes(x = Pop, y = ROH_A)) + 
    geom_violin(aes(fill = Pop), color = "black", adjust = 5, scale = "width") +
    geom_boxplot(width = 0.1, fill = "white", outlier.shape = NA) +
    xlab("Population") +
    ylab("Total Genomic Short ROH (Mbps)") +
    coord_cartesian(ylim = y.range) +
    scale_fill_manual(name = "Pop", values = plot.colors, breaks = c("AA", "PR", "MX")) +
	theme(legend.position = "none")

g.b = ggplot(roh, aes(x = Pop, y = ROH_B)) + 
    geom_violin(aes(fill = Pop), color = "black", adjust = 5, scale = "width") +
    geom_boxplot(width = 0.1, fill = "white", outlier.shape = NA) +
    xlab("Population") +
    ylab("Total Genomic Medium ROH (Mbps)") +
    coord_cartesian(ylim = y.range) +
    scale_fill_manual(name = "Pop", values = plot.colors, breaks = c("AA", "PR", "MX")) +
	theme(legend.position = "none")

g.c = ggplot(roh, aes(x = Pop, y = ROH_C)) + 
    geom_violin(aes(fill = Pop), color = "black", adjust = 5, scale = "width") +
    geom_boxplot(width = 0.1, fill = "white", outlier.shape = NA) +
    xlab("Population") +
    ylab("Total Genomic Long ROH (Mbps)") +
    coord_cartesian(ylim = y.range) +
    scale_fill_manual(name = "Pop", values = plot.colors, breaks = c("AA", "PR", "MX")) +
	theme(legend.position = "none")

# arrange the four plots in a 2x2 grid
roh.distributions = plot_grid(g.a, g.b, g.c, g.total, labels = "AUTO", ncol = 2)

# save multipanel plot to file
roh.distributions.filepath = "~/Box/gala_sage_roh/roh/figures/roh.distributions.perpop.png"
ggsave(roh.distributions, file = roh.distributions.filepath, width = 7, height = 7, unit = "in", dpi = 300)

### now plot kernel density summary of ROH lengths
roh.melt = melt(roh, id.vars = c("ID", "Pop"), variable.name = "ROH_Class", value.name = "ROH_Length") %>% as.data.table

roh.densities = ggplot(roh.melt, aes(x = ROH_Length, color = Pop, linetype = Pop)) +
	geom_density(adjust = 7.5, size = 1.5) +
	xlab("ROH Lengths") +
	ylab("Density") +
    scale_color_manual(values = plot.colors) +
	scale_linetype_manual(values = line.types)

# save density summary plot to file
roh.densities.filepath = "~/Box/gala_sage_roh/roh/figures/roh.densities.perpop.png"
ggsave(roh.densities, file = roh.densities.filepath, width = 7, height = 7, unit = "in", dpi = 300)


#
## ==========================================================================================
## plot ROH with local ancestry information
## ==========================================================================================
#
#aa.lanc.filepath = "~/Box/gala_sage_roh/roh/results/Local_Ancestry/merged_ref_gala2_sage2_from_latplus_biallelic_filtered_chraut_AA_phased.lanc.imputed.bed"
#mx.lanc.filepath = "~/Box/gala_sage_roh/roh/results/Local_Ancestry/merged_ref_gala2_sage2_from_latplus_biallelic_filtered_chraut_MX_phased.lanc.imputed.bed"
#pr.lanc.filepath = "~/Box/gala_sage_roh/roh/results/Local_Ancestry/merged_ref_gala2_sage2_from_latplus_biallelic_filtered_chraut_PR_phased.lanc.imputed.bed"
#
## skip = 1: discard 1st line of BED files since that isn't a valid header
#aa.lanc = fread(aa.lanc.filepath, fill = TRUE, skip = 1)
