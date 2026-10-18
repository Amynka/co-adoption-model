"""
Builds households, technologies and campaigns from the survey and Config.
"""

from typing import Any, Dict, List

from consumer_choice_metamodel import KnowledgeAsset, ModelComponentFactory, Transformer

from .config import Config
from .environment import START_YEAR, InformationCampaign
from .household import House, HouseholdAttributes, HouseholdChoiceModule
from .survey import UNKNOWN_YEAR, Respondent
from .technologies import (
    EV, EV_SAVINGS, EV_SPECS, EXTREME_GHG, EXTREME_PRICES, EXTREME_SAVINGS, HP, PV,
    ElectricVehicle, Technology, ev_utility, hp_utility, pv_utility,
)
from .theories.learning import ExperienceCurve, FixedValue, LinearTrend
from .theories.lifecycle import DurableGood

CAR_REPLACEMENT_YEARS = {
    "every 12 years or when needed": 12,
    "every 8 years": 8,
    "every 4 years": 4,
    "every year": 1,
}

# year of last heating renovation -> age of the current (non-heat-pump) system
_HEATING_AGE = {
    "2019 or later": lambda rng, lifetime: rng.randint(0, 1) + 1,
    "2010-2019": lambda rng, lifetime: rng.randint(0, 9) + 3,
    "1990-1999": lambda rng, lifetime: rng.randint(0, 9) + 13,
}


def _low_or_high(choice: str) -> str:
    """Extreme-scenario chooser value: "low" selects low, every other value selects high"""
    return "low" if choice == "low" else "high"


def _safe_int(v: Any) -> int:
    try:
        return int(float(str(v).strip()))
    except (ValueError, TypeError):
        return 0


