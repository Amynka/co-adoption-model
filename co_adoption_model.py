"""
Co-adoption of low-carbon household energy technologies — Python port
Original NetLogo model v1.1 by the original authors (see CITATION.cff).

Usage:
    python co_adoption_model.py [--households N] [--runs R] [--years Y] [--csv out.csv]

Requires: pandas (pip install pandas)
Optional: matplotlib (for plots, pip install matplotlib)
"""

import argparse
import csv
import math
import random
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

import pandas as pd

# ---------------------------------------------------------------------------
# Default parameter values (mirrors NetLogo sliders / default settings)
# ---------------------------------------------------------------------------
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

    # extreme scenario values (used only when extreme_scenario_testing=True)
    extreme_scenario_prices: str = "high"           # "low" | "high"
    extreme_scenario_savings: str = "high"          # "low" | "high"
    extreme_scenario_GHG: str = "low"               # "low" | "high"
    extreme_scenario_EV_range: float = 700.0        # km
    extreme_scenarios_opinions: str = "PositiveFeedback"
    extreme_scenario_neighbours_meet_and_discuss: float = 1.0
    extreme_scenario_information_campaign: bool = False


# ---------------------------------------------------------------------------
# House
# ---------------------------------------------------------------------------
class House:
    def __init__(self, id_number: int, config: Config):
        self.id_number = id_number
        self.config = config

        self.region: str = ""
        self.historic: bool = False
        self.direct_light: bool = False
        self.private_parking: bool = False

        self.PV_solar_panel: bool = False
        self.thermal_solar_panel: bool = False
        self.thermal_solar_panel_age: int = 0
        self.heat_pump: bool = False
        self.heating_system_other: bool = False
        self.heating_system_other_age: int = 0
        self.home_battery: bool = False

        self.PV_self_sufficiency_potential_local: float = (
            config.PV_self_sufficiency_potential_global
        )


# ---------------------------------------------------------------------------
# Person
# ---------------------------------------------------------------------------
class Person:
    def __init__(self, id_number: int, profile: list, house: House, config: Config):
        self.id_number = id_number
        self.profile = profile          # list of raw survey values (0-indexed)
        self.house = house
        self.config = config

        self.owner: bool = False
        self.car: bool = False
        self.car_size: str = ""
        self.car_replacement_time: int = 8

        self.has_ICE: bool = False
        self.has_HEV: bool = False
        self.has_EV: bool = False

        # car ages
        self.ICE_age: int = 0
        self.HEV_age: int = 0

        self.neighbours_meet_and_discuss: float = 0.0
        self.opinion_PV: str = ""
        self.opinion_EV: str = ""
        self.opinion_heat_pump: str = ""

        self.emotion_PV: float = 0.0
        self.emotion_EV: float = 0.0
        self.emotion_heat_pump: float = 0.0

        # social network neighbours (set after all persons created)
        self.neighbours: list["Person"] = []

    # --- shortcuts into profile -----------------------------------------

    def p(self, i):
        """Return profile[i], converting to float where possible."""
        v = self.profile[i]
        if isinstance(v, str):
            try:
                return float(v)
            except ValueError:
                return v
        return v

    def pf(self, i) -> float:
        v = self.p(i)
        return float(v) if v not in ("", " ", None) else 0.0


