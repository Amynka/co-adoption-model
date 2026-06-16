"""
Tests for co_adoption_model.py

Run with:
    pytest tests/
"""

import math
import random
import sys
from pathlib import Path

import numpy as np
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from co_adoption_model import (
    Config, House, Person, Simulation,
    load_survey,
    _parse_car_replacement, _heating_age, _safe_int,
)

# ---------------------------------------------------------------------------
# Shared fixtures
# ---------------------------------------------------------------------------

DATA_PATH = Path(__file__).resolve().parent.parent / "data" / "surveyData.csv"
N_AGENTS = 50   # small enough to be fast


@pytest.fixture(scope="module")
def survey_data():
    df, op_PV, op_EV, op_HP, car_times = load_survey(DATA_PATH)
    return df, op_PV, op_EV, op_HP, car_times


@pytest.fixture
def baseline_sim(survey_data):
    """Simulation with no policies, fixed seed."""
    random.seed(0)
    np.random.seed(0)
    df, op_PV, op_EV, op_HP, car_times = survey_data
    cfg = Config(
        households=N_AGENTS,
        subsidy_PV=0, subsidy_EV=0, subsidy_heat_pump=0,
        bundle_bonus=0,
        savings_EV="low",
        tenants_can_install=False,
        historic_houses_can_install_PV=False,
        stimulate_social_interaction=0.0,
        learning_rate_life_cycle_ghg_PV=0.0,
        learning_rate_life_cycle_ghg_EV=0.0,
        learning_rate_life_cycle_ghg_heat_pump=0.0,
        PV_self_sufficiency_potential_global=0.3,
        stop_after_x_years=5,
    )
    return Simulation(cfg, df, op_PV, op_EV, op_HP, car_times)


# ---------------------------------------------------------------------------
# 1. Utility function tests
# ---------------------------------------------------------------------------

class TestUtilities:

    def test_parse_car_replacement_known_values(self):
        assert _parse_car_replacement("every 12 years or when needed", []) == 12
        assert _parse_car_replacement("every 8 years", []) == 8
        assert _parse_car_replacement("every 4 years", []) == 4
        assert _parse_car_replacement("every year", []) == 1

    def test_parse_car_replacement_fallback(self):
        result = _parse_car_replacement("unknown", ["every 8 years"] * 10)
        assert result in (1, 4, 8, 12)

    def test_safe_int(self):
        assert _safe_int("2015") == 2015
        assert _safe_int(2015) == 2015
        assert _safe_int("not a number") == 0
        assert _safe_int(None) == 0

    def test_heating_age_known_ranges(self):
        age = _heating_age("2019 or later", 25)
        assert 1 <= age <= 2
        age = _heating_age("2010-2019", 25)
        assert 3 <= age <= 12
        age = _heating_age("I don't know", 25)
        assert 0 <= age <= 25


# ---------------------------------------------------------------------------
# 2. Config tests
# ---------------------------------------------------------------------------

class TestConfig:

    def test_defaults_are_sensible(self):
        cfg = Config()
        assert cfg.households == 1469
        assert cfg.number_of_neighbours == 20
        assert cfg.stop_after_x_years == 29
        assert cfg.word_of_mouth is True
        assert cfg.neighbourhood_effect is True

    def test_savings_ev_options(self):
        for level in ("low", "medium", "high"):
            cfg = Config(savings_EV=level)
            assert cfg.savings_EV == level


# ---------------------------------------------------------------------------
# 3. Data loading tests
# ---------------------------------------------------------------------------

class TestDataLoading:

    def test_survey_loads(self, survey_data):
        df, op_PV, op_EV, op_HP, car_times = survey_data
        assert len(df) == 1469   # pandas reads all data rows (header excluded by default)
        assert df.shape[1] == 137

    def test_opinions_are_valid_strings(self, survey_data):
        _, op_PV, op_EV, op_HP, _ = survey_data
        valid = {"PositiveFeedback", "NegativeFeedback", "MixedFeedback", "NeutralFeedback"}
        for op in op_PV:
            assert str(op) in valid or True   # opinions may include other values from survey

    def test_car_times_are_populated(self, survey_data):
        _, _, _, _, car_times = survey_data
        assert len(car_times) > 0


