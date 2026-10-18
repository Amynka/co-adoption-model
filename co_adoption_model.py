"""
Co-adoption of low-carbon household energy technologies — command-line entry point.

The model lives in the `coadoption` package; this script runs it.

Usage:
    python co_adoption_model.py [--households N] [--runs R] [--years Y] [--csv out.csv]
"""

import argparse
import sys
from dataclasses import replace
from pathlib import Path

from coadoption import (
    DEFAULT_DATA_PATH, CoAdoptionModel, Config, SurveyData,
    plot_results, run_once, save_csv,
)

__all__ = ["Config", "CoAdoptionModel", "SurveyData", "run_once", "save_csv", "plot_results"]


def main():
    parser = argparse.ArgumentParser(description="Co-adoption ABM (Python port)")
    parser.add_argument("--households",         type=int,   default=1469)
    parser.add_argument("--neighbours",         type=int,   default=20)
    parser.add_argument("--years",              type=int,   default=29)
    parser.add_argument("--runs",               type=int,   default=1)
    parser.add_argument("--seed",               type=int,   default=None)
    parser.add_argument("--csv",                type=str,   default=None)
    parser.add_argument("--subsidy-pv",         type=float, default=0.0)
    parser.add_argument("--subsidy-ev",         type=float, default=0.0)
    parser.add_argument("--subsidy-hp",         type=float, default=33.0)
    parser.add_argument("--bundle-bonus",       type=float, default=100.0)
    parser.add_argument("--savings-ev",         type=str,   default="low",
                        choices=["low", "medium", "high"])
    parser.add_argument("--savings-hp",         type=float, default=2090.0,
                        help="Heat pump savings CHF/year")
    parser.add_argument("--pv-net-bill",        type=float, default=-489.0,
                        help="PV net bill after adoption (CHF/year)")
    parser.add_argument("--pv-self-suff",       type=float, default=1.0,
                        help="PV self-sufficiency potential (0-1)")
    parser.add_argument("--stimulate-social",   type=float, default=1.0,
                        help="Social interaction stimulation addend (0-1)")
    parser.add_argument("--no-wom",             action="store_true", help="Disable word-of-mouth")
    parser.add_argument("--no-neighbour",       action="store_true", help="Disable neighbourhood effect")
    parser.add_argument("--no-tenants",         action="store_true", help="Tenants cannot install")
    parser.add_argument("--no-historic",        action="store_true", help="Historic houses cannot install PV")
    parser.add_argument("--no-replacement",     action="store_true", help="Ignore economic lifetimes")
    parser.add_argument("--info-campaign-pv",   type=int,   default=2051)
    parser.add_argument("--info-campaign-ev",   type=int,   default=2051)
    parser.add_argument("--info-campaign-hp",   type=int,   default=2051)
    parser.add_argument("--range-ev-increase",  type=float, default=20.0)
    parser.add_argument("--data",               type=str,   default=str(DEFAULT_DATA_PATH))
    parser.add_argument("--plot",               action="store_true")
    args = parser.parse_args()

    config = Config(
        households=args.households,
        number_of_neighbours=args.neighbours,
        stop_after_x_years=args.years,
        subsidy_PV=args.subsidy_pv,
        subsidy_EV=args.subsidy_ev,
        subsidy_heat_pump=args.subsidy_hp,
        bundle_bonus=args.bundle_bonus,
        savings_EV=args.savings_ev,
        savings_heat_pump=args.savings_hp,
        PV_net_bill_after_adoption=args.pv_net_bill,
        PV_self_sufficiency_potential_global=args.pv_self_suff,
        stimulate_social_interaction=args.stimulate_social,
        word_of_mouth=not args.no_wom,
        neighbourhood_effect=not args.no_neighbour,
        tenants_can_install=not args.no_tenants,
        historic_houses_can_install_PV=not args.no_historic,
        replacement_time=not args.no_replacement,
        information_campaign_PV_year=args.info_campaign_pv,
        information_campaign_EV_year=args.info_campaign_ev,
        information_campaign_heat_pump_year=args.info_campaign_hp,
        range_EV_increase=args.range_ev_increase,
    )

    data_path = Path(args.data)
    if not data_path.exists():
        print(f"ERROR: survey data not found at {data_path}", file=sys.stderr)
        sys.exit(1)
    survey = SurveyData.load(data_path)

    all_runs = []
    for run_idx in range(args.runs):
        seed = (args.seed + run_idx) if args.seed is not None else None
        print(f"\n--- Run {run_idx + 1}/{args.runs} ---")
        rows = run_once(replace(config), survey, seed=seed)
        all_runs.append(rows)

        if args.csv:
            path = Path(args.csv)
            if args.runs > 1:
                path = path.with_stem(f"{path.stem}_run{run_idx + 1}")
            save_csv(rows, path)

    if args.plot:
        plot_results(all_runs)

    # final summary
    last = all_runs[0][-1]
    print(f"\nFinal state (year {last['year']}):")
    for k in ("PV", "EV", "HP", "HB", "co_PV_EV_HP", "co_PV_EV", "co_PV_HP", "co_EV_HP"):
        print(f"  {k}: {last[k]}")


if __name__ == "__main__":
    main()
