"""
Co-adoption of PV, EVs and heat pumps by Swiss households, built on the
consumer_choice_metamodel framework.

Model of van der Kam, Lagomarsino, Azar, Hahnel & Parra (2024), Cell Reports
Sustainability 1, 100268. The default schedule reproduces the order of the
original NetLogo model v1.1 step by step.
"""

import random
from dataclasses import asdict
from typing import Any, Dict, List, Optional, Union

import pandas as pd

from consumer_choice_metamodel import (
    ConsumerChoiceModel, EventBus, ModelEvent, Phase, PhasedScheduler, Scheduler,
)

from .config import Config
from .environment import START_YEAR, CoAdoptionEnvironment
from .factory import SurveyHouseholdFactory
from .household import Household
from .survey import SurveyData
from .technologies import CAR_SIZES, EV, HP, PV, ChoiceSituation, ElectricVehicle, Technology
from .theories.network import SpatialKNNNetwork
from .theories.social import WordOfMouth

TECHNOLOGY_NAMES = (PV, HP, "EV_small", "EV_medium", "EV_large")
BATTERY = "battery"

# summary keys for each combination of owned technologies (PV, EV, HP)
CO_ADOPTION_KEYS = {
    (True, True, True): "co_PV_EV_HP",
    (True, True, False): "co_PV_EV",
    (True, False, True): "co_PV_HP",
    (False, True, True): "co_EV_HP",
    (True, False, False): "co_PV_only",
    (False, True, False): "co_EV_only",
    (False, False, True): "co_HP_only",
}