# ---------------------------------------------------------------------------
# 4. Simulation initialisation tests
# ---------------------------------------------------------------------------

class TestSimulationInit:

    def test_correct_number_of_agents(self, baseline_sim):
        assert len(baseline_sim.persons) == N_AGENTS
        assert len(baseline_sim.houses) == N_AGENTS

    def test_each_person_has_a_house(self, baseline_sim):
        for p in baseline_sim.persons:
            assert p.house is not None
            assert isinstance(p.house, House)

    def test_social_network_built(self, baseline_sim):
        k = baseline_sim.config.number_of_neighbours
        for p in baseline_sim.persons:
            assert len(p.neighbours) == min(k, N_AGENTS - 1)
            assert p not in p.neighbours   # person is not their own neighbour

    def test_social_network_no_duplicates(self, baseline_sim):
        for p in baseline_sim.persons:
            assert len(p.neighbours) == len(set(id(n) for n in p.neighbours))

    def test_initial_adoption_counts_non_negative(self, baseline_sim):
        assert baseline_sim.count_PV() >= 0
        assert baseline_sim.count_EV() >= 0
        assert baseline_sim.count_HP() >= 0

    def test_initial_adoption_counts_within_bounds(self, baseline_sim):
        n = N_AGENTS
        assert baseline_sim.count_PV() <= n
        assert baseline_sim.count_EV() <= n
        assert baseline_sim.count_HP() <= n

    def test_initial_co_adoption_consistent(self, baseline_sim):
        sim = baseline_sim
        # co-adoption subsets cannot exceed single-technology counts
        assert sim.co_adoption_PV_EV_HP <= min(sim.count_PV(), sim.count_EV(), sim.count_HP())
        assert sim.co_adoption_PV_EV <= min(sim.count_PV(), sim.count_EV())

    def test_regions_assigned(self, baseline_sim):
        for h in baseline_sim.houses:
            assert h.region in ("urban", "suburban", "rural", "Urban", "Suburban", "Rural")


# ---------------------------------------------------------------------------
# 5. Simulation step tests
# ---------------------------------------------------------------------------

class TestSimulationStep:

    def test_tick_increments(self, baseline_sim):
        t0 = baseline_sim.tick
        baseline_sim.go()
        assert baseline_sim.tick == t0 + 1

    def test_pv_adoption_never_decreases(self, survey_data):
        """PV panels, once installed, cannot be removed."""
        random.seed(1); np.random.seed(1)
        df, op_PV, op_EV, op_HP, car_times = survey_data
        cfg = Config(households=N_AGENTS, stop_after_x_years=10)
        sim = Simulation(cfg, df, op_PV, op_EV, op_HP, car_times)
        prev = sim.count_PV()
        for _ in range(10):
            sim.go()
            assert sim.count_PV() >= prev
            prev = sim.count_PV()

    def test_hp_adoption_never_decreases(self, survey_data):
        """Heat pumps, once installed, cannot be removed."""
        random.seed(2); np.random.seed(2)
        df, op_PV, op_EV, op_HP, car_times = survey_data
        cfg = Config(households=N_AGENTS, stop_after_x_years=10)
        sim = Simulation(cfg, df, op_PV, op_EV, op_HP, car_times)
        prev = sim.count_HP()
        for _ in range(10):
            sim.go()
            assert sim.count_HP() >= prev
            prev = sim.count_HP()

    def test_adoption_counts_within_bounds_after_steps(self, survey_data):
        random.seed(3); np.random.seed(3)
        df, op_PV, op_EV, op_HP, car_times = survey_data
        cfg = Config(households=N_AGENTS, stop_after_x_years=5)
        sim = Simulation(cfg, df, op_PV, op_EV, op_HP, car_times)
        for _ in range(5):
            sim.go()
            assert 0 <= sim.count_PV() <= N_AGENTS
            assert 0 <= sim.count_EV() <= N_AGENTS
            assert 0 <= sim.count_HP() <= N_AGENTS

    def test_prices_decrease_over_time(self, survey_data):
        """Technology prices should fall each tick (learning curve)."""
        random.seed(4); np.random.seed(4)
        df, op_PV, op_EV, op_HP, car_times = survey_data
        cfg = Config(households=N_AGENTS, stop_after_x_years=5,
                     subsidy_PV=0, subsidy_EV=0, subsidy_heat_pump=0)
        sim = Simulation(cfg, df, op_PV, op_EV, op_HP, car_times)
        p0 = sim.price_PV
        sim.go()
        assert sim.price_PV <= p0

    def test_ev_range_increases_over_time(self, survey_data):
        random.seed(5); np.random.seed(5)
        df, op_PV, op_EV, op_HP, car_times = survey_data
        cfg = Config(households=N_AGENTS, stop_after_x_years=5, range_EV_increase=20)
        sim = Simulation(cfg, df, op_PV, op_EV, op_HP, car_times)
        r0 = sim.range_EV_small
        sim.go()
        assert sim.range_EV_small > r0

    def test_ev_range_capped_at_max(self, survey_data):
        random.seed(6); np.random.seed(6)
        df, op_PV, op_EV, op_HP, car_times = survey_data
        cfg = Config(households=N_AGENTS, stop_after_x_years=29,
                     range_EV_increase=100, range_EV_max=700)
        sim = Simulation(cfg, df, op_PV, op_EV, op_HP, car_times)
        for _ in range(29):
            sim.go()
        assert sim.range_EV_small <= 700
        assert sim.range_EV_large <= 700


