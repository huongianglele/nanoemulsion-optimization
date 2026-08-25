#!/usr/bin/env Rscript
# =============================================================================
# 02_generate_data.R — Generate the factorial experimental dataset
#
# 3 (Smix ratio) x 3 (oil:Smix ratio) full-factorial design, 3 replicates each
# = 27 runs. Flux (Jss) is simulated with main effects, a 2:1 x 1:6 synergy,
# and Gaussian lab noise. NOTE: data are simulated in silico for demonstration;
# the same analysis pipeline accepts a real experimental CSV instead.
#
# Output: data/nanoemulsion_data.csv
# =============================================================================

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
})

project_root <- function() {
  a <- commandArgs(trailingOnly = FALSE)
  f <- sub("^--file=", "", a[grepl("^--file=", a)])
  if (length(f) && nzchar(f)) {
    return(normalizePath(file.path(dirname(f), "..")))
  }
  normalizePath(".")
}
setwd(project_root())
dir.create("data", showWarnings = FALSE)

set.seed(123)

smix_levels      <- c("1:1", "2:1", "3:1")
oil_ratio_levels <- c("1:4", "1:5", "1:6")

design <- expand.grid(Smix_Ratio = smix_levels, Oil_Smix_Ratio = oil_ratio_levels)
design$Formulation_ID <- paste0("F", 1:9)

full_data <- design[rep(seq_len(nrow(design)), each = 3), ]
full_data$Replicate <- rep(1:3, times = 9)

simulate_flux <- function(smix, ratio) {
  flux <- 15                                   # baseline
  if (smix == "2:1")     flux <- flux + 12     # Smix 2:1 main effect
  if (smix == "3:1")     flux <- flux + 6      # Smix 3:1 main effect
  if (ratio == "1:5")    flux <- flux + 4      # oil 1:5 main effect
  if (ratio == "1:6")    flux <- flux + 8      # oil 1:6 main effect
  if (smix == "2:1" & ratio == "1:6") flux <- flux + 15  # synergy term
  flux <- flux + rnorm(1, 0, 1.5)              # lab noise
  round(flux, 1)
}

full_data$Flux_Jss <- mapply(simulate_flux,
                             full_data$Smix_Ratio,
                             full_data$Oil_Smix_Ratio)

write_csv(full_data, "data/nanoemulsion_data.csv")

cat("---- PART 2: SIMULATED DATASET (first 9 rows) ----\n")
print(head(full_data, 9))
cat("\nWrote data/nanoemulsion_data.csv (", nrow(full_data), "rows )\n")
