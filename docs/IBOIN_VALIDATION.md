# iBOIN verification and safety discrepancy

Verification date: September 23, 2026. Official web application: V1.6.3.0.

## Observed official-app behavior

Inputs: target .30, four doses, start 1, cohort 3, maximum 18, stable-dose limit 12, q=.30 and ESS=3 everywhere, prior-enabled final selection, no titration, robust prior, boundMTD or extra safety. Scenario 2 truth (.15,.30,.45,.60), 10,000 trials, seed 20260920.

- With displayed cutoff .90, its decision table eliminates at 2/3 DLTs, 4/6, 5/9 and 6/12. The independent implementation matches this uniform-prior safety rule.
- At displayed cutoff .90, its simulation returned selections 27.7,47.5,21.4,2.2 percent; displayed early stopping 1.18%; allocation percentages 39.3,40.8,17.3,2.5; mean N 17.1.
- At displayed cutoff .80, after regenerating the decision table, the simulation returned selections 34.9,44.2,16.6,1.9; early stopping 2.35%. Allocation percentages and mean N were unchanged at the displayed precision. This does not establish the simulator's internal cutoff; its source has not been obtained.
- A local uniform-safety .90 run gave no-dose 6.56% and mean N 15.9963. A local .95 run gave no-dose 1.19% and mean N 17.082. Similarity to .95 is diagnostic evidence, not proof of a hidden implementation parameter.
- Its final-selection tool with n=(6,6,3,3), DLTs=(2,1,1,2), q=.30, ESS=3 and cutoff .90 recommended Dose 3 and displayed adjusted estimates (.26,.26,.32,.48). Its Dose 4 posterior tail was .82, consistent with an informative prior. A uniform-prior tail for 2/3 exceeds .90; our independent implementation excludes Dose 4 and also selects Dose 3.
- The official simulator rejected exactly flat truths in scenarios 9 and 10. The local implementation accepts them without changing the probabilities.

Consequently, earlier web-app percentages must not be treated as a verified comparison with uniformly matched .90 safety at all stages.

## Independent implementation

`R/iboin_engine.R` implements equations 2.3 and 2.5 of Zhou et al. (2020). Nonnegative integer PESS is used for the finite binomial sum. Overlapping boundaries are rejected. Default reference probabilities are 0.6*target and 1.4*target.

Safety always uses Beta(1+y,1+n-y), at least three actual patients, and strict posterior-tail > gamma. Elimination propagates upward, is permanent, and is applied again at final selection. Prior-based final selection uses (y+m*q)/(n+m), inverse Beta-variance weighted isotonic regression and the small monotone tie perturbation convention of BOIN. This particular combination is explicit and independently implemented; the repository does not claim complete web-app equivalence.

Zero PESS uses standard BOIN final selection. Optional prior-off final selection also uses the BOIN package. Robust priors, titration, extrasafe and boundMTD are not implemented as iBOIN options here.

## Automated checks

`tests/iboin.R` checks the observed official neutral-prior escalation/de-escalation table for n=1..12; cutoff-sensitive elimination; zero-PESS trial-level equivalence with the local BOIN engine; exact flat truths; allocation accounting; patient limits; and all nine scenarios with four methods. Existing app regression suites also pass. These checks are not independent clinical validation.

## Publication gate

The new app is a development candidate until the independent matched-safety interpretation is accepted and deployment checks are complete. No claim is made that existing Zenodo archives contain this candidate.
