#!/usr/bin/env Rscript

# Function to extract all documentation from an R package to a text file
# Usage: extract_package_docs("dplyr", "dplyr_docs.txt")

extract_package_docs <- function(package_name, output_file = NULL) {
  
  # Set default output file name if not provided
  if (is.null(output_file)) {
    output_file <- paste0(package_name, "_documentation.txt")
  }
  
  # Check if package is installed
  if (!requireNamespace(package_name, quietly = TRUE)) {
    stop(paste("Package", package_name, "is not installed."))
  }
  
  # Open connection to output file
  con <- file(output_file, "w")
  
  # Write header
  writeLines(paste0(rep("=", times = 70), collapse = ""), con)
  writeLines(paste("Documentation for R Package:", package_name), con)
  writeLines(paste0(rep("=", times = 70), collapse = ""), con)
  writeLines("", con)
  
  # Get list of all objects in the package
  objects <- ls(paste0("package:", package_name))
  
  # Extract help for each object
  writeLines("### FUNCTION AND OBJECT DOCUMENTATION ###", con)
  writeLines("", con)
  
  for (obj in objects) {
    writeLines(paste0(rep("=", times = 70), collapse = ""), con)
    writeLines(paste("Object:", obj), con)
    writeLines(paste0(rep("=", times = 70), collapse = ""), con)
    
    # Capture help text
    help_text <- tryCatch({
      # Create temporary file for help output
      temp_file <- tempfile()
      print(obj)
      print(package_name)
      # Use tools::Rd2txt to get plain text help
      help_obj <- utils::help(obj, package = package_name)
      
      if (length(help_obj) > 0) {
        # Get the Rd file path
        rd_path <- utils:::.getHelpFile(help_obj)
        
        # Convert to text
        tools::Rd2txt(rd_path, out = temp_file, options = list(underline_titles = FALSE))
        
        # Read the text
        text <- readLines(temp_file, warn = FALSE)
        unlink(temp_file)
        text
      } else {
        "No documentation available"
      }
    }, error = function(e) {
      paste("Error retrieving documentation:", e$message)
    })
    
    writeLines(help_text, con)
    writeLines("", con)
    writeLines("", con)
  }
  
  # Extract vignettes
  writeLines("", con)
  writeLines(paste0(rep("=", times = 70), collapse = ""), con)
  writeLines("### VIGNETTES ###", con)
  writeLines(paste0(rep("=", times = 70), collapse = ""), con)
  writeLines("", con)
  
  # Get list of vignettes
  vignettes <- vignette(package = package_name)$results
  
  if (nrow(vignettes) == 0) {
    writeLines("No vignettes available for this package.", con)
  } else {
    for (i in seq_len(nrow(vignettes))) {
      vig_name <- vignettes[i, "Item"]
      vig_title <- vignettes[i, "Title"]
      
      writeLines(paste0(rep("=", times = 70), collapse = ""), con)
      writeLines(paste("Vignette:", vig_name), con)
      writeLines(paste("Title:", vig_title), con)
      writeLines(paste0(rep("=", times = 70), collapse = ""), con)
      writeLines("", con)
      
      # Try to get vignette content
      vig_text <- tryCatch({
        # Find the vignette file
        vig_path <- system.file("doc", paste0(vig_name, ".R"), package = package_name)
        
        # Try different file extensions
        if (!file.exists(vig_path) || file.info(vig_path)$size == 0) {
          vig_path <- system.file("doc", paste0(vig_name, ".Rmd"), package = package_name)
        }
        if (!file.exists(vig_path) || file.info(vig_path)$size == 0) {
          vig_path <- system.file("doc", paste0(vig_name, ".Rnw"), package = package_name)
        }
        
        # Read the file if it exists
        if (file.exists(vig_path) && file.info(vig_path)$size > 0) {
          readLines(vig_path, warn = FALSE)
        } else {
          paste("Vignette source file not found. View with: vignette('", vig_name, "', package = '", package_name, "')", sep = "")
        }
      }, error = function(e) {
        paste("Error retrieving vignette:", e$message)
      })
      
      writeLines(vig_text, con)
      writeLines("", con)
      writeLines("", con)
    }
  }
  
  # Close connection
  close(con)
  
  message(paste("Documentation written to:", output_file))
  invisible(output_file)
}

# Example usage (uncomment to run):
# extract_package_docs("dplyr", "dplyr_docs.txt")
# extract_package_docs("ggplot2")

extract_package_docs("ggbeeswarm")
