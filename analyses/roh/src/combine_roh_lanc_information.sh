#!/usr/bin/env bash

set -u
set -o

RSCRIPT="/usr/local/bin/Rscript"
R_combine_roh_lanc="combine_roh_lanc_information.R"

outdir="${HOME}/Box/gala_sage_roh/roh/results"
roh_datadir="${HOME}/Box/gala_sage_roh/roh/results/ROH/dosage"
lanc_datadir="${HOME}/Box/gala_sage_roh/roh/results/Local_Ancestry/dosage"
resultsdir="${HOME}/Box/gala_sage_roh/roh/results"
results_pfx="merged_roh_lanc"
#gala_pfx="GALA2_mergedLAT-LATP_noParents_030816_MX.22.ROH.R.out.gz"
gala_pfx="GALA2_mergedLAT-LATP_noParents_030816"
sage_pfx="SAGE_mergedLAT-LATP_030816"
lanc_pfx="merged_ref_gala2_sage2_from_latplus_biallelic_filtered"
lanc_sfx="phased.anc.category.txt.gz"
pops=("AA" "MX" "PR")
chrs=`seq 1 22`
#chrs=(22)
#pops=("AA")

#for pop in ${pops[@]}; do 
#	pfx=${gala_pfx}
#	if [[ ${pop} == "AA" ]]; then
#		pfx=${sage_pfx}
#	fi 
#    echo "constructing results file for pop ${pop}..."
#    for chr in ${chrs[@]}; do
#		rohfile="${roh_datadir}/${pfx}_${pop}.${chr}.ROH.R.out.gz"
#		lancfile="${lanc_datadir}/${lanc_pfx}_chr${chr}_${pop}_${lanc_sfx}"	
#		if [[ ${pop} == "AA" ]]; then
#			rohfile="${roh_datadir}/${pfx}.${chr}.ROH.R.out.gz"
#		fi
#        resultsfile="${outdir}/${results_pfx}.${pop}.${chr}.txt.gz"
#        echo -e "\tchr ${chr}..."
#        $RSCRIPT $R_combine_roh_lanc \
#            --ROH-file ${rohfile} \
#            --local-ancestry-file ${lancfile} \
#            --results-file ${resultsfile} \
#            --output-directory ${outdir} \
#            --chromosome ${chr} \
#            --population ${pop}
#    done
#    echo -e "... pop ${pop} done.\n\n"
#done

for pop in ${pops[@]}; do
    resultsfile="${resultsdir}/${results_pfx}.${pop}.ALLCHR.txt"
    echo "constructing results file for pop ${pop} at ${resultsfile}..."
    cp "${resultsdir}/${results_pfx}.${pop}.1.txt.gz" ${resultsfile}
    for chr in $(seq 2 22); do
        echo -e "\tchr ${chr}..."
        gzip -c  "${resultsdir}/${results_pfx}.${pop}.${chr}.txt.gz" >> ${resultsfile}
    done
#    echo -e "\tgzipping ${resultsfile}..."
#    gzip -9 ${resultsfile}
    echo -e "...done.\n\n"
done
