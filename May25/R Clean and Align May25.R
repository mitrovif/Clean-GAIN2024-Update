### Libraries
library(readxl)
library(dplyr)
library(countrycode)
library(readr)
library(stringr)
# ======================================================
# Step 0: Define file locations
# ======================================================

setwd("C:/Users/mitro/UNHCR/EGRISS Secretariat - Documents/905 - Implementation of Recommendations/01_GAIN Survey/Integration & GAIN Survey/EGRISS GAIN Survey 2024")

final_version_file <- "05 Data Collection/Data Archive/Final Version/EGRISS_GAIN_2024_Final_Version.xlsx"
data_clean_file <- "06 Data Cleaning/EGRISS_GAIN_2024_-_Data Clean.xlsx"
output_directory <- "10 Data"
gain_survey_all_file <- file.path(output_directory, "GAIN Survey - All Data.xlsx")

# Define subfolder for analysis-ready files
analysis_ready_directory <- file.path(output_directory, "Analysis Ready Files")

# Ensure the output directory for analysis-ready files exists
if (!dir.exists(analysis_ready_directory)) {
  dir.create(analysis_ready_directory, recursive = TRUE)
}

# ======================================================
# Step 1: Import all sheets from both files
# ======================================================

final_version_sheets <- excel_sheets(final_version_file)
data_clean_sheets <- excel_sheets(data_clean_file)

# Read all sheets from Final Version
final_version_data <- lapply(final_version_sheets, function(sheet) {
  read_excel(final_version_file, sheet = sheet)
})
names(final_version_data) <- final_version_sheets

# Read all sheets from Data Clean
data_clean_data <- lapply(data_clean_sheets, function(sheet) {
  read_excel(data_clean_file, sheet = sheet)
})
names(data_clean_data) <- data_clean_sheets

# ======================================================
# Step 2: Rename `_PRO02A` to `PRO02` and `_index` to `index` in `group_roster`
# ======================================================

if ("group_roster" %in% names(final_version_data)) {
  group_roster <- final_version_data[["group_roster"]]
  
  # Rename `_PRO02A` to `PRO02` if it exists
  if ("_PRO02A" %in% colnames(group_roster)) {
    group_roster <- group_roster %>%
      rename(PRO02 = `_PRO02A`)
    message("Renamed `_PRO02A` to `PRO02` in `group_roster`.")
  }
  
  # Rename `_index` to `index` if it exists
  if ("_index" %in% colnames(group_roster)) {
    group_roster <- group_roster %>%
      rename(index = `_index`)
    message("Renamed `_index` to `index` in `group_roster`.")
  }
  
  # Save back to the list
  final_version_data[["group_roster"]] <- group_roster
}

# Rename `_index` to `index` in `EGRISS GAIN 2024`
if ("EGRISS GAIN 2024" %in% names(final_version_data)) {
  egriss_gain_2024 <- final_version_data[["EGRISS GAIN 2024"]]
  
  # Rename `_index` to `index` if it exists
  if ("_index" %in% colnames(egriss_gain_2024)) {
    egriss_gain_2024 <- egriss_gain_2024 %>%
      rename(index = `_index`)
    message("Renamed `_index` to `index` in `EGRISS GAIN 2024`.")
  }
  
  # Save back to the list
  final_version_data[["EGRISS GAIN 2024"]] <- egriss_gain_2024
}

# ======================================================
# Step 3: Remove entries in "EGRISS GAIN 2024" based on del_EGRISS GAIN
# ======================================================

if ("EGRISS GAIN 2024" %in% names(final_version_data) && "del_EGRISS GAIN" %in% names(data_clean_data)) {
  egriss_gain_2024 <- final_version_data[["EGRISS GAIN 2024"]]
  del_egriss_gain <- data_clean_data[["del_EGRISS GAIN"]]
  
  # Remove rows from "EGRISS GAIN 2024" based on del_EGRISS GAIN
  egriss_gain_2024 <- egriss_gain_2024 %>%
    filter(!(index %in% del_egriss_gain$index))
  
  # Save cleaned version of "EGRISS GAIN 2024" back to the list
  final_version_data[["EGRISS GAIN 2024"]] <- egriss_gain_2024
}

# ======================================================
# Step 4: Remove entries in "group_roster" based on del_group_roster
# ======================================================

if ("group_roster" %in% names(final_version_data) && "del_group_roster" %in% names(data_clean_data)) {
  group_roster <- final_version_data[["group_roster"]]
  del_group_roster <- data_clean_data[["del_group_roster"]]
  
  # Remove rows from "group_roster" based on del_group_roster
  group_roster <- group_roster %>%
    filter(!(index %in% del_group_roster$index))
  
  # Save cleaned version of "group_roster" back to the list
  final_version_data[["group_roster"]] <- group_roster
}

# ======================================================
# Step 5: Add text values to `PRO02` in "group_roster"
# ======================================================

if ("group_roster" %in% names(final_version_data) && "title_PRO02" %in% names(data_clean_data)) {
  group_roster <- final_version_data[["group_roster"]]
  title_pro02 <- data_clean_data[["title_PRO02"]]
  
  # Add or update `PRO02` in "group_roster" based on title_PRO02
  group_roster <- group_roster %>%
    left_join(title_pro02 %>% select(index, title), by = "index") %>%
    mutate(
      PRO02 = ifelse(is.na(PRO02), title, PRO02) # Update only missing values
    ) %>%
    select(-title) # Remove temporary title column
  
  # Save updated version of "group_roster" back to the list
  final_version_data[["group_roster"]] <- group_roster
}

# ======================================================
# Step 6: Add `year` column to both cleaned datasets
# ======================================================

if ("EGRISS GAIN 2024" %in% names(final_version_data)) {
  final_version_data[["EGRISS GAIN 2024"]] <- final_version_data[["EGRISS GAIN 2024"]] %>%
    mutate(year = 2024)
}

if ("group_roster" %in% names(final_version_data)) {
  final_version_data[["group_roster"]] <- final_version_data[["group_roster"]] %>%
    mutate(year = 2024)
}
# For EGRISS GAIN 2024
egriss_gain_2024 <- final_version_data[["EGRISS GAIN 2024"]] %>%
  mutate(year = 2024)
final_version_data[["EGRISS GAIN 2024"]] <- egriss_gain_2024

# For group_roster
group_roster <- final_version_data[["group_roster"]] %>%
  mutate(year = 2024)
final_version_data[["group_roster"]] <- group_roster

# View final cleaned and renamed datasets
glimpse(final_version_data[["EGRISS GAIN 2024"]]$year)

# ======================================================
# Step 7: Rename variables in "EGRISS GAIN 2024" using var_main (sequence-based)
# ======================================================
# Determine which columns to rename, excluding "year"
egriss_gain_2024 <- final_version_data[["EGRISS GAIN 2024"]]
cols_to_rename <- setdiff(colnames(egriss_gain_2024), "year")

# Number of columns to rename from var_main (make sure not to exceed the length)
num_vars_to_rename <- min(length(cols_to_rename), nrow(var_main))

# Get the old names (the ones you want to change) in order
old_names <- cols_to_rename[1:num_vars_to_rename]
new_names <- var_main$newg_2024[1:num_vars_to_rename]

# Replace the names while preserving the "year" column
for(i in seq_along(old_names)) {
  idx <- which(colnames(egriss_gain_2024) == old_names[i])
  if(length(idx) > 0) {
    colnames(egriss_gain_2024)[idx] <- new_names[i]
  }
}

final_version_data[["EGRISS GAIN 2024"]] <- egriss_gain_2024
final_version_data[["EGRISS GAIN 2024"]] <- final_version_data[["EGRISS GAIN 2024"]] %>%
  mutate(year = 2024)
# After renaming, check the column names:
print(colnames(final_version_data[["EGRISS GAIN 2024"]]))


# ======================================================
# Step 8: Rename variables in "group_roster" using var_group (sequence-based)
# ======================================================

if ("var_group" %in% names(data_clean_data) && "group_roster" %in% names(final_version_data)) {
  var_group <- data_clean_data[["var_group"]]
  group_roster <- final_version_data[["group_roster"]]
  
  # Ensure the sequence matches
  num_vars_to_rename <- min(ncol(group_roster), nrow(var_group)) # Limit to the smaller size
  old_names <- colnames(group_roster)[1:num_vars_to_rename]
  new_names <- var_group$newgr_2024[1:num_vars_to_rename]
  
  # Rename variables in group_roster
  colnames(group_roster)[1:num_vars_to_rename] <- new_names
 
  # Save back to the list
  final_version_data[["group_roster"]] <- group_roster
  message("Variables renamed in 'group_roster' based on sequence.")
}


# Save cleaned and renamed datasets back to the specified directory
write.csv(final_version_data[["EGRISS GAIN 2024"]], file.path(output_directory, "renamed_EGRISS_GAIN_2024.csv"), row.names = FALSE)
write.csv(final_version_data[["group_roster"]], file.path(output_directory, "renamed_group_roster.csv"), row.names = FALSE)

# View final cleaned and renamed datasets
glimpse(final_version_data[["EGRISS GAIN 2024"]])
glimpse(final_version_data[["group_roster"]])
glimpse(final_version_data[["EGRISS GAIN 2024"]]$year)

message("Cleaned and renamed datasets have been saved to: ", output_directory)


# Define file locations
output_directory <- "10 Data"
gain_survey_all_file <- file.path(output_directory, "GAIN Survey - All Data.xlsx")

# Define subfolder for analysis-ready files
analysis_ready_directory <- file.path(output_directory, "Analysis Ready Files")

# Ensure the output directory for analysis-ready files exists
if (!dir.exists(analysis_ready_directory)) {
  dir.create(analysis_ready_directory, recursive = TRUE)
}

# ======================================================
# Step 9: Load `GAIN Survey - All Data` file
# ======================================================

if (file.exists(gain_survey_all_file)) {
  gain_survey_sheets <- excel_sheets(gain_survey_all_file)
  
  # Load relevant sheets
  if ("main_roster" %in% gain_survey_sheets) {
    main_roster <- read_excel(gain_survey_all_file, sheet = "main_roster", .name_repair = "unique") # Handle duplicate names
    message("Loaded 'main_roster' sheet.")
  } else {
    stop("Sheet 'main_roster' not found in 'GAIN Survey - All Data.xlsx'.")
  }
  
  if ("group_roster" %in% gain_survey_sheets) {
    group_roster_all <- read_excel(gain_survey_all_file, sheet = "group_roster", .name_repair = "unique") # Handle duplicate names
    message("Loaded 'group_roster' sheet.")
  } else {
    stop("Sheet 'group_roster' not found in 'GAIN Survey - All Data.xlsx'.")
  }
} else {
  stop("The file 'GAIN Survey - All Data.xlsx' does not exist in the specified directory.")
}

# Ensure consistent naming for `index`
if ("_index" %in% colnames(main_roster)) {
  main_roster <- main_roster %>%
    rename(index = `_index`)
}

# ======================================================
# Step 10: Merge `main_roster` with `renamed_EGRISS_GAIN_2024`
# ======================================================
renamed_EGRISS_GAIN_2024 <- read.csv(file.path(output_directory, "renamed_EGRISS_GAIN_2024.csv"))

