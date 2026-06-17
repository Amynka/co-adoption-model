"""
Reproduces Figures 2, 3, and 5 from:
  van der Kam et al. (2024) "An empirical agent-based model of consumer
  co-adoption of low-carbon technologies to inform energy policy."
  Cell Reports Sustainability 1, 100268.

Usage:
    python make_figures.py [--scenarios N] [--households N] [--seed N] [--out DIR]

Requires: pandas, matplotlib, numpy, scipy  (pip install pandas matplotlib numpy scipy)
"""

import argparse
import itertools
import math
import multiprocessing as mp
import pickle
import random
import time
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import Optional

import numpy as np
import pandas as pd
import matplotlib
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
from matplotlib.lines import Line2D

# --------------------------------------------------------------------------
# Path to survey data (relative to this script)
# --------------------------------------------------------------------------
_DATA_PATH = Path(__file__).resolve().parent / "data" / "surveyData.csv"

# ============================================================
# Policy definitions
# ============================================================
# 14 binary policy dimensions matching the paper.
# Each entry: (name_shown_in_figure, config_delta_when_ON)

POLICY_NAMES = [
    "Subsidy PV (30%)",
    "Subsidy EV (30%)",
    "Subsidy HP (30%)",
    "Bundle Bonus (30%)",
    "High savings EV",
    "High savings HP (+600)",
    "High savings PV (net bill +73.5)",
    "GHG standards PV (−2%/yr)",
    "GHG standards EV (−1%/yr)",
    "GHG standards HP (−2%/yr)",
    "Neighbourhood battery (+20% self-suff)",
    "Tenants can install",
    "Historic houses can install",
    "Stimulate social interaction",
]
N_POLICIES = len(POLICY_NAMES)  # 14  →  2^14 = 16 384 total

# Short labels for Figure 3 / 4 axes
POLICY_LABELS_SHORT = [
    "Subsidy PV (30%)",
    "Subsidy EV (30%)",
    "Subsidy HP (30%)",
    "Bundle Bonus (30%)",
    "High savings EV",
    "High savings HP",
    "High savings PV",
    "GHG std. PV",
    "GHG std. EV",
    "GHG std. HP",
    "Nbhd battery",
    "Tenants install",
    "Historic install",
    "Social interaction",
]


def policy_vector_to_config_kwargs(vec: tuple[int, ...]) -> dict:
    """
    Convert a binary policy vector (length 14) to keyword overrides for Config.
    Baseline = no policies, low savings, no GHG improvement.
    """
    (s_pv, s_ev, s_hp, bundle, sev_hi, shp_hi, spv_hi,
     ghg_pv, ghg_ev, ghg_hp, nbhd_bat, tenants, historic, social) = vec

    # --- Baseline parameter values (no interventions, low savings) ----------
    kw = dict(
        subsidy_PV=0.0,
        subsidy_EV=0.0,
        subsidy_heat_pump=0.0,
        bundle_bonus=0.0,
        savings_EV="low",          # 3.3 / 3.7 / 4.1 CHF/100 km
        savings_heat_pump=2090.0,
        PV_net_bill_after_adoption=-489.0,
        PV_self_sufficiency_potential_global=0.3,
        learning_rate_life_cycle_ghg_PV=0.0,   # no GHG improvement in baseline
        learning_rate_life_cycle_ghg_EV=0.0,
        learning_rate_life_cycle_ghg_heat_pump=0.0,
        tenants_can_install=False,
        historic_houses_can_install_PV=False,
        stimulate_social_interaction=0.0,
        word_of_mouth=True,
        neighbourhood_effect=True,
        replacement_time=True,
    )

    # --- Apply policies -----------------------------------------------------
    if s_pv:
        kw["subsidy_PV"] = 30.0
    if s_ev:
        kw["subsidy_EV"] = 30.0
    if s_hp:
        kw["subsidy_heat_pump"] = 30.0
    if bundle:
        kw["bundle_bonus"] = 30.0
    if sev_hi:
        kw["savings_EV"] = "high"          # 8.4 / 10.5 / 12.6 CHF/100 km
    if shp_hi:
        kw["savings_heat_pump"] = 2090.0 + 600.0
    if spv_hi:
        kw["PV_net_bill_after_adoption"] = -489.0 + 73.5   # less negative = better
    if ghg_pv:
        kw["learning_rate_life_cycle_ghg_PV"] = 0.02
    if ghg_ev:
        kw["learning_rate_life_cycle_ghg_EV"] = 0.01
    if ghg_hp:
        kw["learning_rate_life_cycle_ghg_heat_pump"] = 0.02
    if nbhd_bat:
        # neighbourhood battery: increases self-sufficiency AND PV savings
        kw["PV_self_sufficiency_potential_global"] = min(
            1.0, kw["PV_self_sufficiency_potential_global"] + 0.2
        )
        kw["PV_net_bill_after_adoption"] = kw["PV_net_bill_after_adoption"] + 73.5
    if tenants:
        kw["tenants_can_install"] = True
    if historic:
        kw["historic_houses_can_install_PV"] = True
    if social:
        kw["stimulate_social_interaction"] = 0.14   # adds ~0.14 to NMD (0-1 scale)

    return kw


