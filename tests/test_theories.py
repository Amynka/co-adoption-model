"""
Unit tests for the reusable theories in coadoption.theories.
"""

import math
import random

import pytest

from consumer_choice_metamodel import EvaluationDimension as D

from coadoption.theories import (
    DurableGood, ExperienceCurve, FixedValue, LinearTrend, LinearUtility,
    SpatialKNNNetwork, UtilityTerm, WordOfMouth, Zone, adopter_share, clamp,
    constant, logistic,
)


class TestChoice:

    def _utility(self):
        return LinearUtility([
            UtilityTerm(D.CUSTOM, "asc", constant),
            UtilityTerm(D.FINANCIAL, "price", lambda s: s["price"]),
            UtilityTerm(D.SOCIAL, "owns", lambda s: 1.0 if s["owns"] else None),
        ])

    def test_linear_utility(self):
        beta = {"asc": 1.0, "price": -0.5, "owns": 2.0}.__getitem__
        u = self._utility()
        assert u.utility(beta, {"price": 4.0, "owns": False}) == pytest.approx(-1.0)
        assert u.utility(beta, {"price": 4.0, "owns": True}) == pytest.approx(1.0)

    def test_absent_term_ignores_missing_coefficient(self):
        beta = {"asc": 0.0, "price": 0.0, "owns": float("nan")}.__getitem__
        assert self._utility().utility(beta, {"price": 1.0, "owns": False}) == 0.0

    def test_by_dimension(self):
        beta = {"asc": 1.0, "price": -0.5, "owns": 2.0}.__getitem__
        dims = self._utility().by_dimension(beta, {"price": 2.0, "owns": True})
        assert dims == {D.CUSTOM: 1.0, D.FINANCIAL: -1.0, D.SOCIAL: 2.0}

    def test_logistic(self):
        assert logistic(0.0) == 0.5
        assert logistic(-10_000) == 0.0
        assert logistic(10_000) == 1.0
        assert logistic(1.0) == pytest.approx(1 / (1 + math.e ** -1))


class TestLearning:

    def test_experience_curve_has_floor(self):
        curve = ExperienceCurve("price", 100.0, 0.5, 30.0)
        values = [curve.update(t, {})["price"] for t in range(3)]
        assert values == [50.0, 30.0, 30.0]

    def test_experience_curve_reset(self):
        curve = ExperienceCurve("ghg", 80.0, 0.5, 10.0, reset_to=40.0)
        curve.update(0, {})
        curve.update(1, {})
        assert curve.value == 20.0

    def test_linear_trend_cap(self):
        trend = LinearTrend("range", 650.0, 20.0, 700.0)
        assert [trend.update(t, {})["range"] for t in range(3)] == [670.0, 690.0, 700.0]

    def test_fixed_value(self):
        fixed = FixedValue("range", 200.0, 700.0, assets=["EV"])
        assert fixed.value == 200.0
        fixed.update(0, {})
        assert fixed.value == 700.0
        assert fixed.affects_assets() == ["EV"]


class TestLifecycle:

    def test_durable_good_retires(self):
        car = DurableGood(lifetime=2)
        car.install()
        assert car.age_one_period() is False
        assert car.age_one_period() is True
        assert not car.owned
        assert car.age_one_period() is False   # nothing to age


class TestSocial:

    def test_helpers(self):
        assert adopter_share(5, 20) == 0.25
        assert clamp(1.3) == 1.0 and clamp(-0.1) == 0.0

    def test_word_of_mouth(self):
        network = SpatialKNNNetwork(k=3, rng=random.Random(0), zones={"any": Zone()})
        for i in range(10):
            network.add_agent(str(i), {"region": "any"})
        wom = WordOfMouth(network, contacts=lambda agent_id: 2)
        heard = []
        listeners = wom.spread("0", "MixedFeedback", random.Random(1),
                               lambda listener, valence: heard.append((listener, valence)))
        assert len(listeners) == 2
        assert set(listeners) <= set(network.get_neighbors("0"))
        assert [v for _, v in heard] == ["positive", "positive", "negative", "negative"]

    def test_neutral_opinion_draws_but_changes_nothing(self):
        network = SpatialKNNNetwork(k=3, rng=random.Random(0), zones={"any": Zone()})
        for i in range(5):
            network.add_agent(str(i), {"region": "any"})
        wom = WordOfMouth(network, contacts=lambda agent_id: 2)
        heard = []
        assert len(wom.spread("0", "NeutralFeedback", random.Random(1),
                              lambda *a: heard.append(a))) == 2
        assert heard == []


class TestNetwork:

    def test_zones_respected(self):
        network = SpatialKNNNetwork(k=5, rng=random.Random(3))
        for i, region in enumerate(["urban", "suburban", "rural"] * 10):
            network.add_agent(f"{region}{i}", {"region": region})
        for agent_id, (x, y) in network.positions.items():
            d = math.hypot(x, y)
            if agent_id.startswith("urban"):
                assert d <= 18
            elif agent_id.startswith("suburban"):
                assert 18 < d <= 31
            else:
                assert d > 31

    def test_toroidal_distance(self):
        network = SpatialKNNNetwork(k=1, rng=random.Random(0))
        assert network.distance((-37.0, 0.0), (37.0, 0.0)) == pytest.approx(2.0)

    def test_neighbours_rebuilt_after_removal(self):
        network = SpatialKNNNetwork(k=2, rng=random.Random(0), zones={"any": Zone()})
        for i in range(4):
            network.add_agent(str(i), {"region": "any"})
        assert len(network.get_neighbors("0")) == 2
        network.remove_agent("3")
        assert "3" not in network.get_neighbors("0")
