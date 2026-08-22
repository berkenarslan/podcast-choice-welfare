# Code provenance map

The original working record mixed code, results and ChatGPT discussion inside
Word documents. This map records how the first repository version separates
those materials.

| Repository file | Original source | Role |
| --- | --- | --- |
| `notebooks/01_pew_user_simulation.ipynb` | `PEW_Report_based_user_simulation.ipynb` | Synthetic-user generation |
| `sql/01_prepare_panel.sql` | `Sql kods(1).docx`, paragraphs 140–256 | Clean tables, features, weights and full panel |
| `sql/02_simulate_choices.sql` | `SQL cleaning model panels(1).docx`, paragraphs 49–142 | Match-only choice simulation |
| `sql/03_build_interactions.sql` | `SQL cleaning model panels(1).docx`, paragraphs 143–454 | Demographic interaction tables |
| `notebooks/02_run_all_models.ipynb` | `tum sonuc tablosu(2).docx`, paragraphs 10–252 | Final model registry and consolidated estimation runner |
| `notebooks/archive/02_original_model_runs.ipynb` | `pytcodes_model_run(2).docx` | Intermediate baseline, heterogeneity and counterfactual runs retained for audit |

Duplicate Word files were byte-compared during the audit. The `(1)` and `(2)`
copies used above do not represent different model versions.

The Word documents themselves are not intended for the public repository: they
contain conversational drafting history rather than executable research code.