# ============================================================
# Simulation runner (imported inline to avoid circular imports)
# ============================================================

def _run_scenario(args):
    """Worker function: (vec, households, data_path_str, seed) → result dict."""
    vec, households, data_path_str, seed = args
    # import here so multiprocessing workers get fresh module state
    from co_adoption_model import Config, Simulation, load_survey

    if seed is not None:
        random.seed(seed)
        np.random.seed(seed)

    kw = policy_vector_to_config_kwargs(vec)
    cfg = Config(households=households, stop_after_x_years=29, **kw)
    df, op_PV, op_EV, op_HP, car_times = load_survey(Path(data_path_str))
    sim = Simulation(cfg, df, op_PV, op_EV, op_HP, car_times)

    years, pv, ev, hp, hb = [], [], [], [], []
    co_all, co_pv_ev, co_pv_hp, co_ev_hp = [], [], [], []
    single_only = []

    for tick in range(cfg.stop_after_x_years + 1):
        s = sim.summary()
        years.append(s["year"])
        pv.append(s["PV"])
        ev.append(s["EV"])
        hp.append(s["HP"])
        hb.append(s["HB"])
        co_all.append(s["co_PV_EV_HP"])
        co_pv_ev.append(s["co_PV_EV"])
        co_pv_hp.append(s["co_PV_HP"])
        co_ev_hp.append(s["co_EV_HP"])
        # co-adopters = own 2 or 3 techs
        co_total = (s["co_PV_EV_HP"] + s["co_PV_EV"] + s["co_PV_HP"] + s["co_EV_HP"])
        # single-only = own exactly 1 tech
        only = s["co_PV_only"] + s["co_EV_only"] + s["co_HP_only"]
        single_only.append(only)
        if tick < cfg.stop_after_x_years:
            sim.go()

    # extract per-person demographics at final state (tick 29)
    # income: use survey column index 26 (neighboordhood_r2, 1-7 scale) as proxy
    # ownership: p.owner
    income_groups = []
    ownership_groups = []
    co_adopt_status = []
    single_adopt_status = []
    for p in sim.persons:
        raw_inc = p.pf(26)  # 1-7 scale
        if raw_inc <= 2:
            income_groups.append("Low")
        elif raw_inc <= 5:
            income_groups.append("Mid")
        else:
            income_groups.append("High")
        ownership_groups.append("Owner" if p.owner else "Tenant")
        # co-adopt: owns 2+ technologies
        n_tech = int(p.house.PV_solar_panel) + int(p.has_EV) + int(p.house.heat_pump)
        co_adopt_status.append(n_tech >= 2)
        single_adopt_status.append(n_tech == 1)

    return {
        "vec": vec,
        "years": years,
        "PV": pv, "EV": ev, "HP": hp, "HB": hb,
        "co_all": co_all, "co_pv_ev": co_pv_ev,
        "co_pv_hp": co_pv_hp, "co_ev_hp": co_ev_hp,
        "single_only": single_only,
        # final-state demographics
        "income_groups": income_groups,
        "ownership_groups": ownership_groups,
        "co_adopt_status": co_adopt_status,
        "single_adopt_status": single_adopt_status,
    }


