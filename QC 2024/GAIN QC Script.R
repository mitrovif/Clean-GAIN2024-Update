library(readr)
library(readxl)
library(writexl)
library(dplyr)

# Define file paths for the two folders
filip_folder <- "C:\\Users\\mitro\\UNHCR\\EGRISS Secretariat - Documents\\905 - Implementation of Recommendations\\01_GAIN Survey\\Integration & GAIN Survey\\EGRISS GAIN Survey 2024\\13 Data QC\\Filip Analysis Ready Files\\Backup_2025-02-28_16-38-57"
ladina_folder <- "C:\\Users\\mitro\\UNHCR\\EGRISS Secretariat - Documents\\905 - Implementation of Recommendations\\01_GAIN Survey\\Integration & GAIN Survey\\EGRISS GAIN Survey 2024\\13 Data QC\\Ladina Analysis Ready Files\\Backup_2025-02-28_07-40-03"

# Define output directory and create it if it does not exist
output_dir <- "C:\\Users\\mitro\\UNHCR\\EGRISS Secretariat - Documents\\905 - Implementation of Recommendations\\01_GAIN Survey\\Integration & GAIN Survey\\EGRISS GAIN Survey 2024\\13 Data QC\\Comparison_Results"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# Define output file path
output_file <- file.path(output_dir, "Dataset_Comparison_Report.xlsx")

# Function to get a list of files in a folder
get_file_list <- function(folder_path) {
  files <- list.files(folder_path, pattern = "\\.csv$|\\.xlsx$|\\.xls$", full.names = TRUE)
  return(files)
}

# Function to compare two datasets
compare_files <- function(file1, file2) {
  tryCatch({
    # Read files
    if (grepl("\\.csv$", file1)) {
      df1 <- read_csv(file1, col_types = cols(.default = "c"))  # Read all as character for comparison
      df2 <- read_csv(file2, col_types = cols(.default = "c"))
    } else {
      df1 <- read_excel(file1, col_types = "text")
      df2 <- read_excel(file2, col_types = "text")
    }
    
    # Ensure both datasets have the same column names (ignoring order)
    if (!identical(sort(names(df1)), sort(names(df2)))) {
      return(list(summary = data.frame(File = basename(file1), Shape_Match = FALSE, Columns_Match = FALSE, Total_Differences = NA, Similarity_Percentage = NA, Error = NA), differences = NULL))
    }
    
    # Sort columns for a fair comparison
    df1 <- df1[, sort(names(df1))]
    df2 <- df2[, sort(names(df2))]
    
    # Compare dimensions
    shape_match <- identical(dim(df1), dim(df2))
    
    # Compare column names
    columns_match <- identical(names(df1), names(df2))
    
    # Compare cell-wise differences
    min_rows <- min(nrow(df1), nrow(df2))
    min_cols <- min(ncol(df1), ncol(df2))
    
    df1_trim <- df1[1:min_rows, 1:min_cols]
    df2_trim <- df2[1:min_rows, 1:min_cols]
    
    total_cells <- min_rows * min_cols
    if (total_cells > 0) {
      differences <- sum(df1_trim != df2_trim, na.rm = TRUE)
      similarity_percentage <- round(100 * (1 - (differences / total_cells)), 2)
    } else {
      differences <- 0
      similarity_percentage <- 100
    }
    
    # If there are differences, create a detailed difference table
    diff_table <- NULL
    if (differences > 0) {
      mismatch_indices <- which(df1_trim != df2_trim, arr.ind = TRUE)
      diff_table <- data.frame(
        Row = mismatch_indices[, 1],
        Column = names(df1_trim)[mismatch_indices[, 2]],
        Filip_Value = df1_trim[mismatch_indices],
        Ladina_Value = df2_trim[mismatch_indices]
      )
    }
    
    return(list(
      summary = data.frame(File = basename(file1), Shape_Match = shape_match, Columns_Match = columns_match, Total_Differences = differences, Similarity_Percentage = similarity_percentage, Error = NA),
      differences = diff_table
    ))
    
  }, error = function(e) {
    return(list(summary = data.frame(File = basename(file1), Shape_Match = NA, Columns_Match = NA, Total_Differences = NA, Similarity_Percentage = NA, Error = as.character(e$message)), differences = NULL))
  })
}

# Function to generate a report
generate_comparison_report <- function(filip_folder, ladina_folder, output_file) {
  files_filip <- basename(get_file_list(filip_folder))
  files_ladina <- basename(get_file_list(ladina_folder))
  
  common_files <- intersect(files_filip, files_ladina)
  missing_in_filip <- setdiff(files_ladina, files_filip)
  missing_in_ladina <- setdiff(files_filip, files_ladina)
  
  results_list <- list()
  
  # Define required column structure
  required_columns <- c("File", "Shape_Match", "Columns_Match", "Total_Differences", "Similarity_Percentage", "Error")
  
  # Store summary comparison results
  summary_results <- lapply(common_files, function(file) {
    result <- compare_files(file.path(filip_folder, file), file.path(ladina_folder, file))
    
    # Standardize column structure before returning summary
    for (col in setdiff(required_columns, names(result$summary))) {
      result$summary[[col]] <- NA
    }
    result$summary <- result$summary[, required_columns, drop = FALSE]
    
    # Store differences if applicable
    if (!is.null(result$differences)) {
      results_list[[paste("Differences_", file, sep = "")]] <- result$differences
    }
    
    return(result$summary)
  })
  
  # Combine summary results
  summary_results <- do.call(rbind, summary_results)
  
  # Add summary results to the output
  results_list[["Comparison Results"]] <- summary_results
  results_list[["Missing in Filip Folder"]] <- data.frame(Files = missing_in_filip)
  results_list[["Missing in Ladina Folder"]] <- data.frame(Files = missing_in_ladina)
  
  # Save results to Excel
  write_xlsx(results_list, output_file)
  
  print(paste("Comparison report saved to", output_file))
}

# Run the comparison
generate_comparison_report(filip_folder, ladina_folder, output_file)
