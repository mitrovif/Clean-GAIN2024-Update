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
