"""Build the public-safe data package used by the assessed reconstruction.

The synthetic listener file is generated from the exact seed, target values,
draw order and column order in the submitted simulation notebook. Licensed
Listen Notes records are reduced to aggregate statistics only.
"""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
import pandas as pd


TOPIC_TARGETS = {
    "Comedy": 47,
    "Entertainment / Pop Culture / Arts": 46,
    "Politics & Government": 41,
    "Science & Technology": 40,
    "History": 40,
    "True Crime": 34,
    "Self-Help & Relationships": 32,
    "Money & Finance": 31,
    "Religion & Spirituality": 30,
    "Health & Fitness": 27,
    "Sports": 22,
    "Race & Ethnicity": 15,
}
FREQUENCY_TARGETS = {
    "Nearly every day": 20,
    "A few times a week": 22,
    "A few times a month": 25,
    "Once a month": 9,
    "Less often": 25,
}
AGE_LISTENING_PROPENSITIES = {"18–29": 67, "30–49": 58, "50–64": 42, "65+": 28}
GENDER_LISTENING_PROPENSITIES = {"Male": 51, "Female": 46}
EDUCATION_LISTENING_PROPENSITIES = {
    "High school or less": 37,
    "Some college": 49,
    "College+": 62,
}
INCOME_LISTENING_PROPENSITIES = {"<30K": 44, "30K–79,999": 45, "80K+": 59}


def normalised_probabilities(values: dict[str, int]) -> np.ndarray:
    array = np.asarray(list(values.values()), dtype=float)
    return array / array.sum()


def draw(rng: np.random.Generator, values: dict[str, int], size: int) -> np.ndarray:
    return rng.choice(
        list(values), size=size, p=normalised_probabilities(values)
    )


def build_synthetic_users(seed: int = 42, size: int = 2000) -> pd.DataFrame:
    rng = np.random.default_rng(seed)
    # Draw order intentionally matches the submitted notebook.
    age = draw(rng, AGE_LISTENING_PROPENSITIES, size)
    gender = draw(rng, GENDER_LISTENING_PROPENSITIES, size)
    education = draw(rng, EDUCATION_LISTENING_PROPENSITIES, size)
    income = draw(rng, INCOME_LISTENING_PROPENSITIES, size)
    topic = draw(rng, TOPIC_TARGETS, size)
    frequency = draw(rng, FREQUENCY_TARGETS, size)
    return pd.DataFrame(
        {
            "Age Group": age,
            "Gender": gender,
            "Education": education,
            "Income": income,
            "Preferred Category (Pew12)": topic,
            "Listening Frequency": frequency,
        }
    )


def targets_table() -> pd.DataFrame:
    blocks = [
        ("topic", TOPIC_TARGETS, "Pew percentage among listeners; normalised for exclusive draw"),
        ("frequency", FREQUENCY_TARGETS, "Pew percentage among listeners"),
        ("age", AGE_LISTENING_PROPENSITIES, "group listening propensity; normalised for draw"),
        ("gender", GENDER_LISTENING_PROPENSITIES, "group listening propensity; normalised for draw"),
        ("education", EDUCATION_LISTENING_PROPENSITIES, "group listening propensity; normalised for draw"),
        ("income", INCOME_LISTENING_PROPENSITIES, "group listening propensity; normalised for draw"),
    ]
    rows = []
    for domain, values, interpretation in blocks:
        probabilities = normalised_probabilities(values)
        for (category, source_value), draw_probability in zip(values.items(), probabilities):
            rows.append(
                {
                    "domain": domain,
                    "category": category,
                    "source_value_pct": source_value,
                    "assessed_draw_probability": draw_probability,
                    "interpretation": interpretation,
                }
            )
    return pd.DataFrame(rows)


def metadata_aggregates(metadata_path: Path) -> dict[str, pd.DataFrame]:
    frame = pd.read_csv(metadata_path, sep=";", skiprows=1)
    required = {
        "Primary Bucket (Pew12)",
        "has_sponsors",
        "listen_score",
        "audio_length_seconds",
        "update_frequency_hours",
    }
    missing = sorted(required - set(frame.columns))
    if missing:
        raise ValueError(f"Missing metadata columns: {missing}")
    if len(frame) != 500:
        raise ValueError(f"Expected 500 metadata rows, found {len(frame)}")

    buckets = (
        frame["Primary Bucket (Pew12)"]
        .value_counts(dropna=False)
        .rename_axis("primary_bucket")
        .rename("count")
        .reset_index()
    )
    buckets["share"] = buckets["count"] / len(frame)

    sponsors = (
        frame["has_sponsors"]
        .value_counts(dropna=False)
        .rename_axis("has_sponsors")
        .rename("count")
        .reset_index()
    )
    sponsors["share"] = sponsors["count"] / len(frame)

    numeric_rows = []
    for column in ["listen_score", "audio_length_seconds", "update_frequency_hours"]:
        values = pd.to_numeric(frame[column], errors="coerce")
        numeric_rows.append(
            {
                "variable": column,
                "n": int(values.notna().sum()),
                "missing": int(values.isna().sum()),
                "mean": values.mean(),
                "std": values.std(ddof=0),
                "min": values.min(),
                "p25": values.quantile(0.25),
                "median": values.median(),
                "p75": values.quantile(0.75),
                "max": values.max(),
            }
        )
    numeric = pd.DataFrame(numeric_rows)
    return {
        "primary_bucket_summary.csv": buckets,
        "sponsor_summary.csv": sponsors,
        "metadata_numeric_summary.csv": numeric,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--metadata", type=Path, required=True)
    parser.add_argument("--output-root", type=Path, required=True)
    args = parser.parse_args()

    synthetic_dir = args.output_root / "synthetic"
    aggregate_dir = args.output_root / "aggregates"
    synthetic_dir.mkdir(parents=True, exist_ok=True)
    aggregate_dir.mkdir(parents=True, exist_ok=True)

    build_synthetic_users().to_csv(
        synthetic_dir / "simulated_users_pew_seed42.csv", index=False
    )
    targets_table().to_csv(
        aggregate_dir / "pew_simulation_targets.csv", index=False
    )
    for filename, table in metadata_aggregates(args.metadata).items():
        table.to_csv(aggregate_dir / filename, index=False, float_format="%.8f")


if __name__ == "__main__":
    main()