# ---------------------------------------------------------------------------
# Simulation state
# ---------------------------------------------------------------------------
class Simulation:
    def __init__(self, config: Config, survey_df: pd.DataFrame,
                 opinions_PV: list, opinions_EV: list, opinions_HP: list,
                 car_replacement_times: list):
        self.config = config
        self.survey_df = survey_df.copy()
        self.opinions_PV = opinions_PV[:]
        self.opinions_EV = opinions_EV[:]
        self.opinions_HP = opinions_HP[:]
        self.car_replacement_times = car_replacement_times[:]
        self.tick = 0

        # technology globals
        self._init_tech()

        # co-adoption trackers
        self.co_adoption_PV_EV_HP: int = 0
        self.co_adoption_PV_EV: int = 0
        self.co_adoption_PV_HP: int = 0
        self.co_adoption_EV_HP: int = 0
        self.co_adoption_PV: int = 0
        self.co_adoption_EV: int = 0
        self.co_adoption_HP: int = 0

        # adoption record lists (id_numbers of adopters this tick)
        self.adoption_PV_ids: list = []
        self.adoption_EV_ids: list = []
        self.adoption_HP_ids: list = []
        self.adoption_battery_ids: list = []

        # persons and houses
        self.persons: list[Person] = []
        self.houses: list[House] = []
        self._setup_agents()
        self._apply_extreme_scenario_overrides()   # once, after all agents created
        self._build_social_network()
        self._update_co_adoption()

    # -----------------------------------------------------------------------
    # Initialisation
    # -----------------------------------------------------------------------

    def _init_tech(self):
        cfg = self.config
        # prices
        self.learning_rate_PV = 0.04
        self.price_min_PV = 5000.0
        self.price_PV = 15000.0
        self.price_net_PV = self.price_PV * (1 - cfg.subsidy_PV / 100)

        self.learning_rate_EV_small = 0.15
        self.price_min_EV_small = 8000.0
        self.price_EV_small = 18000.0
        self.price_net_EV_small = self.price_EV_small * (1 - cfg.subsidy_EV / 100)

        self.learning_rate_EV_medium = 0.15
        self.price_min_EV_medium = 29000.0
        self.price_EV_medium = 44000.0
        self.price_net_EV_medium = self.price_EV_medium * (1 - cfg.subsidy_EV / 100)

        self.learning_rate_EV_large = 0.15
        self.price_min_EV_large = 80000.0
        self.price_EV_large = 100000.0
        self.price_net_EV_large = self.price_EV_large * (1 - cfg.subsidy_EV / 100)

        self.learning_rate_HP = 0.04
        self.price_min_HP = 5000.0
        self.price_HP = 15800.0
        self.price_net_HP = self.price_HP * (1 - cfg.subsidy_heat_pump / 100)

        # EV savings
        sev = cfg.savings_EV
        if sev == "low":
            self.savings_EV_small, self.savings_EV_medium, self.savings_EV_large = 3.3, 3.7, 4.1
        elif sev == "high":
            self.savings_EV_small, self.savings_EV_medium, self.savings_EV_large = 8.4, 10.5, 12.6
        else:
            self.savings_EV_small, self.savings_EV_medium, self.savings_EV_large = 5.3, 7.1, 10.5

        # GHG
        self.ghg_PV = 80.0;      self.ghg_PV_min = 40.0
        self.ghg_EV = 80.0;      self.ghg_EV_min = 60.0
        self.ghg_HP = 50.0;      self.ghg_HP_min = 30.0
        self.lr_ghg_PV  = cfg.learning_rate_life_cycle_ghg_PV
        self.lr_ghg_EV  = cfg.learning_rate_life_cycle_ghg_EV
        self.lr_ghg_HP  = cfg.learning_rate_life_cycle_ghg_heat_pump

        # EV ranges
        self.range_EV_small  = 200.0
        self.range_EV_medium = 350.0
        self.range_EV_large  = 500.0

        # lifetimes
        self.heating_other_lifetime = 25 if cfg.replacement_time else 1
        self.thermal_solar_lifetime  = 25 if cfg.replacement_time else 1

        # adoption thresholds
        self.threshold_PV_owner   = 0.5
        self.threshold_PV_tenant  = 0.45
        self.threshold_EV_small   = 0.45
        self.threshold_EV_medium  = 0.40
        self.threshold_EV_large   = 0.95
        self.threshold_HP_owner   = 0.5
        self.threshold_HP_tenant  = 0.45

    def _setup_agents(self):
        cfg = self.config
        df = self.survey_df
        n = min(cfg.households, len(df))
        rows = df.sample(n=n, replace=False).reset_index(drop=True)

        for _, row in rows.iterrows():
            profile = list(row)
            id_num = int(profile[0]) if str(profile[0]).isdigit() else _

            house = House(id_num, cfg)
            person = Person(id_num, profile, house, cfg)
            self._initialize_person(person, house)
            self.houses.append(house)
            self.persons.append(person)

    def _initialize_person(self, p: Person, h: House):
        cfg = self.config

        # owner / tenant
        p.owner = (p.p(1) == 1)

        # house region / characteristics
        h.region = str(p.p(2))
        h.historic = (str(p.p(3)) == "Yes")
        h.direct_light = (str(p.p(4)) == "Yes")
        h.private_parking = (str(p.p(6)) == "Yes")

        # car ownership
        p.car = (p.p(7) == 1 or p.p(8) == 1 or p.p(9) == 1 or str(p.p(14)) == "YES")
        p.car_size = str(p.p(25))
        p.car_replacement_time = _parse_car_replacement(str(p.p(19)), self.car_replacement_times)
        if not cfg.replacement_time:
            p.car_replacement_time = 1

        # initial technology ownership
        # ICE
        if p.p(7) == 1 and str(p.p(18)) == "ConventionalCAR":
            p.has_ICE = True
            wc = str(p.p(15))
            p.ICE_age = random.randint(0, p.car_replacement_time) if wc == "Je ne me souviens pas" else max(0, 2022 - _safe_int(wc))

        # HEV
        if p.p(8) == 1 and str(p.p(18)) == "HEV":
            p.has_HEV = True
            wc = str(p.p(16))
            p.HEV_age = random.randint(0, p.car_replacement_time) if wc == "Je ne me souviens pas" else max(0, 2022 - _safe_int(wc))

        # EV
        if p.p(9) == 1 and str(p.p(18)) == "EV":
            p.has_EV = True
            p.opinion_EV = cfg.extreme_scenarios_opinions if cfg.extreme_scenario_testing else str(p.p(17))

        # PV
        if p.p(10) == 1:
            h.PV_solar_panel = True
            p.opinion_PV = cfg.extreme_scenarios_opinions if cfg.extreme_scenario_testing else str(p.p(22))

        # thermal solar
        if p.p(11) == 1:
            h.thermal_solar_panel = True
            h.heating_system_other = False
            wt = str(p.p(20))
            h.thermal_solar_panel_age = (
                random.randint(0, self.thermal_solar_lifetime)
                if wt == "Je ne me souviens pas"
                else max(0, 2022 - _safe_int(wt))
            )

        # heat pump
        if p.p(12) == 1:
            h.heat_pump = True
            h.heating_system_other = False
            p.opinion_heat_pump = cfg.extreme_scenarios_opinions if cfg.extreme_scenario_testing else str(p.p(21))

        # other heating system
        if not h.thermal_solar_panel and not h.heat_pump:
            h.heating_system_other = True
            renovation = str(p.p(5))
            h.heating_system_other_age = _heating_age(renovation, self.heating_other_lifetime)

        # home battery
        if p.p(13) == 1 or str(p.p(23)) == "Yes":
            h.home_battery = True
            h.PV_self_sufficiency_potential_local = min(
                1.0, cfg.PV_self_sufficiency_potential_global + 0.4
            )

        # emotions
        p.emotion_PV         = p.pf(46)
        p.emotion_EV         = p.pf(47)
        p.emotion_heat_pump  = p.pf(46)

        # social interaction tendency
        if cfg.extreme_scenario_testing:
            p.neighbours_meet_and_discuss = cfg.extreme_scenario_neighbours_meet_and_discuss
        else:
            p.neighbours_meet_and_discuss = min((p.pf(26) - 1) / 6 + cfg.stimulate_social_interaction, 1.0)

    def _apply_extreme_scenario_overrides(self):
        """Called once after all agents are created — not inside the per-person loop."""
        cfg = self.config
        if not cfg.extreme_scenario_testing:
            return
        if cfg.extreme_scenario_savings == "low":
            cfg.PV_net_bill_after_adoption = -483.5
            cfg.savings_heat_pump = 2200.0
            self.savings_EV_small, self.savings_EV_medium, self.savings_EV_large = 3.3, 3.7, 4.1
        else:
            cfg.PV_net_bill_after_adoption = 90.0
            cfg.savings_heat_pump = 2800.0
            self.savings_EV_small, self.savings_EV_medium, self.savings_EV_large = 8.4, 10.5, 12.5
        if cfg.extreme_scenario_information_campaign:
            cfg.information_campaign_PV_year = 2022
            cfg.information_campaign_EV_year = 2022
            cfg.information_campaign_heat_pump_year = 2022
        else:
            cfg.information_campaign_PV_year = 2051
            cfg.information_campaign_EV_year = 2051
            cfg.information_campaign_heat_pump_year = 2051

    def _build_social_network(self):
        """
        Assign spatial (x, y) coordinates matching the NetLogo 57×57 toroidal grid
        (urban core radius 18, suburban ring radius 31, rural = rest), then connect
        each person to their K nearest neighbours by Euclidean distance.
        """
        import math as _math

        cfg = self.config
        k = min(cfg.number_of_neighbours, len(self.persons) - 1)

        # --- assign coordinates based on region --------------------------------
        # NetLogo grid: patches in [-38,38]×[-38,38], distance from patch 0,0
        #   urban:    distance <= 18
        #   suburban: distance <= 31
        #   rural:    rest
        # We draw random (x,y) within the matching zone for each person.
        rng = random.Random()   # uses global seed already set by caller

        coords = []
        for p in self.persons:
            region = str(p.p(2)).strip().lower()
            for _ in range(500):            # rejection sampling
                x = rng.uniform(-38, 38)
                y = rng.uniform(-38, 38)
                d = _math.hypot(x, y)
                if region == "urban"    and d <= 18:  break
                if region == "suburban" and 18 < d <= 31: break
                if region == "rural"    and d > 31:   break
            coords.append((x, y))

        # --- connect K nearest by Euclidean distance ---------------------------
        xs = [c[0] for c in coords]
        ys = [c[1] for c in coords]
        for i, p in enumerate(self.persons):
            dists = [
                (_math.hypot(xs[i] - xs[j], ys[i] - ys[j]), j)
                for j in range(len(self.persons)) if j != i
            ]
            dists.sort()
            p.neighbours = [self.persons[j] for _, j in dists[:k]]

    # -----------------------------------------------------------------------
    # Main step
    # -----------------------------------------------------------------------

    def go(self):
        cfg = self.config
        year = 2022 + self.tick

        # reset per-tick adoption records
        self.adoption_PV_ids  = []
        self.adoption_EV_ids  = []
        self.adoption_HP_ids  = []
        self.adoption_battery_ids = []

        # --- update prices --------------------------------------------------
        if cfg.extreme_scenario_testing:
            if cfg.extreme_scenario_prices == "low":
                self.price_net_PV        = 5000.0
                self.price_net_EV_small  = 8000.0
                self.price_net_EV_medium = 29000.0
                self.price_net_EV_large  = 80000.0
                self.price_net_HP        = 5000.0
            else:
                self.price_net_PV        = 15000.0
                self.price_net_EV_small  = 18000.0
                self.price_net_EV_medium = 44000.0
                self.price_net_EV_large  = 100000.0
                self.price_net_HP        = 15000.0
        else:
            self.price_PV        = max(self.price_PV        * (1 - self.learning_rate_PV),        self.price_min_PV)
            self.price_EV_small  = max(self.price_EV_small  * (1 - self.learning_rate_EV_small),  self.price_min_EV_small)
            self.price_EV_medium = max(self.price_EV_medium * (1 - self.learning_rate_EV_medium), self.price_min_EV_medium)
            self.price_EV_large  = max(self.price_EV_large  * (1 - self.learning_rate_EV_large),  self.price_min_EV_large)
            self.price_HP        = max(self.price_HP        * (1 - self.learning_rate_HP),        self.price_min_HP)
            self.price_net_PV        = self.price_PV        * (1 - cfg.subsidy_PV        / 100)
            self.price_net_EV_small  = self.price_EV_small  * (1 - cfg.subsidy_EV        / 100)
            self.price_net_EV_medium = self.price_EV_medium * (1 - cfg.subsidy_EV        / 100)
            self.price_net_EV_large  = self.price_EV_large  * (1 - cfg.subsidy_EV        / 100)
            self.price_net_HP        = self.price_HP        * (1 - cfg.subsidy_heat_pump / 100)

        # --- update GHG emissions -------------------------------------------
        if cfg.extreme_scenario_testing:
            if cfg.extreme_scenario_GHG == "low":
                self.ghg_PV, self.ghg_EV, self.ghg_HP = 40.0, 60.0, 30.0
            else:
                self.ghg_PV, self.ghg_EV, self.ghg_HP = 80.0, 80.0, 50.0
        self.ghg_PV = max(self.ghg_PV * (1 - self.lr_ghg_PV), self.ghg_PV_min)
        self.ghg_EV = max(self.ghg_EV * (1 - self.lr_ghg_EV), self.ghg_EV_min)
        self.ghg_HP = max(self.ghg_HP * (1 - self.lr_ghg_HP), self.ghg_HP_min)

        # --- update EV ranges -----------------------------------------------
        if cfg.extreme_scenario_testing:
            r = cfg.extreme_scenario_EV_range
            self.range_EV_small = self.range_EV_medium = self.range_EV_large = r
        else:
            self.range_EV_small  = min(self.range_EV_small  + cfg.range_EV_increase, cfg.range_EV_max)
            self.range_EV_medium = min(self.range_EV_medium + cfg.range_EV_increase, cfg.range_EV_max)
            self.range_EV_large  = min(self.range_EV_large  + cfg.range_EV_increase, cfg.range_EV_max)

        # --- age technologies -----------------------------------------------
        for h in self.houses:
            if h.thermal_solar_panel:
                h.thermal_solar_panel_age += 1
                if h.thermal_solar_panel_age >= self.thermal_solar_lifetime:
                    h.thermal_solar_panel = False
            if h.heating_system_other:
                h.heating_system_other_age += 1
                if h.heating_system_other_age >= self.heating_other_lifetime:
                    h.heating_system_other = False

        for p in self.persons:
            if p.has_ICE:
                p.ICE_age += 1
                if p.ICE_age >= p.car_replacement_time:
                    p.has_ICE = False
            if p.has_HEV:
                p.HEV_age += 1
                if p.HEV_age >= p.car_replacement_time:
                    p.has_HEV = False

        # --- information campaigns ------------------------------------------
        if self.tick == cfg.information_campaign_PV_year - 2022:
            for p in self.persons:
                delta = p.pf(131)
                p.emotion_PV = max(0.0, min(1.0, p.emotion_PV + delta))
        if self.tick == cfg.information_campaign_EV_year - 2022:
            for p in self.persons:
                delta = p.pf(135)
                p.emotion_EV = max(0.0, min(1.0, p.emotion_EV + delta))
        if self.tick == cfg.information_campaign_heat_pump_year - 2022:
            for p in self.persons:
                delta = p.pf(133)
                p.emotion_heat_pump = max(0.0, min(1.0, p.emotion_heat_pump + delta))

        # --- social interaction update --------------------------------------
        for p in self.persons:
            p.neighbours_meet_and_discuss = min(
                (p.pf(26) - 1) / 6 + cfg.stimulate_social_interaction, 1.0
            )

        n_houses = len(self.houses)
        n_EV = sum(1 for p in self.persons if p.has_EV)
        n_PV = sum(1 for h in self.houses if h.PV_solar_panel)
        n_HP = sum(1 for h in self.houses if h.heat_pump)

        # --- bundle adoption ------------------------------------------------
        # NetLogo uses random `ask` order — shuffle to match
        shuffled = self.persons[:]
        random.shuffle(shuffled)

        if cfg.bundle_bonus > 0:
            # PV + EV + heat pump
            for p in shuffled:
                h = p.house
                if (self._pv_eligible(p) and self._hp_eligible(p)
                        and p.car and not p.has_ICE and not p.has_HEV and not p.has_EV
                        and self._eval_PV_bundle(p, n_PV, n_houses)
                        and self._eval_HP_bundle(p, n_HP, n_houses)
                        and self._eval_EV_bundle(p, n_EV, n_houses)):
                    self._adopt_PV(p);  self._adopt_EV(p, n_PV, n_HP, n_EV, n_houses)
                    self._adopt_HP(p, n_PV, n_HP, n_houses)
                    n_EV = sum(1 for q in self.persons if q.has_EV)
                    n_PV = sum(1 for h2 in self.houses if h2.PV_solar_panel)
                    n_HP = sum(1 for h2 in self.houses if h2.heat_pump)

            # PV + EV
            for p in shuffled:
                h = p.house
                if (self._pv_eligible(p)
                        and p.car and not p.has_ICE and not p.has_HEV and not p.has_EV
                        and self._eval_PV_bundle(p, n_PV, n_houses)
                        and self._eval_EV_bundle(p, n_EV, n_houses)):
                    self._adopt_PV(p);  self._adopt_EV(p, n_PV, n_HP, n_EV, n_houses)
                    n_EV = sum(1 for q in self.persons if q.has_EV)
                    n_PV = sum(1 for h2 in self.houses if h2.PV_solar_panel)

            # EV + heat pump
            for p in shuffled:
                if (p.car and not p.has_ICE and not p.has_HEV and not p.has_EV
                        and self._hp_eligible(p)
                        and self._eval_HP_bundle(p, n_HP, n_houses)
                        and self._eval_EV_bundle(p, n_EV, n_houses)):
                    self._adopt_EV(p, n_PV, n_HP, n_EV, n_houses)
                    self._adopt_HP(p, n_PV, n_HP, n_houses)
                    n_EV = sum(1 for q in self.persons if q.has_EV)
                    n_HP = sum(1 for h2 in self.houses if h2.heat_pump)

        # --- individual PV adoption -----------------------------------------
        n_PV = sum(1 for h in self.houses if h.PV_solar_panel)
        n_HP = sum(1 for h in self.houses if h.heat_pump)
        n_EV = sum(1 for p in self.persons if p.has_EV)
        for p in shuffled:
            if self._pv_eligible(p):
                self._eval_PV(p, n_PV, n_houses)
        n_PV = sum(1 for h in self.houses if h.PV_solar_panel)

        # --- individual heat pump adoption ----------------------------------
        for p in shuffled:
            if self._hp_eligible(p):
                self._eval_HP(p, n_PV, n_HP, n_houses)
        n_HP = sum(1 for h in self.houses if h.heat_pump)

        # --- fallback: install other heating system -------------------------
        for p in shuffled:
            h = p.house
            if not h.heating_system_other and not h.thermal_solar_panel and not h.heat_pump:
                h.heating_system_other = True
                h.heating_system_other_age = 0

        # --- EV adoption ----------------------------------------------------
        n_EV = sum(1 for p in self.persons if p.has_EV)
        for p in shuffled:
            if p.car and not p.has_ICE and not p.has_HEV and not p.has_EV:
                if p.car_size == "Small car":
                    self._eval_EV_small(p, n_PV, n_HP, n_EV, n_houses)
                elif p.car_size == "Medium car":
                    self._eval_EV_medium(p, n_PV, n_HP, n_EV, n_houses)
                elif p.car_size == "Large car":
                    self._eval_EV_large(p, n_PV, n_HP, n_EV, n_houses)
                n_EV = sum(1 for q in self.persons if q.has_EV)

        self._update_co_adoption()
        self.tick += 1

    # -----------------------------------------------------------------------
    # Eligibility helpers
    # -----------------------------------------------------------------------

    def _pv_eligible(self, p: Person) -> bool:
        cfg = self.config
        h = p.house
        return (
            (p.owner or cfg.tenants_can_install)
            and (not h.historic or cfg.historic_houses_can_install_PV)
            and h.direct_light
            and not h.PV_solar_panel
            and not h.thermal_solar_panel
        )

    def _hp_eligible(self, p: Person) -> bool:
        cfg = self.config
        h = p.house
        return (
            (p.owner or cfg.tenants_can_install)
            and not h.heating_system_other
            and not h.thermal_solar_panel
            and not h.heat_pump
        )

    # -----------------------------------------------------------------------
    # Logistic evaluation helpers
    # -----------------------------------------------------------------------

    @staticmethod
    def _sigmoid(x: float) -> float:
        return 1.0 / (1.0 + math.exp(-x))

    def _eval_PV(self, p: Person, n_PV: int, n_houses: int):
        score = self._pv_score(p, n_PV, n_houses, bundle_discount=0.0)
        threshold = self.threshold_PV_owner if p.owner else self.threshold_PV_tenant
        if self._sigmoid(score) >= threshold:
            self._adopt_PV(p)

    def _eval_PV_bundle(self, p: Person, n_PV: int, n_houses: int) -> bool:
        score = self._pv_score(p, n_PV, n_houses, bundle_discount=self.config.bundle_bonus / 100)
        threshold = self.threshold_PV_owner if p.owner else self.threshold_PV_tenant
        return self._sigmoid(score) >= threshold

    def _pv_score(self, p: Person, n_PV: int, n_houses: int, bundle_discount: float) -> float:
        cfg = self.config
        h = p.house
        pr = p.profile
        ne = (n_PV / n_houses * p.pf(53)) if cfg.neighbourhood_effect else 0.0
        return (
            p.pf(48)
            + p.pf(49) * (self.price_net_PV / 1000 * (1 - bundle_discount))
            + p.pf(50) * (-1 * cfg.PV_net_bill_after_adoption)
            + p.pf(51) * self.ghg_PV
            + p.pf(52) * h.PV_self_sufficiency_potential_local
            + ne
            + p.pf(54) * p.pf(27)
            + p.pf(55) * p.pf(28)
            + p.pf(56) * p.pf(29)
            + p.pf(57) * p.pf(30)
            + p.pf(58) * p.pf(31)
            + p.pf(59) * p.pf(32)
            + p.pf(60) * p.emotion_PV
            + p.pf(61) * p.pf(44)
            + p.pf(62) * p.pf(45)
            + (p.pf(63) if p.has_EV else 0.0)
            + (p.pf(64) if h.heat_pump else 0.0)
        )

    def _eval_HP(self, p: Person, n_PV: int, n_HP: int, n_houses: int):
        score = self._hp_score(p, n_HP, n_houses, bundle_discount=0.0)
        threshold = self.threshold_HP_owner if p.owner else self.threshold_HP_tenant
        if self._sigmoid(score) >= threshold:
            self._adopt_HP(p, n_PV, n_HP, n_houses)

    def _eval_HP_bundle(self, p: Person, n_HP: int, n_houses: int) -> bool:
        score = self._hp_score(p, n_HP, n_houses, bundle_discount=self.config.bundle_bonus / 100)
        threshold = self.threshold_HP_owner if p.owner else self.threshold_HP_tenant
        return self._sigmoid(score) >= threshold

    def _hp_score(self, p: Person, n_HP: int, n_houses: int, bundle_discount: float) -> float:
        cfg = self.config
        h = p.house
        ne = (n_HP / n_houses * p.pf(120)) if cfg.neighbourhood_effect else 0.0
        return (
            p.pf(116)
            + p.pf(117) * (self.price_net_HP / 1000 * (1 - bundle_discount))
            + p.pf(118) * (cfg.savings_heat_pump / 1000)
            + p.pf(119) * self.ghg_HP
            + ne
            + p.pf(121) * p.pf(33)
            + p.pf(122) * p.pf(34)
            + p.pf(123) * p.pf(35)
            + p.pf(124) * p.pf(36)
            + p.pf(125) * p.pf(37)
            + p.pf(126) * p.emotion_heat_pump
            + p.pf(127) * p.pf(44)
            + p.pf(128) * p.pf(45)
            + (p.pf(129) if p.has_EV else 0.0)
            + (p.pf(130) if h.PV_solar_panel else 0.0)
        )

    def _eval_EV_bundle(self, p: Person, n_EV: int, n_houses: int) -> bool:
        if p.car_size == "Small car":
            score = self._ev_score(p, "small", n_EV, n_houses, bundle_discount=self.config.bundle_bonus / 100)
            return self._sigmoid(score) >= self.threshold_EV_small
        elif p.car_size == "Medium car":
            score = self._ev_score(p, "medium", n_EV, n_houses, bundle_discount=self.config.bundle_bonus / 100)
            return self._sigmoid(score) >= self.threshold_EV_medium
        elif p.car_size == "Large car":
            score = self._ev_score(p, "large", n_EV, n_houses, bundle_discount=self.config.bundle_bonus / 100)
            return self._sigmoid(score) >= self.threshold_EV_large
        return False

    def _eval_EV_small(self, p: Person, n_PV, n_HP, n_EV, n_houses):
        score = self._ev_score(p, "small", n_EV, n_houses, 0.0)
        if self._sigmoid(score) >= self.threshold_EV_small:
            self._adopt_EV(p, n_PV, n_HP, n_EV, n_houses)
        else:
            p.has_ICE = True;  p.ICE_age = 0

    def _eval_EV_medium(self, p: Person, n_PV, n_HP, n_EV, n_houses):
        score = self._ev_score(p, "medium", n_EV, n_houses, 0.0)
        if self._sigmoid(score) >= self.threshold_EV_medium:
            self._adopt_EV(p, n_PV, n_HP, n_EV, n_houses)
        else:
            p.has_ICE = True;  p.ICE_age = 0

    def _eval_EV_large(self, p: Person, n_PV, n_HP, n_EV, n_houses):
        score = self._ev_score(p, "large", n_EV, n_houses, 0.0)
        if self._sigmoid(score) >= self.threshold_EV_large:
            self._adopt_EV(p, n_PV, n_HP, n_EV, n_houses)
        else:
            p.has_ICE = True;  p.ICE_age = 0

    def _ev_score(self, p: Person, size: str, n_EV: int, n_houses: int, bundle_discount: float) -> float:
        cfg = self.config
        h = p.house
        if size == "small":
            base, price, savings, rng = 65, self.price_net_EV_small, self.savings_EV_small, self.range_EV_small
        elif size == "medium":
            base, price, savings, rng = 82, self.price_net_EV_medium, self.savings_EV_medium, self.range_EV_medium
        else:
            base, price, savings, rng = 99, self.price_net_EV_large, self.savings_EV_large, self.range_EV_large
        ne = (n_EV / n_houses * p.pf(base + 5)) if cfg.neighbourhood_effect else 0.0
        return (
            p.pf(base)
            + p.pf(base + 1) * (price / 1000 * (1 - bundle_discount))
            + p.pf(base + 2) * savings
            + p.pf(base + 3) * self.ghg_EV
            + p.pf(base + 4) * (rng / 100)
            + ne
            + p.pf(base + 6)  * p.pf(38)
            + p.pf(base + 7)  * p.pf(39)
            + p.pf(base + 8)  * p.pf(40)
            + p.pf(base + 9)  * p.pf(41)
            + p.pf(base + 10) * p.pf(42)
            + p.pf(base + 11) * p.pf(43)
            + p.pf(base + 12) * p.emotion_EV
            + p.pf(base + 13) * p.pf(44)
            + p.pf(base + 14) * p.pf(45)
            + (p.pf(base + 15) if h.PV_solar_panel else 0.0)
            + (p.pf(base + 16) if h.heat_pump else 0.0)
        )

    # -----------------------------------------------------------------------
    # Adoption actions
    # -----------------------------------------------------------------------

    def _adopt_PV(self, p: Person):
        h = p.house
        if h.PV_solar_panel:
            return
        h.PV_solar_panel = True
        p.opinion_PV = random.choice(self.opinions_PV) if self.opinions_PV else "NeutralFeedback"
        if self.config.word_of_mouth:
            self._word_of_mouth_PV(p)
        # battery co-adoption
        if str(p.p(24)) == "Yes":
            self._adopt_home_battery(p)
        self.adoption_PV_ids.append(p.id_number)

    def _adopt_EV(self, p: Person, n_PV, n_HP, n_EV, n_houses):
        if p.has_EV:
            return
        p.has_EV = True
        if p.house.private_parking:
            pass  # charge point installed (tracked implicitly)
        p.opinion_EV = random.choice(self.opinions_EV) if self.opinions_EV else "NeutralFeedback"
        if self.config.word_of_mouth:
            self._word_of_mouth_EV(p)
        # co-adoption trigger: re-evaluate PV and HP
        if self._pv_eligible(p):
            self._eval_PV(p, n_PV, n_houses)
        if self._hp_eligible(p):
            self._eval_HP(p, n_PV, n_HP, n_houses)
        self.adoption_EV_ids.append(p.id_number)

    def _adopt_HP(self, p: Person, n_PV, n_HP, n_houses):
        h = p.house
        if h.heat_pump:
            return
        h.heat_pump = True
        h.thermal_solar_panel = False
        h.heating_system_other = False
        h.heating_system_other_age = 0
        p.opinion_heat_pump = random.choice(self.opinions_HP) if self.opinions_HP else "NeutralFeedback"
        if self.config.word_of_mouth:
            self._word_of_mouth_HP(p)
        # co-adoption trigger: re-evaluate PV
        if (not h.historic or self.config.historic_houses_can_install_PV) and h.direct_light and not h.PV_solar_panel and not h.thermal_solar_panel:
            self._eval_PV(p, n_PV, n_houses)
        self.adoption_HP_ids.append(p.id_number)

    def _adopt_home_battery(self, p: Person):
        h = p.house
        if h.home_battery:
            return
        h.home_battery = True
        h.PV_self_sufficiency_potential_local = min(
            1.0, self.config.PV_self_sufficiency_potential_global + 0.4
        )
        self.adoption_battery_ids.append(p.id_number)

    # -----------------------------------------------------------------------
    # Word-of-mouth
    # -----------------------------------------------------------------------

    def _word_of_mouth_PV(self, p: Person):
        op = p.opinion_PV
        k = round(p.neighbours_meet_and_discuss * self.config.number_of_neighbours)
        targets = random.sample(p.neighbours, min(k, len(p.neighbours)))
        if op in ("PositiveFeedback", "MixedFeedback"):
            for nb in targets:
                nb.emotion_PV = max(0.0, min(1.0, nb.emotion_PV + nb.pf(131)))
        if op in ("NegativeFeedback", "MixedFeedback"):
            for nb in targets:
                nb.emotion_PV = max(0.0, min(1.0, nb.emotion_PV + nb.pf(132)))

    def _word_of_mouth_EV(self, p: Person):
        op = p.opinion_EV
        k = round(p.neighbours_meet_and_discuss * self.config.number_of_neighbours)
        targets = random.sample(p.neighbours, min(k, len(p.neighbours)))
        if op in ("PositiveFeedback", "MixedFeedback"):
            for nb in targets:
                nb.emotion_EV = max(0.0, min(1.0, nb.emotion_EV + nb.pf(135)))
        if op in ("NegativeFeedback", "MixedFeedback"):
            for nb in targets:
                nb.emotion_EV = max(0.0, min(1.0, nb.emotion_EV + nb.pf(136)))

    def _word_of_mouth_HP(self, p: Person):
        op = p.opinion_heat_pump
        k = round(p.neighbours_meet_and_discuss * self.config.number_of_neighbours)
        targets = random.sample(p.neighbours, min(k, len(p.neighbours)))
        if op in ("PositiveFeedback", "MixedFeedback"):
            for nb in targets:
                nb.emotion_heat_pump = max(0.0, min(1.0, nb.emotion_heat_pump + nb.pf(133)))
        if op in ("NegativeFeedback", "MixedFeedback"):
            for nb in targets:
                nb.emotion_heat_pump = max(0.0, min(1.0, nb.emotion_heat_pump + nb.pf(134)))

    # -----------------------------------------------------------------------
    # Co-adoption counts
    # -----------------------------------------------------------------------

    def _update_co_adoption(self):
        pv_ids  = {h.id_number for h in self.houses if h.PV_solar_panel}
        hp_ids  = {h.id_number for h in self.houses if h.heat_pump}
        ev_pids = {p.id_number for p in self.persons if p.has_EV}
        p_ids   = [p.id_number for p in self.persons]

        self.co_adoption_PV_EV_HP = sum(1 for pid in p_ids if pid in pv_ids and pid in hp_ids and pid in ev_pids)
        self.co_adoption_PV_EV    = sum(1 for pid in p_ids if pid in pv_ids and pid not in hp_ids and pid in ev_pids)
        self.co_adoption_PV_HP    = sum(1 for pid in p_ids if pid in pv_ids and pid in hp_ids and pid not in ev_pids)
        self.co_adoption_EV_HP    = sum(1 for pid in p_ids if pid not in pv_ids and pid in hp_ids and pid in ev_pids)
        self.co_adoption_PV       = sum(1 for pid in p_ids if pid in pv_ids and pid not in hp_ids and pid not in ev_pids)
        self.co_adoption_EV       = sum(1 for pid in p_ids if pid not in pv_ids and pid not in hp_ids and pid in ev_pids)
        self.co_adoption_HP       = sum(1 for pid in p_ids if pid not in pv_ids and pid in hp_ids and pid not in ev_pids)

    def _eligible_PV(self, persons):
        return [p for p in persons if self._pv_eligible(p)]

    # -----------------------------------------------------------------------
    # Reporters
    # -----------------------------------------------------------------------

    def count_PV(self):   return sum(1 for h in self.houses if h.PV_solar_panel)
    def count_EV(self):   return sum(1 for p in self.persons if p.has_EV)
    def count_HP(self):   return sum(1 for h in self.houses if h.heat_pump)
    def count_HB(self):   return sum(1 for h in self.houses if h.home_battery)

    def summary(self) -> dict:
        year = 2022 + self.tick
        return {
            "year": year,
            "tick": self.tick,
            "PV":   self.count_PV(),
            "EV":   self.count_EV(),
            "HP":   self.count_HP(),
            "HB":   self.count_HB(),
            "co_PV_EV_HP": self.co_adoption_PV_EV_HP,
            "co_PV_EV":    self.co_adoption_PV_EV,
            "co_PV_HP":    self.co_adoption_PV_HP,
            "co_EV_HP":    self.co_adoption_EV_HP,
            "co_PV_only":  self.co_adoption_PV,
            "co_EV_only":  self.co_adoption_EV,
            "co_HP_only":  self.co_adoption_HP,
            "price_net_PV":        round(self.price_net_PV, 0),
            "price_net_EV_small":  round(self.price_net_EV_small, 0),
            "price_net_EV_medium": round(self.price_net_EV_medium, 0),
            "price_net_HP":        round(self.price_net_HP, 0),
            "ghg_PV": round(self.ghg_PV, 2),
            "ghg_EV": round(self.ghg_EV, 2),
            "ghg_HP": round(self.ghg_HP, 2),
        }