align_column_types <- function(df1, df2) {
  # Get the column names for both dataframes
  colnames_df1 <- colnames(df1)
  colnames_df2 <- colnames(df2)
  
  # Find the common column names between the two dataframes
  common_cols <- intersect(colnames_df1, colnames_df2)
  
  # Loop through the common columns and align their types
  for (col in common_cols) {
    # Check the types of the first element in both columns
    class_df1 <- class(df1[[col]])[1]  # Take the first element's class
    class_df2 <- class(df2[[col]])[1]  # Take the first element's class
    
    # If one of the columns is a Date or POSIXct, convert both columns to character
    if ("POSIXct" %in% c(class_df1, class_df2)) {
      # Convert both columns to character if one is POSIXct
      df1[[col]] <- as.character(df1[[col]])
      df2[[col]] <- as.character(df2[[col]])
    } else if ("Date" %in% c(class_df1, class_df2)) {
      # Convert both columns to character if one is Date
      df1[[col]] <- as.character(df1[[col]])
      df2[[col]] <- as.character(df2[[col]])
    } else {
      # For non-date types, match the type (prefer character if one column is character)
      if (class_df1 != class_df2) {
        if (class_df1 == "character" || class_df2 == "character") {
          # Convert both columns to character if either is character
          df1[[col]] <- as.character(df1[[col]])
          df2[[col]] <- as.character(df2[[col]])
        } else {
          # If one column is numeric, convert both columns to numeric
          df1[[col]] <- as.numeric(df1[[col]])
          df2[[col]] <- as.numeric(df2[[col]])
        }
      }
    }
  }
  
  # Return the aligned dataframes as a list
  return(list(df1 = df1, df2 = df2))
}

# Remove the 'X' prefix from column names that start with 'X'
colnames(renamed_EGRISS_GAIN_2024) <- gsub("^X", "", colnames(renamed_EGRISS_GAIN_2024))

# Explicitly convert _submission_time to character before alignment
renamed_EGRISS_GAIN_2024$`_submission_time` <- as.character(renamed_EGRISS_GAIN_2024$`_submission_time`)
main_roster$`_submission_time` <- as.character(main_roster$`_submission_time`)

# Align column types
aligned_data <- align_column_types(renamed_EGRISS_GAIN_2024, main_roster)
renamed_EGRISS_GAIN_2024 <- aligned_data$df1 
main_roster <- aligned_data$df2

# Merge datasets
merged_main <- bind_rows(renamed_EGRISS_GAIN_2024, main_roster)

# Ensure `index` exists before arranging
if ("index" %in% colnames(merged_main)) {
  merged_main <- merged_main %>%
    arrange(index)
} else {
  message("`index` column not found in merged_main. Skipping `arrange()`.")
}

# Save merged dataset
output_main_roster <- file.path(analysis_ready_directory, "analysis_ready_main_roster.csv")
write.csv(merged_main, output_main_roster, row.names = FALSE)

message("Merged and saved main roster as analysis-ready dataset at: ", output_main_roster)
# ======================================================
# Step 11: Merge `group_roster_all` with `renamed_group_roster`
# Also ensures `PRO04` and `PRO05` are converted to dates and rounded up to year.
# ======================================================

if (exists("group_roster_all") && exists("final_version_data") && "group_roster" %in% names(final_version_data)) {
  # Ensure column names are valid and not NA
  colnames(group_roster_all) <- make.names(colnames(group_roster_all), unique = TRUE)
  colnames(final_version_data[["group_roster"]]) <- make.names(colnames(final_version_data[["group_roster"]]), unique = TRUE)
  
  # Convert all columns to character to prevent type mismatches
  group_roster_all <- group_roster_all %>% mutate(across(everything(), as.character))
  renamed_group_roster <- final_version_data[["group_roster"]] %>% mutate(across(everything(), as.character))
  
  # Align columns
  all_columns_group <- union(colnames(renamed_group_roster), colnames(group_roster_all))
  
  for (col in setdiff(all_columns_group, colnames(group_roster_all))) {
    group_roster_all[[col]] <- NA
  }
  for (col in setdiff(all_columns_group, colnames(renamed_group_roster))) {
    renamed_group_roster[[col]] <- NA
  }
  
  # Merge datasets
  merged_group <- bind_rows(renamed_group_roster, group_roster_all)
  
  # Ensure `index` exists before arranging
  if ("X_index" %in% colnames(merged_group)) {
    merged_group <- merged_group %>% arrange(X_index)
  } else {
    message("`index` column not found in merged_group. Skipping `arrange()`.")
  }
  
  # Save merged dataset
  output_group_roster <- file.path(analysis_ready_directory, "analysis_ready_group_roster.csv")
  tryCatch({
    write.csv(merged_group, output_group_roster, row.names = FALSE)
    message("Merged and saved group roster as analysis-ready dataset at: ", output_group_roster)
  }, error = function(e) {
    message("Error in writing group roster file: ", e$message)
  })
} else {
  message("One or more datasets are missing for merging 'group_roster_all' with 'renamed_group_roster'.")
}

# ======================================================
# Step 12: Confirm saved files
# ======================================================

saved_files <- list.files(analysis_ready_directory, full.names = TRUE)
if (length(saved_files) > 0) {
  message("Analysis-ready files have been saved:")
  print(saved_files)
} else {
  message("No analysis-ready files were saved. Please check the script and data inputs.")
}

# Load the analysis-ready group roster file
analysis_ready_group_roster_file <- "10 Data/Analysis Ready Files/analysis_ready_group_roster.csv"

if (file.exists(analysis_ready_group_roster_file)) {
  # Load the dataset
  group_roster <- read.csv(analysis_ready_group_roster_file)
  
  # Identify correct column names for `year`
  year_cols <- grep("^year", colnames(group_roster), value = TRUE)
  
  if (length(year_cols) >= 1) {
    # Use the first detected year column
    group_roster <- group_roster %>%
      mutate(ryear = coalesce(!!!syms(year_cols))) # Combine all potential year columns
    
    # Save the updated dataset under the same name
    write.csv(group_roster, analysis_ready_group_roster_file, row.names = FALSE)
    message("Created `ryear` column by combining available `year` columns. Updated file saved to `analysis_ready_group_roster.csv`.")
  } else {
    stop("No valid `year` columns found in the dataset.")
  }
} else {
  stop("The file 'analysis_ready_group_roster.csv' does not exist in the specified directory.")
}

# ======================================================
# Step 13: Create `pindex2` - Combine `ryear` and `pindex1` into an 8-digit index
# ======================================================

# Ensure `pindex1` exists by extracting from `X_parent_index`
if (!"pindex1" %in% colnames(group_roster) & "X_parent_index" %in% colnames(group_roster)) {
  group_roster <- group_roster %>%
    mutate(pindex1 = as.numeric(X_parent_index))
}

if ("pindex1" %in% colnames(group_roster) & "ryear" %in% colnames(group_roster)) {
  group_roster <- group_roster %>%
    mutate(
      pindex1 = as.numeric(pindex1),
      ryear = as.numeric(ryear),
      pindex2 = sprintf("%d%04d", ryear, pindex1) # Combine `ryear` and padded `pindex1`
    )
  
  # Save the updated dataset under the same name
  tryCatch({
    write.csv(group_roster, analysis_ready_group_roster_file, row.names = FALSE)
    message("Created `pindex1` and `pindex2` variables. Updated file saved to `analysis_ready_group_roster.csv`.")
  }, error = function(e) {
    message("Failed to save the file. Check if the file is open or the path is writable.")
    stop(e)
  })
} else {
  stop("Columns `ryear` or `pindex1` are missing in the dataset.")
}



# Load the analysis-ready main roster file
analysis_ready_main_roster_file <- "10 Data/Analysis Ready Files/analysis_ready_main_roster.csv"

if (file.exists(analysis_ready_main_roster_file)) {
  # Load the dataset
  main_roster <- read.csv(analysis_ready_main_roster_file)
  
  # Ensure `year` and `index` columns exist
  if ("year" %in% colnames(main_roster) & "index" %in% colnames(main_roster)) {
    # Create `pindex2` by combining `year` and `index`
    main_roster <- main_roster %>%
      mutate(
        index = as.numeric(index), # Ensure `index` is numeric
        year = as.numeric(year), # Ensure `year` is numeric
        pindex2 = sprintf("%d%04d", year, index) # Combine `year` and padded `index`
      )
    
    # Save the updated dataset under the same name
    tryCatch({
      write.csv(main_roster, analysis_ready_main_roster_file, row.names = FALSE)
      message("Created `pindex2` variable in the main roster file. Updated file saved to `analysis_ready_main_roster.csv`.")
    }, error = function(e) {
      message("Failed to save the file. Check if the file is open or the path is writable.")
      stop(e)
    })
  } else {
    stop("Columns `year` or `index` are missing in the dataset.")
  }
} else {
  stop("The file 'analysis_ready_main_roster.csv' does not exist in the specified directory.")
}
# Load the analysis-ready main roster file
analysis_ready_main_roster_file <- "10 Data/Analysis Ready Files/analysis_ready_main_roster.csv"

if (file.exists(analysis_ready_main_roster_file)) {
  # Load the dataset
  main_roster <- read.csv(analysis_ready_main_roster_file)
  
  # Ensure that the LOC03 column exists (since Country has been removed)
  if ("LOC03" %in% colnames(main_roster)) {
    # Create the `mcountry` variable directly from LOC03
    main_roster <- main_roster %>%
      mutate(
        mcountry = LOC03
      )
    
    # Save the updated dataset under the same name
    tryCatch({
      write.csv(main_roster, analysis_ready_main_roster_file, row.names = FALSE)
      message("Created `mcountry` variable from LOC03. Updated file saved to `analysis_ready_main_roster.csv`.")
    }, error = function(e) {
      message("Failed to save the file. Check if the file is open or the path is writable.")
      stop(e)
    })
  } else {
    stop("Column `LOC03` is missing in the dataset.")
  }
} else {
  stop("The file 'analysis_ready_main_roster.csv' does not exist in the specified directory.")
}

# Load the analysis-ready main roster file
analysis_ready_main_roster_file <- "10 Data/Analysis Ready Files/analysis_ready_main_roster.csv"

# Load the dataset
main_roster <- read.csv(analysis_ready_main_roster_file)

# Remove rows where `INT02` is "No" but preserve `NA`
main_roster <- main_roster %>%
  filter(is.na(INT02) | INT02 != "No") # Keeps rows with `NA` or not "No"

# Save the updated dataset under the same name
write.csv(main_roster, analysis_ready_main_roster_file, row.names = FALSE)
message("Removed rows where `INT02` is 'No'. Preserved rows with `NA`. Updated file saved to `analysis_ready_main_roster.csv`.")

# ======================================================
# Step 14: Standardizes `LOC01` by recoding it to 1 (COUNTRY), 2 (INTERNATIONAL ORG), or 3 (CSO),
# and creates `morganization` with all text in the `organization` column capitalized.
# ======================================================

# Load the analysis-ready main roster file
analysis_ready_main_roster_file <- "10 Data/Analysis Ready Files/analysis_ready_main_roster.csv"

# Load the dataset
main_roster <- read.csv(analysis_ready_main_roster_file)

# Recode `LOC01` values
main_roster <- main_roster %>%
  mutate(
    LOC01 = case_when(
      LOC01 == "COUNTRY NSS/NSO/LINE MINISTRY" ~ 1,    # Recode as 1
      LOC01 == "INTERNATIONAL ORGANIZATION" ~ 2,        # Recode as 2
      LOC01 == "CIVIL SOCIETY ORGANIZATION (CSO)" ~ 3,  # Recode as 3
      LOC01 == "1" ~ 1,                                 # Keep "1" as is, converted to numeric
      LOC01 == "2" ~ 2,                                 # Keep "2" as is, converted to numeric
      LOC01 == "3" ~ 3,                                 # Keep "3" as is, converted to numeric
      TRUE ~ NA_real_                                  # For everything else, convert to NA
    )
  ) %>%
  mutate(
    LOC01 = as.numeric(LOC01)  # Ensure everything is numeric (NA values remain NA)
  )

