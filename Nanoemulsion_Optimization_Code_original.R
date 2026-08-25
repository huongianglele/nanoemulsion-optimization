# ==============================================================================
# R SCRIPT: MINOXIDIL NANOEMULSION OPTIMIZATION PROJECT
# Purpose: Sample Size Simulation, Data Generation, ANOVA, and Post-Hoc Analysis
# ==============================================================================

# ------------------------------------------------------------------------------
# PART 1: SAMPLE SIZE "MULTIVERSE" SIMULATION (Reverse Probability)
# ------------------------------------------------------------------------------
# We assume Formulation B (Optimized) is truly better than A (Baseline).
mean_A <- 20       # Baseline Flux
mean_B <- 30       # Improved Flux (+10 units)
sd_noise <- 8      # Lab Error (Pipetting mistakes, machine noise)
n <- 3             # Replicates per group
alpha <- 0.05      # Significance threshold
simulations <- 5000 # Number of "Parallel Universes" to simulate

set.seed(42) # Set seed for reproducibility

# Run the "Multiverse" Loop
p_values <- replicate(simulations, {
  group_A <- rnorm(n, mean = mean_A, sd = sd_noise)
  group_B <- rnorm(n, mean = mean_B, sd = sd_noise)
  test_result <- t.test(group_A, group_B, var.equal = TRUE)
  test_result$p.value
})

# Calculate the "Success Rate" (Power)
wins <- sum(p_values < alpha)
success_rate <- wins / simulations

print("--- PART 1: POWER SIMULATION RESULTS ---")
print(paste("Total Simulations:", simulations))
print(paste("Calculated Success Rate (Power):", round(success_rate * 100, 1), "%"))
if(success_rate >= 0.80) {
  print("VERDICT: ✅ SUFFICIENT. n=3 is safe to use.")
} else {
  print("VERDICT: ❌ INSUFFICIENT. You need more samples.")
}
cat("\n")

# ------------------------------------------------------------------------------
# PART 2: GENERATING THE EXPERIMENTAL DATASET (Factorial Design)
# ------------------------------------------------------------------------------
set.seed(123)

# Define the Factors
smix_levels <- c("1:1", "2:1", "3:1")
oil_ratio_levels <- c("1:4", "1:5", "1:6")

# Create Factorial Design (3x3 = 9 unique recipes, 3 replicates each = 27 runs)
design <- expand.grid(Smix_Ratio = smix_levels, Oil_Smix_Ratio = oil_ratio_levels)
design$Formulation_ID <- paste0("F", 1:9)

full_data <- design[rep(seq_len(nrow(design)), each = 3), ]
full_data$Replicate <- rep(1:3, times = 9)

# Function to simulate Flux (Higher is Better)
simulate_flux <- function(smix, ratio) {
  flux <- 15 # Baseline
  if(smix == "2:1") flux <- flux + 12  
  if(smix == "3:1") flux <- flux + 6   
  if(ratio == "1:5") flux <- flux + 4  
  if(ratio == "1:6") flux <- flux + 8  
  if(smix == "2:1" & ratio == "1:6") flux <- flux + 15 # Synergy
  flux <- flux + rnorm(1, 0, 1.5) # Lab noise
  return(round(flux, 1))
}

full_data$Flux_Jss <- mapply(simulate_flux, full_data$Smix_Ratio, full_data$Oil_Smix_Ratio)

print("--- PART 2: SIMULATED DATASET (First 9 Rows) ---")
print(head(full_data, 9)) 
cat("\n")

# ------------------------------------------------------------------------------
# PART 3: VALIDATING ASSUMPTIONS (Normality of Residuals)
# ------------------------------------------------------------------------------
# Fit the ANOVA Model
model <- aov(Flux_Jss ~ Smix_Ratio * Oil_Smix_Ratio, data = full_data)

# Extract the Residuals (The "Noise")
model_residuals <- residuals(model)

# Statistical Proof (Shapiro-Wilk Test)
shapiro_test <- shapiro.test(model_residuals)

print("--- PART 3: NORMALITY VALIDATION ---")
print(paste("Shapiro-Wilk P-Value:", round(shapiro_test$p.value, 4)))
if(shapiro_test$p.value > 0.05) {
  print("VERDICT: ✅ PASS. The residuals follow a Normal Distribution.")
} else {
  print("VERDICT: ❌ FAIL. Data is skewed.")
}
cat("\n")

# ------------------------------------------------------------------------------
# PART 4: STATISTICAL ANALYSIS (ANOVA & POST-HOC)
# ------------------------------------------------------------------------------
print("--- PART 4: ANOVA RESULTS (Omnibus Test) ---")
print(summary(model))
cat("\n")

print("--- PART 4: POST-HOC (TUKEY HSD) RESULTS ---")
# Run Tukey HSD to find the specific winner
tukey_results <- TukeyHSD(model)
print(tukey_results)
