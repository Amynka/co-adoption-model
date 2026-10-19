"""
Low-carbon technologies as metamodel physical assets, each with the
individual-level utility function used to evaluate it.

Utility terms are listed in the same order as in the original NetLogo model;
the coefficient names are survey columns holding each respondent's part-worths.
"""

from dataclasses import dataclass
from typing import TYPE_CHECKING, Any, Dict, List, Optional

from consumer_choice_metamodel import EvaluationDimension, PhysicalAsset

from .theories.choice import LinearUtility, UtilityTerm, constant
from .theories.social import adopter_share

if TYPE_CHECKING:
    from .environment import CoAdoptionEnvironment
    from .household import Household

FIN = EvaluationDimension.FINANCIAL
ENV = EvaluationDimension.ENVIRONMENTAL
SOC = EvaluationDimension.SOCIAL
PERF = EvaluationDimension.PERFORMANCE
OTHER = EvaluationDimension.CUSTOM      # intercept, emotions, co-ownership

# technology families (what a household owns) and their member technologies
PV, HP, EV = "PV", "HP", "EV"
CAR_SIZES = {"small": "Small car", "medium": "Medium car", "large": "Large car"}


@dataclass
class ChoiceSituation:
    """Everything a utility term may depend on when a household evaluates a technology"""
    household: 'Household'
    technology: 'Technology'
    environment: 'CoAdoptionEnvironment'
    adopters: int               # adopters of this family used for the peer effect
    population: int
    bundle_discount: float = 0.0


class Technology(PhysicalAsset):

    def __init__(self, name: str, family: str, list_price: Any, subsidy_percent: float,
                 ghg: Any, utility: LinearUtility,
                 threshold_owner: float, threshold_tenant: float):
        super().__init__(name)
        self.family = family
        self.list_price = list_price            # process with a .value (CHF)
        self.subsidy_percent = subsidy_percent
        self.ghg = ghg                          # process with a .value (life-cycle GHG)
        self.utility = utility
        self.threshold_owner = threshold_owner
        self.threshold_tenant = threshold_tenant
        self.fixed_net_price: Optional[float] = None   # extreme-scenario override
        self.net_price = self.list_price.value * (1 - self.subsidy_percent / 100)

    def update_net_price(self) -> None:
        """Called once per period after the exogenous processes have run"""
        if self.fixed_net_price is not None:
            self.net_price = self.fixed_net_price
        else:
            self.net_price = self.list_price.value * (1 - self.subsidy_percent / 100)

    def threshold(self, owner: bool) -> float:
        return self.threshold_owner if owner else self.threshold_tenant

    def get_availability(self) -> float:
        return 1.0

    def get_cost(self) -> float:
        return self.net_price

    def get_properties(self) -> Dict[str, Any]:
        return {'family': self.family, 'net_price': self.net_price,
                'list_price': self.list_price.value, 'ghg': self.ghg.value}


class ElectricVehicle(Technology):

    def __init__(self, name: str, size: str, savings: float, range_km: Any, **kwargs):
        super().__init__(name, EV, **kwargs)
        self.size = size
        self.car_size = CAR_SIZES[size]     # matching survey answer
        self.savings = savings              # CHF / 100 km
        self.range = range_km               # process with a .value (km)

    def get_properties(self) -> Dict[str, Any]:
        props = super().get_properties()
        props.update({'size': self.size, 'savings': self.savings, 'range': self.range.value})
        return props


def _price(s: ChoiceSituation) -> float:
    return s.technology.net_price / 1000 * (1 - s.bundle_discount)


def _ghg(s: ChoiceSituation) -> float:
    return s.technology.ghg.value


def _peers(s: ChoiceSituation) -> Optional[float]:
    if not s.environment.config.neighbourhood_effect:
        return None
    return adopter_share(s.adopters, s.population)


def _emotion(s: ChoiceSituation) -> float:
    return s.household.attributes.emotions[s.technology.family]


def _answer(column: str):
    return lambda s: s.household.respondent.number(column)


def _owns(family: str):
    return lambda s: 1.0 if s.household.owns(family) else None


def _perceptions(coefficient: str, level: str, names: List[tuple]) -> List[UtilityTerm]:
    """Perceived benefits / risks: coefficient name pattern, answer column pattern"""
    return [UtilityTerm(dim, coefficient.format(n), _answer(level.format(n)))
            for n, dim in names]


_BENEFITS_RISKS = [
    ("ben_savings", FIN), ("ben_independence", PERF), ("ben_environment", ENV),
    ("ben_collectiveAction", SOC), ("risks_highInvestCost", FIN),
    ("risks_lowReturnOnInvestment", FIN),
]