# Standardize `organization` text
main_roster <- main_roster %>%
  mutate(
    morganization = toupper(organization) # Convert all text in `organization` to uppercase
  )

# Save the updated dataset under the same name
write.csv(main_roster, analysis_ready_main_roster_file, row.names = FALSE)
message("Recode of `LOC01` and capitalization of `organization` completed. Updated file saved to `analysis_ready_main_roster.csv`.")

# ======================================================
# Step 15: Converts `LOC04` text values to numeric codes: 1 = NATIONAL, 2 = SUB-NATIONAL, 6 = OTHER.
# Standardizes `LOC04` to contain only numeric values (1, 2, or 6).
# ======================================================

# Load the analysis-ready main roster file
analysis_ready_main_roster_file <- "10 Data/Analysis Ready Files/analysis_ready_main_roster.csv"

# Load the dataset
main_roster <- read.csv(analysis_ready_main_roster_file)

# Standardize `LOC04` values to numeric
main_roster <- main_roster %>%
  mutate(
    LOC04 = case_when(
      LOC04 == "01" | LOC04 == "1" | LOC04 == "NATIONAL" ~ 1,          # NATIONAL → 1
      LOC04 == "02" | LOC04 == "2" | LOC04 == "SUB-NATIONAL" ~ 2,       # SUB-NATIONAL → 2
      LOC04 == "06" | LOC04 == "6" | LOC04 == "OTHER" ~ 6,              # OTHER → 6
      TRUE ~ NA_real_                                                    # For all other cases, convert to NA
    )
  ) %>%
  mutate(
    LOC04 = as.numeric(LOC04)  # Ensure column is numeric
  )

# Save the updated dataset under the same name
write.csv(main_roster, analysis_ready_main_roster_file, row.names = FALSE)
message("Standardized `LOC04` to numeric values (1, 2, or 6). Updated file saved to `analysis_ready_main_roster.csv`.")

# ======================================================
# Step 16: Adds `morganization` and `mcountry` from `analysis_ready_main_roster`
# to `analysis_ready_group_roster` based on `pindex2`.
# Handles multiple entries for the same `pindex2`.
# ======================================================

# File paths
main_roster_file <- "10 Data/Analysis Ready Files/analysis_ready_main_roster.csv"
group_roster_file <- "10 Data/Analysis Ready Files/analysis_ready_group_roster.csv"

# Load the datasets
main_roster <- read.csv(main_roster_file)
group_roster <- read.csv(group_roster_file)

# Convert `pindex2` in both datasets to numeric for a proper join
main_roster <- main_roster %>%
  mutate(pindex2 = as.numeric(pindex2))

group_roster <- group_roster %>%
  mutate(pindex2 = as.numeric(pindex2))

# Merge `morganization` and `mcountry` into `group_roster` based on `pindex2`
group_roster <- group_roster %>%
  left_join(
    main_roster %>% select(pindex2, morganization, mcountry), # Select relevant columns
    by = "pindex2" # Join on `pindex2`
  )

# Add "Djibouti" to `mcountry` for index 17 and pindex2 == 20240032
group_roster <- group_roster %>%
  mutate(mcountry = ifelse(X_index == 17 & pindex2 == 20240032, "Djibouti", mcountry))

# Save the updated group roster
write.csv(group_roster, group_roster_file, row.names = FALSE)
message("Added `morganization` and `mcountry` to `analysis_ready_group_roster.csv`. Updated file saved.")

# ======================================================
# Step 17: Standardizes `PRO03B` in `analysis_ready_group_roster` to numeric values:
# 1 = GLOBAL, 2 = REGIONAL, 3 = COUNTRY, 8 = DON'T KNOW.
# ======================================================

# File path
group_roster_file <- "10 Data/Analysis Ready Files/analysis_ready_group_roster.csv"

# Load the dataset
group_roster <- read.csv(group_roster_file)

# Recode `PRO03B` values to numeric
group_roster <- group_roster %>%
  mutate(
    PRO03B = case_when(
      PRO03B == "01" | PRO03B == "1" | PRO03B == "GLOBAL" ~ 1,            # GLOBAL → 1
      PRO03B == "02" | PRO03B == "2" | PRO03B == "REGIONAL" ~ 2,          # REGIONAL → 2
      PRO03B == "03" | PRO03B == "3" | PRO03B == "COUNTRY" ~ 3,           # COUNTRY → 3
      PRO03B == "08" | PRO03B == "8" | PRO03B == "DON'T KNOW" ~ 8,        # DON'T KNOW → 8
      TRUE ~ NA_real_                                                     # Keep numeric if already valid
    ) 
  ) %>%
  mutate(
    PRO03B = as.numeric(PRO03B)  # Ensure column is numeric
  )

# Save the updated dataset under the same name
write.csv(group_roster, group_roster_file, row.names = FALSE)
message("Recode of `PRO03B` completed. All values are now numeric. Updated file saved to `analysis_ready_group_roster.csv`.")

# ======================================================
# Step 18: Standardizes `PRO03D` in `analysis_ready_group_roster` to numeric values:
# 1 = NATIONAL, 2 = INSTITUTIONAL, 8 = DON'T KNOW.
# ======================================================

# File path
group_roster_file <- "10 Data/Analysis Ready Files/analysis_ready_group_roster.csv"

# Load the dataset
group_roster <- read.csv(group_roster_file)

# Recode `PRO03D` values to numeric
group_roster <- group_roster %>%
  mutate(
    PRO03D = case_when(
      PRO03D == "1" | PRO03D == "NATIONAL" ~ 1,             # NATIONAL → 1
      PRO03D == "2" | PRO03D == "INSTITUTIONAL" ~ 2,        # INSTITUTIONAL → 2
      PRO03D == "8" | PRO03D == "DON'T KNOW" ~ 8,           # DON'T KNOW → 8
      TRUE ~ NA_real_                            # Keep numeric if already valid
    )
  ) %>%
  mutate(
    PRO03D = as.numeric(PRO03D)  # Ensure column is numeric
  )

# Save the updated dataset under the same name
write.csv(group_roster, group_roster_file, row.names = FALSE)
message("Recode of `PRO03D` completed. All values are now numeric. Updated file saved to `analysis_ready_group_roster.csv`.")

# ======================================================
# Step 19: Standardizes `PRO06` in `analysis_ready_group_roster` to numeric values:
# 01 = DESIGN/PLANNING, 02 = IMPLEMENTATION, 03 = COMPLETED,
# 06 = OTHER, 08 = DON’T KNOW.
# ======================================================

# File path
group_roster_file <- "10 Data/Analysis Ready Files/analysis_ready_group_roster.csv"

# Load the dataset
group_roster <- read.csv(group_roster_file)

# Recode `PRO06` values to numeric
group_roster <- group_roster %>%
  mutate(
    PRO06 = case_when(
      PRO06 == "01" | PRO06 == "1" | PRO06 == "DESIGN/PLANNING" | PRO06 == "CONCEPTION/PLANIFICATION" | PRO06 == "DISEÑO/PLANIFICACIÓN" ~ 1,
      PRO06 == "02" | PRO06 == "2" | PRO06 == "IMPLEMENTATION" | PRO06 == "MISE EN ŒUVRE" | PRO06 == "IMPLEMENTACIÓN" ~ 2,
      PRO06 == "03" | PRO06 == "3" | PRO06 == "COMPLETED" | PRO06 == "ACHEVÉ" | PRO06 == "FINALIZADA" ~ 3,
      PRO06 == "06" | PRO06 == "6" | PRO06 == "OTHER" | PRO06 == "AUTRE" | PRO06 == "OTROS" ~ 6,
      PRO06 == "08" | PRO06 == "8" | PRO06 == "DON’T KNOW" | PRO06 == "NE SAIT PAS" | PRO06 == "NO SABE" ~ 8,
      TRUE ~ NA_real_ # Keep numeric values as is
    )
  ) %>%
  mutate(
    PRO06 = as.numeric(PRO06)  # Ensure column is numeric
  )

# Save the updated dataset under the same name
write.csv(group_roster, group_roster_file, row.names = FALSE)
message("Recode of `PRO06` completed. All values are now numeric. Updated file saved to `analysis_ready_group_roster.csv`.")

# ======================================================
# Step 20: Standardizes `PRO09`, `PRO13B`, `PRO19`, and `PRO21` in `analysis_ready_group_roster`
# to numeric values: 01 = YES, 02 = NO, 08 = DON'T KNOW, 09 = NO RESPONSE.
# ======================================================

# File path
group_roster_file <- "10 Data/Analysis Ready Files/analysis_ready_group_roster.csv"

# Load the dataset
group_roster <- read.csv(group_roster_file)

# Recode PRO09, PRO13B, PRO19, and PRO21 to numeric with consistent logic
group_roster <- group_roster %>%
  mutate(across(
    c(PRO09, PRO13B, PRO19, PRO21),
    ~ case_when(
      .x %in% c("01", "1", "YES", "OUI", "SÍ") ~ 1,                                           # YES → 1
      .x %in% c("02", "2", "NO", "NON") ~ 2,                                                  # NO → 2
      .x %in% c("08", "8", "DON'T KNOW", "NE SAIT PAS", "NO SABE") ~ 8,                      # DON'T KNOW → 8
      .x %in% c("09", "9", "NO RESPONSE") ~ 9,                                               # NO RESPONSE → 9
      TRUE ~ NA_real_                                                                        # All others → NA
    ),
    .names = "{.col}"
  )) %>%
  mutate(across(c(PRO09, PRO13B, PRO19, PRO21), as.numeric))  # Ensure numeric type


# Save the updated dataset under the same name
write.csv(group_roster, group_roster_file, row.names = FALSE)
message("Recode of `PRO09` completed. All values are now numeric. Updated file saved to `analysis_ready_group_roster.csv`.")

# ======================================================
# Step 21: Standardizes `PRO14` in `analysis_ready_group_roster` to numeric values:
# 1 = YES, 2 = NO.
# ======================================================

# File path
group_roster_file <- "10 Data/Analysis Ready Files/analysis_ready_group_roster.csv"

# Load the dataset
group_roster <- read.csv(group_roster_file)

# Recode `PRO14` values to numeric
group_roster <- group_roster %>%
  mutate(
    PRO14 = case_when(
      PRO14 == "01" | PRO14 == "1" | PRO14 == "YES" | PRO14 == "OUI" | PRO14 == "SÍ" ~ 1,  # YES → 1
      PRO14 == "02" | PRO14 == "2" | PRO14 == "NO" | PRO14 == "NON" ~ 2,                  # NO → 2
      TRUE ~ NA_real_                                                            # Keep numeric values as is
    )
  ) %>%
  mutate(
    PRO14 = as.numeric(PRO14)  # Ensure column is numeric
  )

# Save the updated dataset under the same name
write.csv(group_roster, group_roster_file, row.names = FALSE)
message("Recode of `PRO14` completed. All values are now numeric. Updated file saved to `analysis_ready_group_roster.csv`.")

# ======================================================
# Step 22: Standardizes `PRO15` in `analysis_ready_group_roster` to numeric values:
# 1 = YES, 2 = NO.
# ======================================================

# File path
group_roster_file <- "10 Data/Analysis Ready Files/analysis_ready_group_roster.csv"

# Load the dataset
group_roster <- read.csv(group_roster_file)

