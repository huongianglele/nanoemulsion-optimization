# Minoxidil Nanoemulsion Optimization
## Factorial design, power simulation, ANOVA, and Tukey HSD

A reproducible R analysis of a **3 × 3 full-factorial experiment** optimizing a
minoxidil nanoemulsion formulation. Two factors are varied — surfactant
co-surfactant (Smix) ratio and oil:Smix ratio — and the response is **flux
(Jss)**, where higher is better.

> ⚠️ **Note on data:** the response data are **simulated in silico** (`02_generate_data.R`)
> to illustrate the full statistical workflow. The same pipeline accepts a real
> experimental CSV by replacing `data/nanoemulsion_data.csv`.

---

## The four analysis steps

| Script | What it does |
|---|---|
| `R/01_power_simulation.R` | Sample-size "multiverse" simulation: how often does n = 3 detect a true +10-unit flux difference? |
| `R/02_generate_data.R` | Builds the 3 × 3 factorial design (27 runs) and simulates flux. |
| `R/03_check_assumptions.R` | Fits the ANOVA and validates residual normality (Shapiro-Wilk) + diagnostic plots. |
| `R/04_anova_posthoc.R` | Omnibus two-way ANOVA and Tukey HSD post-hoc comparisons + figures. |

---

## Key results

**1. Power simulation (a cautionary finding).** With n = 3 replicates, σ = 8
noise, and a true +10-unit effect, a two-sample t-test detects the difference
only **21.6%** of the time — far below the 80% convention. This flags n = 3 as
**underpowered** for effect sizes of this magnitude and motivates larger
replicates for confirmatory experiments.

**2. ANOVA (omnibus).** All terms are significant:

| Source | Df | Sum Sq | F | p |
|---|---|---|---|---|
| Smix ratio | 2 | 1327.8 | 264.9 | < 0.001 |
| Oil:Smix ratio | 2 | 683.5 | 136.4 | < 0.001 |
| Smix × Oil:Smix | 4 | 271.4 | 27.1 | < 0.001 |
| Residuals | 18 | 45.1 | | |

**3. Residual diagnostics.** Shapiro-Wilk p = 0.66 → residuals are consistent
with normality (assumption satisfied).

**4. Tukey HSD.** The interaction is driven by a **synergy**: formulation
**Smix 2:1 + oil:Smix 1:6** has the highest flux (≈ +33.6 units vs. baseline,
p < 0.001), confirming the optimum is the 2:1 × 1:6 combination, not either
factor alone.

---

## Reproduce the analysis

**Dependencies (R ≥ 4.1):** `readr`, `dplyr`, `tidyr`, `ggplot2`.

```r
install.packages(c("readr", "dplyr", "tidyr", "ggplot2"))
```

Run everything (scripts locate the project root automatically):

```bash
Rscript R/00_run_all.R
```

Each script can also be run individually. Outputs are written to `output/`:

- `power_simulation_results.csv`
- `shapiro_test.csv`
- `anova_table.csv`
- `tukey_interaction.csv`
- `diagnostic_qq.png`, `diagnostic_resid_fitted.png`
- `boxplot_flux.png`, `interaction_plot.png`

The original single-file script is retained for reference at
`Nanoemulsion_Optimization_Code_original.R`.

---

## Repository structure

```
.
├── R/
│   ├── 00_run_all.R           # master pipeline
│   ├── 01_power_simulation.R
│   ├── 02_generate_data.R
│   ├── 03_check_assumptions.R
│   └── 04_anova_posthoc.R
├── data/
│   └── nanoemulsion_data.csv  # generated 27-run factorial dataset
├── output/                    # generated tables and figures
├── Nanoemulsion_Optimization_Code_original.R
└── README.md
```

## Author

**Giang H. Le** — pharmaceutical formulation research, minoxidil nanoemulsion
optimization. This analysis accompanies a factorial ANOVA and Tukey HSD study of
experimental formulation data.
