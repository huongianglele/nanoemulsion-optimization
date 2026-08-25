#!/usr/bin/env Rscript
# =============================================================================
# 03_check_assumptions.R — ANOVA residual diagnostics
#
# Fits the two-way factorial ANOVA, checks residual normality (Shapiro-Wilk),
# and produces diagnostic plots (Q-Q and residuals-vs-fitted).
#
# Outputs:
#   output/shapiro_test.csv
#   output/diagnostic_qq.png
#   output/diagnostic_resid_fitted.png
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

dat <- read_csv("data/nanoemulsion_data.csv", show_col_types = FALSE) |>
  mutate(
    Smix_Ratio     = factor(Smix_Ratio,     levels = c("1:1", "2:1", "3:1")),
    Oil_Smix_Ratio = factor(Oil_Smix_Ratio, levels = c("1:4", "1:5", "1:6"))
  )

model <- aov(Flux_Jss ~ Smix_Ratio * Oil_Smix_Ratio, data = dat)
resid_df <- tibble(fitted = fitted(model), residual = residuals(model))

shapiro <- shapiro.test(residuals(model))
cat("---- PART 3: NORMALITY VALIDATION ----\n")
cat(sprintf("Shapiro-Wilk p-value: %.4f\n", shapiro$p.value))
cat(if (shapiro$p.value > 0.05) "VERDICT: PASS. Residuals are consistent with normality.\n"
    else "VERDICT: FAIL. Residuals deviate from normality.\n")

write_csv(tibble(statistic = unname(shapiro$statistic),
                 p_value = shapiro$p.value),
          "output/shapiro_test.csv")

theme_pub <- function(base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(plot.title = element_text(face = "bold", size = base_size + 1))
}

p_qq <- ggplot(resid_df, aes(sample = residual)) +
  stat_qq() +
  stat_qq_line() +
  theme_pub() +
  labs(title = "Normal Q-Q plot of ANOVA residuals",
       x = "Theoretical quantiles", y = "Sample quantiles")

p_rf <- ggplot(resid_df, aes(fitted, residual)) +
  geom_point(size = 2, alpha = 0.8) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey40") +
  theme_pub() +
  labs(title = "Residuals vs. fitted values",
       x = "Fitted flux", y = "Residual")

ggsave("output/diagnostic_qq.png", p_qq, width = 6, height = 5, dpi = 300)
ggsave("output/diagnostic_resid_fitted.png", p_rf, width = 6, height = 5, dpi = 300)

message("Wrote output/shapiro_test.csv and diagnostic plots")
