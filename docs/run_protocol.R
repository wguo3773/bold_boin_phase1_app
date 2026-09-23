source("R/bold_engine.R")
source("R/boin_engine.R")
source("R/iboin_engine.R")
source("R/scenarios.R")
source("R/analysis_utils.R")

dir.create("docs/data",recursive=TRUE,showWarnings=FALSE)
ans <- run_all_scenarios(protocol_scenarios(),n_trial=10000,seed=20260920,
  methods=c("BOLD","BOLD-exp","BOIN","iBOIN"))
write.csv(ans$scenarios,"docs/data/protocol_scenarios.csv",row.names=FALSE)
write.csv(ans$summary,"docs/data/protocol_performance.csv",row.names=FALSE)
write.csv(ans$selection,"docs/data/protocol_selections.csv",row.names=FALSE)
write.csv(ans$allocation,"docs/data/protocol_allocations.csv",row.names=FALSE)
parameters <- data.frame(parameter=names(ans$parameters),
  value=vapply(ans$parameters,function(x) paste(x,collapse=";"),character(1)))
write.csv(parameters,"docs/data/protocol_parameters.csv",row.names=FALSE)
saveRDS(ans,"results/protocol_10000.rds")
source("docs/plot_protocol.R")
print(ans$summary)
