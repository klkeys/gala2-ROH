# ROH association analysis pipeline
Association testing with ROH segments 


## Overview

This pipeline performs a genome-wide association analysis over genotyped encoded with their presence within an ROH or not.


## Data

Data were taken from the [GALA II](https://www.ncbi.nlm.nih.gov/projects/gap/cgi-bin/study.cgi?study_id=phs001180.v1.p1) and [SAGE](https://www.ncbi.nlm.nih.gov/projects/gap/cgi-bin/study.cgi?study_id=phs000921.v4.p1) pediatric cohort studies of asthma and related lung disease traits. Data access can be requested through NIH dbGaP.

ROH segments were called with [GARLIC](https://github.com/szpiech/garlic)([Szpiech et al. 2017](https://www.ncbi.nlm.nih.gov/pubmed/28205676)), which implements the ROH model of [Pemberton et al. 2012](https://www.ncbi.nlm.nih.gov/pubmed/22883143).

Each SNP is marked as lying within an ROH (1) or not (0) -- a crude comparison is to a recessive allele model -- and association tests are performed against these binary data.


## Execution

Files `.env.sh` (in the git root directory of this repository) and `parse_phenotype_data.R` require modification prior to execution.
In particular, these scripts require file paths to genotype and ROH data.

Assuming that scripts can see the correct directory paths to data, then analyses are simple to run.
First, parse phenotypes and covariates by running the following command in a terminal:
```bash
./parse_phenotype_data.sh
```
Run the association analysis with
```bash
./run_roh_association_analysis.sh
```
This will run association tests in parallel.