# ============================================================
# Figure helpers
# ============================================================

def _cell_reports_style():
    """Apply a clean, Cell Reports–style matplotlib rcParams."""
    plt.rcParams.update({
        "font.family": "sans-serif",
        "font.size": 9,
        "axes.spines.top": False,
        "axes.spines.right": False,
        "axes.linewidth": 0.8,
        "xtick.major.width": 0.8,
        "ytick.major.width": 0.8,
        "xtick.labelsize": 8,
        "ytick.labelsize": 8,
        "axes.labelsize": 9,
        "legend.fontsize": 7.5,
        "figure.dpi": 150,
    })


# ---- Figure 2 ---------------------------------------------------------------

def figure2(results: list[dict], baseline_idx: int, out_dir: Path):
    """
    4-panel diffusion curves (A=PV, B=EV, C=HP, D=co- vs single adoption).
    Replicates the style of Figure 2 in the paper.
    """
    _cell_reports_style()
    fig, axes = plt.subplots(2, 2, figsize=(9, 7))
    axes = axes.flatten()

    years = results[0]["years"]
    n_households = max(r["PV"][-1] for r in results)   # rough max

    panel_cfg = [
        ("A  Total PV solar panel adoption", "PV",  "#d62728", "#e08080"),
        ("B  Total EV adoption",             "EV",  "#2ca02c", "#82c882"),
        ("C  Total heat pump adoption",      "HP",  "#1f77b4", "#7ab8e0"),
    ]

    for ax, (title, key, dark_col, light_col) in zip(axes[:3], panel_cfg):
        # all scenario lines in light colour
        for r in results:
            ax.plot(years, r[key], color=light_col, alpha=0.4, lw=0.6)
        # baseline (no policies) in black
        ax.plot(years, results[baseline_idx][key], color="black", lw=1.4, zorder=5)
        # potential market (dashed)
        pot = max(r[key][-1] for r in results)
        ax.axhline(pot, color="black", lw=1, ls="--", alpha=0.6)

        ax.set_title(title, loc="left", fontweight="bold", fontsize=9)
        ax.set_xlabel("time (year)")
        ax.set_ylabel("# adopters")
        ax.set_ylim(bottom=0)
        ax.set_xlim(years[0], years[-1])

    # panel D: co-adoption (orange) vs single adoption (purple)
    ax = axes[3]
    co_data  = np.array([
        [r["co_all"][t] + r["co_pv_ev"][t] + r["co_pv_hp"][t] + r["co_ev_hp"][t]
         for t in range(len(years))]
        for r in results
    ])
    sng_data = np.array([[r["single_only"][t] for t in range(len(years))] for r in results])

    co_lo,  co_hi  = co_data.min(axis=0),  co_data.max(axis=0)
    sng_lo, sng_hi = sng_data.min(axis=0), sng_data.max(axis=0)
    co_med  = np.median(co_data,  axis=0)
    sng_med = np.median(sng_data, axis=0)

    ax.fill_between(years, co_lo,  co_hi,  color="#ff7f0e", alpha=0.35)
    ax.fill_between(years, sng_lo, sng_hi, color="#9467bd", alpha=0.35)
    ax.plot(years, co_med,  color="#ff7f0e", lw=1.4, label="Co-adoption")
    ax.plot(years, sng_med, color="#9467bd", lw=1.4, label="Single adoption")
    ax.plot(years, results[baseline_idx]["single_only"], color="black", lw=1.4)
    co_bl = [results[baseline_idx]["co_all"][t] + results[baseline_idx]["co_pv_ev"][t]
             + results[baseline_idx]["co_pv_hp"][t] + results[baseline_idx]["co_ev_hp"][t]
             for t in range(len(years))]
    ax.plot(years, co_bl, color="black", lw=1.4)

    ax.set_title("D  Total co-adoption and single adoption", loc="left",
                 fontweight="bold", fontsize=9)
    ax.set_xlabel("time (year)")
    ax.set_ylabel("# adopters")
    ax.set_ylim(bottom=0)
    ax.set_xlim(years[0], years[-1])
    ax.legend(loc="upper left")

    plt.tight_layout()
    path = out_dir / "figure2_diffusion_curves.png"
    fig.savefig(path, bbox_inches="tight")
    print(f"Saved → {path}")
    plt.close(fig)