# ---------------------------------------------------------------------------
# Utility functions
# ---------------------------------------------------------------------------

def _parse_car_replacement(value: str, fallback_list: list) -> int:
    mapping = {
        "every 12 years or when needed": 12,
        "every 8 years": 8,
        "every 4 years": 4,
        "every year": 1,
    }
    if value in mapping:
        return mapping[value]
    # draw from distribution
    candidate = random.choice(fallback_list) if fallback_list else "every 8 years"
    return mapping.get(str(candidate), 8)


def _safe_int(v) -> int:
    try:
        return int(float(str(v).strip()))
    except (ValueError, TypeError):
        return 0


def _heating_age(renovation: str, lifetime: int) -> int:
    mapping = {
        "I don't know":   lambda lt: random.randint(0, lt),
        "2019 or later":  lambda lt: random.randint(0, 1) + 1,
        "2010-2019":      lambda lt: random.randint(0, 9) + 3,
        "1990-1999":      lambda lt: random.randint(0, 9) + 13,
        "1980-1989":      lambda lt: random.randint(0, lt),
        "1970-1979":      lambda lt: random.randint(0, lt),
        "1960-1969":      lambda lt: random.randint(0, lt),
        "Before 1960":    lambda lt: random.randint(0, lt),
    }
    fn = mapping.get(renovation, lambda lt: random.randint(0, lt))
    return fn(lifetime)