class SurveyHouseholdFactory(ModelComponentFactory):
    """Creates the model components of one simulation run.

    Set factory.rng to the model's generator; it is used for every random draw
    made while creating households (car replacement times, ages of equipment
    whose purchase year the respondent did not remember).
    """

    def __init__(self, config: Config, car_purchase_frequencies: List[Any]):
        self.config = config
        self.car_purchase_frequencies = car_purchase_frequencies
        self.lifetime = 25 if config.replacement_time else 1   # heating, thermal solar

    def create_agent_attributes(self, config: Dict[str, Any]) -> HouseholdAttributes:
        """config: {'agent_id', 'id_number', 'respondent'}"""
        cfg = self.config
        r: Respondent = config['respondent']

        house = House(thermal_solar=DurableGood(self.lifetime),
                      other_heating=DurableGood(self.lifetime),
                      self_sufficiency=cfg.PV_self_sufficiency_potential_global)
        a = HouseholdAttributes(agent_id=config['agent_id'], respondent=r, house=house,
                                id_number=config['id_number'])

        a.owner = (r.value("Owners") == 1)
        house.region = r.text("AreaType")
        house.historic = (r.text("HistoricalBuilding") == "Yes")
        house.direct_light = (r.text("ROOFsunlight") == "Yes")
        house.private_parking = (r.text("PrivateParking") == "Yes")

        # cars
        a.car = (r.value("OWNconventionalcar") == 1 or r.value("OWNhybridcar") == 1
                 or r.value("OWNelectriccar") == 1 or r.text("FutureNOcar") == "YES")
        a.car_size = r.text("CarSize")
        a.car_replacement_time = self._car_replacement_time(r.text("CarPurchaseFrequency"))
        if not cfg.replacement_time:
            a.car_replacement_time = 1
        a.ice = DurableGood(a.car_replacement_time)
        a.hev = DurableGood(a.car_replacement_time)
        main_car = r.text("VoiturePrincipale")
        if r.value("OWNconventionalcar") == 1 and main_car == "ConventionalCAR":
            a.ice.owned = True
            a.ice.age = self._age(r.text("WhenConventionalCar"), a.car_replacement_time)
        if r.value("OWNhybridcar") == 1 and main_car == "HEV":
            a.hev.owned = True
            a.hev.age = self._age(r.text("WhenHeV"), a.car_replacement_time)
        if r.value("OWNelectriccar") == 1 and main_car == "EV":
            a.has_ev = True
            a.opinions[EV] = self._initial_opinion(r, "EVWoMowners")

        # PV, thermal solar, heat pump, other heating, battery
        if r.value("OWNsolarsystem") == 1:
            house.pv = True
            a.opinions[PV] = self._initial_opinion(r, "PVWoMowners")
        if r.value("OWNthermal") == 1:
            house.thermal_solar.owned = True
            house.other_heating.owned = False
            house.thermal_solar.age = self._age(r.text("WhenThermique"), self.lifetime)
        if r.value("OWNheatpump") == 1:
            house.heat_pump = True
            house.other_heating.owned = False
            a.opinions[HP] = self._initial_opinion(r, "HPWoMowners")
        if not house.thermal_solar.owned and not house.heat_pump:
            house.other_heating.owned = True
            house.other_heating.age = self._heating_age(r.text("HPrenovation"))
        if r.value("OWNstoragebattery") == 1 or r.text("BatteryOWNERS_r1") == "Yes":
            house.battery = True
            house.self_sufficiency = min(1.0, cfg.PV_self_sufficiency_potential_global + 0.4)

        # emotions; heat pumps use the PV emotion column
        a.emotions = {PV: r.number("PVEmotion.x"), EV: r.number("EVEmotion"),
                      HP: r.number("PVEmotion.x")}
        return a

    def create_choice_module(self, agent_id: str, attributes: HouseholdAttributes,
                             config: Dict[str, Any]) -> HouseholdChoiceModule:
        return HouseholdChoiceModule(agent_id, attributes)

    def create_transformer(self, config: Dict[str, Any]) -> Transformer:
        return Transformer([], [])

    def _car_replacement_time(self, answer: str) -> int:
        if answer in CAR_REPLACEMENT_YEARS:
            return CAR_REPLACEMENT_YEARS[answer]
        pool = self.car_purchase_frequencies
        candidate = self.rng.choice(pool) if pool else "every 8 years"
        return CAR_REPLACEMENT_YEARS.get(str(candidate), 8)

    def _age(self, purchase_year: str, lifetime: int) -> int:
        if purchase_year == UNKNOWN_YEAR:
            return self.rng.randint(0, lifetime)
        return max(0, START_YEAR - _safe_int(purchase_year))

    def _heating_age(self, renovation: str) -> int:
        draw = _HEATING_AGE.get(renovation, lambda rng, lifetime: rng.randint(0, lifetime))
        return draw(self.rng, self.lifetime)

    def _initial_opinion(self, r: Respondent, column: str) -> str:
        if self.config.extreme_scenario_testing:
            return self.config.extreme_scenarios_opinions
        return r.text(column)

    def create_physical_asset(self, asset_config: Dict[str, Any]) -> Technology:
        """asset_config: {'name': 'PV' | 'HP' | 'EV_small' | 'EV_medium' | 'EV_large',
        'ghg': shared emissions process of its family}"""
        cfg = self.config
        name, ghg = asset_config['name'], asset_config['ghg']
        if name == PV:
            tech = Technology(PV, PV, ExperienceCurve("price_PV", 15000.0, 0.04, 5000.0, [PV]),
                              cfg.subsidy_PV, ghg, pv_utility(), 0.5, 0.45)
        elif name == HP:
            tech = Technology(HP, HP, ExperienceCurve("price_HP", 15800.0, 0.04, 5000.0, [HP]),
                              cfg.subsidy_heat_pump, ghg, hp_utility(), 0.5, 0.45)
        else:
            size = name.split("_", 1)[1]
            price, rate, floor, range_km, threshold = EV_SPECS[size]
            savings = dict(zip(("small", "medium", "large"), self._ev_savings()))[size]
            if cfg.extreme_scenario_testing:
                ev_range = FixedValue(f"range_{name}", range_km, cfg.extreme_scenario_EV_range, [name])
            else:
                ev_range = LinearTrend(f"range_{name}", range_km, cfg.range_EV_increase,
                                       cfg.range_EV_max, [name])
            tech = ElectricVehicle(name, size, savings, ev_range,
                                   list_price=ExperienceCurve(f"price_{name}", price, rate, floor, [name]),
                                   subsidy_percent=cfg.subsidy_EV, ghg=ghg,
                                   utility=ev_utility(size),
                                   threshold_owner=threshold, threshold_tenant=threshold)
        if cfg.extreme_scenario_testing:
            tech.fixed_net_price = EXTREME_PRICES[_low_or_high(cfg.extreme_scenario_prices)][name]
        return tech

    def create_ghg_curves(self) -> Dict[str, ExperienceCurve]:
        """Life-cycle emissions per family (shared by the EV sizes)"""
        cfg = self.config
        specs = {   # initial, floor, learning rate
            PV: (80.0, 40.0, cfg.learning_rate_life_cycle_ghg_PV),
            EV: (80.0, 60.0, cfg.learning_rate_life_cycle_ghg_EV),
            HP: (50.0, 30.0, cfg.learning_rate_life_cycle_ghg_heat_pump),
        }
        extreme = (EXTREME_GHG[_low_or_high(cfg.extreme_scenario_GHG)]
                   if cfg.extreme_scenario_testing else {})
        return {family: ExperienceCurve(f"ghg_{family}", initial, rate, floor, [family],
                                        reset_to=extreme.get(family))
                for family, (initial, floor, rate) in specs.items()}

    def _ev_savings(self):
        cfg = self.config
        if cfg.extreme_scenario_testing:
            return EXTREME_SAVINGS[_low_or_high(cfg.extreme_scenario_savings)][2]
        return EV_SAVINGS.get(cfg.savings_EV, EV_SAVINGS["medium"])

    def economics(self):
        """(PV net bill after adoption, heat pump savings) in CHF / year"""
        cfg = self.config
        if cfg.extreme_scenario_testing:
            bill, hp_savings, _ = EXTREME_SAVINGS[_low_or_high(cfg.extreme_scenario_savings)]
            return bill, hp_savings
        return cfg.PV_net_bill_after_adoption, cfg.savings_heat_pump

    def create_knowledge_asset(self, knowledge_config: Dict[str, Any]) -> KnowledgeAsset:
        """knowledge_config: {'topic': 'PV' | 'EV' | 'HP', 'year': int}"""
        return InformationCampaign(knowledge_config['topic'], knowledge_config['year'])

    def campaign_years(self) -> Dict[str, int]:
        cfg = self.config
        if cfg.extreme_scenario_testing:
            year = START_YEAR if cfg.extreme_scenario_information_campaign else 2051
            return {PV: year, EV: year, HP: year}
        return {PV: cfg.information_campaign_PV_year, EV: cfg.information_campaign_EV_year,
                HP: cfg.information_campaign_heat_pump_year}
