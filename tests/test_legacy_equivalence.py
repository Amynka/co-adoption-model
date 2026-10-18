"""
Regression test: the refactored model reproduces the original Python port
(legacy/netlogo_port.py) exactly, year by year, for the same random draws.

The two implementations draw households differently (the original used
pandas/numpy sampling, the new model uses model.rng) and the original placed
households in the social network with an unseeded generator. To compare like
with like, both runs are given the same household sample and the same network
generator; everything else (car ages, opinions, shuffling, word of mouth) comes
from the same seeded random.Random sequence in both.
"""

import random
import sys
from pathlib import Path

import numpy as np
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from legacy import netlogo_port as legacy  # noqa: E402

from coadoption import CoAdoptionModel, Config, policy_vector_to_config_kwargs  # noqa: E402

N_HOUSEHOLDS = 200
YEARS = 29


class _SeededNetworkRandom:
    """The `random` module for the legacy code, with a seeded random.Random() for network placement"""

    def __init__(self, seed):
        self._seed = seed

    def Random(self, *args):
        return random.Random(f"{self._seed}:network")

    def __getattr__(self, name):
        return getattr(random, name)


def _legacy_rows(config, seed, data_path, monkeypatch):
    monkeypatch.setattr(legacy, "random", _SeededNetworkRandom(seed))
    random.seed(seed)
    np.random.seed(seed)
    df, op_pv, op_ev, op_hp, car_times = legacy.load_survey(data_path)
    sim = legacy.Simulation(config, df, op_pv, op_ev, op_hp, car_times)
    rows = [sim.summary()]
    for _ in range(YEARS):
        sim.go()
        rows.append(sim.summary())
    return rows


class _LegacySampling(CoAdoptionModel):
    """Draw households as the legacy code did (numpy global state after np.random.seed)"""

    def select_respondents(self, n):
        return self.survey.frame.sample(
            n=n, replace=False, random_state=np.random.RandomState(self.seed)
        ).reset_index(drop=True)


def _new_rows(config, seed, survey):
    model = _LegacySampling(survey, seed=seed)
    model.initialize_model(config)
    return model.run_simulation(YEARS)["simulation_data"]


SCENARIOS = {
    "netlogo_defaults": dict(),
    "paper_baseline": policy_vector_to_config_kwargs([0] * 14),
    "all_policies": policy_vector_to_config_kwargs([1] * 14),
    "no_social": dict(word_of_mouth=False, neighbourhood_effect=False),
    "campaigns_no_replacement": dict(information_campaign_PV_year=2025,
                                     information_campaign_EV_year=2030,
                                     information_campaign_heat_pump_year=2024,
                                     replacement_time=False, savings_EV="medium"),
    "extreme_low": dict(extreme_scenario_testing=True, extreme_scenario_prices="low",
                        extreme_scenario_savings="low", extreme_scenario_GHG="high",
                        extreme_scenario_information_campaign=True,
                        extreme_scenarios_opinions="MixedFeedback"),
    "extreme_high": dict(extreme_scenario_testing=True),
}


@pytest.mark.parametrize("seed", [0, 7])
@pytest.mark.parametrize("scenario", sorted(SCENARIOS))
def test_matches_legacy_port(scenario, seed, survey, monkeypatch):
    from conftest import DATA_PATH

    kwargs = dict(households=N_HOUSEHOLDS, stop_after_x_years=YEARS, **SCENARIOS[scenario])
    # fresh Config for each: the legacy code mutates its config in extreme scenarios
    expected = _legacy_rows(legacy.Config(**kwargs), seed, DATA_PATH, monkeypatch)
    actual = _new_rows(Config(**kwargs), seed, survey)

    assert len(actual) == len(expected)
    for old, new in zip(expected, actual):
        assert new == old, f"{scenario}, seed {seed}: first difference in {old['year']}"
