"""
03_mann_whitney_test.py
-----------------------
Runs Mann-Whitney U tests comparing EEG frontal power between the
Music and NoMusic groups, for each wave band and task block.

Effect size: r = |Z| / sqrt(N)  (rank-biserial approximation)

Input : data/EEG_ALL_GROUPS.csv
Output: results/mann_whitney_results.csv  (console table printed as well)

Usage:
    python 03_mann_whitney_test.py
"""

import os

import numpy as np
import pandas as pd
from scipy import stats

DATA_PATH = os.path.join("data", "EEG_ALL_GROUPS.csv")
RESULTS_PATH = os.path.join("results", "mann_whitney_results.csv")

TASKS = ["BL01", "BL02", "BL03", "BL04", "IBOE"]


def effect_size_r(u_stat: float, n1: int, n2: int) -> tuple[float, float]:
    """Return (Z, r) where r = |Z| / sqrt(N)."""
    mean_u = (n1 * n2) / 2
    std_u = np.sqrt((n1 * n2 * (n1 + n2 + 1)) / 12)
    z = (u_stat - mean_u) / std_u
    r = abs(z) / np.sqrt(n1 + n2)
    return z, r


def interpret_r(r: float) -> str:
    r = abs(r)
    if r < 0.10:
        return "negligible"
    if r < 0.30:
        return "small"
    if r < 0.50:
        return "medium"
    return "large"


def significance_label(p: float) -> str:
    if p < 0.001:
        return "***"
    if p < 0.01:
        return "**"
    if p < 0.05:
        return "*"
    return "ns"


def main() -> None:
    df = pd.read_csv(DATA_PATH)
    waves = df["Wave"].unique()
    records = []

    print("=" * 70)
    print("        MANN-WHITNEY U TEST  |  Music vs NoMusic")
    print("=" * 70)

    for wave in waves:
        df_wave = df[df["Wave"] == wave]
        print(f"\n{'━'*70}")
        print(f"  WAVE: {wave}")
        print(f"{'━'*70}")
        print(f"  {'Task':<8} {'U':>8} {'Z':>8} {'p-value':>10} {'Sig':>5} {'r':>7}  Effect")
        print(f"  {'-'*64}")

        for task in TASKS:
            music = df_wave[df_wave["Group"] == "Music"][task].dropna()
            control = df_wave[df_wave["Group"] == "NoMusic"][task].dropna()

            u_stat, p_val = stats.mannwhitneyu(music, control, alternative="two-sided")
            n1, n2 = len(music), len(control)
            z, r = effect_size_r(u_stat, n1, n2)
            effect = interpret_r(r)
            sig = significance_label(p_val)

            print(f"  {task:<8} {u_stat:>8.1f} {z:>8.3f} {p_val:>10.4f} {sig:>5} {r:>7.3f}  {effect}")

            records.append({
                "Wave": wave,
                "Task": task,
                "n_Music": n1,
                "n_NoMusic": n2,
                "U": u_stat,
                "Z": round(z, 3),
                "p_value": round(p_val, 4),
                "Significant": p_val < 0.05,
                "r": round(r, 3),
                "Effect_size": effect,
            })

    print(f"\n{'━'*70}")
    print("  Sig: *** p<.001  ** p<.01  * p<.05  ns = not significant")
    print(f"{'━'*70}\n")

    os.makedirs("results", exist_ok=True)
    pd.DataFrame(records).to_csv(RESULTS_PATH, index=False)
    print(f"Results saved -> {RESULTS_PATH}")


if __name__ == "__main__":
    main()