# ---------------------------------------------------------------------------
# CSV loading
# ---------------------------------------------------------------------------

def load_survey(data_path: Path):
    df = pd.read_csv(data_path)
    raw = df.values.tolist()

    def clean_list(col_idx, remove_header):
        vals = [row[col_idx] for row in raw]
        vals = [v for v in vals if str(v).strip() not in (remove_header, " ", "", "nan")]
        return vals

    car_times  = clean_list(19, "CarPurchaseFrequency")
    opinions_PV = clean_list(22, "PVWoMowners")
    opinions_EV = clean_list(17, "EVWoMowners")
    opinions_HP = clean_list(21, "HPWoMowners")

    return df, opinions_PV, opinions_EV, opinions_HP, car_times


# ---------------------------------------------------------------------------
# Runner
# ---------------------------------------------------------------------------

def run_once(config: Config, data_path: Path, seed: Optional[int] = None) -> list[dict]:
    if seed is not None:
        random.seed(seed)
    df, op_PV, op_EV, op_HP, car_times = load_survey(data_path)
    sim = Simulation(config, df, op_PV, op_EV, op_HP, car_times)

    results = [sim.summary()]
    for _ in range(config.stop_after_x_years):
        sim.go()
        s = sim.summary()
        results.append(s)
        year = s["year"]
        if year in (2030, 2050):
            print(
                f"{year}: PV={s['PV']}  EV={s['EV']}  HP={s['HP']}  "
                f"co(PV+EV+HP)={s['co_PV_EV_HP']}  co(PV+EV)={s['co_PV_EV']}  "
                f"co(PV+HP)={s['co_PV_HP']}  co(EV+HP)={s['co_EV_HP']}"
            )
    return results


