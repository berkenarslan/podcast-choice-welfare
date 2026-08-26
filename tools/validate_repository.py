"""Structural validation for the assessed-version repository.

This script intentionally does not connect to BigQuery and does not claim to
reproduce estimation results. It checks repository contracts that can be
verified without private or licensed data.
"""

from __future__ import annotations

import csv
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def validate_notebooks() -> None:
    expected = [
        ROOT / "notebooks/01_pew_user_simulation.ipynb",
        ROOT / "notebooks/02_run_all_models.ipynb",
        ROOT / "notebooks/archive/02_original_model_runs.ipynb",
    ]
    for path in expected:
        notebook = json.loads(path.read_text(encoding="utf-8"))
        require(notebook.get("nbformat") == 4, f"Unexpected nbformat: {path}")
        require(bool(notebook.get("cells")), f"Notebook has no cells: {path}")


def validate_results() -> None:
    path = ROOT / "results/original/model_summary.csv"
    with path.open(newline="", encoding="utf-8") as stream:
        rows = list(csv.DictReader(stream))
    require(len(rows) == 9, "Historical summary must contain nine models")
    require(rows[0]["model"] == "M1_baseline", "Baseline model missing")
    require({row["N_users"] for row in rows} == {"1921"}, "User count drift")
    require({row["N_rows"] for row in rows} == {"94690"}, "Row count drift")
    require(
        all(row["status"] == "reported_not_rerun" for row in rows),
        "Historical values must not be labelled as rerun output",
    )


def validate_public_data() -> None:
    users_path = ROOT / "data/synthetic/simulated_users_pew_seed42.csv"
    with users_path.open(newline="", encoding="utf-8") as stream:
        users = list(csv.DictReader(stream))
    require(len(users) == 2000, "Synthetic listener row count drift")
    forbidden = {"email", "rss", "title", "publisher", "listennotes_id"}
    require(
        forbidden.isdisjoint(users[0]),
        "Provider/contact fields found in synthetic public data",
    )

    bucket_path = ROOT / "data/aggregates/primary_bucket_summary.csv"
    with bucket_path.open(newline="", encoding="utf-8") as stream:
        buckets = list(csv.DictReader(stream))
    require(sum(int(row["count"]) for row in buckets) == 500, "Bucket totals drift")


def validate_sql_disclosures() -> None:
    prepare = (ROOT / "sql/01_prepare_panel.sql").read_text(encoding="utf-8")
    choices = (ROOT / "sql/02_simulate_choices.sql").read_text(encoding="utf-8")
    require("update_frequency_hours" in prepare, "Assessed TimeCost source changed")
    require("gumbel_noise" in choices, "Assessed Gumbel stage changed")
    require("p_softmax" in choices, "Assessed softmax draw changed")
    require("RAND()" in choices, "Assessed unseeded randomness changed")


def validate_no_local_data() -> None:
    tracked_sensitive_suffixes = {".numbers", ".docx", ".pdf"}
    found = [
        path.relative_to(ROOT)
        for path in ROOT.rglob("*")
        if path.is_file()
        and ".git" not in path.parts
        and path.suffix.lower() in tracked_sensitive_suffixes
    ]
    require(not found, f"Source/private documents found in repository: {found}")


def main() -> None:
    validate_notebooks()
    validate_results()
    validate_public_data()
    validate_sql_disclosures()
    validate_no_local_data()
    print("Repository structural validation passed.")
    print("This is not an end-to-end BigQuery replication claim.")


if __name__ == "__main__":
    main()
