"""
Model parameters (mirrors the NetLogo sliders / default settings)
"""

from dataclasses import dataclass


@dataclass
class Config:
    # population
    households: int = 1469
    number_of_neighbours: int = 20

    # subsidies (%)
    subsidy_PV: float = 0.0
    subsidy_EV: float = 0.0
    subsidy_heat_pump: float = 33.0     # NetLogo default: 33 %

    # savings
    # savings_EV chooser: "low" | "medium" | "high"  (NetLogo default index 0 = "low")
    savings_EV: str = "low"
    savings_heat_pump: float = 2090.0   # CHF / year  (NetLogo default slider)
    PV_net_bill_after_adoption: float = -489.0  # CHF / year (NetLogo default)

    # GHG learning rates
    learning_rate_life_cycle_ghg_PV: float = 0.02
    learning_rate_life_cycle_ghg_EV: float = 0.01
    learning_rate_life_cycle_ghg_heat_pump: float = 0.02

    # EV range
    range_EV_increase: float = 20.0     # km / year
    range_EV_max: float = 700.0

    # policies
    bundle_bonus: float = 100.0         # % discount on bundle (NetLogo default 100)
    word_of_mouth: bool = True          # switch ON
    neighbourhood_effect: bool = True   # switch ON
    tenants_can_install: bool = True    # switch ON (NetLogo default 0 = ON)
    historic_houses_can_install_PV: bool = True  # switch ON
    replacement_time: bool = True       # respect economic lifetimes
    stimulate_social_interaction: float = 1.0  # NetLogo default slider: 1.0

    # information campaigns (year; set > 2050 to disable)
    information_campaign_PV_year: int = 2051
    information_campaign_EV_year: int = 2051
    information_campaign_heat_pump_year: int = 2051

    # PV self-sufficiency potential (global default, 0-1)
    PV_self_sufficiency_potential_global: float = 1.0  # NetLogo default slider: 1.0

    # run length
    stop_after_x_years: int = 29        # 2022 → 2051

    # sensitivity analysis (disabled by default)
    sensitivity_analysis: bool = False

    # extreme scenario testing (disabled by default)
    extreme_scenario_testing: bool = False

    # extreme scenario values (apply when extreme_scenario_testing=True)
    extreme_scenario_prices: str = "high"           # "low" | "high"
    extreme_scenario_savings: str = "high"          # "low" | "high"
    extreme_scenario_GHG: str = "low"               # "low" | "high"
    extreme_scenario_EV_range: float = 700.0        # km
    extreme_scenarios_opinions: str = "PositiveFeedback"
    extreme_scenario_neighbours_meet_and_discuss: float = 1.0
    extreme_scenario_information_campaign: bool = False
