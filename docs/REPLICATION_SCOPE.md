# Replication scope

## What `v1.0-thesis-replication` means

This release is a transparent reconstruction of the code path assessed in the
MSc dissertation. It is not the corrected research version.

The release must:

1. preserve the original model definitions and table lineage;
2. retain reported specifications and results as historical outputs;
3. distinguish recovered code from subsequently refactored code;
4. expose known limitations rather than repairing them without disclosure; and
5. avoid claims that have not been verified by a clean end-to-end rerun.

## Known issues preserved for audit

- The thesis describes `TimeCost` as average episode duration, while the
  assessed SQL constructs `timecost_z` from `update_frequency_hours`.
- The user simulation normalises Pew group-level listening rates and samples
  demographic variables independently.
- Pew topic percentages are multi-response, while the simulation assigns one
  exclusive preferred category to each synthetic user.
- The SQL choice generator adds Gumbel noise and then performs an additional
  softmax random draw.
- BigQuery `RAND()` calls are not seeded in the assessed SQL.
- Users assigned to a category with no podcast supply do not enter the
  match-only estimation sample.
- Category weights require a separate justification and sensitivity analysis.
- Welfare outputs are expressed in model utility units and should not be
  described as a monetary or behavioural percentage without an identified
  scale.

None of these issues is silently changed in the replication release. They will
be addressed, one decision at a time, in `v2.0-corrected-analysis`.