class CoAdoptionModel(ConsumerChoiceModel):
    """
    Usage:
        survey = SurveyData.load("data/surveyData.csv")
        model = CoAdoptionModel(survey, seed=42)
        model.initialize_model(Config(households=300))
        results = model.run_simulation(model.config.stop_after_x_years)

    All random draws come from model.rng, except household placement in the
    social network, which uses model.network_rng so that the network geometry
    does not shift the population's random sequence.
    """

    def __init__(self, survey: SurveyData, seed: Optional[int] = None,
                 scheduler: Optional[Scheduler] = None):
        super().__init__(seed=seed, scheduler=scheduler)
        if scheduler is None:
            self.scheduler = self.netlogo_schedule()
        self.survey = survey
        self.config: Optional[Config] = None
        self.factory: Optional[SurveyHouseholdFactory] = None
        self.environment: Optional[CoAdoptionEnvironment] = None
        self.households: List[Household] = self.agents
        self.households_by_id: Dict[str, Household] = {}
        self.network_rng = self._network_rng(seed)
        self.setup_complete = False
        self.adopters = {PV: 0, EV: 0, HP: 0}        # live counts
        self.counts = dict(self.adopters)            # snapshot used within a phase
        self.adoptions: Dict[str, List[int]] = {PV: [], EV: [], HP: [], BATTERY: []}
        self.co_adoption = {key: 0 for key in CO_ADOPTION_KEYS.values()}

    @staticmethod
    def _network_rng(seed: Optional[int]) -> random.Random:
        return random.Random(f"{seed}:network") if seed is not None else random.Random()

    def reseed(self, seed: Optional[int]) -> None:
        super().reseed(seed)
        self.network_rng = self._network_rng(seed)

    def initialize_model(self, parameters: Union[Config, Dict[str, Any]]) -> None:
        """parameters: a Config, or a dict of Config field overrides"""
        cfg = parameters if isinstance(parameters, Config) else Config(**parameters)
        self.config = cfg
        self.model_parameters = asdict(cfg)
        self.factory = SurveyHouseholdFactory(cfg, self.survey.car_purchase_frequencies)
        self.factory.rng = self.rng

        self.environment = self.create_environment({})
        self.add_agents(self.create_agents(cfg.households, {}))
        for h in self.households:
            self.environment.network.add_agent(h.agent_id, {'region': h.house.region})

        self.adopters = {family: sum(h.owns(family) for h in self.households)
                         for family in (PV, EV, HP)}
        self.snapshot_counts()
        self._subscribe_spillovers()
        self.setup_complete = True
        self.update_co_adoption()

    def create_environment(self, environment_config: Dict[str, Any]) -> CoAdoptionEnvironment:
        cfg, f = self.config, self.factory
        pv_net_bill, hp_savings = f.economics()
        env = CoAdoptionEnvironment(cfg, pv_net_bill, hp_savings)

        ghg = f.create_ghg_curves()
        for name in TECHNOLOGY_NAMES:
            tech = f.create_physical_asset({'name': name, 'ghg': ghg[name.split("_")[0]]})
            env.add_physical_asset(tech)
            if not cfg.extreme_scenario_testing:     # extreme scenarios fix net prices
                env.exogenous_processes.append(tech.list_price)
            if isinstance(tech, ElectricVehicle):
                env.exogenous_processes.append(tech.range)
        env.exogenous_processes.extend(ghg.values())

        for topic, year in f.campaign_years().items():
            env.add_knowledge_asset(f.create_knowledge_asset({'topic': topic, 'year': year}))

        network = SpatialKNNNetwork(cfg.number_of_neighbours, self.network_rng)
        env.networks.append(network)
        env.rules.append(WordOfMouth(network, self._contacts))
        return env

    def select_respondents(self, n: int) -> pd.DataFrame:
        """Survey rows of the simulated households (override to control sampling)"""
        rows = self.rng.sample(range(len(self.survey)), n)
        return self.survey.frame.iloc[rows].reset_index(drop=True)

    def create_agents(self, agent_count: int, agent_config: Dict[str, Any]) -> List[Household]:
        rows = self.select_respondents(min(agent_count, len(self.survey)))
        households = []
        for index, respondent in enumerate(self.survey.respondents(rows)):
            raw_id = respondent.raw("respondentID")
            id_number = int(raw_id) if str(raw_id).isdigit() else index
            agent_id = str(id_number)
            if agent_id in self.households_by_id:
                agent_id = f"{id_number}#{index}"
            attributes = self.factory.create_agent_attributes(
                {'agent_id': agent_id, 'id_number': id_number, 'respondent': respondent})
            household = Household(attributes, self)
            household.update_meet_and_discuss(self.config)
            self.households_by_id[agent_id] = household
            households.append(household)
        return households

    def netlogo_schedule(self) -> PhasedScheduler:
        """One year in the order of the NetLogo `go` procedure; households are
        shuffled once per year and keep that order in every phase"""
        snapshot = Phase("snapshot adopter counts", lambda m: m.snapshot_counts(), per_agent=False)
        phases = [
            Phase("age durable goods", lambda h, m: h.age_durable_goods()),
            Phase("information campaigns",
                  lambda h, m: h.receive_information(h.perceive_environment(m.environment))),
            Phase("social interaction", lambda h, m: h.update_meet_and_discuss(m.config)),
            snapshot,
            Phase("bundle PV+EV+HP", lambda h, m: m.consider_bundle_pv_ev_hp(h)),
            Phase("bundle PV+EV", lambda h, m: m.consider_bundle_pv_ev(h)),
            Phase("bundle EV+HP", lambda h, m: m.consider_bundle_ev_hp(h)),
            snapshot,
            Phase("PV", lambda h, m: m.consider_pv(h)),
            snapshot,
            Phase("heat pump", lambda h, m: m.consider_heat_pump(h)),
            Phase("replace other heating", lambda h, m: h.replace_heating_if_missing()),
        ]
        for car_size in CAR_SIZES.values():
            phases.append(Phase(f"EV ({car_size})",
                                lambda h, m, size=car_size: m.consider_ev(h, size)))
        return PhasedScheduler(phases)

    def step(self) -> None:
        self.adoptions = {key: [] for key in self.adoptions}
        super().step()
        self.update_co_adoption()

    def decide_alone(self, h: Household) -> List[Dict[str, Any]]:
        """All of one household's yearly decisions at once (for per-agent schedulers)"""
        before = {family: h.owns(family) for family in (PV, EV, HP)}
        self.snapshot_counts()
        self.consider_bundle_pv_ev_hp(h)
        self.consider_bundle_pv_ev(h)
        self.consider_bundle_ev_hp(h)
        self.snapshot_counts()
        self.consider_pv(h)
        self.snapshot_counts()
        self.consider_heat_pump(h)
        h.replace_heating_if_missing()
        for car_size in CAR_SIZES.values():
            self.consider_ev(h, car_size)
        return [{'action': 'adopt', 'technology': family, 'agent_id': h.agent_id}
                for family, owned in before.items() if h.owns(family) and not owned]

    def snapshot_counts(self, *families: str) -> None:
        """Refresh the adopter counts seen by peer effects (all families by default)"""
        for family in families or self.adopters:
            self.counts[family] = self.adopters[family]

    def may_install(self, h: Household) -> bool:
        return h.attributes.owner or self.config.tenants_can_install

    def roof_available(self, h: Household) -> bool:
        house = h.house
        return ((not house.historic or self.config.historic_houses_can_install_PV)
                and house.direct_light and not house.pv and not house.thermal_solar.owned)

    def pv_eligible(self, h: Household) -> bool:
        return self.may_install(h) and self.roof_available(h)

    def hp_eligible(self, h: Household) -> bool:
        house = h.house
        return (self.may_install(h) and not house.other_heating.owned
                and not house.thermal_solar.owned and not house.heat_pump)

    def situation(self, h: Household, tech: Technology, adopters: int,
                  bundle_discount: float = 0.0) -> ChoiceSituation:
        return ChoiceSituation(h, tech, self.environment, adopters,
                               len(self.households), bundle_discount)

    def accepts(self, h: Household, tech: Optional[Technology], adopters: int,
                bundle_discount: float = 0.0) -> bool:
        if tech is None:
            return False
        return h.choice_module.accepts(tech, self.situation(h, tech, adopters, bundle_discount))

    def _bundle_discount(self) -> float:
        return self.config.bundle_bonus / 100

    def _ev(self, h: Household) -> Optional[ElectricVehicle]:
        return self.environment.ev_for(h.attributes.car_size)

    def consider_bundle_pv_ev_hp(self, h: Household) -> None:
        if self.config.bundle_bonus <= 0:
            return
        d, c, tech = self._bundle_discount(), self.counts, self.environment.technology
        if (self.pv_eligible(h) and self.hp_eligible(h) and h.needs_car()
                and self.accepts(h, tech(PV), c[PV], d)
                and self.accepts(h, tech(HP), c[HP], d)
                and self.accepts(h, self._ev(h), c[EV], d)):
            self.adopt(h, PV)
            self.adopt(h, EV)
            self.adopt(h, HP)
            self.snapshot_counts()

    def consider_bundle_pv_ev(self, h: Household) -> None:
        if self.config.bundle_bonus <= 0:
            return
        d, c, tech = self._bundle_discount(), self.counts, self.environment.technology
        if (self.pv_eligible(h) and h.needs_car()
                and self.accepts(h, tech(PV), c[PV], d)
                and self.accepts(h, self._ev(h), c[EV], d)):
            self.adopt(h, PV)
            self.adopt(h, EV)
            # refreshes the EV and PV counts only, as in NetLogo
            self.snapshot_counts(EV, PV)

    def consider_bundle_ev_hp(self, h: Household) -> None:
        if self.config.bundle_bonus <= 0:
            return
        d, c, tech = self._bundle_discount(), self.counts, self.environment.technology
        if (h.needs_car() and self.hp_eligible(h)
                and self.accepts(h, tech(HP), c[HP], d)
                and self.accepts(h, self._ev(h), c[EV], d)):
            self.adopt(h, EV)
            self.adopt(h, HP)
            self.snapshot_counts(EV, HP)

    def consider_pv(self, h: Household) -> None:
        """Peer effect uses the count from the start of the phase"""
        if self.pv_eligible(h) and self.accepts(h, self.environment.technology(PV), self.counts[PV]):
            self.adopt(h, PV)

    def consider_heat_pump(self, h: Household) -> None:
        """Peer effect uses the count from the start of the phase"""
        if self.hp_eligible(h) and self.accepts(h, self.environment.technology(HP), self.counts[HP]):
            self.adopt(h, HP)

    def consider_ev(self, h: Household, car_size: str) -> None:
        """Replacement decision for a retired car: an EV, or else a new combustion car"""
        if not (h.needs_car() and h.attributes.car_size == car_size):
            return
        if self.accepts(h, self.environment.ev_for(car_size), self.adopters[EV]):
            self.adopt(h, EV)
        else:
            h.attributes.ice.install()

    def adopt(self, h: Household, family: str) -> None:
        """Install a technology, draw the adopter's opinion of it and announce it"""
        if h.owns(family):
            return
        h.install(family)
        self.adopters[family] += 1
        pool = self.survey.opinions[family]
        h.attributes.opinions[family] = self.rng.choice(pool) if pool else "NeutralFeedback"
        self.publish(f"adopted:{family}", h.agent_id, {'household': h, 'technology': family})

    def adopt_battery(self, h: Household) -> None:
        if h.house.battery:
            return
        h.install_battery(self.config.PV_self_sufficiency_potential_global)
        self.publish(f"adopted:{BATTERY}", h.agent_id, {'household': h, 'technology': BATTERY})

    def _subscribe_spillovers(self) -> None:
        """Handlers run in this order: word of mouth, co-adoption, adoption record"""
        bus = self.event_bus
        if self.config.word_of_mouth:
            for family in (PV, EV, HP):
                bus.subscribe(f"adopted:{family}", self._word_of_mouth)
        bus.subscribe(f"adopted:{PV}", self._battery_after_pv)
        bus.subscribe(f"adopted:{EV}", self._co_adoption_after_ev)
        bus.subscribe(f"adopted:{HP}", self._co_adoption_after_hp)
        bus.subscribe(EventBus.ALL_EVENTS, self._record_adoption)

    def _contacts(self, agent_id: str) -> int:
        h = self.households_by_id[agent_id]
        return round(h.attributes.meet_and_discuss * self.config.number_of_neighbours)

    def _word_of_mouth(self, event: ModelEvent) -> None:
        h, family = event.data['household'], event.data['technology']
        self.environment.word_of_mouth.spread(
            h.agent_id, h.attributes.opinions[family], self.rng,
            lambda listener_id, valence: self.households_by_id[listener_id].hear(family, valence))

    def _battery_after_pv(self, event: ModelEvent) -> None:
        h = event.data['household']
        if h.respondent.text("Battery_installation") == "Yes":
            self.adopt_battery(h)

    def _co_adoption_after_ev(self, event: ModelEvent) -> None:
        """Buying an EV prompts a fresh look at PV and a heat pump (live counts)"""
        if not self.setup_complete:
            return
        h, tech = event.data['household'], self.environment.technology
        live_hp = self.adopters[HP]
        if self.pv_eligible(h) and self.accepts(h, tech(PV), self.adopters[PV]):
            self.adopt(h, PV)
        if self.hp_eligible(h) and self.accepts(h, tech(HP), live_hp):
            self.adopt(h, HP)

    def _co_adoption_after_hp(self, event: ModelEvent) -> None:
        """Installing a heat pump prompts a fresh look at PV (live count).
        Checks the roof only, as in NetLogo."""
        if not self.setup_complete:
            return
        h = event.data['household']
        if self.roof_available(h) and self.accepts(h, self.environment.technology(PV),
                                                    self.adopters[PV]):
            self.adopt(h, PV)

    def _record_adoption(self, event: ModelEvent) -> None:
        if not event.event_type.startswith("adopted:"):
            return
        family = event.data['technology']
        self.adoptions[family].append(event.data['household'].id_number)
        self.environment.add_communication({
            'agent_id': event.source, 'action': 'adopted',
            'technology': family, 'year': START_YEAR + self.current_time,
        })

    @property
    def year(self) -> int:
        return START_YEAR + self.current_time

    def count(self, family: str) -> int:
        if family == BATTERY:
            return sum(h.house.battery for h in self.households)
        return self.adopters[family]

    def update_co_adoption(self) -> None:
        counts = {key: 0 for key in CO_ADOPTION_KEYS.values()}
        for h in self.households:
            key = CO_ADOPTION_KEYS.get((h.owns(PV), h.owns(EV), h.owns(HP)))
            if key is not None:
                counts[key] += 1
        self.co_adoption = counts

    def summary(self) -> Dict[str, Any]:
        tech = self.environment.technology
        return {
            "year": self.year,
            "tick": self.current_time,
            "PV": self.count(PV),
            "EV": self.count(EV),
            "HP": self.count(HP),
            "HB": self.count(BATTERY),
            **self.co_adoption,
            "price_net_PV": round(tech(PV).net_price, 0),
            "price_net_EV_small": round(tech("EV_small").net_price, 0),
            "price_net_EV_medium": round(tech("EV_medium").net_price, 0),
            "price_net_HP": round(tech(HP).net_price, 0),
            "ghg_PV": round(tech(PV).ghg.value, 2),
            "ghg_EV": round(tech("EV_small").ghg.value, 2),
            "ghg_HP": round(tech(HP).ghg.value, 2),
        }

    def collect_data(self) -> Dict[str, Any]:
        return self.summary()
