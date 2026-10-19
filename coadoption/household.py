"""
Household agents: a survey respondent and their house.
"""

from dataclasses import dataclass, field
from typing import TYPE_CHECKING, Any, Dict, List, Optional, Union

from consumer_choice_metamodel import (
    AgentAttributes, ChoiceModule, ConsumerAgent, EvaluationDimension, Transformer,
)

from .survey import WOM_COLUMNS, Respondent
from .technologies import EV, HP, PV, ChoiceSituation, Technology
from .theories.choice import logistic
from .theories.lifecycle import DurableGood
from .theories.social import clamp

if TYPE_CHECKING:
    from .environment import CoAdoptionEnvironment
    from .model import CoAdoptionModel

# perceived benefits and risks (0-1) and climate emotions reported in the survey
_PSYCHOLOGICAL_COLUMNS = [
    "PVPROBben_savings.x", "PVPROBben_independence.x", "PVPROBben_environment.x",
    "PVPROBben_collectiveAction.x", "PVPROBrisks_highInvestCost.x",
    "PVPROBrisks_lowReturnOnInvestment.x",
    "HPPROBben_savings.x", "HPPROBben_environment.x", "HPPROBben_collectiveAction.x",
    "HPPROBrisks_highInvestCost.x", "HPPROBrisks_lowReturnOnInvestment.x",
    "EVPROBben_savings", "EVPROBben_independence", "EVPROBben_environment",
    "EVPROBben_collectiveAction", "EVPROBrisks_highInvestCost",
    "EVPROBrisks_lowReturnOnInvestment",
    "NegEmotionsCC", "PosEmotionsCC",
]


@dataclass
class House:
    thermal_solar: DurableGood
    other_heating: DurableGood
    region: str = ""
    historic: bool = False
    direct_light: bool = False
    private_parking: bool = False
    pv: bool = False
    heat_pump: bool = False
    battery: bool = False
    self_sufficiency: float = 1.0       # PV self-sufficiency potential (0-1)


@dataclass
class HouseholdAttributes(AgentAttributes):
    respondent: Optional[Respondent] = None
    house: Optional[House] = None
    id_number: int = 0
    owner: bool = False
    car: bool = False
    car_size: str = ""
    car_replacement_time: int = 8
    ice: DurableGood = field(default_factory=lambda: DurableGood(8))
    hev: DurableGood = field(default_factory=lambda: DurableGood(8))
    has_ev: bool = False
    meet_and_discuss: float = 0.0       # share of neighbours talked to (0-1)
    opinions: Dict[str, str] = field(default_factory=lambda: {PV: "", EV: "", HP: ""})
    emotions: Dict[str, float] = field(default_factory=lambda: {PV: 0.0, EV: 0.0, HP: 0.0})

    def get_psychological_attributes(self) -> Dict[str, float]:
        attrs = {}
        for col in _PSYCHOLOGICAL_COLUMNS:
            value = self.respondent.number(col)
            if value == value:          # skip unanswered (NaN)
                attrs[col] = value
        attrs.update({f"emotion_{family}": value for family, value in self.emotions.items()})
        return attrs

    def get_socioeconomic_attributes(self) -> Dict[str, Union[int, float]]:
        return {
            'owner': int(self.owner),
            'neighbourhood_interaction': self.respondent.number("neighboordhood_r2"),
        }

    def get_stock_variables(self) -> Dict[str, Any]:
        return {
            'region': self.house.region, 'PV': self.house.pv,
            'heat_pump': self.house.heat_pump, 'EV': self.has_ev,
            'ICE': self.ice.owned, 'HEV': self.hev.owned,
            'thermal_solar': self.house.thermal_solar.owned,
            'other_heating': self.house.other_heating.owned,
            'home_battery': self.house.battery, 'car_size': self.car_size,
        }

    def update_attributes(self, changes: Dict[str, Any]) -> None:
        for key, value in changes.items():
            setattr(self, key, value)