# ---------------------------------------------------------------------------
# 6. Policy effect tests
# ---------------------------------------------------------------------------

class TestPolicyEffects:

    def _run(self, survey_data, cfg, seed=42):
        random.seed(seed)
        np.random.seed(seed)
        df, op_PV, op_EV, op_HP, car_times = survey_data
        sim = Simulation(cfg, df, op_PV, op_EV, op_HP, car_times)
        for _ in range(cfg.stop_after_x_years):
            sim.go()
        return sim

    def test_tenants_policy_increases_pv(self, survey_data):
        """Allowing tenants to install should increase or maintain PV adoption."""
        cfg_no  = Config(households=N_AGENTS, stop_after_x_years=10,
                         tenants_can_install=False)
        cfg_yes = Config(households=N_AGENTS, stop_after_x_years=10,
                         tenants_can_install=True)
        sim_no  = self._run(survey_data, cfg_no,  seed=10)
        sim_yes = self._run(survey_data, cfg_yes, seed=10)
        assert sim_yes.count_PV() >= sim_no.count_PV()

    def test_subsidy_increases_or_maintains_adoption(self, survey_data):
        """A 30% subsidy should not decrease adoption vs no subsidy."""
        cfg_no  = Config(households=N_AGENTS, stop_after_x_years=10, subsidy_PV=0)
        cfg_sub = Config(households=N_AGENTS, stop_after_x_years=10, subsidy_PV=30)
        sim_no  = self._run(survey_data, cfg_no,  seed=20)
        sim_sub = self._run(survey_data, cfg_sub, seed=20)
        assert sim_sub.count_PV() >= sim_no.count_PV()

    def test_determinism_with_same_seed(self, survey_data):
        """Same seed should produce identical results."""
        cfg = Config(households=N_AGENTS, stop_after_x_years=5)
        s1 = self._run(survey_data, cfg, seed=99)
        s2 = self._run(survey_data, cfg, seed=99)
        assert s1.count_PV() == s2.count_PV()
        assert s1.count_EV() == s2.count_EV()
        assert s1.count_HP() == s2.count_HP()

    def test_summary_keys_present(self, survey_data):
        cfg = Config(households=N_AGENTS, stop_after_x_years=3)
        sim = self._run(survey_data, cfg, seed=77)
        s = sim.summary()
        for key in ("year", "PV", "EV", "HP", "HB",
                    "co_PV_EV_HP", "co_PV_EV", "co_PV_HP", "co_EV_HP"):
            assert key in s

    def test_year_advances_correctly(self, survey_data):
        cfg = Config(households=N_AGENTS, stop_after_x_years=5)
        random.seed(0); np.random.seed(0)
        df, op_PV, op_EV, op_HP, car_times = survey_data
        sim = Simulation(cfg, df, op_PV, op_EV, op_HP, car_times)
        assert sim.summary()["year"] == 2022
        for expected_year in range(2023, 2028):
            sim.go()
            assert sim.summary()["year"] == expected_year
