#!/usr/bin/env Rscript
# =============================================================================
# 01_power_simulation.R — Sample-size power simulation and power curve
#
# Reverse-probability ("multiverse") approach: for a two-sample t-test with
# n = 3 replicates and sd = 8 lab noise, how often is a true flux difference
# detected? We report (a) power for the observed effect (~33 units, the F6
# optimum vs. baseline) and (b) a full power curve across effect sizes,
# including the minimum detectable difference (MDD) at 80% power.
#
# Outputs:
#   output/power_simulation_results.csv
#   output/power_curve.csv
#   output/power_curve.png
# =============================================================================

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(ggplot2)
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

mean_A          <- 20   # baseline flux
sd_noise        <- 8    # observed lab / measurement noise
n               <- 3    # replicates per group
alpha           <- 0.05 # significance threshold
simulations     <- 5000 # "parallel universes" per scenario
observed_effect <- 33   # observed F6 (Smix 2:1 x Oil:Smix 1:6) vs. baseline

power_for <- function(diff, seed = 42) {
  set.seed(seed)
  p_values <- replicate(simulations, {
    t.test(rnorm(n, mean_A, sd_noise),
           rnorm(n, mean_A + diff, sd_noise),
           var.equal = TRUE)$p.value
  })
  mean(p_values < alpha)
}

# --- (a) Power at the observed effect size -----------------------------------
power_observed <- power_for(observed_effect)

cat("---- PART 1: POWER SIMULATION RESULTS ----\n")
cat(sprintf("Observed effect (optimum vs. baseline): %d units\n", observed_effect))
cat(sprintf("sd = %.1f, n = %d, simulations = %d\n", sd_noise, n, simulations))
cat(sprintf("Power to detect the %d-unit effect: %.1f%%\n",
            observed_effect, power_observed * 100))
cat(if (power_observed >= 0.80) "VERDICT: SUFFICIENT (power >= 80%).\n"
    else "VERDICT: INSUFFICIENT. Increase replicates per group.\n")

# --- (b) Power curve and minimum detectable difference -----------------------
diffs <- c(10, 15, 20, 25, 30, 33, 40)
power_curve <- tibble(
  diff = diffs,
  power = vapply(diffs, power_for, numeric(1))
)

# Minimum detectable difference at 80% power (linear interpolation on curve)
mdd <- approx(power_curve$power, power_curve$diff, xout = 0.80)$y

cat(sprintf("\nMinimum detectable difference at 80%% power: %.1f units\n", mdd))
print(power_curve)

write_csv(tibble(mean_A, sd_noise, n, alpha, simulations,
                 observed_effect, power_observed, mdd_80pct = mdd),
          "output/power_simulation_results.csv")
write_csv(power_curve, "output/power_curve.csv")

p <- ggplot(power_curve, aes(diff, power)) +
  geom_line(color = "#2C7BB6", linewidth = 1) +
  geom_point(size = 2.5, color = "#2C7BB6") +
  geom_hline(yintercept = 0.80, linetype = "dashed", color = "grey40") +
  geom_vline(xintercept = mdd, linetype = "dotted", color = "grey40") +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1),
                     limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
  labs(title = "Statistical power vs. true flux difference",
       subtitle = sprintf("n = %d per group, sd = %.1f; dashed line = 80%% power; MDD = %.1f units",
                          n, sd_noise, mdd),
       x = "True flux difference (units)", y = "Power") +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold"))

ggsave("output/power_curve.png", p, width = 7, height = 5, dpi = 300)

message("Wrote output/power_simulation_results.csv, power_curve.csv, power_curve.png")