# Recode `PRO15` values to numeric
group_roster <- group_roster %>%
  mutate(
    PRO15 = case_when(
      PRO15 == "01" | PRO15 == "1" | PRO15 == "YES" | PRO15 == "OUI" | PRO15 == "SÍ" ~ 1,  # YES → 1
      PRO15 == "02" | PRO15 == "2" | PRO15 == "NO" | PRO15 == "NON" ~ 2,                  # NO → 2
      TRUE ~ NA_real_                                                           # Keep numeric values as is
    ) 
  ) %>%
  mutate(
    PRO15 = as.numeric(PRO15)  # Ensure column is numeric
  )

# Save the updated dataset under the same name
write.csv(group_roster, group_roster_file, row.names = FALSE)
message("Recode of `PRO15` completed. All values are now numeric. Updated file saved to `analysis_ready_group_roster.csv`.")

# ======================================================
# Step 23: Standardizes `PRO17` in `analysis_ready_group_roster` to numeric values:
# 1 = YES, 2 = NO.
# ======================================================

# File path
group_roster_file <- "10 Data/Analysis Ready Files/analysis_ready_group_roster.csv"

# Load the dataset
group_roster <- read.csv(group_roster_file)

# Recode `PRO17` values to numeric
group_roster <- group_roster %>%
  mutate(
    PRO17 = case_when(
      PRO17 == "01" | PRO17 == "1" | PRO17 == "YES" | PRO17 == "OUI" | PRO17 == "SÍ" ~ 1,  # YES → 1
      PRO17 == "02" | PRO17 == "2" | PRO17 == "NO" | PRO17 == "NON" ~ 2,                  # NO → 2
      TRUE ~ NA_real_                                                           # Keep numeric values as is
    )
  ) %>%
  mutate(
    PRO17 = as.numeric(PRO17)  # Ensure column is numeric
  )

# Save the updated dataset under the same name
write.csv(group_roster, group_roster_file, row.names = FALSE)
message("Recode of `PRO17` completed. All values are now numeric. Updated file saved to `analysis_ready_group_roster.csv`.")

# ======================================================
# Step 24: Copies `LOC01` from `analysis_ready_main_roster` to `gLOC01` in `analysis_ready_group_roster` based on `pindex2`.
# ======================================================

# File paths
main_roster_file <- "10 Data/Analysis Ready Files/analysis_ready_main_roster.csv"
group_roster_file <- "10 Data/Analysis Ready Files/analysis_ready_group_roster.csv"

# Load datasets
main_roster <- read.csv(main_roster_file)
group_roster <- read.csv(group_roster_file)

# Ensure `pindex2` is numeric in both datasets
main_roster <- main_roster %>%
  mutate(pindex2 = as.numeric(pindex2))

group_roster <- group_roster %>%
  mutate(pindex2 = as.numeric(pindex2))

# Join `LOC01` from `main_roster` to `group_roster` and create `gLOC01`
group_roster <- group_roster %>%
  left_join(
    main_roster %>% select(pindex2, LOC01), # Select `pindex2` and `LOC01` from `main_roster`
    by = "pindex2" # Match on `pindex2`
  ) %>%
  rename(gLOC01 = LOC01) # Rename the joined `LOC01` column to `gLOC01`

# Save the updated group roster
write.csv(group_roster, group_roster_file, row.names = FALSE)
message("Copied `LOC01` to `gLOC01` in `analysis_ready_group_roster.csv` based on `pindex2`. Updated file saved.")

# ======================================================
# Step 25: Creates `g_conled` in `analysis_ready_group_roster` to categorize projects:
# 1 = Country-led, 2 = Institutional-led, 3 = Other (based on `gLOC01` and `PRO03D`).
# ======================================================

# File path
group_roster_file <- "10 Data/Analysis Ready Files/analysis_ready_group_roster.csv"

# Load the dataset
group_roster <- read.csv(group_roster_file)

# Check column names for debugging
print(colnames(group_roster))  # Ensure `PRO03D` and `gLOC01` are present

# Create `g_conled` based on `gLOC01` and `PRO03D`
group_roster <- group_roster %>%
  mutate(
    g_conled = case_when(
      gLOC01 == 1 ~ 1, # Country-led if `gLOC01` is 1
      gLOC01 == 2 & PRO03D == 1 ~ 1, # Country-led if `gLOC01` is 2 and `PRO03D` is 1
      gLOC01 == 2 ~ 2, # Institutional-led if `gLOC01` is 2 and `PRO03D` is not 1
      gLOC01 == 3 ~ 3, # Other if `gLOC01` is 3
      TRUE ~ NA_real_ # Assign NA for missing or unmatched cases
    )
  )

# Save the updated group roster
write.csv(group_roster, group_roster_file, row.names = FALSE)
message("Created `g_conled` in `analysis_ready_group_roster.csv` based on `gLOC01` and `PRO03D`. Updated file saved.")
# ======================================================
# Step 26: Recodes ISO country codes in `PRO03C` in `analysis_ready_group_roster` 
# to full country names (e.g., "SOM" → "Somalia"), preserving existing names.
# ======================================================
library(dplyr)

# 1) Read in the raw file
group_roster_file <- "10 Data/Analysis Ready Files/analysis_ready_group_roster.csv"
group_roster <- read.csv(group_roster_file, stringsAsFactors = FALSE)

# 2) Define your ISO→Name lookup once
iso_map <- c(
  SOM = "Somalia", LAO = "Laos", ITA = "Italy", PER = "Peru",
  LBN = "Lebanon", BFA = "Burkina Faso", CMR = "Cameroon",
  COD = "Democratic Republic of the Congo", HND = "Honduras",
  SLV = "El Salvador", ZMB = "Zambia", MOZ = "Mozambique",
  CAF = "Central African Republic", TCD = "Chad", COG = "Republic of the Congo",
  KEN = "Kenya", ETH = "Ethiopia", DJI = "Djibouti", BGD = "Bangladesh",
  CHL = "Chile", COL = "Colombia", ECU = "Ecuador", IRQ = "Iraq",
  NGA = "Nigeria", UKR = "Ukraine", UGA = "Uganda", AFG = "Afghanistan",
  SDN = "Sudan", LBY = "Libya", YEM = "Yemen", MYS = "Malaysia",
  THA = "Thailand", FRA = "France", MDA = "Moldova", EGY = "Egypt",
  JOR = "Jordan", PAN = "Panama", SYR = "Syrian Arab Republic",
  MAR = "Marshall Islands", GHA = "Ghana", ZWE = "Zimbabwe",
  MLI = "Mali", BWA = "Burundi", MRT = "Mauritania", MWI = "Malawi",
  AZE = "Azerbaijan", TUR = "Turkiye", ZAF = "South Africa"
)
library(countrycode)
library(dplyr)

group_roster <- group_roster %>%
  mutate(across(
    c(PRO03C, mcountry),
    ~ coalesce(countrycode(.x, "iso3c", "country.name"), .x)
  ))


# Save the updated dataset
write.csv(group_roster, group_roster_file, row.names = FALSE)
# Load dataset
group_roster <- read.csv(group_roster_file, stringsAsFactors = FALSE)

# --- List unique 3-letter uppercase entries in each field ---
codes_PRO03C <- group_roster %>%
  pull(PRO03C) %>%
  unique() %>%
  .[str_detect(., "^[A-Z]{3}$")]

codes_mcountry <- group_roster %>%
  pull(mcountry) %>%
  unique() %>%
  .[str_detect(., "^[A-Z]{3}$")]

# --- Display them ---
cat("3-letter codes in PRO03C:\n", paste(codes_PRO03C, collapse = ", "), "\n\n")
cat("3-letter codes in mcountry:\n", paste(codes_mcountry, collapse = ", "), "\n")
# ======================================================
# Step 27: This script updates the 'mcountry' field in the 'analysis_ready_group_roster' dataset
# by mapping ISO country codes to their full names where 'g_conled' equals 1.
# It only updates entries where 'mcountry' is NA and 'PRO03C' contains an ISO code,
# ensuring all updates are relevant to country-led examples.
# ======================================================

# File path
group_roster_file <- "10 Data/Analysis Ready Files/analysis_ready_group_roster.csv"

# Load the dataset
group_roster <- read.csv(group_roster_file)

# Example mapping of ISO codes to full country names
iso_to_country <- data.frame(
  ISO = c("SOM", "LAO", "ITA", "PER", "LBN", "BFA", "CMR", "COD", "HND", 
          "SLV", "ZMB", "CAF", "TCD", "ETH", "DJI", "CHL", "COL", "UKR", 
          "UGA", "SDN"),
  CountryName = c("Somalia", "Laos", "Italy", "Peru", "Lebanon", "Burkina Faso", 
                  "Cameroon", "Democratic Republic of the Congo", "Honduras", 
                  "El Salvador", "Zambia", "Central African Republic", "Chad", 
                  "Ethiopia", "Djibouti", "Chile", "Colombia", "Ukraine", 
                  "Uganda", "Sudan")
)

# Update `mcountry` based on ISO codes and conditions
group_roster <- group_roster %>%
  left_join(iso_to_country, by = c("PRO03C" = "ISO")) %>%
  mutate(
    mcountry = ifelse(is.na(mcountry) & g_conled == 1 & !is.na(CountryName), CountryName, mcountry)
  ) %>%
  select(-CountryName)  # Remove the temporary CountryName column after the update

# 2. Copy `PRO03C` to `mcountry` if `PRO03C` contains a full name (longer than 3 characters) and `g_conled == 1`
group_roster <- group_roster %>%
  mutate(
    mcountry = ifelse(nchar(PRO03C) > 3 & g_conled == 1 & is.na(mcountry), PRO03C, mcountry)
  )

# Update United Kingdom specific cases
group_roster <- group_roster %>%
  mutate(mcountry = ifelse(mcountry == "United Kingdom of Great Britain and Northern Ireland", 
                           "United Kingdom", 
                           mcountry))

# Save the updated dataset
write.csv(group_roster, group_roster_file, row.names = FALSE)
message("Updated `mcountry` in `analysis_ready_group_roster.csv` based on `PRO03C`. Saved to the same file.")



# ======================================================
# Step 28: Assign Regions to Countries in `analysis_ready_group_roster`
# - This script maps country names (`mcountry`) to their respective regions.
# - If a country is not in the predefined list, it is assigned "Other".
# ======================================================
library(readr)
library(dplyr)
# File path
group_roster_file <- "10 Data/Analysis Ready Files/analysis_ready_group_roster.csv"

# Load the dataset
group_roster <- read_csv(group_roster_file, show_col_types = FALSE)

