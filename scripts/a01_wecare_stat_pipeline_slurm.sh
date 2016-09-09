#!/bin/bash

# skat_pipeline_slurm.sh
# Run skat pipeline for wecare dataset
# Alexey Larionov, 08Sep2016
# Use: sbatch stat_pipeline_slurm.sh job_description.txt

# ---------------------------------------- #
#           sbatch instructions            #
# ---------------------------------------- #

#SBATCH -J wecare_stat_pipeline
#SBATCH -A TISCHKOWITZ-SL2
#SBATCH --nodes=1
#SBATCH --exclusive
#SBATCH --mail-type=ALL
#SBATCH --no-requeue
#SBATCH -p sandybridge

#SBATCH --time=01:00:00
#SBATCH --qos=INTR
#SBATCH --output filter_genotypes.log

# Stop on errors
set -e

# Modules section (required, do not remove)
. /etc/profile.d/modules.sh
module purge
module load default-impi
module load gcc/5.2.0
module load boost/1.50.0
module load texlive/2015
module load pandoc/1.15.2.1

# Set initial working folder
cd "${SLURM_SUBMIT_DIR}"

# Report settings
echo "Job id: ${SLURM_JOB_ID}"
echo "Job name: ${SLURM_JOB_NAME}"
echo "Allocated node: $(hostname)"
echo "Initial working folder:"
echo "${SLURM_SUBMIT_DIR}"
echo ""
echo " ------------------ Output ------------------ "
echo ""
echo "Started pipeline: $(date +%d%b%Y_%H:%M:%S)"
echo ""

# Job description file name
job_file="${1}"

#--------------------------------------------------#
#   Read parameters from the job description file  #
#--------------------------------------------------#

scripts_folder=$(awk '$1=="scripts_folder:" {print $2}' "${job_file}")
project_folder=$(awk '$1=="project_folder:" {print $2}' "${job_file}")
source_data_folder="${project_folder}/source_data"
prefix=$(awk '$1=="prefix:" {print $2}' "${job_file}")
steps=$(awk '$1=="steps:" {print}' "${job_file}")
interim_data_folder="${project_folder}/interim_data"
priority_genes_folder="${project_folder}/gene_lists"
results_folder="${project_folder}/results"
logs_folder="${project_folder}/logs"
r_libs_folder=$(awk '$1=="r_libs_folder:" {print $2}' "${job_file}")
r_bin_folder=$(awk '$1=="r_bin_folder:" {print $2}' "${job_file}")
r="${r_bin_folder}/R"

min_dp=$(awk '$1=="min_dp:" {print $2}' "${job_file}")
max_dp=$(awk '$1=="max_dp:" {print $2}' "${job_file}")
min_gq=$(awk '$1=="min_gq:" {print $2}' "${job_file}")
hets_filter_type=$(awk '$1=="hets_filter_type:" {print $2}' "${job_file}")
hets_filter_threshold=$(awk '$1=="hets_filter_threshold:" {print $2}' "${job_file}")
homs_max_frma=$(awk '$1=="homs_max_frma:" {print $2}' "${job_file}")

min_call_rate=$(awk '$1=="min_call_rate:" {print $2}' "${job_file}")

data_subset=$(awk '$1=="data_subset:" {print $2}' "${job_file}")
gene_groups=$(awk '$1=="gene_groups:" {print $2}' "${job_file}")

#--------------------------------------------------#
#          Report parameters for the job           #
#--------------------------------------------------#

echo " ----- Job settings ----- "
echo ""
echo "scripts_folder: ${scripts_folder}" # e.g. /scratch/medgen/scripts/wecare_stat_09.16/scripts
echo "project_folder: ${project_folder}" # e.g. /scratch/medgen/users/alexey/wecare_stat_sep2016
echo "source_data_folder: ${source_data_folder}"
echo "prefix: ${prefix}" # e.g. IGP_L1_vqsr_shf_sma_ann
echo "steps: ${steps}" # e.g. steps: read calculate
echo "interim_data_folder: ${interim_data_folder}"
echo "priority_genes_folder: ${priority_genes_folder}"
echo "results_folder: ${results_folder}"
echo "logs_folder: ${logs_folder}"
echo "r_libs_folder: ${r_libs_folder}" # e.g. "/scratch/medgen/tools/r/R-3.2.2/lib64/R/library/"
echo "r_bin_folder: ${r_bin_folder}" # e.g. "/scratch/medgen/tools/r/R-3.2.2/bin"
echo "r: ${r}" # e.g. "/scratch/medgen/tools/r/R-3.2.2/bin/R"
echo ""
echo "min_dp: ${min_dp}" # e.g. 10
echo "max_dp: ${max_dp}" # e.g. 500
echo "min_gq: ${min_gq}" # e.g. 20
echo "hets_filter_type: ${hets_filter_type}" # e.g. probability
echo "hets_filter_threshold: ${hets_filter_threshold}" # e.g. 0.05
echo "homs_max_frma: ${homs_max_frma}" # e.g. 0.05
echo ""
echo "min_call_rate: ${min_call_rate}" # e.g. 0.8
echo ""
echo "data_subset: ${data_subset}" # e.g. priority_genes_strict
echo "gene_groups: ${gene_groups}" # Can be "dna_repair,bc_risk,bc_somatic,es_related"
echo ""
echo " ------------------------ "

