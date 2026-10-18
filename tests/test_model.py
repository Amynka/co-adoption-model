"""
Tests for the coadoption package (model behaviour).

Run with:
    pytest tests/
"""

import pytest

from consumer_choice_metamodel import ModelValidator, PhasedScheduler

from coadoption import (
    EV, HP, PV, Config, House, Household, N_POLICIES, POLICY_NAMES,
    policy_vector_to_config_kwargs,
)
from coadoption.factory import SurveyHouseholdFactory, _safe_int

N_AGENTS = 50   # small enough to be fast

BASELINE = dict(
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


@pytest.fixture
def baseline_model(make_model):
    """Model with no policies, fixed seed."""
    return make_model(seed=0, **BASELINE)


def _run(make_model, seed, years, **config):
    model = make_model(seed=seed, households=N_AGENTS, stop_after_x_years=years, **config)
    model.run_simulation(years)
    return model


class TestFactoryHelpers:

    def _factory(self, survey, **config):
        import random
        f = SurveyHouseholdFactory(Config(**config), survey.car_purchase_frequencies)
        f.rng = random.Random(0)
        return f

    def test_car_replacement_known_values(self, survey):
        f = self._factory(survey)
        assert f._car_replacement_time("every 12 years or when needed") == 12
        assert f._car_replacement_time("every 8 years") == 8
        assert f._car_replacement_time("every 4 years") == 4
        assert f._car_replacement_time("every year") == 1

    def test_car_replacement_fallback(self, survey):
        assert self._factory(survey)._car_replacement_time("unknown") in (1, 4, 8, 12)

    def test_safe_int(self):
        assert _safe_int("2015") == 2015
        assert _safe_int(2015) == 2015
        assert _safe_int("2015.0") == 2015
        assert _safe_int("not a number") == 0
        assert _safe_int(None) == 0

    def test_heating_age_known_ranges(self, survey):
        f = self._factory(survey)
        assert 1 <= f._heating_age("2019 or later") <= 2
        assert 3 <= f._heating_age("2010-2019") <= 12
        assert 0 <= f._heating_age("I don't know") <= 25


class TestConfig:

    def test_defaults_are_sensible(self):
        cfg = Config()
        assert cfg.households == 1469
        assert cfg.number_of_neighbours == 20
        assert cfg.stop_after_x_years == 29
        assert cfg.word_of_mouth is True
        assert cfg.neighbourhood_effect is True

    def test_policy_vector(self):
        assert N_POLICIES == len(POLICY_NAMES) == 14
        base = policy_vector_to_config_kwargs([0] * 14)
        assert base["subsidy_PV"] == 0.0 and base["tenants_can_install"] is False
        allon = policy_vector_to_config_kwargs([1] * 14)
        assert allon["subsidy_PV"] == 30.0
        # high PV savings and the neighbourhood battery both raise the net bill
        assert allon["PV_net_bill_after_adoption"] == -489.0 + 73.5 + 73.5
        assert allon["PV_self_sufficiency_potential_global"] == pytest.approx(0.5)
        Config(**allon)   # valid Config keywords

    def test_policy_vector_length_checked(self):
        with pytest.raises(ValueError):
            policy_vector_to_config_kwargs([0] * 3)


class TestDataLoading:

    def test_survey_loads(self, survey):
        assert len(survey) == 1469
        assert survey.frame.shape[1] == 137

    def test_opinion_pools_populated(self, survey):
        for family in (PV, EV, HP):
            assert len(survey.opinions[family]) > 0

    def test_car_times_are_populated(self, survey):
        assert len(survey.car_purchase_frequencies) > 0

    def test_respondent_access_by_name(self, survey):
        r = survey.respondents(survey.frame.head(1))[0]
        assert r.number("respondentID") == float(survey.frame["respondentID"].iloc[0])
        assert r.text("AreaType") in ("urban", "suburban", "rural")
        assert r.number("PVIntercept") == float(survey.frame["PVIntercept"].iloc[0])


class TestInitialisation:

    def test_correct_number_of_agents(self, baseline_model):
        assert len(baseline_model.households) == N_AGENTS
        assert baseline_model.agents is baseline_model.households

    def test_each_household_has_a_house(self, baseline_model):
        for h in baseline_model.households:
            assert isinstance(h, Household)
            assert isinstance(h.house, House)

    def test_social_network_built(self, baseline_model):
        k = baseline_model.config.number_of_neighbours
        network = baseline_model.environment.network
        for h in baseline_model.households:
            neighbours = network.get_neighbors(h.agent_id)
            assert len(neighbours) == min(k, N_AGENTS - 1)
            assert h.agent_id not in neighbours
            assert len(neighbours) == len(set(neighbours))

    def test_initial_adoption_counts_within_bounds(self, baseline_model):
        for family in (PV, EV, HP):
            assert 0 <= baseline_model.count(family) <= N_AGENTS

    def test_live_counts_match_households(self, baseline_model):
        for family in (PV, EV, HP):
            assert baseline_model.count(family) == sum(
                h.owns(family) for h in baseline_model.households)

    def test_initial_co_adoption_consistent(self, baseline_model):
        m = baseline_model
        assert m.co_adoption["co_PV_EV_HP"] <= min(m.count(PV), m.count(EV), m.count(HP))
        assert m.co_adoption["co_PV_EV"] <= min(m.count(PV), m.count(EV))

    def test_regions_assigned(self, baseline_model):
        for h in baseline_model.households:
            assert h.house.region in ("urban", "suburban", "rural")

    def test_netlogo_schedule_is_default(self, baseline_model):
        assert isinstance(baseline_model.scheduler, PhasedScheduler)
        assert all(h.rng is baseline_model.rng for h in baseline_model.households)

    def test_households_pass_metamodel_validation(self, baseline_model):
        assert ModelValidator.validate_model(baseline_model, required_socioeconomic=["owner"]) == []


class TestSteps:

    def test_tick_increments(self, baseline_model):
        baseline_model.step()
        assert baseline_model.current_time == 1
        assert baseline_model.summary()["year"] == 2023

    @pytest.mark.parametrize("family", [PV, HP])
    def test_adoption_never_decreases(self, make_model, family):
        model = make_model(seed=1, households=N_AGENTS)
        prev = model.count(family)
        for _ in range(10):
            model.step()
            assert model.count(family) >= prev
            prev = model.count(family)

    def test_live_counts_stay_consistent(self, make_model):
        model = make_model(seed=3, households=N_AGENTS)
        for _ in range(5):
            model.step()
            for family in (PV, EV, HP):
                assert model.count(family) == sum(h.owns(family) for h in model.households)

    def test_prices_decrease_over_time(self, make_model):
        model = make_model(seed=4, households=N_AGENTS, subsidy_PV=0)
        p0 = model.environment.technology(PV).net_price
        model.step()
        assert model.environment.technology(PV).net_price <= p0

    def test_ev_range_increases_and_is_capped(self, make_model):
        model = make_model(seed=5, households=N_AGENTS, range_EV_increase=100, range_EV_max=700)
        ev = model.environment.technology("EV_small")
        r0 = ev.range.value
        model.step()
        assert ev.range.value > r0
        for _ in range(28):
            model.step()
        assert ev.range.value <= 700
        assert model.environment.technology("EV_large").range.value <= 700

    def test_adoption_events_recorded(self, make_model):
        model = make_model(seed=6, households=N_AGENTS, subsidy_PV=60, subsidy_heat_pump=60)
        events = []
        model.event_bus.subscribe("*", events.append)
        for _ in range(5):
            model.step()
        adopted = [e for e in events if e.event_type.startswith("adopted:")]
        assert all(e.timestamp is not None for e in adopted)
        assert len(model.environment.communications) == len(adopted)


class TestPolicyEffects:

    def test_tenants_policy_increases_pv(self, make_model):
        no = _run(make_model, 10, 10, tenants_can_install=False)
        yes = _run(make_model, 10, 10, tenants_can_install=True)
        assert yes.count(PV) >= no.count(PV)

    def test_subsidy_increases_or_maintains_adoption(self, make_model):
        no = _run(make_model, 20, 10, subsidy_PV=0)
        sub = _run(make_model, 20, 10, subsidy_PV=30)
        assert sub.count(PV) >= no.count(PV)

    def test_same_seed_same_run(self, make_model):
        """The whole run, network included, is determined by the seed."""
        a = make_model(seed=99, households=N_AGENTS).run_simulation(5)
        b = make_model(seed=99, households=N_AGENTS).run_simulation(5)
        assert a["simulation_data"] == b["simulation_data"]

    def test_summary_keys_present(self, make_model):
        s = _run(make_model, 77, 3).summary()
        for key in ("year", "PV", "EV", "HP", "HB",
                    "co_PV_EV_HP", "co_PV_EV", "co_PV_HP", "co_EV_HP"):
            assert key in s

    def test_run_simulation_reports_every_year(self, make_model):
        model = make_model(seed=0, households=N_AGENTS)
        rows = model.run_simulation(5)["simulation_data"]
        assert [r["year"] for r in rows] == list(range(2022, 2028))

    def test_extreme_scenario_fixes_prices(self, make_model):
        model = make_model(seed=0, households=N_AGENTS, extreme_scenario_testing=True,
                           extreme_scenario_prices="low", extreme_scenario_EV_range=650)
        model.run_simulation(3)
        env = model.environment
        assert env.technology(PV).net_price == 5000.0
        assert env.technology("EV_medium").range.value == 650
        assert Config().extreme_scenario_testing is False   # config not mutated


def test_available_options_need_only_the_household(baseline_model):
    model = baseline_model
    for h in model.households:
        options = model.environment.get_available_options(h.agent_id, {'household': h})
        names = {tech.name for tech in options}
        assert ("PV" in names) == model.pv_eligible(h)
        assert ("HP" in names) == model.hp_eligible(h)


def test_per_agent_scheduler_runs(survey):
    from consumer_choice_metamodel import RandomActivationScheduler
    from coadoption import CoAdoptionModel

    model = CoAdoptionModel(survey, seed=1, scheduler=RandomActivationScheduler())
    model.initialize_model(Config(households=N_AGENTS))
    model.run_simulation(3)
    for family in (PV, EV, HP):
        assert model.count(family) == sum(h.owns(family) for h in model.households)