# ---- Figure 3 ---------------------------------------------------------------

def figure3(results: list[dict], out_dir: Path):
    """
    Slope chart of policy effects in 2030 vs 2050 (linear regression coefficients).
    Replicates the style of Figure 3 in the paper.
    """
    from sklearn.linear_model import LinearRegression  # optional
    _cell_reports_style()

    years = results[0]["years"]
    t2030 = years.index(2030)
    t2050 = years.index(2050)

    techs = [("PV solar panels", "PV", "#d62728"),
             ("EVs",             "EV", "#2ca02c"),
             ("Heat pumps",      "HP", "#1f77b4")]

    fig, axes = plt.subplots(1, 3, figsize=(13, 5), sharey=False)

    for ax, (tech_name, key, col) in zip(axes, techs):
        # build design matrix: each row = policy vector; y = adoption count
        X = np.array([list(r["vec"]) for r in results], dtype=float)
        y30 = np.array([r[key][t2030] for r in results], dtype=float)
        y50 = np.array([r[key][t2050] for r in results], dtype=float)

        # OLS regression for each year
        try:
            from sklearn.linear_model import LinearRegression
            lr30 = LinearRegression(fit_intercept=True).fit(X, y30)
            lr50 = LinearRegression(fit_intercept=True).fit(X, y50)
            coef30 = lr30.coef_
            coef50 = lr50.coef_
        except ImportError:
            # fallback: numpy lstsq
            Xa = np.column_stack([np.ones(len(X)), X])
            coef30 = np.linalg.lstsq(Xa, y30, rcond=None)[0][1:]
            coef50 = np.linalg.lstsq(Xa, y50, rcond=None)[0][1:]

        # sort by 2050 coefficient
        order = np.argsort(coef50)[::-1]

        y_pos = np.arange(len(order))
        ys_30 = coef30[order]
        ys_50 = coef50[order]
        labels = [POLICY_LABELS_SHORT[i] for i in order]

        # draw connecting lines (slope chart)
        for i, (v30, v50) in enumerate(zip(ys_30, ys_50)):
            ax.plot([0, 1], [v30, v50], color=col, alpha=0.7, lw=1.2)
            ax.scatter([0, 1], [v30, v50], color=col, s=30, zorder=5)

        # annotate right-side labels
        for i, (v50, lab) in enumerate(zip(ys_50, labels)):
            ax.annotate(lab, (1.05, v50), fontsize=6.5, va="center")

        ax.set_xticks([0, 1])
        ax.set_xticklabels(["2022–2030", "2022–2050"])
        ax.set_ylabel("Δ adopters (regression coef.)" if ax == axes[0] else "")
        ax.set_title(f"Increased {tech_name}\nadoption by policy",
                     fontweight="bold", fontsize=9)
        ax.axhline(0, color="gray", lw=0.6, ls="--")

    plt.tight_layout()
    path = out_dir / "figure3_policy_impacts.png"
    fig.savefig(path, bbox_inches="tight")
    print(f"Saved → {path}")
    plt.close(fig)


# ---- Figure 5 ---------------------------------------------------------------

