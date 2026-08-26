# Corrected analysis protocol

Branch: `v2-corrected-analysis`

Status: pre-result protocol frozen before the first corrected run.

## Scientific reframing

The available listener choices are simulated, not observed. The corrected
analysis therefore cannot estimate real listener preferences or causal welfare
effects. Its defensible purpose is narrower:

> demonstrate a transparent Monte Carlo discrete-choice pipeline on real
> podcast attributes and test whether the estimator recovers explicitly chosen
> simulation parameters.

The corrected outputs are simulation-recovery and scenario-welfare quantities.
They must not be described as empirical estimates of US podcast listeners.

## Frozen corrections

1. **Time cost:** use `log1p(audio_length_seconds)`, then z-standardise. The
   assessed use of `update_frequency_hours` is discontinued.
2. **Topics:** retain Pew's multi-response nature. Each of the 12 topics is
   drawn independently using its reported regular-listening percentage; users
   may have zero, one, or multiple topic matches.
3. **Demographics:** do not manufacture demographic heterogeneity from
   independently sampled group-level listening propensities. Demographic
   interaction claims are removed from the corrected core.
4. **Choice set:** every scenario listener faces all 500 podcasts. A missing
   supply category therefore does not delete the listener.
5. **Randomness:** use a declared NumPy seed (`42` by default).
6. **Choice draw:** use one Random Utility Model draw, `argmax(V + Gumbel)`.
   Do not add Gumbel noise and then conduct a second softmax draw.
7. **Weights:** do not apply the assessed category supply-demand weights.
8. **Welfare:** report log-sum differences in utility units only. Do not label
   them as money, realised welfare, or a behavioural percentage.
9. **Outside option:** still absent. Absolute log-sum levels remain
   scale/choice-set dependent; only the defined within-scenario contrast is
   reported.

## Frozen simulation truth

These are design inputs, not findings:

| Term | Simulation coefficient |
| --- | ---: |
| ListenScore z-score | `0.30` |
| Log episode duration z-score | `-0.10` |
| Sponsor indicator | `-0.25` |
| Any Pew-topic match | `0.75` |

The values were selected before running the corrected model to produce a
non-degenerate recovery exercise with signs aligned to the theoretical story.
They are not calibrated estimates.

## Primary diagnostics

- convergence and gradient norm;
- coefficient recovery error (`estimate - simulation truth`);
- number of scenario listeners and alternatives;
- sponsor share and duration transformation checks;
- mean, median, 5th and 95th percentiles of the Sponsor=0 log-sum difference.

No model tournament, interaction search, or significance fishing is authorised
in this corrected core.
