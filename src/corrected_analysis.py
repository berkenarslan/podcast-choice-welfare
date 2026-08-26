"""Deterministic corrected simulation-recovery analysis.

This module uses real podcast attributes but simulated listener topic matches
and simulated choices. Its outputs are not empirical preference estimates.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
import pandas as pd
from scipy.optimize import minimize
from scipy.special import logsumexp


TOPIC_PROBABILITIES = {
    "Comedy": 0.47,
    "Entertainment / Pop Culture / Arts": 0.46,
    "Politics & Government": 0.41,
    "Science & Technology": 0.40,
    "History": 0.40,
    "True Crime": 0.34,
    "Self-Help & Relationships": 0.32,
    "Money & Finance": 0.31,
    "Religion & Spirituality": 0.30,
    "Health & Fitness": 0.27,
    "Sports": 0.22,
    "Race & Ethnicity": 0.15,
}

TERM_NAMES = ["ListenScore_z", "LogDuration_z", "Sponsor", "AnyTopicMatch"]
TRUE_BETA = np.array([0.30, -0.10, -0.25, 0.75], dtype=float)


def zscore(values: np.ndarray) -> np.ndarray:
    mean = values.mean()
    std = values.std(ddof=0)
    if not np.isfinite(std) or std == 0:
        raise ValueError("Cannot standardise a constant or non-finite variable")
    return (values - mean) / std


def read_metadata(path: Path) -> pd.DataFrame:
    """Read the local Listen Notes export without redistributing it."""
    frame = pd.read_csv(path, sep=";", skiprows=1)
    required = {
        "id_podcast",
        "listen_score",
        "audio_length_seconds",
        "has_sponsors",
        "Primary Bucket (Pew12)",
    }
    missing = sorted(required - set(frame.columns))
    if missing:
        raise ValueError(f"Missing metadata fields: {missing}")
    if len(frame) != 500:
        raise ValueError(f"Expected 500 podcasts, found {len(frame)}")
    if frame["id_podcast"].duplicated().any():
        raise ValueError("Podcast identifiers are not unique")

    numeric = frame[["listen_score", "audio_length_seconds"]].apply(
        pd.to_numeric, errors="coerce"
    )
    if numeric.isna().any().any() or (numeric["audio_length_seconds"] <= 0).any():
        raise ValueError("Invalid ListenScore or episode-duration values")

    sponsor = frame["has_sponsors"]
    if sponsor.dtype == bool:
        sponsor_numeric = sponsor.astype(int)
    else:
        mapped = sponsor.astype(str).str.strip().str.lower().map(
            {"true": 1, "false": 0, "1": 1, "0": 0}
        )
        if mapped.isna().any():
            raise ValueError("Unrecognised sponsorship values")
        sponsor_numeric = mapped.astype(int)

    out = pd.DataFrame(
        {
            "podcast_id": frame["id_podcast"].astype(int),
            "primary_bucket": frame["Primary Bucket (Pew12)"].astype(str),
            "listen_score_z": zscore(numeric["listen_score"].to_numpy(float)),
            "log_duration_z": zscore(
                np.log1p(numeric["audio_length_seconds"].to_numpy(float))
            ),
            "sponsor": sponsor_numeric.to_numpy(int),
        }
    )
    return out


def simulate_topic_membership(
    n_users: int, rng: np.random.Generator
) -> tuple[np.ndarray, list[str]]:
    topics = list(TOPIC_PROBABILITIES)
    probs = np.array(list(TOPIC_PROBABILITIES.values()), dtype=float)
    draws = rng.random((n_users, len(topics))) < probs[None, :]
    return draws, topics


def build_design(
    metadata: pd.DataFrame, memberships: np.ndarray, topics: list[str]
) -> np.ndarray:
    n_users = memberships.shape[0]
    n_alternatives = len(metadata)
    alt = np.column_stack(
        [
            metadata["listen_score_z"].to_numpy(float),
            metadata["log_duration_z"].to_numpy(float),
            metadata["sponsor"].to_numpy(float),
        ]
    )
    design = np.empty((n_users, n_alternatives, 4), dtype=float)
    design[:, :, :3] = alt[None, :, :]

    topic_index = {topic: idx for idx, topic in enumerate(topics)}
    podcast_topic_index = np.array(
        [topic_index.get(bucket, -1) for bucket in metadata["primary_bucket"]],
        dtype=int,
    )
    match = np.zeros((n_users, n_alternatives), dtype=float)
    supplied = podcast_topic_index >= 0
    match[:, supplied] = memberships[:, podcast_topic_index[supplied]]
    design[:, :, 3] = match
    return design


def simulate_choices(
    design: np.ndarray, beta: np.ndarray, rng: np.random.Generator
) -> np.ndarray:
    systematic = np.einsum("ijk,k->ij", design, beta)
    noise = rng.gumbel(size=systematic.shape)
    return np.argmax(systematic + noise, axis=1)


def fit_mnl(
    design: np.ndarray, chosen: np.ndarray
) -> tuple[object, np.ndarray, np.ndarray]:
    n_users = design.shape[0]

    def objective(beta: np.ndarray) -> float:
        utility = np.einsum("ijk,k->ij", design, beta)
        return float(-(utility[np.arange(n_users), chosen] - logsumexp(utility, axis=1)).sum())

    def gradient(beta: np.ndarray) -> np.ndarray:
        utility = np.einsum("ijk,k->ij", design, beta)
        probabilities = np.exp(utility - logsumexp(utility, axis=1)[:, None])
        observed = design[np.arange(n_users), chosen, :].sum(axis=0)
        expected = np.einsum("ij,ijk->k", probabilities, design)
        return expected - observed

    result = minimize(
        objective,
        x0=np.zeros(design.shape[2]),
        jac=gradient,
        method="BFGS",
        options={"gtol": 1e-7, "maxiter": 500},
    )
    utility = np.einsum("ijk,k->ij", design, result.x)
    probabilities = np.exp(utility - logsumexp(utility, axis=1)[:, None])
    expected_x = np.einsum("ij,ijk->ik", probabilities, design)
    centered = design - expected_x[:, None, :]
    information = np.einsum(
        "ij,ijk,ijl->kl", probabilities, centered, centered
    )
    covariance = np.linalg.inv(information)
    standard_errors = np.sqrt(np.diag(covariance))
    return result, gradient(result.x), standard_errors


def welfare_scenario(design: np.ndarray, beta: np.ndarray) -> np.ndarray:
    utility = np.einsum("ijk,k->ij", design, beta)
    counterfactual = utility - beta[2] * design[:, :, 2]
    return logsumexp(counterfactual, axis=1) - logsumexp(utility, axis=1)


def run(metadata_path: Path, output_dir: Path, seed: int, n_users: int) -> None:
    rng = np.random.default_rng(seed)
    metadata = read_metadata(metadata_path)
    memberships, topics = simulate_topic_membership(n_users, rng)
    design = build_design(metadata, memberships, topics)
    chosen = simulate_choices(design, TRUE_BETA, rng)
    fit, gradient, standard_errors = fit_mnl(design, chosen)
    if not fit.success and np.linalg.norm(gradient) > 1e-5:
        raise RuntimeError(f"MNL optimisation failed: {fit.message}")

    recovery = pd.DataFrame(
        {
            "term": TERM_NAMES,
            "simulation_truth": TRUE_BETA,
            "estimate": fit.x,
            "standard_error": standard_errors,
            "ci95_low": fit.x - 1.96 * standard_errors,
            "ci95_high": fit.x + 1.96 * standard_errors,
            "recovery_error": fit.x - TRUE_BETA,
            "truth_inside_ci95": (TRUE_BETA >= fit.x - 1.96 * standard_errors)
            & (TRUE_BETA <= fit.x + 1.96 * standard_errors),
        }
    )
    delta = welfare_scenario(design, fit.x)
    welfare = pd.DataFrame(
        [
            {
                "scenario": "Sponsor=0",
                "unit": "log-sum utility units",
                "mean_delta": delta.mean(),
                "median_delta": np.median(delta),
                "p05_delta": np.quantile(delta, 0.05),
                "p95_delta": np.quantile(delta, 0.95),
            }
        ]
    )
    diagnostics = {
        "analysis_type": "simulation recovery; not empirical preference estimation",
        "seed": seed,
        "n_users": n_users,
        "n_alternatives": len(metadata),
        "sponsor_share": float(metadata["sponsor"].mean()),
        "mean_topic_memberships": float(memberships.sum(axis=1).mean()),
        "users_with_zero_topic_memberships": int((memberships.sum(axis=1) == 0).sum()),
        "optimizer_success": bool(fit.success),
        "optimizer_message": str(fit.message),
        "negative_log_likelihood": float(fit.fun),
        "gradient_norm": float(np.linalg.norm(gradient)),
    }

    output_dir.mkdir(parents=True, exist_ok=True)
    recovery.to_csv(
        output_dir / "simulation_recovery_summary.csv",
        index=False,
        float_format="%.8f",
    )
    welfare.to_csv(
        output_dir / "welfare_scenario_summary.csv",
        index=False,
        float_format="%.8f",
    )
    (output_dir / "run_diagnostics.json").write_text(
        json.dumps(diagnostics, indent=2) + "\n", encoding="utf-8"
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--metadata", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--n-users", type=int, default=2000)
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    run(args.metadata, args.output_dir, args.seed, args.n_users)
