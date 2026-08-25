#!/usr/bin/env Rscript
# =============================================================================
# 00_run_all.R — Master pipeline for the nanoemulsion optimization analysis
#
# Usage: Rscript R/00_run_all.R   (from anywhere)
# =============================================================================

project_root <- function() {
  a <- commandArgs(trailingOnly = FALSE)
  f <- sub("^--file=", "", a[grepl("^--file=", a)])
  if (length(f) && nzchar(f)) {
    return(normalizePath(file.path(dirname(f), "..")))
  }
  normalizePath(".")
}
setwd(project_root())
dir.create("output", showWarnings = FALSE)

message("Project root: ", getwd())

steps <- c(
  "R/01_power_simulation.R",
  "R/02_generate_data.R",
  "R/03_check_assumptions.R",
  "R/04_anova_posthoc.R"
)

for (s in steps) {
  message("\n===== Running ", s, " =====")
  sys.source(s, envir = new.env())
}

message("\n===== Pipeline complete =====")
message("Outputs written to: ", file.path(getwd(), "output"))
