# Independent implementation of Zhou et al. (2020), equations 2.3 and 2.5.
iboin_boundaries <- function(phi, q, m, n_max) {
  if (length(phi)!=1L || !is.finite(phi) || phi<=0 || 1.4*phi>=1 ||
      length(q)!=length(m) || any(!is.finite(c(q,m))) ||
      any(q<=0 | q>=1) || any(m<0 | m!=floor(m)))
    stop("iBOIN requires prior means in (0,1), nonnegative integer PESS, and target below 1/1.4.")
  rates <- c(phi,.6*phi,1.4*phi)
  lapply(seq_along(q), function(j) {
    z <- 0:m[j]
    support <- vapply(z,function(x) {
      ll <- dbinom(x,m[j],rates,log=TRUE)
      a <- exp(ll-max(ll))
      a/sum(a)
    },numeric(3))
    w <- as.vector(support %*% dbinom(z,m[j],q[j]))
    n <- seq_len(n_max)
    e <- pmax(0,(log((1-rates[2])/(1-phi))+log(w[2]/w[1])/n)/
      log(phi*(1-rates[2])/(rates[2]*(1-phi))))
    d <- pmin(1,(log((1-phi)/(1-rates[3]))+log(w[1]/w[3])/n)/
      log(rates[3]*(1-phi)/(phi*(1-rates[3]))))
    if(any(e>=d)) stop("This prior produces overlapping iBOIN boundaries; reduce PESS or revise the prior.")
    data.frame(n=n,escalate=floor(n*e+1e-10),deescalate=ceiling(n*d-1e-10))
  })
}

iboin_select <- function(n,y,phi,q,m,gamma,eliminated=rep(FALSE,length(n)),use_prior=TRUE) {
  unsafe <- which(n>=3 & pbeta(phi,y+1,n-y+1,lower.tail=FALSE)>gamma)
  if(length(unsafe)) eliminated[min(unsafe):length(n)] <- TRUE
  ids <- which(n>0 & !eliminated)
  if(!length(ids) || eliminated[1]) return(0L)
  if(!use_prior || all(m==0)) {
    result <- BOIN::select.mtd(phi,n,y,cutoff.eli=gamma)$MTD
    return(if(result %in% ids) as.integer(result) else 0L)
  }
  a <- y[ids]+m[ids]*q[ids]
  b <- n[ids]-y[ids]+m[ids]*(1-q[ids])
  # A zero-ESS dose uses BOIN's small regularization for variance weights.
  zero <- m[ids]==0
  a[zero] <- a[zero]+.05
  b[zero] <- b[zero]+.05
  p <- a/(a+b)
  variance <- a*b/((a+b)^2*(a+b+1))
  p <- Iso::pava(p,w=1/variance)+seq_along(ids)*1e-10
  ids[which.min(abs(p-phi))]
}

simulate_iboin_oc <- function(true_dlt,n_trial=500L,phi=.30,cohort_size=3L,
    n_max=18L,n_stop_per_dose=12L,gamma=.90,true_state=NULL,
    seed=20260918L,keep_trials=FALSE,start_dose=1L,require_stability=TRUE,
    prior_mean=phi,pess=3L,use_prior=TRUE) {
  J <- length(true_dlt)
  if(!length(prior_mean)%in%c(1L,J) || !length(pess)%in%c(1L,J))
    stop("Specify one iBOIN prior value or one per dose.")
  q <- rep_len(prior_mean,J); m <- rep_len(pess,J)
  stopifnot(n_trial>=1,n_trial==floor(n_trial),n_max>=cohort_size,
    n_max%%cohort_size==0,start_dose%in%seq_len(J),length(gamma)==1,
    is.finite(gamma),gamma>0,gamma<1,length(n_stop_per_dose)==1,
    n_stop_per_dose>=1,all(is.finite(true_dlt)),all(true_dlt>0 & true_dlt<1),
    all(diff(true_dlt)>=0))
  bounds <- iboin_boundaries(phi,q,m,n_max)
  set.seed(seed)
  allocation <- matrix(0L,n_trial,J); toxicity <- allocation
  selected <- integer(n_trial)
  for(r in seq_len(n_trial)) {
    n <- y <- integer(J); eliminated <- rep(FALSE,J); current <- start_dose
    for(k in seq_len(n_max/cohort_size)) {
      y[current] <- y[current]+sum(runif(cohort_size)<true_dlt[current])
      n[current] <- n[current]+cohort_size
      if(n[current]>=3 && pbeta(phi,y[current]+1,n[current]-y[current]+1,lower.tail=FALSE)>gamma) {
        eliminated[current:J] <- TRUE
        if(current==1L) break
      }
      if(sum(n)>=n_max) break
      b <- bounds[[current]][n[current],]
      next_dose <- current
      if(eliminated[current] || y[current]>=b$deescalate) next_dose <- max(1L,current-1L)
      else if(y[current]<=b$escalate && current<J && !eliminated[current+1L]) next_dose <- current+1L
      if(n[current]>=n_stop_per_dose && (!require_stability || next_dose==current)) break
      current <- next_dose
    }
    allocation[r,] <- n; toxicity[r,] <- y
    selected[r] <- iboin_select(n,y,phi,q,m,gamma,eliminated,use_prior)
  }
  selection <- setNames(tabulate(selected+1L,J+1L)/n_trial,c("No MTD",paste("Dose",seq_len(J))))
  if(is.null(true_state)) true_state <- as.character(which.min(abs(true_dlt-phi)))
  chosen <- if(true_state=="<1") 0L else if(true_state==paste0(">",J)) J else as.integer(true_state)
  overdose <- rowSums(allocation[,which(true_dlt>phi),drop=FALSE])
  total <- rowSums(allocation)
  trials <- data.frame(trial=seq_len(n_trial),selected=selected,total_n=total,
    total_dlt=rowSums(toxicity),stop_reason=ifelse(selected==0,"no MTD","other/end of trial"),allocation)
  names(trials)[6:(5+J)] <- paste0("n_dose",seq_len(J))
  list(method="iBOIN",accuracy=mean(selected==chosen),selection=selection,
    allocation=colMeans(allocation),mean_n=mean(total),sd_n=sd(total),
    mean_dlt=mean(rowSums(toxicity)),overdose_rate=sum(overdose)/sum(total),
    trials=if(keep_trials) trials else NULL)
}