# Define the final list of countries and their corresponding regions
country_region_mapping <- tibble::tribble(
  ~mcountry, ~region,
  "Armenia", "Asia",
  "Azerbaijan", "Asia",
  "Belarus", "Europe",
  "Belgium", "Europe",
  "Burkina Faso", "Africa",
  "Côte d’Ivoire", "Africa",
  "Cambodia", "Asia",
  "Cameroon", "Africa",
  "Canada", "North America",
  "Central African Republic", "Africa",
  "Chad", "Africa",
  "Chile", "South America",
  "Colombia", "South America",
  "Congo - Kinshasa", "Africa",
  "Democratic Republic of the Congo", "Africa",
  "Djibouti", "Africa",
  "Egypt", "Africa",
  "El Salvador", "North America",
  "Estonia", "Europe",
  "Ethiopia", "Africa",
  "Finland", "Europe",
  "France", "Europe",
  "Georgia", "Europe",
  "Germany", "Europe",
  "Ghana", "Africa",
  "Greece", "Europe",
  "Honduras", "North America",
  "Hungary", "Europe",
  "Indonesia", "Asia",
  "Iraq", "Middle East",
  "Italy", "Europe",
  "Jordan", "Middle East",
  "Kazakhstan", "Asia",
  "Kenya", "Africa",
  "Kyrgyzstan", "Asia",
  "Laos", "Asia",
  "Lebanon", "Middle East",
  "Liechtenstein", "Europe",
  "Mali", "Africa",
  "Marshall Islands", "Oceania",
  "Mauritania", "Africa",
  "Mexico", "North America",
  "Moldova", "Europe",
  "Morocco", "Africa",
  "Netherlands", "Europe",
  "Nigeria", "Africa",
  "Norway", "Europe",
  "Palestinian Territories", "Middle East",
  "Panama", "North America",
  "Peru", "South America",
  "Philippines", "Asia",
  "Poland", "Europe",
  "Republic of Moldova", "Europe",
  "Rwanda", "Africa",
  "Slovenia", "Europe",
  "Somalia", "Africa",
  "South Africa", "Africa",
  "South Sudan", "Africa",
  "Spain", "Europe",
  "Sri Lanka", "Asia",
  "State of Palestine", "Middle East",
  "Sudan", "Africa",
  "Sweden", "Europe",
  "Switzerland", "Europe",
  "Thailand", "Asia",
  "Turkey", "Asia",
  "Turkmenistan", "Asia",
  "Uganda", "Africa",
  "Ukraine", "Europe",
  "United Kingdom", "Europe",
  "United States", "North America",
  "Yemen", "Middle East",
  "Zambia", "Africa",
  # Additional requested country-region mappings
  "Burundi", "Africa",
  "Bangladesh", "Asia",
  "Zimbabwe", "Africa",
  "Mozambique", "Africa",
  "Malawi", "Africa",
  # "Azerbaijan", "Asia",
  # "Honduras", "North America",
  # "Marshall Islands", "Oceania"
  "Kosovo*", "Europe") #Kosovo* added in March 2025, we May have to recode due to asterisk

country_region_mapping <- country_region_mapping %>%
  unique()

# Ensure `region` column exists in `group_roster` before updating
if (!"region" %in% colnames(group_roster)) {
  group_roster <- group_roster %>%
    mutate(region = NA_character_)  # Create an empty `region` column
}

# Assign regions to the dataset
group_roster <- group_roster %>%
  left_join(country_region_mapping, by = "mcountry") %>%
  mutate(
    region = coalesce(region.y, region.x, "Other") # Fill missing values and remove `.y`
  ) %>%
  select(-region.x, -region.y) # Drop extra columns after merging

# Save the updated dataset
write_csv(group_roster, group_roster_file)
message("Updated `region` variable in `analysis_ready_group_roster.csv`. Saved to the same file.")

# ======================================================
# Step 29: Assign Regions to Countries in analysis_ready_group_roster
# This script assigns regions to countries in the analysis_ready_group_roster2 dataset.
# A predefined mapping of country names to their respective regions is used for categorization.
# The region column is added or updated to ensure consistency in geographic classifications.
# The cleaned dataset is then saved in the Analysis Ready Files folder.
# ======================================================

# Load necessary libraries
library(dplyr)
library(readr)

# Define file paths
final_version_directory <- "05 Data Collection/Data Archive/Final Version"
analysis_ready_directory <- "10 Data/Analysis Ready Files"

# File paths
group_roster2_file <- file.path(final_version_directory, "group_roster2.csv")
main_roster_file <- file.path(analysis_ready_directory, "analysis_ready_main_roster.csv")
output_group_roster2_file <- file.path(analysis_ready_directory, "analysis_ready_group_roster2.csv")

# Load datasets
group_roster2 <- read.csv(group_roster2_file)
main_roster <- read.csv(main_roster_file)

# Step 1: Check if `X_parent_index` exists
if ("X_parent_index" %in% colnames(group_roster2)) {
  group_roster2 <- group_roster2 %>%
    mutate(
      index1 = as.numeric(X_parent_index)  # Create a new numeric variable without altering the original column
    )
  message("Created `index1` as a numeric version of `X_parent_index`.")
} else {
  stop("Column `X_parent_index` not found in `group_roster2`. Check the dataset.")
}

# Step 2: Add `year` variable as 2024
group_roster2 <- group_roster2 %>%
  mutate(year = 2024)

# Step 3: Rename `index1` to `pindex1`
group_roster2 <- group_roster2 %>%
  rename(pindex1 = index1)

# Step 4: Create `pindex2` - 8-digit identifier using `year` and `pindex1`
group_roster2 <- group_roster2 %>%
  mutate(
    pindex2 = ifelse(is.na(pindex1), NA, as.numeric(sprintf("%d%04d", year, pindex1))) # Ensure numeric
  )

# Ensure `pindex2` in `main_roster` is also numeric
main_roster <- main_roster %>%
  mutate(pindex2 = as.numeric(pindex2))

# Step 5: Merge `gLOC01`, `morganization`, and `mcountry` from `main_roster`
group_roster2 <- group_roster2 %>%
  left_join(main_roster %>% select(pindex2, LOC01, morganization, mcountry), by = "pindex2")
# Ensure `region` column is created in `group_roster2`
group_roster2 <- group_roster2 %>%
  mutate(region = NA_character_)  # Create an empty `region` column

# Assign regions to `group_roster2` dataset using `country_region_mapping`
group_roster2 <- group_roster2 %>%
  left_join(country_region_mapping, by = "mcountry") %>%
  mutate(
    region = coalesce(region.y, "Other")  # Use region from mapping, fill missing with "Other"
  ) %>%
  select(-region.y)  # Drop intermediate column from join
# Create `q2025` based on the quarter variable
# Identify the column that starts with "FPR07"
column_name <- colnames(group_roster2)[startsWith(colnames(group_roster2), "FPR07")][1]

# Use the identified column in mutate
group_roster2 <- group_roster2 %>%
  mutate(
    q2025 = case_when(
      grepl("Quarter 1", .data[[column_name]]) ~ 1,
      grepl("Quarter 2", .data[[column_name]]) ~ 2,
      grepl("Quarter 3", .data[[column_name]]) ~ 3,
      grepl("Quarter 4", .data[[column_name]]) ~ 4,
      TRUE ~ NA_real_
    )
  )
# Save the final dataset
write.csv(group_roster2, output_group_roster2_file, row.names = FALSE)
message("Saved `analysis_ready_group_roster2.csv` with `pindex2`, `gLOC01`, `morganization`, and `mcountry`. File located at: ", output_group_roster2_file)

# ======================================================
# Step 30: Update `PRO02A` and `PRO03` Based on `ryear`
# - If `ryear == 2024`: 
#   - Copy `PRO02A` → `PRO03`
# - If `ryear == 2023, 2022, or 2021`: 
#   - Copy `PRO03` → `PRO02A`
# ======================================================

# File path
group_roster_file <- "10 Data/Analysis Ready Files/analysis_ready_group_roster.csv"

# Load dataset
group_roster <- read_csv(group_roster_file, show_col_types = FALSE)

# Ensure required columns exist
required_columns <- c("ryear", "PRO02A", "PRO03")
missing_columns <- setdiff(required_columns, colnames(group_roster))

if (length(missing_columns) > 0) {
  stop(paste("Missing required columns:", paste(missing_columns, collapse = ", ")))
}

# Apply conditional updates
group_roster <- group_roster %>%
  mutate(
    PRO03 = ifelse(ryear == 2024, PRO02A, PRO03),   # Copy `PRO02A` → `PRO03`
    PRO02A = ifelse(ryear %in% c(2023, 2022, 2021), PRO03, PRO02A)  # Copy `PRO03` → `PRO02A`
  )

# Save the updated dataset
write_csv(group_roster, group_roster_file)
message("Successfully updated `PRO02A` and `PRO03` based on `ryear` conditions (Step 32).")

# ======================================================
# Step 31: Overwrite `group_roster` Values Using JDC Data
# - Matches rows where `pindex2` & `X_index` are identical.
# - Replaces values for specified columns directly.
# - Ensures data integrity by only updating matching records.
# ======================================================

# File path
group_roster_file <- "10 Data/Analysis Ready Files/analysis_ready_group_roster.csv"

# Load datasets
group_roster <- read_csv(group_roster_file, show_col_types = FALSE)
jdc <- read_csv("06 Data Cleaning/Data Clean_JDC.csv", show_col_types = FALSE)

group_roster <- group_roster %>%
  rename_with(~ gsub("^X_", "", .), starts_with("X_"))


# jdc <- data_clean_data[["JDC"]] %>%
#   rename(PRO07a = `PRO07a. Please elaborate on other populations captured in <span style='color:#3b71b9; font-weight: bold;'>${_PRO02A}</span>`)

# colnames(jdc) <- gsub("\\.", "/", colnames(jdc))
# colnames(group_roster)[is.na(colnames(group_roster))] <- "new_column_name" #there is one column without a column name
# print(colnames(group_roster))

# group_roster_ls <- group_roster %>%
#   filter(pindex2==20240115)

group_roster <- group_roster %>%
  left_join(jdc, by = c("pindex2", "index" = "X_index"))

group_roster <- group_roster %>%
  # Loop through columns ending with .x (lowercase)
  mutate(across(
    .cols = ends_with(".x"),  # Apply to columns ending with .x (lowercase)
    .fns = ~ {
      y_col_name <- paste0(sub(".x$", "", cur_column()), ".y")
      # Only use the .y column from the same group_roster if it exists
      if (y_col_name %in% colnames(group_roster)) {
        coalesce(as.character(.x), as.character(group_roster[[y_col_name]]))
      } else {
        .x  # If .y column doesn't exist, keep the original .x column
      }
    },
    .names = "{.col}"  # Keep the same column name
  )) %>%
  select(-ends_with(".y")) %>%

  # Rename columns to remove .x (lowercase only)
  rename_with(~ gsub("\\.x$", "", .), ends_with(".x")) %>%
  mutate(region = case_when(
    mcountry == "Sudan" ~ "Africa",
    mcountry == "Burundi" ~ "Africa",
    mcountry == "Central African Republic" ~ "Africa",
    mcountry == "Iraq" ~ "Middle East",
    mcountry == "Turkiye" ~ "Asia",
    mcountry == "Bangladesh" ~ "Asia",
    mcountry == "Zimbabwe" ~ "Africa",
    mcountry == "Mauritania" ~ "Africa",
    mcountry == "Mozambique" ~ "Africa",
    mcountry == "Malawi" ~ "Africa",
    TRUE ~ region))
# Step 4: Recalculate `g_conled` ONLY for `pindex2 == 20240115`

group_roster <- group_roster %>%
  mutate(g_conled = as.numeric(g_conled))

group_roster <- group_roster %>%
  mutate(
    g_conled = case_when(
      pindex2 == 20240115 & gLOC01 == 1 ~ 1,  # Country-led if `gLOC01` is 1
      pindex2 == 20240115 & gLOC01 == 2 & PRO03D == 1 ~ 1,  # Country-led if `gLOC01` is 2 and `PRO03D` is 1
      pindex2 == 20240115 & gLOC01 == 2 ~ 2,  # Institutional-led if `gLOC01` is 2 and `PRO03D` is not 1
      pindex2 == 20240115 & gLOC01 == 3 ~ 3,  # Other if `gLOC01` is 3
      TRUE ~ g_conled  # Keep existing values for other rows
    )
  )

# Save updated version to "analysis_ready_group_roster.csv"
analysis_ready_file <- "10 Data/Analysis Ready Files/analysis_ready_group_roster.csv"
write_csv(group_roster, analysis_ready_file)

message("✅ Updated `group_roster` has been saved to: ", analysis_ready_file)

# Save updated version of "group_roster" back to the list
final_version_data[["group_roster"]] <- group_roster
library(dplyr)
library(readr)

# ======================================================
# Step 32: Write and Clean PRO12 roster for challenges and use of recommendations
# ======================================================

