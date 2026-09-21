source(file.path("R", "bold_engine.R"))
source(file.path("R", "boin_engine.R"))
source(file.path("R", "scenarios.R"))
source(file.path("R", "analysis_utils.R"))

result <- run_all_scenarios(
  scenarios = default_scenarios(),
  phi = 0.30,
  cohort_size = 3,
  n_max = 18,
  n_stop_per_dose = 12,
  gamma = 0.90,
  tau = 0.50,
  pess = 3,
  n_trial = 500,
  seed = 20260918,
  methods = c("BOLD", "BOIN")
)

tables <- format_result_tables(result)
dir.create("results", showWarnings = FALSE, recursive = TRUE)
utils::write.csv(result$scenarios, file.path("results", "scenario_definitions.csv"), row.names = FALSE)
utils::write.csv(tables$summary, file.path("results", "operating_characteristics.csv"), row.names = FALSE)
utils::write.csv(tables$selection, file.path("results", "dose_selection_percentages.csv"), row.names = FALSE)
utils::write.csv(tables$allocation, file.path("results", "mean_patient_allocation.csv"), row.names = FALSE)
saveRDS(result, file.path("results", "simulation_results.rds"))

message("Saved results to: ", normalizePath("results"))
print(tables$summary, row.names = FALSE)
