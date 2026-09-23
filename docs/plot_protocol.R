library(ggplot2)
s <- read.csv("docs/data/protocol_scenarios.csv")
d <- read.csv("docs/data/protocol_performance.csv")
labels <- paste0(s$scenario," | ",s$endpoint)
d$panel <- factor(d$scenario,levels=s$scenario,labels=labels)
d$method <- factor(d$method,levels=c("BOLD","BOLD-exp","BOIN","iBOIN"))
colors <- c(BOLD="#087F8C","BOLD-exp"="#AD437D",BOIN="#C76D00",iBOIN="#4267A9")
p <- ggplot(d,aes(method,accuracy_pct,fill=method))+
  geom_col(width=.7)+
  geom_errorbar(aes(ymin=pmax(0,accuracy_pct-1.96*accuracy_mcse_pct),
    ymax=pmin(100,accuracy_pct+1.96*accuracy_mcse_pct)),width=.2)+
  geom_text(aes(label=sprintf("%.2f",accuracy_pct)),vjust=-.7,size=3.5)+
  facet_wrap(~panel,ncol=3)+scale_fill_manual(values=colors)+
  scale_y_continuous(limits=c(0,108),breaks=seq(0,100,25))+
  labs(title="CD229 CAR-T protocol: nine simulation scenarios",
    subtitle="10,000 trials per scenario and method | target 0.30 | N <= 18 | cohort 3 | cutoff 0.90 at all doses",
    x=NULL,y="Prespecified selection endpoint (%)",fill=NULL,
    caption="Independent implementations; not official MD Anderson simulation outputs. Error bars: +/- 1.96 MCSE.\nBOLD-exp: constant tau 0.49 only. Prior means 0.30, PESS 3. Scenario 8 excluded.\nS5: highest-dose convention. S9: any target dose. S10: any available dose, not unique-MTD accuracy.")+
  theme_minimal(base_size=12)+theme(legend.position="bottom",axis.text.x=element_blank(),
    panel.grid.major.x=element_blank(),panel.grid.minor=element_blank(),
    strip.text=element_text(face="bold"),plot.caption=element_text(hjust=0))
dir.create("docs/figures",recursive=TRUE,showWarnings=FALSE)
ggsave("docs/figures/protocol_nine_scenarios.png",p,width=14,height=10,dpi=180,bg="white")
ggsave("docs/figures/protocol_nine_scenarios.pdf",p,width=14,height=10)
lines <- c("# Nine-scenario results","","Entries: percentage (MCSE in percentage points).", "",
  "| Scenario | Endpoint | BOLD | BOLD-exp | BOIN | iBOIN |","|---|---|---:|---:|---:|---:|")
for(i in seq_len(nrow(s))) {
  z <- d[d$scenario==s$scenario[i],]
  z <- z[order(z$method),]
  lines <- c(lines,paste0("| ",paste(c(s$scenario[i],s$endpoint[i],
    sprintf("%.2f (%.2f)",z$accuracy_pct,z$accuracy_mcse_pct)),collapse=" | ")," |"))
}
writeLines(lines,"docs/protocol_results.md")