def figure5(results: list[dict], out_dir: Path):
    """
    Stacked area charts by income group and home ownership.
    Replicates Figure 5 in the paper (averaged across all simulations).
    """
    _cell_reports_style()
    years = results[0]["years"]
    n_agents = len(results[0]["income_groups"])
    n_results = len(results)

    # --- aggregate across all simulations ------------------------------------
    # For each year and each demographic group, average co-/single-/no-adoption share

    income_cats  = ["High", "Mid", "Low"]
    own_cats     = ["Owner", "Tenant"]
    inc_colors   = ["#e41a1c", "#ff7f00", "#377eb8"]   # red, orange, blue
    own_colors   = ["#ff7f00", "#377eb8"]

    fig, axes = plt.subplots(3, 4, figsize=(14, 10))
    row_labels = ["Co-adoption", "Single adoption", "No adoption"]

    def _shares_by_group(results, group_attr, cats, status_key):
        """Average share (fraction of total) for each category over all simulations."""
        # shape: (n_years, n_cats)
        all_shares = np.zeros((len(years), len(cats)))
        for r in results:
            groups = r[group_attr]
            for ti in range(len(years)):
                total = n_agents
                for ci, cat in enumerate(cats):
                    idx = [i for i, g in enumerate(groups) if g == cat]
                    if status_key == "co":
                        count = sum(r["co_adopt_status"][i] for i in idx)
                    elif status_key == "single":
                        count = sum(r["single_adopt_status"][i] for i in idx)
                    else:  # no adoption
                        count = sum(
                            not r["co_adopt_status"][i] and not r["single_adopt_status"][i]
                            for i in idx
                        )
                    all_shares[ti, ci] += count / total
        return all_shares / n_results

    def _within_shares_by_group(results, group_attr, cats, status_key):
        """Within-group share for each category."""
        all_shares = np.zeros((len(years), len(cats)))
        for r in results:
            groups = r[group_attr]
            for ti in range(len(years)):
                for ci, cat in enumerate(cats):
                    idx = [i for i, g in enumerate(groups) if g == cat]
                    if not idx:
                        continue
                    if status_key == "co":
                        count = sum(r["co_adopt_status"][i] for i in idx)
                    elif status_key == "single":
                        count = sum(r["single_adopt_status"][i] for i in idx)
                    else:
                        count = sum(
                            not r["co_adopt_status"][i] and not r["single_adopt_status"][i]
                            for i in idx
                        )
                    all_shares[ti, ci] += count / len(idx)
        return all_shares / n_results

    for ri, (status_key, row_label) in enumerate(
        [("co", "Co-adoption"), ("single", "Single adoption"), ("no", "No adoption")]
    ):
        # --- Income / fraction of total (col 0) ---
        ax = axes[ri, 0]
        shares = _shares_by_group(results, "income_groups", income_cats, status_key)
        ax.stackplot(years, shares.T, labels=income_cats, colors=inc_colors, alpha=0.85)
        ax.set_ylabel(f"{row_label}\nshare")
        ax.set_ylim(0, 1)
        if ri == 0:
            ax.set_title("Income group\nFraction of total", fontsize=8.5)
            ax.legend(loc="upper left", fontsize=6.5)

        # --- Income / within group (col 1) ---
        ax = axes[ri, 1]
        shares = _within_shares_by_group(results, "income_groups", income_cats, status_key)
        for ci, (cat, col) in enumerate(zip(income_cats, inc_colors)):
            ax.plot(years, shares[:, ci], color=col, lw=1.4, label=cat)
        ax.set_ylim(0, 1)
        if ri == 0:
            ax.set_title("Within group", fontsize=8.5)

        # --- Ownership / fraction of total (col 2) ---
        ax = axes[ri, 2]
        shares = _shares_by_group(results, "ownership_groups", own_cats, status_key)
        ax.stackplot(years, shares.T, labels=own_cats, colors=own_colors, alpha=0.85)
        ax.set_ylim(0, 1)
        if ri == 0:
            ax.set_title("Home ownership\nFraction of total", fontsize=8.5)
            ax.legend(loc="upper left", fontsize=6.5)

        # --- Ownership / within group (col 3) ---
        ax = axes[ri, 3]
        shares = _within_shares_by_group(results, "ownership_groups", own_cats, status_key)
        for ci, (cat, col) in enumerate(zip(own_cats, own_colors)):
            ax.plot(years, shares[:, ci], color=col, lw=1.4, label=cat)
        ax.set_ylim(0, 1)
        if ri == 0:
            ax.set_title("Within group", fontsize=8.5)

    for ax in axes.flatten():
        ax.set_xlabel("year" if ax in axes[2] else "")
        ax.set_xlim(years[0], years[-1])

    plt.suptitle("Average adoption shares across all simulations\n"
                 "by household income and home ownership", fontsize=10, fontweight="bold")
    plt.tight_layout()
    path = out_dir / "figure5_demographics.png"
    fig.savefig(path, bbox_inches="tight")
    print(f"Saved → {path}")
    plt.close(fig)


