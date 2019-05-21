# MineralMine ------------------------------------------------------------------
# Summary: extract mineral solubility information from EQ3 output files
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



  # string to isolate the mineral saturation section:
  front_trim <- "^.*\n\n\n\n           --- Saturation States of Pure Solids ---\n\n       Phase                      Log Q/K    Affinity, kcal\n\n\\s+"

  # check if mineral block exists. If not, skip processing the file:
  if (grepl(front_trim, extractme) == FALSE){
    next # skip to next sample file
  }

  # trim off everything before:
  mineral_trailing <- sub(front_trim, "", extractme)
  # trim off everything after:
  mineral_block <- sub("\n\n.*$", "", mineral_trailing)
  # replace all commas with underscores
  mineral_block <- gsub(",", "_", mineral_block)
  # split into substrings, each representing a separate row in the table
  mineral_block <- strsplit(mineral_block, "\n")




  #create an empty data frame to store results
  df <- data.frame(mineral = character(0),
                   logQoverK = numeric(0),
                   affinity = numeric(0),
                   stringsAsFactors = FALSE)
  # convert into dataframe
  for(this_row in mineral_block[[1]]){
    # remove any leading spaces
    this_row <- sub("^\\s+", "", this_row)
    # trim off everything after mineral name to get this_mineral
    this_mineral <- sub("\\s+.*$", "", this_row)
    # to get LogQ/K, trim off everything before it
    this_LogQoverK_trailing <- sub("^.*[A-Z]\\s+", "", this_row)
    # then trim off everything after it
    this_LogQoverK <- sub("\\s+.*$", "", this_LogQoverK_trailing)
    # to get Affinity, trim off everything before it:
    this_Affinity_trailing <- sub("^.*[A-Z]\\s+\\S+\\s+", "", this_row)
    # then trim off everything after it
    this_Affinity <- sub("\\s+.*$", "", this_Affinity_trailing)
    # create a dataframe with results
    this_df <- data.frame(mineral = this_mineral,
                          logQoverK = as.numeric(this_LogQoverK),
                          affinity = as.numeric(this_Affinity),
                          stringsAsFactors = FALSE)
    # bind results to dataframe
    df <- rbind(df, this_df)
  }
  df

  # add mineral affinities to master_df
  for(this_mineral in df[, "mineral"]){
    # if this_mineral does not have a column in the master_df, add it
    if (!(this_mineral %in% colnames(master_df))){
      master_df <- cbind(master_df, rep(NA, nrow(master_df))) # add extra column
      colnames(master_df)[ncol(master_df)] <- this_mineral # rename added column
    }

    master_df[nrow(master_df), this_mineral] <- df[which(df[, "mineral"] == this_mineral), MM_output_type]
      
  }

} # end for this_file in sample_files


# sort mineral columns in alphabetical order
library(dplyr)
df_init <- select(master_df, sample, Name)
df_tosort <- select(master_df, -sample, -Name)
master_df <- cbind(df_init, df_tosort[, sort(colnames(df_tosort))])

# sort rows in same order as input file
master_df <- master_df[match(paste0(row_order, ".3o"), master_df$sample), ]

setwd("../")
write.csv(master_df, paste("mineral_", MM_output_type,".csv", sep=""), row.names=FALSE)

this_time <- proc.time() - ptm                             

print(paste("MineralMine finished! Took", round(this_time["elapsed"], 1), "seconds."))
