# DataJoin ---------------------------------------------------------------------
# Summary: join together multiple sources output into a single csv file
# Author: Grayson Boyer (gmboyer@asu.edu)
# Last updated: 1/18/2019
# Created for the ENKI project

# Start the timer:
ptm <- proc.time()

library(dplyr)

master_df <- read.csv(csv_filename, check.names = F, stringsAsFactors=F)

if(exists("run_AquaMine")){
    if(run_AquaMine){
        AM_out <- read.csv(paste0("aq_", AM_output_type, ".csv"), check.names = F, stringsAsFactors=F)
        master_df <- left_join(master_df, AM_out[, 2:ncol(AM_out)], by = c("Sample" = "Name"))
    }
}

if(exists("run_MineralMine")){
    if(run_MineralMine){
        MM_out <- read.csv(paste0("mineral_", MM_output_type, ".csv"), check.names = F, stringsAsFactors=F)
        master_df <- left_join(master_df, MM_out[, 2:ncol(MM_out)], by = c("Sample" = "Name"))
    }
}

if(exists("run_RedoxMine")){
    if(run_RedoxMine){
        RM_out <- read.csv(paste0("redox_", RM_output_type, ".csv"), check.names = F, stringsAsFactors=F)
        master_df <- left_join(master_df, RM_out[, 2:ncol(RM_out)], by = c("Sample" = "Name"))
    }
}

if(exists("run_MiscMine")){
    if(run_MiscMine){
        MiscM_out <- read.csv("MiscMine_output.csv", check.names = F, stringsAsFactors=F)
        master_df <- left_join(master_df, MiscM_out[, 2:ncol(MiscM_out)], by = c("Sample" = "Name"))
    }
}

if(exists("run_EnergyMine")){
    if(run_EnergyMine){
        EM_out <- read.csv("rxn_affinity_energy.csv", check.names = F, stringsAsFactors=F)
        master_df <- left_join(master_df, EM_out[, 2:ncol(EM_out)], by = c("Sample" = "Name"))
    }
}

write.csv(master_df, filename_join, row.names=FALSE)

this_time <- proc.time() - ptm                             

print(paste("Join finished! Took", round(this_time["elapsed"], 1), "seconds."))