# ============================================================
# Main
# ============================================================

def main():
    matplotlib.use("Agg")   # non-interactive backend for saving files
    parser = argparse.ArgumentParser(description="Reproduce paper figures")
    parser.add_argument("--scenarios",  type=int, default=256,
                        help="Number of policy scenarios to sample (max 16384)")
    parser.add_argument("--households", type=int, default=300,
                        help="Agents per run (lower = faster; paper used 1469)")
    parser.add_argument("--seed",       type=int, default=42)
    parser.add_argument("--workers",    type=int, default=max(1, mp.cpu_count() - 1))
    parser.add_argument("--out",        type=str, default="figures")
    parser.add_argument("--cache",      type=str, default=None,
                        help="Load cached results from this pickle file instead of running")
    parser.add_argument("--save-cache", type=str, default=None,
                        help="Save results to this pickle file after running")
    parser.add_argument("--data",       type=str, default=str(_DATA_PATH))
    args = parser.parse_args()

    out_dir = Path(args.out)
    out_dir.mkdir(exist_ok=True)

    # --- load or generate results ------------------------------------------
    if args.cache and Path(args.cache).exists():
        print(f"Loading cached results from {args.cache} …")
        with open(args.cache, "rb") as f:
            results = pickle.load(f)
        print(f"Loaded {len(results)} scenarios.")
    else:
        # build scenario list
        rng = random.Random(args.seed)
        all_vecs = list(itertools.product([0, 1], repeat=N_POLICIES))
        # always include baseline (all zeros) and all-on (all ones)
        baseline_vec = tuple([0] * N_POLICIES)
        allon_vec    = tuple([1] * N_POLICIES)
        sample_n = min(args.scenarios - 2, len(all_vecs) - 2)
        rest     = [v for v in all_vecs if v not in (baseline_vec, allon_vec)]
        sampled  = rng.sample(rest, sample_n)
        vecs     = [baseline_vec] + sampled + [allon_vec]

        print(f"Running {len(vecs)} scenarios with {args.households} agents each …")
        print(f"Using {args.workers} parallel worker(s). This may take a few minutes.")
        t0 = time.time()

        worker_args = [
            (v, args.households, args.data, args.seed + i)
            for i, v in enumerate(vecs)
        ]

        if args.workers > 1:
            with mp.Pool(processes=args.workers) as pool:
                results = pool.map(_run_scenario, worker_args)
        else:
            results = [_run_scenario(a) for a in worker_args]

        elapsed = time.time() - t0
        print(f"Finished {len(results)} runs in {elapsed:.0f}s "
              f"({elapsed/len(results):.1f}s/run)")

        if args.save_cache:
            with open(args.save_cache, "wb") as f:
                pickle.dump(results, f)
            print(f"Results cached → {args.save_cache}")

    # find baseline index (all-zero policy vector)
    baseline_idx = next(
        i for i, r in enumerate(results) if all(v == 0 for v in r["vec"])
    )
    print(f"Baseline index: {baseline_idx}")

    # --- generate figures ---------------------------------------------------
    print("Generating Figure 2 …")
    figure2(results, baseline_idx, out_dir)

    print("Generating Figure 3 …")
    figure3(results, out_dir)

    print("Generating Figure 5 …")
    figure5(results, out_dir)

    print(f"\nAll figures saved to {out_dir}/")

    # quick console summary matching the paper's 2030/2050 printout
    bl = results[baseline_idx]
    years = bl["years"]
    for yr in (2030, 2050):
        ti = years.index(yr)
        print(f"\nBaseline {yr}: PV={bl['PV'][ti]}  EV={bl['EV'][ti]}  HP={bl['HP'][ti]}")
    best = max(results, key=lambda r: r["PV"][-1] + r["EV"][-1] + r["HP"][-1])
    print(f"\nBest scenario {2050}: PV={best['PV'][-1]}  EV={best['EV'][-1]}  HP={best['HP'][-1]}")
    print(f"  Policies: {[POLICY_NAMES[i] for i, v in enumerate(best['vec']) if v]}")


if __name__ == "__main__":
    main()
