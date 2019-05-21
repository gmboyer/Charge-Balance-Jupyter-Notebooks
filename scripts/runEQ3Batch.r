# runEQ3Batch R wrapper ---------------------------------------------------------------------
# Summary: use Tucker's runEQ3 python script in an R environment
# Author: Grayson Boyer (gmboyer@asu.edu)
# Last updated: 11/17/2018
# Created for the ENKI project

# Start the timer:
ptm <- proc.time()

library('reticulate')

source_python("/Users/graysonboyer/Batch_EQ3/scripts/runEQ3_initialize.py")

source_python("/Users/graysonboyer/Batch_EQ3/scripts/runEQ3Batch_forR.py")

if(!exists("db")){
    db <- 'jus'
}

for(i in three_i_files){
    call_EQ3(db, 'rxn_3i', i)
    message(paste('calling EQ3 on', i, 'using', db))

    setwd(input_dir)
    i_trunc = sub(".3i$", "", i)
    setwd(output_dir)
    outputFileName <- paste0(i_trunc, ".3o")
    if(outputFileName %in% list.files()){
        if(!grepl("\\* Error", readChar(outputFileName, file.info(outputFileName)$size))){
            # rename and move pickup files if generated
            setwd(input_dir)
            tryCatch({
                file.rename("pickup", paste0(i_trunc, ".3p"))
                file.copy(paste0(input_dir, i_trunc, ".3p"), paste0(pickup_dir, i_trunc, ".3p"))},
            error= function(e){print(message("Warning: pickup file for ", i, " not generated"))},
            warning = function(e){print(message("Warning: pickup file for ", i, " not generated"))})
        }else{
            output_error <- sub("^.*?\\* Error", "", readChar(outputFileName, file.info(outputFileName)$size))
            output_error <- gsub("No further input found.*$", "", output_error)
            output_error <- gsub("\\n", " ", output_error)
            output_error <- gsub("\\s+", " ", output_error)
            print(message("Warning: the output file for ", i, " reports error(s): ", output_error))
        }
    }else{
        print(message("Warning: an output file for ", i, "was not generated"))
    }
             
    setwd(pwd)
}

this_time <- proc.time() - ptm                             

print(paste("runEQ3Batch finished! Took", round(this_time["elapsed"], 1), "seconds."))