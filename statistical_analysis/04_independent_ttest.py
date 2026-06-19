"""
04_independent_ttest.py
-----------------------
Runs independent-samples t-tests (Student or Welch, chosen via Levene's
test for equality of variances) comparing EEG frontal power between the
Music and NoMusic groups, for each wave band and task block.

Effect size: Cohen's d (pooled standard deviation)

Input : data/EEG_ALL_GROUPS.csv
Output: results/ttest_results.csv  (console table printed as well)

Note: sample sizes are small (n = 7 per group); interpret with caution.

Usage:
    python 04_independent_ttest.py
"""

import os

import numpy as np
import pandas as pd
from scipy import stats

DATA_PATH = os.path.join("data", "EEG_ALL_GROUPS.csv")
RESULTS_PATH = os.path.join("results", "ttest_results.csv")

TASKS = ["BL01", "BL02", "BL03", "BL04", "IBOE"]


def cohens_d(group1: pd.Series, group2: pd.Series) -> float:
    n1, n2 = len(group1), len(group2)
    var1, var2 = np.var(group1, ddof=1), np.var(group2, ddof=1)
    pooled_std = np.sqrt(((n1 - 1) * var1 + (n2 - 1) * var2) / (n1 + n2 - 2))
    return (np.mean(group1) - np.mean(group2)) / pooled_std


def welch_df(s1: float, n1: int, s2: float, n2: int) -> int:
    """Welch-Satterthwaite degrees of freedom."""
    return int(
        (s1 / n1 + s2 / n2) ** 2
        / ((s1 / n1) ** 2 / (n1 - 1) + (s2 / n2) ** 2 / (n2 - 1))
    )


def interpret_d(d: float) -> str:
    d = abs(d)
    if d < 0.20:
        return "negligible"
    if d < 0.50:
        return "small"
    if d < 0.80:
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

    print("=" * 75)
    print("      INDEPENDENT SAMPLES T-TEST  |  Music vs NoMusic")
    print("  Note: small samples (n=7); interpret with caution")
    print("=" * 75)

    for wave in waves:
        df_wave = df[df["Wave"] == wave]
        print(f"\n{'━'*75}")
        print(f"  WAVE: {wave}")
        print(f"{'━'*75}")
        print(f"  {'Task':<8} {'t':>8} {'df':>4} {'p-value':>10} {'Sig':>5} {'Cohen d':>9}  Effect    [Type]")
        print(f"  {'-'*70}")

        for task in TASKS:
            music = df_wave[df_wave["Group"] == "Music"][task].dropna()
            control = df_wave[df_wave["Group"] == "NoMusic"][task].dropna()

            _, p_levene = stats.levene(music, control)
            equal_var = p_levene > 0.05

            t_stat, p_val = stats.ttest_ind(music, control, equal_var=equal_var)
            d = cohens_d(music, control)
            effect = interpret_d(d)

            if equal_var:
                df_val = len(music) + len(control) - 2
                test_type = "Student"
            else:
                s1, s2 = np.var(music, ddof=1), np.var(control, ddof=1)
                df_val = welch_df(s1, len(music), s2, len(control))
                test_type = "Welch"

            sig = significance_label(p_val)

            print(
                f"  {task:<8} {t_stat:>8.3f} {df_val:>4} {p_val:>10.4f} {sig:>5}"
                f" {d:>9.3f}  {effect:<10} [{test_type}]"
            )

            records.append({
                "Wave": wave,
                "Task": task,
                "n_Music": len(music),
                "n_NoMusic": len(control),
                "t": round(t_stat, 3),
                "df": df_val,
                "p_value": round(p_val, 4),
                "Significant": p_val < 0.05,
                "Cohens_d": round(d, 3),
                "Effect_size": effect,
                "Test_type": test_type,
                "Levene_p": round(p_levene, 4),
            })

    print(f"\n{'━'*75}")
    print("  Sig : *** p<.001  ** p<.01  * p<.05  ns = not significant")
    print("  Type: [Student] equal variances | [Welch] unequal variances")
    print(f"{'━'*75}\n")

    os.makedirs("results", exist_ok=True)
    pd.DataFrame(records).to_csv(RESULTS_PATH, index=False)
    print(f"Results saved -> {RESULTS_PATH}")


if __name__ == "__main__":
    main()
