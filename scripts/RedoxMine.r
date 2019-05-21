# RedoxMine --------------------------------------------------------------------
# Summary: extract oxidation-reduction information from EQ3 output files
#   in the user's rxn_3o directory.
# Author: Grayson Boyer (gmboyer@asu.edu)
# Last updated: 10/23/2018
# Created for the ENKI project

# Start the timer:
ptm <- proc.time()

setwd("rxn_3o")

sample_files <- list.files()

master_df <- data.frame(sample=character(0),
                        Name=character(0),
                        stringsAsFactors=FALSE)

for(this_file in sample_files){

  # read .3o file as a string
  fileName <- this_file
  extractme <- readChar(fileName, file.info(fileName)$size) # readChar requires filesize, which is obtained from file.info()$size

  # getting name using sub()
  # 1. trim off everything before substring of interest
  name_trailing <- sub("^.*\\|Sample:\\s+", "", extractme)

  # 2. trim off everything after substring of interest
  this_name <- sub("\\|\\n\\|.*$", "", name_trailing) # trim file contents from name
  this_name <- sub("\\s+$", "", this_name) # trim off trailing spaces from name
    
  # bind to master data frame
  master_df[nrow(master_df)+1, ] <- rep(NA, ncol(master_df)) # create a new row
  master_df[nrow(master_df), "sample"] <- this_file
  master_df[nrow(master_df), "Name"] <- this_name


  # string to isolate the species saturation section:
  front_trim <- "^.*\n\n\n\n                --- Aqueous Redox Reactions ---\n\n   Couple                           Eh, volts      pe-      log fO2   Ah, kcal\n\n\\s+"

  # check if species block exists. If not, skip processing the file:
  if (grepl(front_trim, extractme) == FALSE){
    next # skip to next sample file
  }

  # trim off everything before:
  species_trailing <- sub(front_trim, "", extractme)
  # trim off everything after:
  species_block <- sub("\n\n.*$", "", species_trailing)
  # replace all commas with underscores
  species_block <- gsub(",", "_", species_block)
  # split into substrings, each representing a separate row in the table
  species_block <- strsplit(species_block, "\n")


  #create an empty data frame to store results
  df <- data.frame(couple = character(0),
                   Eh = numeric(0),
                   pe = numeric(0),
                   logfO2 = numeric(0),
                   Ah = numeric(0),
                   stringsAsFactors = FALSE)
  # convert into dataframe
  for(this_row in species_block[[1]]){

    # remove any leading spaces
    this_row <- sub("^\\s+", "", this_row)
    # trim off everything after species name to get this_species
    this_species <- sub("\\s+.*$", "", this_row)
    # to get row numeric values, trim off everything before it
    aq_numerics <- sub("^\\S+\\s+", "", this_row)
    # to get molality, trim off everything after its value in aq_numerics
    Eh <- sub("\\s+.*$", "", aq_numerics)
    # to get log molality, trim off everything before and after it
    pe_trailing <- sub("^\\S+\\s+", "", aq_numerics)
    pe <- sub("\\s+.*$", "", pe_trailing)
    # to get log gamma, trim off everything before and after it
    logfO2_trailing <- sub("^\\S+\\s+\\S+\\s+", "", aq_numerics)
    logfO2 <- sub("\\s+.*$", "", logfO2_trailing)
    # to get log activity, trim off everything before and after it
    Ah_trailing <- sub("^\\S+\\s+\\S+\\s+\\S+\\s+", "", aq_numerics)
    Ah <- sub("\\s+.*$", "", Ah_trailing)

    # create a dataframe with results
    this_df <- data.frame(couple = this_species,
                          Eh = as.numeric(Eh),
                          pe = as.numeric(pe),
                          logfO2 = as.numeric(logfO2),
                          Ah = as.numeric(Ah),
                          stringsAsFactors = FALSE)
    # bind results to dataframe
    df <- rbind(df, this_df)
  }
  df

  # add species affinities to master_df
  for(this_species in df[, "couple"]){
    # if this_species does not have a column in the master_df, add it
    if (!(this_species %in% colnames(master_df))){
      master_df <- cbind(master_df, rep(NA, nrow(master_df))) # add extra column
      colnames(master_df)[ncol(master_df)] <- this_species # rename added column
    }

    master_df[nrow(master_df), this_species] <- df[which(df[, "couple"] == this_species), RM_output_type]
  }
}

# sort mineral columns in alphabetical order
library(dplyr)
df_init <- select(master_df, sample, Name)
df_tosort <- select(master_df, -sample, -Name)
master_df <- cbind(df_init, df_tosort[, sort(colnames(df_tosort))])

# sort rows in same order as input file
master_df <- master_df[match(paste0(row_order, ".3o"), master_df$sample), ]

# master_df

setwd("../")
write.csv(master_df, paste("redox_", RM_output_type,".csv", sep=""), row.names=FALSE)

this_time <- proc.time() - ptm                        

print(paste("RedoxMine finished! Took", round(this_time["elapsed"], 1), "seconds."))