class HouseholdChoiceModule(ChoiceModule):
    """Binary logit with the respondent's own part-worths and a threshold rule"""

    def __init__(self, agent_id: str, agent_attributes: HouseholdAttributes):
        super().__init__(agent_id, agent_attributes)
        self.coefficients = agent_attributes.respondent.number

    def utility(self, option: Technology, situation: ChoiceSituation) -> float:
        return option.utility.utility(self.coefficients, situation)

    def probability(self, option: Technology, situation: ChoiceSituation) -> float:
        return logistic(self.utility(option, situation))

    def accepts(self, option: Technology, situation: ChoiceSituation) -> bool:
        return self.probability(option, situation) >= option.threshold(self.agent_attributes.owner)

    def evaluate_option(self, option: Technology,
                        evaluation_context: Dict[str, Any]) -> Dict[EvaluationDimension, float]:
        """Utility split by dimension; evaluation_context['situation'] is a ChoiceSituation"""
        return option.utility.by_dimension(self.coefficients, evaluation_context['situation'])

    def aggregate_evaluations(self, evaluations: Dict[EvaluationDimension, float]) -> float:
        # equals utility() up to floating-point rounding; decisions use utility()
        return sum(evaluations.values())

    def make_choice(self, options: List[Technology],
                    choice_context: Dict[str, Any]) -> Optional[Technology]:
        """First acceptable option; choice_context['situation'](option) builds its situation"""
        for option in options:
            if self.accepts(option, choice_context['situation'](option)):
                return option
        return None


class Household(ConsumerAgent):

    def __init__(self, attributes: HouseholdAttributes, model: 'CoAdoptionModel'):
        super().__init__(attributes.agent_id, attributes,
                         HouseholdChoiceModule(attributes.agent_id, attributes),
                         Transformer([], []))
        self.model = model

    @property
    def house(self) -> House:
        return self.attributes.house

    @property
    def respondent(self) -> Respondent:
        return self.attributes.respondent

    @property
    def id_number(self) -> int:
        return self.attributes.id_number

    def owns(self, family: str) -> bool:
        if family == PV:
            return self.house.pv
        if family == HP:
            return self.house.heat_pump
        return self.attributes.has_ev

    def needs_car(self) -> bool:
        """Has a car slot whose ICE / HEV has been retired and no EV yet"""
        a = self.attributes
        return a.car and not a.ice.owned and not a.hev.owned and not a.has_ev

    def install(self, family: str) -> None:
        if family == PV:
            self.house.pv = True
        elif family == HP:
            self.house.heat_pump = True
            self.house.thermal_solar.owned = False
            self.house.other_heating.owned = False
            self.house.other_heating.age = 0
        else:
            self.attributes.has_ev = True

    def install_battery(self, self_sufficiency_global: float) -> None:
        self.house.battery = True
        self.house.self_sufficiency = min(1.0, self_sufficiency_global + 0.4)

    def age_durable_goods(self) -> None:
        self.house.thermal_solar.age_one_period()
        self.house.other_heating.age_one_period()
        self.attributes.ice.age_one_period()
        self.attributes.hev.age_one_period()

    def replace_heating_if_missing(self) -> None:
        h = self.house
        if not h.other_heating.owned and not h.thermal_solar.owned and not h.heat_pump:
            h.other_heating.install()

    def update_meet_and_discuss(self, config: Any) -> None:
        if config.extreme_scenario_testing:
            self.attributes.meet_and_discuss = config.extreme_scenario_neighbours_meet_and_discuss
        else:
            self.attributes.meet_and_discuss = min(
                (self.respondent.number("neighboordhood_r2") - 1) / 6
                + config.stimulate_social_interaction, 1.0)

    def hear(self, family: str, valence: str) -> None:
        """Emotional response to word of mouth (or a campaign) about a technology"""
        delta = self.respondent.number(WOM_COLUMNS[family][valence])
        self.attributes.emotions[family] = clamp(self.attributes.emotions[family] + delta)

    def receive_information(self, perception: Dict[str, Any]) -> None:
        """Information campaigns act like positive word of mouth"""
        for campaign in perception.get('campaigns', []):
            self.hear(campaign.topic, "positive")

    # Metamodel agent interface: runs the household's whole year at once under a
    # per-agent scheduler. CoAdoptionModel.netlogo_schedule calls the routines above.

    def perceive_environment(self, environment: 'CoAdoptionEnvironment') -> Dict[str, Any]:
        knowledge = environment.get_relevant_knowledge(self.agent_id, {'year': environment.year})
        return {'campaigns': self.transformer.process_incoming(self.attributes, knowledge)}

    def make_decisions(self, environment: 'CoAdoptionEnvironment') -> List[Dict[str, Any]]:
        self.age_durable_goods()
        self.receive_information(self.memory.get(self.PERCEPTION_KEY, {}))
        self.update_meet_and_discuss(self.model.config)
        return self.model.decide_alone(self)

    def communicate(self, environment: 'CoAdoptionEnvironment',
                    decisions: List[Dict[str, Any]]) -> None:
        pass    # adoptions are announced on the model's event bus when they happen

    def update_state(self, decisions: List[Dict[str, Any]],
                     environment_feedback: Dict[str, Any]) -> None:
        pass    # state changes are applied immediately on adoption