# Load datasets
group_roster <- read_csv("10 Data/Analysis Ready Files/analysis_ready_group_roster.csv", show_col_types = FALSE)
repeat_data <- read_csv("05 Data Collection/Data Archive/Final Version/repeat_PRO11_PRO12.csv", show_col_types = FALSE)

# Ensure `_parent_index` is numeric in `repeat_data`
repeat_data <- repeat_data %>%
  mutate(across(c(`_parent_index`), as.numeric))

# Map values from group_roster without duplicating rows in repeat_data
repeat_data <- repeat_data %>%
  mutate(
    morganization = group_roster$morganization[match(`_parent_index`, group_roster$index)],
    mcountry = group_roster$mcountry[match(`_parent_index`, group_roster$index)],
    gPRO04 = group_roster$gPRO04[match(`_parent_index`, group_roster$index)],
    gPRO05 = group_roster$gPRO05[match(`_parent_index`, group_roster$index)],
    gLOC01 = group_roster$gLOC01[match(`_parent_index`, group_roster$index)],
    g_conled = group_roster$g_conled[match(`_parent_index`, group_roster$index)],
    region = group_roster$region[match(`_parent_index`, group_roster$index)]
  )

library(dplyr)
library(readr)

# ======================================================
# Step 33: Write and Clean PRO12 roster for challenges and use of recommendations
# ======================================================

# Load datasets
group_roster <- read_csv("10 Data/Analysis Ready Files/analysis_ready_group_roster.csv", show_col_types = FALSE)
repeat_data <- read_csv("05 Data Collection/Data Archive/Final Version/repeat_PRO11_PRO12.csv", show_col_types = FALSE)

# Ensure `_parent_index` is numeric in `repeat_data`
repeat_data <- repeat_data %>%
  mutate(across(c(`_parent_index`), as.numeric))

# Map values from group_roster without duplicating rows in repeat_data
repeat_data <- repeat_data %>%
  mutate(
    morganization = group_roster$morganization[match(`_parent_index`, group_roster$index)],
    mcountry = group_roster$mcountry[match(`_parent_index`, group_roster$index)],
    gPRO04 = group_roster$gPRO04[match(`_parent_index`, group_roster$index)],
    gPRO05 = group_roster$gPRO05[match(`_parent_index`, group_roster$index)],
    gLOC01 = group_roster$gLOC01[match(`_parent_index`, group_roster$index)],
    g_conled = group_roster$g_conled[match(`_parent_index`, group_roster$index)],
    region = group_roster$region[match(`_parent_index`, group_roster$index)]
  )

library(dplyr)
library(readr)
# ======================================================
# Step 34: Renames column `NA.` in `analysis_ready_group_roster` to `PRO20`.
# This typically occurs if the column had no header or was malformed in the source file.
# ======================================================

# File paths
group_roster_file <- "10 Data/Analysis Ready Files/analysis_ready_group_roster.csv"

# Load datasets
group_roster <- read.csv(group_roster_file)

# Rename column `NA.` to `PRO20`
group_roster <- group_roster %>%
  rename(PRO20 = `NA.`)
# Save the updated dataset
write.csv(group_roster, group_roster_file, row.names = FALSE)
# ======================================================
# Step 35: Standardize PRO04 to year-only format from mixed inputs
# Handles: MDY strings, Excel serials, plain years, and special values like "9999"
# ======================================================

library(dplyr)
library(lubridate)
# File paths
group_roster_file <- "10 Data/Analysis Ready Files/analysis_ready_group_roster.csv"

# Load datasets
group_roster <- read.csv(group_roster_file)
group_roster <- group_roster %>%
  mutate(
    PRO04_year = case_when(
      # Preserve 9999
      PRO04 == "9999" ~ "9999",
      
      # Plain 4-digit year
      grepl("^\\d{4}$", PRO04) ~ PRO04,
      
      # Excel serial numbers
      suppressWarnings(!is.na(as.numeric(PRO04))) & as.numeric(PRO04) > 1000 & as.numeric(PRO04) < 60000 ~
        as.character(year(as.Date(as.numeric(PRO04), origin = "1899-12-30"))),
      
      # ISO-format YYYY-MM-DD
      grepl("^\\d{4}-\\d{2}-\\d{2}$", PRO04) ~ as.character(year(ymd(PRO04))),
      
      # US-style MM/DD/YYYY or M/D/YYYY
      grepl("^\\d{1,2}/\\d{1,2}/\\d{4}$", PRO04) ~ as.character(year(mdy(PRO04))),
      
      # Everything else becomes NA
      TRUE ~ NA_character_
    )
  )

group_roster <- group_roster %>%
  mutate(
    PRO05_year = case_when(
      # Handle date strings like "1/1/9999" as 9999
      grepl("^1/1/9999$", PRO05) ~ "9999",
      grepl("^1/1/9998$", PRO05) ~ "9998",
      
      # Preserve exact values 9999, 9998
      PRO05 %in% c("9999", "9998") ~ PRO05,
      
      # MDY format (1/1/2024)
      grepl("^\\d{1,2}/\\d{1,2}/\\d{4}$", PRO05) ~ as.character(year(mdy(PRO05))),
      
      # ISO date (e.g., 2024-09-30)
      grepl("^\\d{4}-\\d{2}-\\d{2}$", PRO05) ~ as.character(year(ymd(PRO05))),
      
      # Plain 4-digit years
      grepl("^\\d{4}$", PRO05) ~ PRO05,
      
      # Excel-style serial numbers within valid range
      suppressWarnings(!is.na(as.numeric(PRO05))) & as.numeric(PRO05) > 1000 & as.numeric(PRO05) < 60000 ~
        as.character(year(as.Date(as.numeric(PRO05), origin = "1899-12-30"))),
      
      # Everything else → NA
      TRUE ~ NA_character_
    )
  )
# === Preview before saving ===
cat("\n===== Preview of cleaned PRO04_year values =====\n")
print(head(group_roster$PRO04_year, 20))         # Print first 20 entries
cat("\n===== Frequency table of PRO04_year =====\n")
print(table(group_roster$PRO04_year, useNA = "ifany"))
cat("\nFirst 20 values of PRO05_year:\n")
print(head(group_roster$PRO05_year, 20))

cat("\nFrequency table:\n")
print(table(group_roster$PRO05_year, useNA = "ifany"))

# === Save updated dataset ===
write.csv(group_roster, group_roster_file, row.names = FALSE)
message("PRO04 standardized to year format in new variable `PRO04_year`.")

# ======================================================
# Step 36: Write and Clean PRO12 roster for challenges and use of recommendations
# ======================================================

# Load datasets
group_roster <- read_csv("10 Data/Analysis Ready Files/analysis_ready_group_roster.csv", show_col_types = FALSE)
repeat_data <- read_csv("05 Data Collection/Data Archive/Final Version/repeat_PRO11_PRO12.csv", show_col_types = FALSE)

# Ensure `_parent_index` is numeric in `repeat_data`
repeat_data <- repeat_data %>%
  mutate(across(c(`_parent_index`), as.numeric))

# Map values from group_roster without duplicating rows in repeat_data
repeat_data <- repeat_data %>%
  mutate(
    morganization = group_roster$morganization[match(`_parent_index`, group_roster$index)],
    mcountry = group_roster$mcountry[match(`_parent_index`, group_roster$index)],
    gPRO04 = group_roster$gPRO04[match(`_parent_index`, group_roster$index)],
    gPRO05 = group_roster$gPRO05[match(`_parent_index`, group_roster$index)],
    gLOC01 = group_roster$gLOC01[match(`_parent_index`, group_roster$index)],
    g_conled = group_roster$g_conled[match(`_parent_index`, group_roster$index)],
    region = group_roster$region[match(`_parent_index`, group_roster$index)]
  )


# Rename PRO12 variables systematically


# Identify PRO12 columns (ensure they contain "PRO12" somewhere)
pro12_columns <- grep("PRO12", names(repeat_data), value = TRUE)

# Define standard labels starting with "PRO12" and then "PRO12A" to "PRO12I"
standard_labels <- c("PRO12", "PRO12A", "PRO12B", "PRO12C", "PRO12D", 
                     "PRO12E", "PRO12F", "PRO12G", "PRO12H", "PRO12I")

# Assign names in sequence
if (length(pro12_columns) >= 10) {
  main_pro12_names <- setNames(pro12_columns[1:10], standard_labels)
} else {
  main_pro12_names <- setNames(pro12_columns, standard_labels[seq_along(pro12_columns)])
}

# Identify the "Other (Specify)" and "Don't Know" columns
pro12_other <- grep("OTHER|SPECIFY", pro12_columns, value = TRUE, ignore.case = TRUE)
pro12_dont_know <- grep("DON.TKNOW|DONâ€™TKNOW|DONTKNOW", pro12_columns, value = TRUE, ignore.case = TRUE)

# Assign PRO12X for "Other (Specify)" and PRO12Z for "Don't Know"
if (length(pro12_other) > 0) {
  main_pro12_names["PRO12X"] <- pro12_other[1]
}
if (length(pro12_dont_know) > 0) {
  main_pro12_names["PRO12Z"] <- pro12_dont_know[1]
}

# Rename columns in repeat_data
names(repeat_data)[match(unlist(main_pro12_names), names(repeat_data))] <- names(main_pro12_names)


# Convert PRO12 variables to numeric
pro12_numeric_vars <- c("PRO12", "PRO12A", "PRO12B", "PRO12C", "PRO12D", 
                        "PRO12E", "PRO12F", "PRO12G", "PRO12H", "PRO12I",
                        "PRO12X", "PRO12Z")

# Ensure these columns exist in the dataset before converting
existing_pro12_vars <- intersect(pro12_numeric_vars, names(repeat_data))

repeat_data <- repeat_data %>%
  mutate(across(all_of(existing_pro12_vars), as.numeric))

# Save the cleaned dataset
write_csv(repeat_data, "10 Data/Analysis Ready Files/analysis_ready_repeat_PRO11_PRO12.csv")

# Confirm success
message("Updated repeat_data saved successfully with properly renamed PRO12 variables as numeric!")




# ======================================================
# Step 37: Write and Clean GRF Repeat Pledge File (Without Increasing Rows)
# ======================================================

# Load necessary libraries
library(dplyr)
library(readr)
library(openxlsx)

# File paths
repeat_pledges_path <- "05 Data Collection/Data Archive/Final Version/repeat_pledges.csv"
main_roster_path <- "10 Data/Analysis Ready Files/analysis_ready_main_roster.csv"
output_path <- "10 Data/Analysis Ready Files/repeat_pledges_cleaned.csv"

# Load datasets
repeat_pledges <- read_csv(repeat_pledges_path, show_col_types = FALSE)
main_roster <- read_csv(main_roster_path, show_col_types = FALSE)

# Ensure `_parent_index` is numeric
repeat_pledges <- repeat_pledges %>%
  mutate(across(c(`_parent_index`), as.numeric))

# Map values from `main_roster` without increasing rows in `repeat_pledges`
repeat_pledges_cleaned <- repeat_pledges %>%
  mutate(
    mcountry = main_roster$mcountry[match(`_parent_index`, main_roster$index)],
    morganization = main_roster$morganization[match(`_parent_index`, main_roster$index)],
    LOC01 = main_roster$LOC01[match(`_parent_index`, main_roster$index)]
  )

# Rename column for pledge status
colnames(repeat_pledges_cleaned)[
  colnames(repeat_pledges_cleaned) == "GRF04. What is the current status of the pledge implementation for pledge: **${pledge_name}?**"
] <- "GRF04"

