This is a set of scripts to do stat analysis in wecare dataset. 
The pipeline is deployed on a local university cluster.  
This repository is intended for the author's pesonal use. 
Version 09.16

The main steps include:
- Data import and check into R 
- Filtering genotypes + removing variants with low call rates after genotypes filtering
- Filtering by variant effect
- Reshaping phenotype annotations
- Re-calculating general AFs and calculating AFs in CBC and UBC subgroups
- Logisitc regression CBC vs UBC for individual variants
- Trend analysis CBC : UBC : Exac for individual variants
- SKAT analysis for genes 
- Aggregating AFs to genes and Trend analysis CBC : UBC : Exac for genes