def pv_utility() -> LinearUtility:
    return LinearUtility([
        UtilityTerm(OTHER, "PVIntercept", constant),
        UtilityTerm(FIN, "PVInvCost", _price),
        UtilityTerm(FIN, "PVNetBill", lambda s: -1 * s.environment.pv_net_bill),
        UtilityTerm(ENV, "PVGHG", _ghg),
        UtilityTerm(PERF, "PVSelfsuff", lambda s: s.household.house.self_sufficiency),
        UtilityTerm(SOC, "PVPeers", _peers),
        *_perceptions("PVPROB{}.y", "PVPROB{}.x", _BENEFITS_RISKS),
        UtilityTerm(OTHER, "PVEmotion.y", _emotion),
        UtilityTerm(OTHER, "PVNegEmotionsCC", _answer("NegEmotionsCC")),
        UtilityTerm(OTHER, "PVPosEmotionsCC", _answer("PosEmotionsCC")),
        UtilityTerm(OTHER, "PVOWNelectriccar", _owns(EV)),
        UtilityTerm(OTHER, "PVOWNheatpump", _owns(HP)),
    ])


def hp_utility() -> LinearUtility:
    hp_benefits_risks = [b for b in _BENEFITS_RISKS if b[0] != "ben_independence"]
    return LinearUtility([
        UtilityTerm(OTHER, "HPIntercept", constant),
        UtilityTerm(FIN, "HPInvCost", _price),
        UtilityTerm(FIN, "HPSavings", lambda s: s.environment.hp_savings / 1000),
        UtilityTerm(ENV, "HPGHG", _ghg),
        UtilityTerm(SOC, "HPPeers", _peers),
        *_perceptions("HPPROB{}.y", "HPPROB{}.x", hp_benefits_risks),
        UtilityTerm(OTHER, "HPEmotion.y", _emotion),
        UtilityTerm(OTHER, "HPNegEmotionsCC", _answer("NegEmotionsCC")),
        UtilityTerm(OTHER, "HPPosEmotionsCC", _answer("PosEmotionsCC")),
        UtilityTerm(OTHER, "HPOWNelectriccar", _owns(EV)),
        UtilityTerm(OTHER, "HPOWNsolarpanels", _owns(PV)),
    ])


def ev_utility(size: str) -> LinearUtility:
    p = size[0]     # coefficient prefix: s / m / l
    return LinearUtility([
        UtilityTerm(OTHER, f"{p}EVIntercept", constant),
        UtilityTerm(FIN, f"{p}EVInvCost", _price),
        UtilityTerm(FIN, f"{p}EVSavings", lambda s: s.technology.savings),
        UtilityTerm(ENV, f"{p}EVGHG", _ghg),
        UtilityTerm(PERF, f"{p}EVRange", lambda s: s.technology.range.value / 100),
        UtilityTerm(SOC, f"{p}EVPeers", _peers),
        *_perceptions(p + "EVPROB{}", "EVPROB{}", _BENEFITS_RISKS),
        UtilityTerm(OTHER, f"{p}EVEmotion", _emotion),
        UtilityTerm(OTHER, f"{p}EVNegEmotionsCC", _answer("NegEmotionsCC")),
        UtilityTerm(OTHER, f"{p}EVPosEmotionsCC", _answer("PosEmotionsCC")),
        UtilityTerm(OTHER, f"{p}EVOWNsolarpanels", _owns(PV)),
        UtilityTerm(OTHER, f"{p}EVOWNheatpump", _owns(HP)),
    ])


EV_SAVINGS = {   # CHF / 100 km for small / medium / large
    "low": (3.3, 3.7, 4.1),
    "medium": (5.3, 7.1, 10.5),
    "high": (8.4, 10.5, 12.6),
}
EV_SPECS = {     # list price, learning rate, price floor, initial range, threshold
    "small": (18000.0, 0.15, 8000.0, 200.0, 0.45),
    "medium": (44000.0, 0.15, 29000.0, 350.0, 0.40),
    "large": (100000.0, 0.15, 80000.0, 500.0, 0.95),
}

# extreme-scenario fixed net prices
EXTREME_PRICES = {
    "low": {"PV": 5000.0, "EV_small": 8000.0, "EV_medium": 29000.0,
            "EV_large": 80000.0, "HP": 5000.0},
    "high": {"PV": 15000.0, "EV_small": 18000.0, "EV_medium": 44000.0,
             "EV_large": 100000.0, "HP": 15000.0},
}
EXTREME_GHG = {"low": {PV: 40.0, EV: 60.0, HP: 30.0},
               "high": {PV: 80.0, EV: 80.0, HP: 50.0}}
EXTREME_SAVINGS = {    # PV net bill, HP savings, EV savings small / medium / large
    "low": (-483.5, 2200.0, (3.3, 3.7, 4.1)),
    "high": (90.0, 2800.0, (8.4, 10.5, 12.5)),
}