# Save cleaned dataset as CSV
write_csv(repeat_pledges_cleaned, output_path)

# Print success message
cat("The repeat_pledges dataset has been cleaned and saved as 'repeat_pledges_cleaned.csv'.\n")

# ======================================================
# Step 38: Data Cleaning: Merge Unique PRO18 Variables into Analysis Ready Group Roster
# ======================================================

# Load necessary libraries
library(dplyr)
library(readr)

# File paths
partners_file <- "06 Data Cleaning/analysis_ready_group_roster_partners.csv"
roster_file <- "10 Data/Analysis Ready Files/analysis_ready_group_roster.csv"
output_file <- "10 Data/Analysis Ready Files/analysis_ready_group_roster.csv"

# Load datasets
partners_data <- read_csv(partners_file)
roster_data <- read_csv(roster_file)

# Ensure all relevant columns are numeric
partners_data <- partners_data %>%
  mutate(across(c(PRO18.A, PRO18.B, PRO18.C), as.numeric))

# Keep only unique matches based on identical index & pindex2
partners_data_unique <- partners_data %>%
  distinct(index, pindex2, .keep_all = TRUE)  # Remove duplicates

# Merge only exact matches
updated_roster <- roster_data %>%
  left_join(partners_data_unique %>% select(index, pindex2, PRO18.A, PRO18.B, PRO18.C), 
            by = c("index", "pindex2"))

# Resolve .x and .y suffixes by keeping the most complete data
updated_roster <- updated_roster %>%
  mutate(across(
    .cols = ends_with(".x"),  # Apply to columns ending with .x
    .fns = ~ {
      y_col_name <- paste0(sub(".x$", "", cur_column()), ".y")
      # Use .y column if it exists; otherwise, keep .x
      if (y_col_name %in% colnames(updated_roster)) {
        coalesce(as.character(.x), as.character(updated_roster[[y_col_name]]))
      } else {
        .x  # If .y column doesn't exist, keep .x column
      }
    },
    .names = "{.col}"  # Retain original column names
  )) %>%
  # Drop all .y columns after merging
  select(-ends_with(".y")) %>%
  rename_with(~ sub(".x$", "", .), ends_with(".x"))  # Remove .x from column names

# Save the updated dataset
write_csv(updated_roster, output_file)

# Print success message
cat("The updated analysis_ready_group_roster has been saved as 'analysis_ready_group_roster.csv'.\n")

# ======================================================
# Step 39: Standardizes response variables in `analysis_ready_main_roster`
# to numeric values: 01 = YES, 02 = NO, 08 = DON'T KNOW, 09 = NO RESPONSE.
# Applies to: PRO01A, FPR01, GRF02, ACT02, ACT03, ACT05, FOL01, FOC04A
# ======================================================

# File path
main_roster_file <- "10 Data/Analysis Ready Files/analysis_ready_main_roster.csv"

# Load the dataset
main_roster <- read.csv(main_roster_file, stringsAsFactors = FALSE)

# Recode to numeric using unified logic
main_roster <- main_roster %>%
  mutate(across(
    c(PRO01A, FPR01, GRF02, ACT02, ACT03, ACT05, FOL01, FOC04A),
    ~ case_when(
      .x %in% c("01", "1", "YES", "OUI", "SÍ") ~ 1,
      .x %in% c("02", "2", "NO", "NON") ~ 2,
      .x %in% c("08", "8", "DON'T KNOW", "NE SAIT PAS", "NO SABE") ~ 8,
      .x %in% c("09", "9", "NO RESPONSE") ~ 9,
      TRUE ~ NA_real_
    ),
    .names = "{.col}"
  )) %>%
  mutate(across(c(PRO01A, FPR01, GRF02, ACT02, ACT03, ACT05, FOL01, FOC04A), as.numeric))

# Save the updated dataset
write.csv(main_roster, main_roster_file, row.names = FALSE)
message("Response variables standardized in `analysis_ready_main_roster.csv` and saved.")
# ======================================================
# Step 40: Merge & recode UPD02/UPD03A, create UPD25
# ======================================================
library(readr)
library(dplyr)

# 1) File paths
group_roster_file  <- file.path(analysis_ready_directory, "analysis_ready_group_roster.csv")
prev_projects_file <- file.path(analysis_ready_directory, "prev_projects _clean.csv")

# 2) Load data
gr <- read_csv(group_roster_file,  show_col_types = FALSE)
pp <- read_csv(prev_projects_file, show_col_types = FALSE)

# 3) Shorten any long UPD* headers so we have plain UPD02 & UPD03A in pp
shorten_upd <- function(df) {
  for(pref in c("UPD02","UPD03A")) {
    hits <- grep(paste0("^", pref), names(df), perl = TRUE, value = TRUE)
    if(length(hits)>0) df <- df %>% rename(!!pref := all_of(hits[1]))
  }
  df
}
pp <- shorten_upd(pp)

# 4) Merge in the two new columns
gr <- gr %>%
  left_join(
    pp %>% select(index, pindex2, UPD02, UPD03A),
    by = c("pindex2", "index")
  )

# 5) Now recode UPD02 into PRO06 categories, then build UPD25
gr <- gr %>%
  mutate(
    UPD02 = as.character(UPD02),
    rec_UPD02 = case_when(
      UPD02 %in% c("01","1","DESIGN/PLANNING","CONCEPTION/PLANIFICATION","DISEÑO/PLANIFICACIÓN") ~ 1,
      UPD02 %in% c("02","2","IMPLEMENTATION","MISE EN ŒUVRE","IMPLEMENTACIÓN")             ~ 2,
      UPD02 %in% c("03","3","COMPLETED","ACHEVÉ","FINALIZADA")                           ~ 3,
      UPD02 %in% c("06","6","OTHER","AUTRE","OTROS")                                     ~ 6,
      UPD02 %in% c("08","8","DON’T KNOW","NE SAIT PAS","NO SABE")                       ~ 8,
      TRUE                                                                                ~ NA_real_
    ),
    UPD25 = coalesce(as.numeric(rec_UPD02), PRO06)
  ) %>%
  select(-rec_UPD02)

# 6) Save back over the CSV
write_csv(gr, group_roster_file)
message("✔ Step 41 complete: UPD02/UPD03A merged, UPD25 created.")

# ======================================================
# Step 41: Identify & Remove Complete Duplicate Rows in `group_roster` for 2024
# + Lists index numbers and requested values before cleaning
# + Keeps other years unchanged
# + Saves the cleaned version back to `analysis_ready_group_roster.csv`
# + Removes specific rows based on the `index` column from `del_group_roster_37`
# ======================================================

# Load necessary libraries
library(dplyr)
library(readr)
library(readxl)

# File paths
group_roster_file <- "10 Data/Analysis Ready Files/analysis_ready_group_roster.csv"
duplicate_entries_file <- "10 Data/Analysis Ready Files/duplicate_entries_2024.csv"

# File path for the data cleaning Excel file
data_clean_file <- "06 Data Cleaning/EGRISS_GAIN_2024_-_Data Clean.xlsx"

# Load dataset
group_roster <- read_csv(group_roster_file, show_col_types = FALSE)

# Step 1: Identify duplicate rows for 2024
group_roster_2024 <- group_roster %>% filter(ryear == 2024)

# Find complete duplicates (all column values are identical)
duplicates_2024 <- group_roster_2024 %>%
  group_by(across(everything())) %>%
  filter(n() > 1) %>%
  ungroup()

# Extract requested values for duplicate rows
duplicate_entries <- duplicates_2024 %>%
  select(submission__id, submission__submission_time, morganization, PRO02A, mcountry, ryear, index, parent_index) %>%
  distinct()

# Save duplicate entries before cleaning
write_csv(duplicate_entries, duplicate_entries_file)
message("📌 Duplicate entries for 2024 saved in `duplicate_entries_2024.csv`.")

# Step 2: Remove complete duplicate rows only for 2024
group_roster_2024_cleaned <- group_roster_2024 %>% distinct()

# Preserve data from other years
group_roster_other <- group_roster %>% filter(ryear != 2024)

# Combine cleaned 2024 data with other years
group_roster_final <- bind_rows(group_roster_2024_cleaned, group_roster_other)

# Step 3: Remove specific rows based on `index` values from `del_group_roster_37`

# Load the Excel sheet containing indexes to be removed
del_group_roster_37 <- read_excel(data_clean_file, sheet = "del_group_roster_37")

# Ensure `index` column is numeric
del_group_roster_37 <- del_group_roster_37 %>% mutate(index = as.numeric(index))

# Remove rows from `group_roster_final` where `index` is in `del_group_roster_37`
group_roster_final <- group_roster_final %>%
  filter(!index %in% del_group_roster_37$index)

message("🚀 Removed specific rows from `group_roster` based on `index` values from `del_group_roster_37`.")

# Save cleaned dataset back to the same file (overwrite)
write_csv(group_roster_final, group_roster_file)

message("✅ Cleaned version of `group_roster` saved as `analysis_ready_group_roster.csv`.")

# ======================================================
# Step 42: Recode `group_roster` for Analysis Ready File
# ======================================================

# Define file path
roster_file <- "10 Data/Analysis Ready Files/analysis_ready_group_roster.csv"

# Load dataset
roster_data <- read_csv(roster_file)

# Apply recoding ONLY where:
# - ryear == 2024
# - mcountry == "Norway"
# - PRO09 is exactly 2 (no other values are changed)
# Additionally, set PRO10.A to 1 and PRO10 to "IRRS" for Norway (2024) where index is 52, 53, 91-97
roster_data <- roster_data %>%
  mutate(
    ryear = as.numeric(ryear),
    PRO09 = ifelse(ryear == 2024 & mcountry == "Norway" & PRO09 == 2, 1, PRO09),
    `PRO10.A` = ifelse(ryear == 2024 & mcountry == "Norway" & index %in% c(52, 53, 91:97), 1, `PRO10.A`),
    PRO10 = ifelse(ryear == 2024 & mcountry == "Norway" & index %in% c(52, 53, 91:97), "IRRS", PRO10)
  ) %>%
  mutate(
    PRO09 = as.numeric(PRO09),
    `PRO10.A` = as.numeric(`PRO10.A`)
  )

# Save the updated dataset
write_csv(roster_data, roster_file)

# Print success message
cat("Recode applied to 'analysis_ready_group_roster.csv' for Norway (2024) where PRO10.A is now 1 and PRO10 is 'IRRS' based on index condition, and saved.\n")


# ======================================================
# Step 43: GRF File Merging 
# ======================================================

# Load necessary libraries
library(readxl)
library(dplyr)

# File paths
pledge_data_path    <- "10 Data/GRF Files External and Internal/Statistical_Inclusion_Pledge_Datav03.xlsx"
repeat_pledges_path <- "10 Data/Analysis Ready Files/repeat_pledges_cleaned.csv"

# Read the data files
stat_pledges <- read_excel(pledge_data_path, sheet = "Statistical Inclusion Pledges") %>%
  mutate(pledge_id = as.character(`Pledge ID`))

pledge_updates <- read_excel(pledge_data_path, sheet = "Pledge Updates 2024") %>%
  mutate(pledge_id = as.character(`Pledge ID`))

repeat_pledges <- read.csv(repeat_pledges_path, stringsAsFactors = FALSE) %>%
  mutate(
    Pledge.ID = gsub("GRF_", "GRF-", pledge_name),
    pledge_id = as.character(Pledge.ID)
  )

# Deduplicate to avoid many-to-many joins
pledge_updates <- pledge_updates %>% distinct(pledge_id, .keep_all = TRUE)
repeat_pledges <- repeat_pledges %>% distinct(pledge_id, .keep_all = TRUE)

