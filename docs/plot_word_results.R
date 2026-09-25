library(ggplot2)
d <- read.csv("docs/data/word_all_results.csv", colClasses="character", check.names=FALSE)
d$value <- as.numeric(d$percentage)
d$error <- as.numeric(d$mcse)
colors <- c(BOIN="#C76D00", iBOIN="#4267A9", BOLD="#087F8C", "BOLD-exp"="#AD437D")
dir.create("docs/figures", recursive=TRUE, showWarnings=FALSE)
for (key in unique(d$figure)) {
  if (key == "word_09_scenario_8") next
  z <- d[d$figure == key, ]
  z$category <- factor(z$category, levels=unique(z$category))
  z$method <- factor(z$method, levels=names(colors)[names(colors) %in% z$method])
  dodge <- position_dodge(width=.72)
  p <- ggplot(z, aes(category, value, fill=method, group=method)) +
    geom_col(position=dodge, width=.42) +
    geom_errorbar(aes(ymin=pmax(0,value-1.96*error), ymax=pmin(100,value+1.96*error)),
      position=dodge, width=.12, linewidth=.35) +
    geom_text(aes(label=percentage), position=dodge, vjust=-.8, size=3.1) +
    scale_fill_manual(values=colors, drop=TRUE) +
    scale_y_continuous(limits=c(0,108), breaks=seq(0,100,20),
      labels=function(x) paste0(x,"%"), expand=expansion(mult=c(0,.01))) +
    labs(title=paste0("Scenario ",z$scenario[1],": ",z$endpoint[1]),
      subtitle=paste0("True DLT probabilities: (",z$rates[1],")"),
      x=NULL,y="Percentage of simulated trials",fill=NULL,
      caption=paste0("Source: ALL SCENARIOS.docx. Exact reported percentages; error bars: +/- 1.96 reported MCSE.\n",
        "BOLD-exp: tau 0.49. Historical results; official iBOIN safety equivalence remains unverified.",
        if (z$scenario[1] %in% c("9","10")) " iBOIN not available." else "")) +
    theme_minimal(base_size=12) +
    theme(legend.position="bottom",panel.grid.major.x=element_blank(),
      panel.grid.minor=element_blank(), plot.title=element_text(face="bold",size=15),
      plot.caption=element_text(hjust=0,size=9), axis.text.x=element_text(size=11))
  ggsave(paste0("docs/figures/",key,".png"),p,width=12,height=5.6,dpi=180,bg="white")
  ggsave(paste0("docs/figures/",key,".pdf"),p,width=12,height=5.6)
}
