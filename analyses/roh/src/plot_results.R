library(data.table)
library(dplyr)
library(ggplot2)

x = fread("GALA_SAGE_ROH_merged_phenotypes.txt")

g1 = x %>% 
    dplyr::select(SubjectID, Pop_Code, AFR, EUR, NAM) %>%
    rename(AMR = "NAM") %>%
    dplyr::filter(!is.na(AFR)) %>%
    group_by(Pop_Code) %>% 
    arrange(Pop_Code, desc(AMR), desc(EUR), desc(AFR)) %>% 
    mutate(ID = row_number(Pop_Code)) %>%  
    dplyr::select(-SubjectID) %>% as.data.table %>% 
    melt(., id.vars = c("ID", "Pop_Code"), variable.name = "Ancestry", value.name = "Ancestry_Prop") %>%
    group_by(Pop_Code) %>%
    as.data.table %>%
    ggplot(., aes(x = ID, y = Ancestry_Prop, fill = Ancestry)) +
        geom_bar(position = "fill", stat = "identity") +
        facet_grid(rows = vars(Pop_Code)) +
        xlab("Subject Number") +
        ylab("Ancestry Proportion") +
        ggtitle("Global Genetic Ancestry Proportions in GALA II and SAGE") +
        scale_fill_manual(name = "Ancestry", values = c("AFR" = "blue", "EUR" = "red", "AMR" = "goldenrod"))

# save plots in various formats
ggsave(plot = g1, file = "gala_sage_global_genetic_ancestry.png",  units = "in", width = 18, height = 11)
ggsave(plot = g1, file = "gala_sage_global_genetic_ancestry.pdf",  units = "in", width = 18, height = 11)
ggsave(plot = g1, file = "gala_sage_global_genetic_ancestry.tiff", units = "in", width = 18, height = 11)
