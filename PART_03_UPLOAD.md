# Part 3 — assessed public data package

This upload adds the data that can be published without changing the assessed
study:

- `data/synthetic/simulated_users_pew_seed42.csv`: the exact 2,000-row,
  seed-42 synthetic listener output defined by the submitted notebook;
- `data/aggregates/pew_simulation_targets.csv`: the Pew inputs and the
  probabilities used by the assessed exclusive-category simulation;
- `data/aggregates/primary_bucket_summary.csv`: aggregate distribution for the
  500-podcast metadata sample;
- `data/aggregates/sponsor_summary.csv`: aggregate sponsorship distribution;
- `data/aggregates/metadata_numeric_summary.csv`: permitted numeric summaries;
  and
- `tools/build_public_data_package.py`: deterministic rebuild utility.

The purchased Listen Notes rows are not included because the provider permits
publication of analysis and aggregate statistics but prohibits redistribution
of its dataset. This is a licensing boundary, not a revision of the thesis.

No model specification, historical result or dissertation claim is changed by
this upload.
