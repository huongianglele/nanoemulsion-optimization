#!/usr/bin/env Rscript
# =============================================================================
# 01_power_simulation.R — Sample-size power simulation
#
# "Reverse probability" / multiverse approach: if the optimized formulation (B)
# is truly +10 flux units better than baseline (A), how often does a two-sample
# t-test with n = 3 replicates correctly detect it?
#
# Output: output/power_simulation_results.csv
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
dir.create("output", showWarnings = FALSE)

mean_A      <- 20   # baseline flux
mean_B      <- 30   # improved flux (+10 units)
sd_noise    <- 8    # lab / measurement noise
n           <- 3    # replicates per group
alpha       <- 0.05 # significance threshold
simulations <- 5000 # number of "parallel universes"

set.seed(42) # reproducibility

p_values <- replicate(simulations, {
  t.test(rnorm(n, mean_A, sd_noise),
         rnorm(n, mean_B, sd_noise),
         var.equal = TRUE)$p.value
})

power <- mean(p_values < alpha)

cat("---- PART 1: POWER SIMULATION RESULTS ----\n")
cat("Total simulations:", simulations, "\n")
cat(sprintf("Power (probability of detecting a true +10 unit difference): %.1f%%\n",
            power * 100))
cat(if (power >= 0.80) "VERDICT: SUFFICIENT (power >= 80%).\n"
    else "VERDICT: INSUFFICIENT. Increase replicates per group.\n")

write_csv(
  tibble(mean_A, mean_B, sd_noise, n, alpha, simulations, power),
  "output/power_simulation_results.csv"
)