#--------------------------------------------------#
#                  Read source data                #
#--------------------------------------------------#
# ~ 1hr for filtered wecare ?

# Progress report
echo "Started reading data: $(date +%d%b%Y_%H:%M:%S)"

#######################
if [[ "${steps}" == *"read_data"* ]]; then
#######################

# R script name
r_script="${scripts_folder}/s01_read_data_sep2016.Rmd"

# Report name
r_script_name=$(basename "${r_script}")
html_report="${logs_folder}/${r_script_name%.Rmd}.html"

# Compile R expression to run (commnds are in single line, separated by semicolon)
r_expressions="library('rmarkdown', lib='"${r_libs_folder}/"'); render('"${r_script}"', params=list(source_data='"${source_data_folder}"', interim_data='"${interim_data_folder}"', prefix='"${prefix}"'), output_file='"${html_report}"')"

# Run R expressions
"${r}" -e "${r_expressions}"

#######################
fi
#######################

# Progress report
echo "Completed reading data: $(date +%d%b%Y_%H:%M:%S)"
echo ""
echo " ------------------------ "
echo ""

#--------------------------------------------------#
#                  Filter genotypes                #
#--------------------------------------------------#
# ~15 min 

# Progress report
echo "Started filtering genotypes: $(date +%d%b%Y_%H:%M:%S)"

#######################
if [[ "${steps}" == *"filter_genotypes"* ]]; then
#######################

# R script name
r_script="${scripts_folder}/s02_filter_genotypes_sep2016.Rmd"

# Report name
r_script_name=$(basename "${r_script}")
html_report="${logs_folder}/${r_script_name%.Rmd}.html"

# Compile R expression to run (commnds are in single line, separated by semicolon)
r_expressions="library('rmarkdown', lib='"${r_libs_folder}/"'); render('"${r_script}"', params=list(interim_data='"${interim_data_folder}"', min_dp='"${min_dp}"', max_dp='"${max_dp}"', min_gq='"${min_gq}"', hets_filter_type='"${hets_filter_type}"', hets_filter_threshold='"${hets_filter_threshold}"', homs_max_frma='"${homs_max_frma}"', min_call_rate='"${min_call_rate}"'), output_file='"${html_report}"')"

# Run R expressions
"${r}" -e "${r_expressions}"

#######################
fi
#######################

# Progress report
echo "Completed filtering genotypes: $(date +%d%b%Y_%H:%M:%S)"
echo ""
echo " ------------------------ "
echo ""

#--------------------------------------------------#
#                  Filter by effect                #
#--------------------------------------------------#
# ~5 min

# Progress report
echo "Started filtering by effect: $(date +%d%b%Y_%H:%M:%S)"

#######################
if [[ "${steps}" == *"filter_by_effect"* ]]; then
#######################

# R script name
r_script="${scripts_folder}/s04_filter_by_effect_feb2016.Rmd"

# Report name
r_script_name=$(basename "${r_script}")
html_report="${logs_folder}/${r_script_name%.Rmd}.html"

# Compile R expression to run (commnds are in single line, separated by semicolon)
r_expressions="library('rmarkdown', lib='"${r_libs_folder}/"'); render('"${r_script}"', params=list(interim_data='"${interim_data_folder}"', priority_genes='"${priority_genes_folder}"'), output_file='"${html_report}"')"

# Run R expressions
"${r}" -e "${r_expressions}"

#######################
fi
#######################

# Progress report
echo "Completed filtering by effect: $(date +%d%b%Y_%H:%M:%S)"
echo ""
echo " ------------------------ "
echo ""

#--------------------------------------------------#
#                   Reshape data                   #
#--------------------------------------------------#
# ~5 min

# Progress report
echo "Started reshaping data: $(date +%d%b%Y_%H:%M:%S)"

#######################
if [[ "${steps}" == *"reshape_data"* ]]; then
#######################

# R script name
r_script="${scripts_folder}/s05_reshape_data_feb2016.Rmd"

# Report name
r_script_name=$(basename "${r_script}")
html_report="${logs_folder}/${r_script_name%.Rmd}_${data_subset}.html"

# Compile R expression to run (commnds are in single line, separated by semicolon)
r_expressions="library('rmarkdown', lib='"${r_libs_folder}/"'); render('"${r_script}"', params=list(interim_data='"${interim_data_folder}"', subset='"${data_subset}"'), output_file='"${html_report}"')"

# Run R expressions
"${r}" -e "${r_expressions}"

#######################
fi
#######################

