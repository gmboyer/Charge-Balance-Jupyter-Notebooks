# MiscMine --------------------------------------------------------------------
# Summary: extract miscellaneous information from EQ3 output files in the
#   user's rxn_3o directory, such as charge imbalance and ionic strength.
# Author: Grayson Boyer (gmboyer@asu.edu)
# Last updated: 1/18/2019
# Created for the ENKI project

# Start the timer:
ptm <- proc.time()

setwd("rxn_3o")

sample_files <- list.files()

master_df <- data.frame(sample=character(0),
                        Name=character(0),
                        stringsAsFactors=FALSE)

columns_initialized <- FALSE

for(this_file in sample_files){

  # read .3o file as a string
  fileName <- this_file
  extractme <- readChar(fileName, file.info(fileName)$size) # readChar requires filesize, which is obtained from file.info()$size

  # getting sample name using sub()
  # 1. trim off everything before substring of interest
  name_trailing <- sub("^.*\\|Sample:\\s+", "", extractme)

  # 2. trim off everything after substring of interest
  this_name <- sub("\\|\\n\\|.*$", "", name_trailing) # trim file contents from name
  this_name <- sub("\\s+$", "", this_name) # trim off trailing spaces from name
    
  # bind to master data frame
  master_df[nrow(master_df)+1, ] <- rep(NA, ncol(master_df)) # create a new row
  master_df[nrow(master_df), "sample"] <- this_file
  master_df[nrow(master_df), "Name"] <- this_name

  # string to isolate ionic strength:
  front_trim <- "^.*Ionic strength \\(I\\)=\\s+"
    
  # check if ionic strength exists. If not, skip processing the file:
  if (grepl(front_trim, extractme) == FALSE){
    next # skip to next sample file
  }

  # trim off everything before:
  IS_trailing <- sub(front_trim, "", extractme)
  # trim off everything after:
  IS <- sub("\\s+.*$", "", IS_trailing)
  names(IS) <- "IS (molal)"

  # string to isolate stoichiometric ionic strength:
  front_trim <- "^.*Stoichiometric ionic strength=\\s+"

  # trim off everything before:
  IS_trailing <- sub(front_trim, "", extractme)
  # trim off everything after:
  IS_stoich <- sub("\\s+.*$", "", IS_trailing)
  names(IS_stoich) <- "stoichiometric IS (molal)"

  # string to isolate the electrical balance section:
  front_trim <- "^.*Sigma\\(mz\\) cations=\\s+"

  # trim off everything before:
  elec_trailing <- sub(front_trim, "", extractme)
  # trim off everything after:
  elec_block <- sub("\n\n.*$", "", elec_trailing)

  # split electrical block into strings and numerics
  elec_block <- strsplit(elec_block, "=\\s+|\n\\s+")[[1]]
  # take only numerics
  suppressWarnings({
  elec_block <- elec_block[!is.na(as.numeric(elec_block))]
  })
  # name numerics
  names(elec_block) <- c("Sigma(mz) cations", "Sigma(mz) anions", "Total charge", "Mean charge", "Charge imbalance")

  # string to isolate charge balance:
  front_trim <- "^.*The electrical imbalance is:\n\n\\s+"

  # trim off everything before:
  cbal_bal_trailing <- sub(front_trim, "", extractme)
  # trim off everything after:
  cbal_bal <- sub("\n\n.*$", "", cbal_bal_trailing)

  # split electrical block into strings and numerics
  cbal_block <- strsplit(cbal_bal, " per cent|\n\\s+")[[1]]
  # take only numerics
  suppressWarnings({
  cbal_block <- cbal_block[!is.na(as.numeric(cbal_block))]
  })
  # name numerics
  names(cbal_block) <- c("%CI of total", "%CI of mean")

  this_vec <- c(IS, IS_stoich, elec_block, cbal_block)
  these_names <- names(this_vec)
  this_vec <- as.numeric(this_vec)
  names(this_vec) <- these_names 
    
  # append master_df
  if(!columns_initialized){
      master_df <- cbind(master_df, t(this_vec))
      columns_initialized <- TRUE
  } else {
      master_df[nrow(master_df), names(this_vec)] <- this_vec
  }

}

# sort rows in same order as input file
master_df <- master_df[match(paste0(row_order, ".3o"), master_df$sample), ]

# master_df

setwd("../")
write.csv(master_df, paste("MiscMine_output.csv", sep=""), row.names=FALSE)

this_time <- proc.time() - ptm                        

print(paste("MiscMine finished! Took", round(this_time["elapsed"], 1), "seconds."))
