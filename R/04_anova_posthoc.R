#!/usr/bin/env Rscript
# =============================================================================
# 04_anova_posthoc.R — Omnibus ANOVA and Tukey HSD post-hoc comparisons
#
# Outputs:
#   output/anova_table.csv
#   output/tukey_interaction.csv
#   output/boxplot_flux.png
#   output/interaction_plot.png
# =============================================================================

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
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

# --- Omnibus ANOVA -----------------------------------------------------------
cat("---- PART 4: ANOVA (omnibus) ----\n")
print(summary(model))

aov_table <- as.data.frame(summary(model)[[1]])
aov_table$term <- rownames(aov_table)
write_csv(aov_table, "output/anova_table.csv")

# --- Tukey HSD ----------------------------------------------------------------
tukey <- TukeyHSD(model)
cat("\n---- PART 4: TUKEY HSD (interaction contrasts) ----\n")
print(tukey$`Smix_Ratio:Oil_Smix_Ratio`)

tukey_int <- as.data.frame(tukey$`Smix_Ratio:Oil_Smix_Ratio`)
tukey_int$comparison <- rownames(tukey_int)
write_csv(tukey_int, "output/tukey_interaction.csv")

# --- Publication-style figures -------------------------------------------------
theme_pub <- function(base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title    = element_text(face = "bold", size = base_size + 1),
      legend.position = "bottom",
      legend.title  = element_blank()
    )
}

p_box <- ggplot(dat, aes(Smix_Ratio, Flux_Jss, fill = Oil_Smix_Ratio)) +
  geom_boxplot(alpha = 0.85) +
  scale_fill_brewer(palette = "Set2") +
  theme_pub() +
  labs(title = "Flux by Smix ratio and oil:Smix ratio",
       x = "Smix ratio", y = expression(Flux~(J[ss])))

means <- dat |>
  group_by(Smix_Ratio, Oil_Smix_Ratio) |>
  summarise(mean_flux = mean(Flux_Jss), sd_flux = sd(Flux_Jss), .groups = "drop")

p_int <- ggplot(means, aes(Smix_Ratio, mean_flux,
                           color = Oil_Smix_Ratio, group = Oil_Smix_Ratio)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2.5) +
  geom_errorbar(aes(ymin = mean_flux - sd_flux, ymax = mean_flux + sd_flux),
                width = 0.1) +
  scale_color_brewer(palette = "Set2") +
  theme_pub() +
  labs(title = "Interaction profile (mean flux ± SD)",
       x = "Smix ratio", y = expression(Mean~flux~(J[ss])))

ggsave("output/boxplot_flux.png", p_box, width = 7, height = 5, dpi = 300)
ggsave("output/interaction_plot.png", p_int, width = 7, height = 5, dpi = 300)

message("Wrote ANOVA/Tukey tables and figures to output/")