# Progress report
echo "Completed reshaping data: $(date +%d%b%Y_%H:%M:%S)"
echo ""
echo " ------------------------ "
echo ""

#--------------------------------------------------#
#                  Calculate afs                   #
#--------------------------------------------------#
# ~5 min

# Progress report
echo "Started calculating afs: $(date +%d%b%Y_%H:%M:%S)"

#######################
if [[ "${steps}" == *"recalculate_afs"* ]]; then
#######################

# R script name
r_script="${scripts_folder}/s06_recalculate_afs_feb2016.Rmd"

# Report name
r_script_name=$(basename "${r_script}")
html_report="${logs_folder}/${r_script_name%.Rmd}_${data_subset}.html"

# Compile R expression to run (commnds are in single line, separated by semicolon)
r_expressions="library('rmarkdown', lib='"${r_libs_folder}/"'); render('"${r_script}"', params=list(interim_data='"${interim_data_folder}"', subset='"${data_subset}"'), output_file='"${html_report}"')"

# Run R expressions
"${r}" -e "${r_expressions}"

#######################
fi
#######################

# Progress report
echo "Completed calculating afs: $(date +%d%b%Y_%H:%M:%S)"
echo ""
echo " ------------------------ "
echo ""

#--------------------------------------------------#
#             Calculate variants glm               #
#--------------------------------------------------#
# ~5 min

# Progress report
echo "Started calculating variants glm: $(date +%d%b%Y_%H:%M:%S)"

#######################
if [[ "${steps}" == *"variants_glm"* ]]; then
#######################

# R script name
r_script="${scripts_folder}/s07_variants_glm_feb2016.Rmd"

# Report name
r_script_name=$(basename "${r_script}")
html_report="${logs_folder}/${r_script_name%.Rmd}_${data_subset}.html"

# Compile R expression to run (commnds are in single line, separated by semicolon)
r_expressions="library('rmarkdown', lib='"${r_libs_folder}/"'); render('"${r_script}"', params=list(interim_data='"${interim_data_folder}"', subset='"${data_subset}"', results_folder='"${results_folder}"'), output_file='"${html_report}"')"

# Run R expressions
"${r}" -e "${r_expressions}"

#######################
fi
#######################

# Progress report
echo "Completed calculating variants glm: $(date +%d%b%Y_%H:%M:%S)"
echo ""
echo " ------------------------ "
echo ""

#--------------------------------------------------#
#              Calculate genes skat                #
#--------------------------------------------------#
# Up to overnight - depends on size of data subset

# Progress report
echo "Started calculating genes skat: $(date +%d%b%Y_%H:%M:%S)"

#######################
if [[ "${steps}" == *"genes_skat"* ]]; then
#######################

# R script name
r_script="${scripts_folder}/s08_genes_SKAT_feb2016.Rmd"

# Report name
r_script_name=$(basename "${r_script}")
html_report="${logs_folder}/${r_script_name%.Rmd}_${data_subset}.html"

# Compile R expression to run (commnds are in single line, separated by semicolon)
r_expressions="library('rmarkdown', lib='"${r_libs_folder}/"'); render('"${r_script}"', params=list(interim_data='"${interim_data_folder}"', subset='"${data_subset}"', results_folder='"${results_folder}"', scripts_folder='"${scripts_folder}"'), output_file='"${html_report}"')"

# Run R expressions
"${r}" -e "${r_expressions}"

#######################
fi
#######################

# Progress report
echo "Completed calculating genes skat: $(date +%d%b%Y_%H:%M:%S)"
echo ""
echo " ------------------------ "
echo ""

#--------------------------------------------------#
#            Calculate gene groups skat            #
#--------------------------------------------------#
# ~5 min

# Progress report
echo "Started calculating gene groups skat: $(date +%d%b%Y_%H:%M:%S)"

#######################
if [[ "${steps}" == *"groups_skat"* ]]; then
#######################

# R script name
r_script="${scripts_folder}/s09_groups_SKAT_feb2016.Rmd"

# Report name
r_script_name=$(basename "${r_script}")
html_report="${logs_folder}/${r_script_name%.Rmd}_${data_subset}.html"

# Compile R expression to run (commnds are in single line, separated by semicolon)
r_expressions="library('rmarkdown', lib='"${r_libs_folder}/"'); render('"${r_script}"', params=list(interim_data='"${interim_data_folder}"', subset='"${data_subset}"', results_folder='"${results_folder}"', scripts_folder='"${scripts_folder}"', gene_groups='"${gene_groups}"'), output_file='"${html_report}"')"

# Run R expressions
"${r}" -e "${r_expressions}"

#######################
fi
#######################

# Progress report
echo "Completed calculating groups skat: $(date +%d%b%Y_%H:%M:%S)"
echo ""
echo " ------------------------ "
echo ""

#--------------------------------------------------#

# Completion message
echo "Completed pipeline: $(date +%d%b%Y_%H:%M:%S)"
