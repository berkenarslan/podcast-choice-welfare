# Validation report

Validation date: 2026-08-26

## Completed checks

- GitHub repository is public and the linked account has push/admin access.
- The submitted thesis Word file and PDF were inspected; both identify the same
  research design and headline results.
- The source Pew simulation notebook and the repository notebook have identical
  concatenated cell source (`SHA-256 8f50022edb4649072fc788da9501f4d4d6f7837545cf1acca479fcaa7e06e829`).
- All three repository notebooks are valid nbformat 4 JSON documents.
- The assessed podcast metadata was checked locally: 500 records, 500 unique
  podcast identifiers, 38 source fields, and 11 non-empty primary buckets.
- Contact/provider fields remain outside the repository.
- The final model registry contains M1 plus M2V1–M2V8 and points to 94,690 rows
  and 1,921 retained users in the historical results record.
- Historical table values were cross-checked between the submitted thesis and
  the consolidated results record.
- Structural repository validation is available through
  `tools/validate_repository.py`.

## Not yet verified

- A clean BigQuery rebuild from `usersdata` and `metadata_native`.
- Equality of rebuilt panel row counts, weights, and choices to the assessed
  cloud tables.
- Re-estimation of coefficients from rebuilt tables.
- Reproduction of user-level clustered standard errors.
- Reproduction of the reported mean CS and Sponsor-removal delta from the
  recovered final runner.

Until these checks pass, the repository must not claim end-to-end
reproducibility.

## Deliberately preserved assessed issues

See `REPLICATION_SCOPE.md`. In particular, the assessed `timecost_z` uses
`update_frequency_hours`, the choice generator uses unseeded BigQuery randomness
and a two-stage Gumbel-plus-softmax draw, and the listener simulation converts
multi-response Pew topic percentages to an exclusive category.