# From repeat_pledges, map GRF04 codes → pledge-style text so we can fall back on them
repeat_pledges <- repeat_pledges %>%
  mutate(grf4_pledge = case_when(
    GRF04 == "COMPLETED"        ~ "Fulfilled",
    GRF04 == "DESIGN/PLANNING"  ~ "Planning stage",
    GRF04 == "IMPLEMENTATION"   ~ "In progress",
    TRUE                         ~ NA_character_
  ))

# Prepare lookup tables
pledge_updates_clean <- pledge_updates %>%
  select(pledge_id, `Implementation Stage FU`) %>%
  rename(Implementation_Stage_FU_updates = `Implementation Stage FU`)

repeat_pledges_clean <- repeat_pledges %>%
  select(pledge_id, grf4_pledge)

# Identify which IDs are unique to each set
ids_updates_only <- setdiff(pledge_updates_clean$pledge_id, repeat_pledges_clean$pledge_id)
ids_repeat_only  <- setdiff(repeat_pledges_clean$pledge_id, pledge_updates_clean$pledge_id)

# Join everything and compute the final stage + source flag
stat_pledges <- stat_pledges %>%
  left_join(pledge_updates_clean, by = "pledge_id") %>%
  left_join(repeat_pledges_clean, by = "pledge_id") %>%
  mutate(
    # Final stage: prefer raw-text update; else use grf4_pledge from repeat_pledges
    stage_final = coalesce(
      Implementation_Stage_FU_updates,
      grf4_pledge
    ),
    
    # Source flag: 1 if it came from the raw-text update,
    #              2 if it came from the grf4_pledge fallback,
    #             NA if neither
    source_pledge = case_when(
      !is.na(Implementation_Stage_FU_updates)                         ~ 1L,
      is.na(Implementation_Stage_FU_updates) & !is.na(grf4_pledge)    ~ 2L,
      TRUE                                                            ~ NA_integer_
    )
  ) %>%
  select(-Implementation_Stage_FU_updates, -grf4_pledge)

# Country–region mapping
df_country_region <- tibble::tribble(
  ~mcountry,                         ~region,
  "Armenia",                          "Asia",
  "Azerbaijan",                       "Asia",
  "Belarus",                          "Europe",
  "Belgium",                          "Europe",
  "Burkina Faso",                     "Africa",
  "Côte d’Ivoire",                    "Africa",
  "Cambodia",                         "Asia",
  "Cameroon",                         "Africa",
  "Canada",                           "North America",
  "Central African Republic",         "Africa",
  "Chad",                             "Africa",
  "Chile",                            "South America",
  "Colombia",                         "South America",
  "Congo - Kinshasa",                 "Africa",
  "Democratic Republic of the Congo","Africa",
  "Djibouti",                         "Africa",
  "Egypt",                            "Africa",
  "El Salvador",                      "North America",
  "Estonia",                          "Europe",
  "Ethiopia",                         "Africa",
  "Finland",                          "Europe",
  "France",                           "Europe",
  "Georgia",                          "Europe",
  "Germany",                          "Europe",
  "Ghana",                            "Africa",
  "Greece",                           "Europe",
  "Honduras",                         "North America",
  "Hungary",                          "Europe",
  "Indonesia",                        "Asia",
  "Iraq",                             "Middle East",
  "Italy",                            "Europe",
  "Jordan",                           "Middle East",
  "Kazakhstan",                       "Asia",
  "Kenya",                            "Africa",
  "Kyrgyzstan",                       "Asia",
  "Laos",                             "Asia",
  "Lebanon",                          "Middle East",
  "Liechtenstein",                    "Europe",
  "Mali",                             "Africa",
  "Marshall Islands",                 "Oceania",
  "Mauritania",                       "Africa",
  "Mexico",                           "North America",
  "Moldova",                          "Europe",
  "Morocco",                          "Africa",
  "Netherlands",                      "Europe",
  "Nigeria",                          "Africa",
  "Norway",                           "Europe",
  "Palestinian Territories",          "Middle East",
  "Panama",                           "North America",
  "Peru",                             "South America",
  "Philippines",                      "Asia",
  "Poland",                           "Europe",
  "Republic of Moldova",              "Europe",
  "Rwanda",                           "Africa",
  "Slovenia",                         "Europe",
  "Somalia",                          "Africa",
  "South Africa",                     "Africa",
  "South Sudan",                      "Africa",
  "Spain",                            "Europe",
  "Sri Lanka",                        "Asia",
  "State of Palestine",               "Middle East",
  "Sudan",                            "Africa",
  "Sweden",                           "Europe",
  "Switzerland",                      "Europe",
  "Thailand",                         "Asia",
  "Turkey",                           "Asia",
  "Turkmenistan",                     "Asia",
  "Uganda",                           "Africa",
  "Ukraine",                          "Europe",
  "United Kingdom",                   "Europe",
  "United States",                    "North America",
  "Yemen",                            "Middle East",
  "Zambia",                           "Africa",
  "Burundi",                          "Africa",
  "Bangladesh",                       "Asia",
  "Zimbabwe",                         "Africa",
  "Mozambique",                       "Africa",
  "Malawi",                           "Africa",
  "Kosovo*",                          "Europe",
  "Guinea-Bissau",                    "Africa",
  "United States of America",         "North America",
  "Gambia",                           "Africa",
  "Nepal",                            "Asia",
  "Costa Rica",                       "North America",
  "Belize",                           "North America",
  "Niger",                            "Africa",
  "Denmark",                          "Europe",
  "The Philippines",                  "Asia",
  "Australia",                        "Oceania",
  "Democratic Republic of The Congo", "Africa",
  "Brazil",                           "South America",
  "New Zealand",                      "Oceania",
  "Angola",                           "Africa",
  "Bulgaria",                         "Europe",
  "Eswatini",                         "Africa"
)

stat_pledges <- stat_pledges %>%
  left_join(
    df_country_region,
    by = c("Country - Submitting Entity" = "mcountry")
  )

# Final deduplication and save
stat_pledges   <- stat_pledges   %>% distinct(pledge_id, .keep_all = TRUE)
pledge_updates <- pledge_updates %>% distinct(pledge_id, .keep_all = TRUE)
repeat_pledges <- repeat_pledges %>% distinct(pledge_id, .keep_all = TRUE)

output_dir <- "10 Data/Analysis Ready Files"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

write.csv(stat_pledges,   file.path(output_dir, "Statistical_Inclusion_Pledges_Updated.csv"), row.names = FALSE)
write.csv(pledge_updates, file.path(output_dir, "Pledge_Updates_2024.csv"),                 row.names = FALSE)
write.csv(repeat_pledges, file.path(output_dir, "repeat_pledges_cleaned.csv"),               row.names = FALSE)
# ======================================================
# Step 44: Remove specified variables from main roster and save as "main.csv"
# ======================================================

# Define file paths:
analysis_ready_main_roster_file <- "10 Data/Analysis Ready Files/analysis_ready_main_roster.csv"
output_file <- "10 Data/Analysis Ready Files/main.csv"

# Create a vector of columns to remove:
cols_to_remove <- c(
  "LOC06_2", "Country_UNHCR", "prev_projects", "PRO02Note", "END01",
  "X_id", "X_uuid", "X_submission_time", "X_validation_status", "X_notes",
  "X_status", "X_submitted_by", "X__version__", "X_tags", "FOL01",
  "FOL02A", "FOL02B", "FOL02C", "FOL02D", "FOL03", "FOL04", "ACT06.A",
  "count_ACT04", "ACT04", "count_pledges", "GRF03", "pledgesavailable",
  "organizationGRF", "FPR02", "count_FPR02", "count_PRO02A", "PRO02",
  "NameFOC04_1", "NameFOC04_2", "NameFOC04_3", "NameFOC04_4", "NameFOC04_5",
  "NameFOC04_6", "NameFOC04_7", "NameFOC04_8", "NameFOC04_9", "NameFOC04_10",
  "UPD01", "count_prev_projects", "LOC01B", "LOC02", "LOC03", "LOC04",
  "LOC04A", "LOC05", "LOC06", "LOC06_UNCT", "LOC06A", "UNHCR_Level",
  "Bureau", "LOC06C", "LOC06_3", "LOC06_2_other", "LOC06_2_label",
  "LOC06_2_label2", "LOC06_label", "LOC06_label2", "LOC01B_label",
  "LOC06_4", "organization", "FOC01A", "FOC01B", "FOC01C", "NameFOC01",
  "FOC02", "FOC03A", "start", "end", "today", "logo"
)

# Check if the main roster file exists, then remove listed columns and save as main.csv
if (file.exists(analysis_ready_main_roster_file)) {
  main_roster <- read.csv(analysis_ready_main_roster_file)
  
  main_roster_sub <- main_roster %>%
    select(-any_of(cols_to_remove))
  
  write.csv(main_roster_sub, output_file, row.names = FALSE)
  
  message(paste("Successfully removed requested columns. File saved as:", output_file))
} else {
  stop("The file 'analysis_ready_main_roster.csv' does not exist in the specified directory.")
}

# ======================================================
# Step 45: Create final version of group_roster as `pro.csv`
# Removes administrative, unused, and auxiliary fields
# ======================================================
# Define file paths:
# File paths
group_roster_file <- "10 Data/Analysis Ready Files/analysis_ready_group_roster.csv"

# Load datasets
group_roster <- read.csv(group_roster_file)
# List of variables to remove (optional ones marked with `?`)
vars_to_remove <- c(
  "submission__tags",
  "submission___version__",
  "submission__status",
  "submission__submitted_by",
  "submission__validation_status",
  "submission__submission_time",
  "submission__uuid",
  "submission__id",
  "year/ryear",
  "PRO14A",
  "PRO18",
  "PRO13",
  "PRO16",
  "parent_table_name",
  "index",
  "parent_index",
  "PRO22AA",
  "PRO22",
  "PRO20A",
  "PRO13C_other",
  "PRO13C",
  "recommendations",
  "count_recommendations",
  "PRO10",
  "PRO08a",
  "PRO08",
  "PRO07a",
  "PRO07",
  "phase",
  "PRO06A",
  "project",
  "PRO02A"
)

# Keep only variables not in the removal list
group_roster_final <- group_roster %>%
  select(-any_of(vars_to_remove))

# Save final version as pro.csv
write.csv(group_roster_final, "10 Data/Analysis Ready Files/pro.csv", row.names = FALSE)
message("Final cleaned group roster saved as `pro.csv` with selected variables removed.")


# ======================================================
# Step 46: Backup Analysis Ready Files with a Timestamp
# ======================================================

# Load necessary libraries
library(fs)  # For file operations
library(lubridate)  # For timestamp generation
library(stringr)  # For string manipulation

# Define the base directory for analysis-ready files
analysis_ready_directory <- "10 Data/Analysis Ready Files"

# Define the backup folder with timestamp
timestamp <- format(Sys.time(), "%Y-%m-%d_%H-%M-%S")  # Generate timestamp
backup_directory <- file.path(analysis_ready_directory, paste0("Backup_", timestamp))

# Ensure the backup directory exists
dir_create(backup_directory)
message("✅ Backup folder created: ", backup_directory)

# List all analysis-ready files (excluding previous backups)
analysis_files <- dir_ls(analysis_ready_directory, type = "file")
analysis_files <- analysis_files[!str_detect(analysis_files, "Backup_")]

# Copy each file to the backup folder
file_copy(analysis_files, backup_directory, overwrite = TRUE)

# List and print the backed-up files
backup_files <- dir_ls(backup_directory, type = "file")
message("📂 Backup Completed. Files in the backup folder:")
print(backup_files)
