library(ggplot2)
d <- read.csv("docs/data/car_t_six_scenarios.csv")
d <- subset(d, scenario %in% c("1", "2", "3", "4", ">4"))
d$scenario <- factor(d$scenario, c("1", "2", "3", "4", ">4"),
                     c("Dose 1", "Dose 2", "Dose 3", "Dose 4", "All below target\n(>4)"))
d$method <- factor(d$method, c("Original BOLD", "Experimental BOLD", "BOIN"))
# Decimal half-up rounding avoids floating-point ties in saved percentages.
d$label <- sprintf("%.1f", floor(d$accuracy_pct * 10 + 0.5 + 1e-8) / 10)
p <- ggplot(d, aes(scenario, accuracy_pct, fill = method)) +
  geom_col(position = position_dodge(.8), width = .72) +
  geom_text(aes(label = label), position = position_dodge(.8), vjust = -.4, size = 4) +
  scale_fill_manual(values = c("#0B7A82", "#B1457A", "#C46A00"), name = NULL) +
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 20), labels = function(x) paste0(x, "%")) +
  labs(title = "MTD-selection accuracy: Dose 1 through above Dose 4",
       subtitle = "10,000 trials/scenario; target 0.30; N=18; cohorts of 3; toxicity cutoff 0.90*",
       x = "True MTD state", y = "Correct selection",
       caption = paste("Dose 4 true DLT rates: (0.05, 0.10, 0.20, 0.30). Subset of six scenarios; full results in README.",
         "*Experimental BOLD: Dose 1 cutoff 0.85; tau 0.50 changes to 0.49 after any DLT. Original BOLD: tau 0.50.", sep = "\n")) +
  theme_minimal(base_size = 13) +
  theme(panel.grid.major.x = element_blank(), panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold", size = 19),
        plot.caption = element_text(hjust = 0, size = 10),
        legend.position = "bottom", plot.margin = margin(16, 16, 16, 16))
dir.create("docs/figures", recursive = TRUE, showWarnings = FALSE)
ggsave("docs/figures/mtd_selection_accuracy_upper_scenarios.png", p, width = 12, height = 7, dpi = 240)
ggsave("docs/figures/mtd_selection_accuracy_upper_scenarios.pdf", p, width = 12, height = 7)
