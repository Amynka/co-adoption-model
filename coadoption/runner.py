"""
Helpers to run the model and save or plot results.
"""

import csv
from pathlib import Path
from typing import Dict, List, Optional, Union

from .config import Config
from .model import CoAdoptionModel
from .survey import SurveyData

# survey of the repository checkout; pass another path (or --data) for other survey data
DEFAULT_DATA_PATH = Path(__file__).resolve().parent.parent / "data" / "surveyData.csv"


def build_model(config: Config, survey: Union[SurveyData, str, Path, None] = None,
                seed: Optional[int] = None) -> CoAdoptionModel:
    if not isinstance(survey, SurveyData):
        survey = SurveyData.load(survey or DEFAULT_DATA_PATH)
    model = CoAdoptionModel(survey, seed=seed)
    model.initialize_model(config)
    return model


def run_once(config: Config, survey: Union[SurveyData, str, Path, None] = None,
             seed: Optional[int] = None, verbose: bool = True) -> List[Dict]:
    """Yearly summaries from the initial state to the end of the run.

    ConsumerChoiceModel.run_simulation() returns {'simulation_data': [collect_data() per year],
    'final_stats': last entry, 'parameters': model_parameters}; CoAdoptionModel.collect_data()
    returns summary().
    """
    model = build_model(config, survey, seed)
    rows = model.run_simulation(config.stop_after_x_years)['simulation_data']
    if verbose:
        for s in rows:
            if s["year"] in (2030, 2050):
                print(
                    f"{s['year']}: PV={s['PV']}  EV={s['EV']}  HP={s['HP']}  "
                    f"co(PV+EV+HP)={s['co_PV_EV_HP']}  co(PV+EV)={s['co_PV_EV']}  "
                    f"co(PV+HP)={s['co_PV_HP']}  co(EV+HP)={s['co_EV_HP']}"
                )
    return rows


def save_csv(rows: List[Dict], path: Path) -> None:
    if not rows:
        return
    with open(path, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=rows[0].keys())
        w.writeheader()
        w.writerows(rows)
    print(f"Saved {len(rows)} rows → {path}")


def plot_results(all_runs: List[List[Dict]], out: Path = Path("co_adoption_results.png")) -> None:
    try:
        import matplotlib.pyplot as plt
    except ImportError:
        print("matplotlib not installed — skipping plots.")
        return

    import numpy as np

    years = [r["year"] for r in all_runs[0]]
    metrics = ["PV", "EV", "HP"]
    fig, axes = plt.subplots(1, 3, figsize=(14, 4), sharey=False)

    for ax, m in zip(axes, metrics):
        data = np.array([[r[m] for r in run] for run in all_runs])
        mean = data.mean(axis=0)
        lo, hi = np.percentile(data, 10, axis=0), np.percentile(data, 90, axis=0)
        ax.plot(years, mean, label="mean")
        ax.fill_between(years, lo, hi, alpha=0.25, label="10-90th pct")
        ax.set_title(m)
        ax.set_xlabel("Year")
        ax.set_ylabel("# adopters")
        ax.legend(fontsize=8)

    fig.suptitle("Co-adoption of low-carbon household energy technologies")
    plt.tight_layout()
    plt.savefig(out, dpi=120)
    print(f"Plot saved → {out}")
    plt.show()
