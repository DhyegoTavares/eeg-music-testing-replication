"""
02_normality_tests.py
---------------------
Runs Shapiro-Wilk normality tests on the EEG frontal power values
for each wave band, task block, and group (Music vs NoMusic).

Input : data/EEG_ALL_GROUPS.csv
Output: results/normality_results.csv  (console summary printed as well)

Usage:
    python 02_normality_tests.py
"""

import os

import pandas as pd
from scipy import stats

DATA_PATH = os.path.join("data", "EEG_ALL_GROUPS.csv")
RESULTS_PATH = os.path.join("results", "normality_results.csv")

TASKS = ["BL01", "BL02", "BL03", "BL04"]
ALPHA = 0.05


def interpret(p_value: float) -> str:
    return "normal" if p_value > ALPHA else "non-normal"


def main() -> None:
    df = pd.read_csv(DATA_PATH)
    waves = df["Wave"].unique()
    records = []

    print("=" * 65)
    print("          SHAPIRO-WILK NORMALITY TEST")
    print("=" * 65)

    for wave in waves:
        df_wave = df[df["Wave"] == wave]
        print(f"\n===== Wave: {wave} =====")

        for task in TASKS:
            music = pd.to_numeric(df_wave[df_wave["Group"] == "Music"][task], errors="coerce").dropna()
            control = pd.to_numeric(df_wave[df_wave["Group"] == "NoMusic"][task], errors="coerce").dropna()

            stat_m, p_m = stats.shapiro(music)
            stat_c, p_c = stats.shapiro(control)

            print(f"\n  Task {task}:")
            print(f"    Music   : W={stat_m:.3f}, p={p_m:.4f}  -> {interpret(p_m)}")
            print(f"    NoMusic : W={stat_c:.3f}, p={p_c:.4f}  -> {interpret(p_c)}")

            records.append({
                "Wave": wave,
                "Task": task,
                "Group": "Music",
                "n": len(music),
                "W": round(stat_m, 4),
                "p_value": round(p_m, 4),
                "Normal": p_m > ALPHA,
            })
            records.append({
                "Wave": wave,
                "Task": task,
                "Group": "NoMusic",
                "n": len(control),
                "W": round(stat_c, 4),
                "p_value": round(p_c, 4),
                "Normal": p_c > ALPHA,
            })

    os.makedirs("results", exist_ok=True)
    pd.DataFrame(records).to_csv(RESULTS_PATH, index=False)
    print(f"\nResults saved -> {RESULTS_PATH}")


if __name__ == "__main__":
    main()
