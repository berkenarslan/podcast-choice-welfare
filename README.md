# The Economics of Podcast Attention

[![Validate assessed reconstruction](https://github.com/berkenarslan/podcast-choice-welfare/actions/workflows/validate.yml/badge.svg)](https://github.com/berkenarslan/podcast-choice-welfare/actions/workflows/validate.yml)

Reproducibility repository for the MSc dissertation **“The Economics of
Podcast Attention: Multinomial Logit Estimation and Welfare Implications.”**

This first release preserves the analysis assessed in the dissertation. It
organises the original Pew-based user simulation, BigQuery panel construction,
choice simulation and multinomial-logit estimation without silently changing
the model or its reported results.

## Release status

**Current target:** `v1.0-thesis-replication`

- The assessed code path has been recovered from the original Word and notebook
  records and mapped to repository files.
- The original specification is preserved, including the methodological
  limitations disclosed in the dissertation and repository documentation.
- A successful end-to-end rerun has not yet been claimed.
- The repository does not contain the licensed Listen Notes record-level data.
- Values under `results/original/` are checked historical transcriptions, not
  fresh rerun output.

## Research question

How do podcast popularity, the model's time-cost proxy and sponsorship status
relate to simulated podcast choices and model-based welfare comparisons in a
restricted choice environment?

The listener records are synthetic. They use published Pew Research Center
targets as simulation inputs and are not observed individual listening choices.

## Repository map

```text
podcast-choice-welfare/
├── docs/                  # Scope, data access and code provenance
├── data/                  # Synthetic listeners and permitted aggregates
├── notebooks/             # Pew simulation and original estimation runs
├── sql/                   # BigQuery preparation and choice-set scripts
├── results/original/      # Results reported by the assessed dissertation
├── tools/                 # One-off provenance/extraction utilities
└── archive/source-notes/  # Inventory only; Word chat transcripts stay out
```

## Intended execution order

1. Run `notebooks/01_pew_user_simulation.ipynb` to create the synthetic user
   table.
2. Obtain the source podcast metadata under the provider's terms and create the
   primary-bucket field described in `docs/DATA_ACCESS.md`.
3. Run `sql/01_prepare_panel.sql` in BigQuery.
4. Run `sql/02_simulate_choices.sql`.
5. Run `sql/03_build_interactions.sql`.
6. Run `notebooks/02_run_all_models.ipynb` to reproduce the final model
   registry used for the dissertation tables.

The exact cloud table names used in the dissertation are retained for
provenance. A later portability pass will move them into configuration.

The longer sequence of intermediate estimation attempts is retained under
`notebooks/archive/` for audit, but it is not the recommended entry point.

The exact seed-42 synthetic listener output and permitted aggregate metadata
tables are included under `data/`. The purchased podcast-level Listen Notes
records are not redistributed.

Run `python tools/validate_repository.py` for structural checks that do not
require access to the private BigQuery project or licensed metadata.

## Interpretation boundary

This repository reproduces a simulation study. Its coefficients must not be
presented as estimates from observed listener choices or as causal effects.
The reported log-sum welfare quantities are model utility units, not money and
not an identified behavioural percentage.
Any later sensitivity or corrected analysis will remain separate instead of
rewriting the history of the assessed thesis.

## Documentation

- [`docs/REPLICATION_SCOPE.md`](docs/REPLICATION_SCOPE.md): boundary between
  the assessed version and later corrections.
- [`docs/CODE_MAP.md`](docs/CODE_MAP.md): source-to-repository provenance.
- [`docs/DATA_SCHEMA.md`](docs/DATA_SCHEMA.md): local input and generated-table
  contracts.
- [`docs/RESULTS_LINEAGE.md`](docs/RESULTS_LINEAGE.md): where each published
  historical result came from.
- [`docs/VALIDATION_REPORT.md`](docs/VALIDATION_REPORT.md): checks completed and
  checks still blocked by private cloud data.

## Author

Berken Arslan  
MSc Economics and Data Science, University of Nottingham
