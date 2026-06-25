"""
Comparison test: NetLogo baseline_validation experiment vs Python model.

The test reads the CSV produced by NetLogo's BehaviorSpace headless run
(5 repetitions × 30 ticks, baseline parameters) and compares adoption counts
at 2030 (tick 8) and 2050 (tick 28) against 5 Python runs with the same config.

Both models are stochastic — we compare means and require them to agree within
±10% of total households (≈147 agents). This is a cross-model sanity check,
not a bit-for-bit comparison.

Run locally (after generating netlogo_baseline.csv):
    NETLOGO_CSV=netlogo_baseline.csv pytest tests/test_netlogo_comparison.py -v

In CI the path is set via the NETLOGO_CSV environment variable.
"""

import os
import random
import sys
from pathlib import Path

import numpy as np
import pandas as pd
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from co_adoption_model import Config, Simulation, load_survey

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

DATA_PATH    = Path(__file__).resolve().parent.parent / "data" / "surveyData.csv"
NETLOGO_CSV  = Path(os.environ.get("NETLOGO_CSV", "netlogo_baseline.csv"))
N_REPS       = 5
N_HOUSEHOLDS = 1469
TOLERANCE    = 0.10   # ±10% of total households = ±147 agents


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _baseline_config():
    """Exact parameters used in the NetLogo baseline_validation experiment."""
    return Config(
        households=N_HOUSEHOLDS,
        stop_after_x_years=29,
        number_of_neighbours=20,
        neighbourhood_effect=True,
        word_of_mouth=True,
        replacement_time=True,
        subsidy_PV=0,
        subsidy_EV=0,
        subsidy_heat_pump=33,
        bundle_bonus=100,
        savings_EV="low",
        savings_heat_pump=2090,
        PV_net_bill_after_adoption=-489,
        PV_self_sufficiency_potential_global=0.3,
        learning_rate_life_cycle_ghg_PV=0.0,
        learning_rate_life_cycle_ghg_EV=0.0,
        learning_rate_life_cycle_ghg_heat_pump=0.0,
        stimulate_social_interaction=1.0,
        tenants_can_install=True,
        historic_houses_can_install_PV=True,
        range_EV_increase=20,
        information_campaign_PV_year=2051,
        information_campaign_EV_year=2051,
        information_campaign_heat_pump_year=2051,
        extreme_scenario_testing=False,
    )


def _run_python_replicates(n_reps: int):
    """Run n_reps Python simulations, return dict of lists of (tick→count)."""
    survey_df, op_PV, op_EV, op_HP, car_times = load_survey(DATA_PATH)
    records = []
    for rep in range(n_reps):
        random.seed(rep * 1000)
        np.random.seed(rep * 1000)
        cfg = _baseline_config()
        sim = Simulation(cfg, survey_df, op_PV, op_EV, op_HP, car_times)
        for tick in range(cfg.stop_after_x_years + 1):
            s = sim.summary()
            records.append({
                "rep": rep, "tick": tick, "year": s["year"],
                "PV": s["PV"], "EV": s["EV"], "HP": s["HP"],
            })
            if tick < cfg.stop_after_x_years:
                sim.go()
    return pd.DataFrame(records)


def _parse_netlogo_csv(path: Path) -> pd.DataFrame:
    """
    Parse a NetLogo BehaviorSpace table CSV.
    The format has a few header lines then columns:
      [run number], [step], metric1, metric2, ...
    """
    # skip the first line (experiment metadata) and read from second
    with open(path) as f:
        lines = f.readlines()

    # find the header row (contains "[run number]")
    header_idx = next(i for i, l in enumerate(lines) if "[run number]" in l)
    df = pd.read_csv(path, skiprows=header_idx)
    df.columns = [c.strip().strip('"') for c in df.columns]

    col_map = {
        "[run number]":               "rep",
        "[step]":                     "tick",
        "count PV-solar-panels":      "PV",
        "count EVs":                  "EV",
        "count heat-pumps":           "HP",
        "count home-batteries":       "HB",
        "co-adoption-PV-EV-heat-pump": "co_PV_EV_HP",
        "co-adoption-PV-EV":          "co_PV_EV",
        "co-adoption-PV-heat-pump":   "co_PV_HP",
        "co-adoption-EV-heat-pump":   "co_EV_HP",
    }
    df = df.rename(columns={k: v for k, v in col_map.items() if k in df.columns})
    df["rep"] = df["rep"] - df["rep"].min()   # zero-index runs
    return df


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

@pytest.fixture(scope="module")
def netlogo_df():
    if not NETLOGO_CSV.exists():
        pytest.skip(f"NetLogo CSV not found at {NETLOGO_CSV} — run NetLogo first")
    return _parse_netlogo_csv(NETLOGO_CSV)


@pytest.fixture(scope="module")
def python_df():
    return _run_python_replicates(N_REPS)


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