def save_csv(rows: list[dict], path: Path):
    if not rows:
        return
    with open(path, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=rows[0].keys())
        w.writeheader()
        w.writerows(rows)
    print(f"Saved {len(rows)} rows → {path}")


def plot_results(all_runs: list[list[dict]], config: Config):
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
    plt.savefig("co_adoption_results.png", dpi=120)
    print("Plot saved → co_adoption_results.png")
    plt.show()


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------

def main():
    _default_data = str(Path(__file__).resolve().parent / "data" / "surveyData.csv")
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
    parser.add_argument("--data",               type=str,   default=_default_data)
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

    all_runs = []
    for run_idx in range(args.runs):
        seed = (args.seed + run_idx) if args.seed is not None else None
        print(f"\n--- Run {run_idx + 1}/{args.runs} ---")
        rows = run_once(config, data_path, seed=seed)
        all_runs.append(rows)

        if args.csv:
            path = Path(args.csv)
            if args.runs > 1:
                path = path.with_stem(f"{path.stem}_run{run_idx + 1}")
            save_csv(rows, path)

    if args.plot:
        plot_results(all_runs, config)

    # final summary
    last = all_runs[0][-1]
    print(f"\nFinal state (year {last['year']}):")
    for k in ("PV", "EV", "HP", "HB", "co_PV_EV_HP", "co_PV_EV", "co_PV_HP", "co_EV_HP"):
        print(f"  {k}: {last[k]}")


if __name__ == "__main__":
    main()
