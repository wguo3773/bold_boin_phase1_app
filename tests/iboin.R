source("R/iboin_engine.R")
source("R/boin_engine.R")
source("R/bold_engine.R")
source("R/scenarios.R")
source("R/analysis_utils.R")
# Official iBOIN V1.6.3.0 decision table observed at phi=.30, q=.30, ESS=3.
b <- iboin_boundaries(.30,rep(.30,4),rep(3,4),12)
stopifnot(identical(b[[1]]$escalate,c(0,0,0,0,1,1,1,1,2,2,2,2)),
  identical(b[[1]]$deescalate,c(1,1,2,2,2,3,3,3,4,4,4,5)))
stopifnot(iboin_select(c(3,0,0,0),c(2,0,0,0),.30,rep(.30,4),rep(3,4),.90)==0)
stopifnot(iboin_select(c(3,0,0,0),c(2,0,0,0),.30,rep(.30,4),rep(3,4),.95)==1)
stopifnot(iboin_select(c(6,6,3,3),c(2,1,1,2),.30,rep(.30,4),rep(3,4),.90)==3)
for(p in list(c(.15,.30,.45,.60),rep(.05,4),rep(.30,4))) {
  a <- simulate_iboin_oc(p,n_trial=200,pess=0,keep_trials=TRUE)
  b <- simulate_boin_oc(p,n_trial=200,keep_trials=TRUE)
  stopifnot(identical(a$trials$selected,b$trials$selected),
    identical(a$trials$total_n,b$trials$total_n))
}
s <- protocol_scenarios()
stopifnot(nrow(s)==9,!"S8"%in%s$scenario)
z <- run_all_scenarios(s,n_trial=10,methods=c("BOLD","BOIN","iBOIN","BOLD-exp"))
stopifnot(nrow(z$summary)==36,all(is.finite(z$summary$accuracy_pct)))
for(key in names(z$detail)) {
  d <- z$detail[[key]]$trials
  stopifnot(all(rowSums(d[,paste0("n_dose",1:4)])==d$total_n),all(d$total_n<=18))
}
cat("iBOIN decision, safety, zero-ESS parity and protocol tests passed.\n")