class TestNetLogoPythonComparison:

    def _mean_at_tick(self, df: pd.DataFrame, tick: int, col: str) -> float:
        return df[df["tick"] == tick][col].mean()

    def test_pv_2030_within_tolerance(self, netlogo_df, python_df):
        """PV adoption at 2030 (tick 8) should agree within ±10% of households."""
        nl = self._mean_at_tick(netlogo_df, 8,  "PV")
        py = self._mean_at_tick(python_df,  8,  "PV")
        tol = TOLERANCE * N_HOUSEHOLDS
        assert abs(nl - py) <= tol, (
            f"PV at 2030: NetLogo mean={nl:.1f}, Python mean={py:.1f}, "
            f"diff={abs(nl-py):.1f} > tolerance {tol:.1f}"
        )

    def test_ev_2030_within_tolerance(self, netlogo_df, python_df):
        nl = self._mean_at_tick(netlogo_df, 8,  "EV")
        py = self._mean_at_tick(python_df,  8,  "EV")
        tol = TOLERANCE * N_HOUSEHOLDS
        assert abs(nl - py) <= tol, (
            f"EV at 2030: NetLogo mean={nl:.1f}, Python mean={py:.1f}, "
            f"diff={abs(nl-py):.1f} > tolerance {tol:.1f}"
        )

    def test_hp_2030_within_tolerance(self, netlogo_df, python_df):
        nl = self._mean_at_tick(netlogo_df, 8,  "HP")
        py = self._mean_at_tick(python_df,  8,  "HP")
        tol = TOLERANCE * N_HOUSEHOLDS
        assert abs(nl - py) <= tol, (
            f"HP at 2030: NetLogo mean={nl:.1f}, Python mean={py:.1f}, "
            f"diff={abs(nl-py):.1f} > tolerance {tol:.1f}"
        )

    def test_pv_2050_within_tolerance(self, netlogo_df, python_df):
        nl = self._mean_at_tick(netlogo_df, 28, "PV")
        py = self._mean_at_tick(python_df,  28, "PV")
        tol = TOLERANCE * N_HOUSEHOLDS
        assert abs(nl - py) <= tol, (
            f"PV at 2050: NetLogo mean={nl:.1f}, Python mean={py:.1f}, "
            f"diff={abs(nl-py):.1f} > tolerance {tol:.1f}"
        )

    def test_ev_2050_within_tolerance(self, netlogo_df, python_df):
        nl = self._mean_at_tick(netlogo_df, 28, "EV")
        py = self._mean_at_tick(python_df,  28, "EV")
        tol = TOLERANCE * N_HOUSEHOLDS
        assert abs(nl - py) <= tol, (
            f"EV at 2050: NetLogo mean={nl:.1f}, Python mean={py:.1f}, "
            f"diff={abs(nl-py):.1f} > tolerance {tol:.1f}"
        )

    def test_hp_2050_within_tolerance(self, netlogo_df, python_df):
        nl = self._mean_at_tick(netlogo_df, 28, "HP")
        py = self._mean_at_tick(python_df,  28, "HP")
        tol = TOLERANCE * N_HOUSEHOLDS
        assert abs(nl - py) <= tol, (
            f"HP at 2050: NetLogo mean={nl:.1f}, Python mean={py:.1f}, "
            f"diff={abs(nl-py):.1f} > tolerance {tol:.1f}"
        )

    def test_pv_monotone_in_both_models(self, netlogo_df, python_df):
        """PV should never decrease in either model."""
        for rep, grp in netlogo_df.groupby("rep"):
            pvs = grp.sort_values("tick")["PV"].tolist()
            assert pvs == sorted(pvs), f"NetLogo rep {rep}: PV decreased"
        for rep, grp in python_df.groupby("rep"):
            pvs = grp.sort_values("tick")["PV"].tolist()
            assert pvs == sorted(pvs), f"Python rep {rep}: PV decreased"

    def test_ev_hp_ordering_agrees_at_2050(self, netlogo_df, python_df):
        """NetLogo and Python should agree on which of EV/HP leads at 2050 for this baseline config.

        The relative ordering of EV vs HP adoption depends on the specific baseline
        parameters (subsidies, savings, prices) and is close (~3%) with only 5 reps,
        so we check cross-model agreement rather than asserting a fixed direction.
        """
        nl_ev = self._mean_at_tick(netlogo_df, 28, "EV")
        nl_hp = self._mean_at_tick(netlogo_df, 28, "HP")
        py_ev = self._mean_at_tick(python_df,  28, "EV")
        py_hp = self._mean_at_tick(python_df,  28, "HP")
        assert (nl_ev > nl_hp) == (py_ev > py_hp), (
            f"NetLogo and Python disagree on EV/HP ordering at 2050: "
            f"NetLogo EV={nl_ev:.0f} HP={nl_hp:.0f}, Python EV={py_ev:.0f} HP={py_hp:.0f}"
        )

    def test_print_comparison_summary(self, netlogo_df, python_df, capsys):
        """Print a side-by-side table (always passes — for human inspection)."""
        print("\n── NetLogo vs Python adoption comparison ──")
        print(f"{'Year':<6} {'Metric':<6}  {'NetLogo':>10}  {'Python':>10}  {'Diff':>8}  {'Diff%':>7}")
        print("-" * 55)
        for tick, year in [(8, 2030), (28, 2050)]:
            for col in ("PV", "EV", "HP"):
                nl = self._mean_at_tick(netlogo_df, tick, col)
                py = self._mean_at_tick(python_df,  tick, col)
                diff = py - nl
                pct  = diff / nl * 100 if nl > 0 else float("nan")
                print(f"{year:<6} {col:<6}  {nl:>10.1f}  {py:>10.1f}  {diff:>+8.1f}  {pct:>+6.1f}%")
        print()
