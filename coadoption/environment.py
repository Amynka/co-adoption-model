"""
The market environment: technologies, learning processes, information
campaigns, the social network and word-of-mouth rules.
"""

from typing import Any, Dict, List, Optional

from consumer_choice_metamodel import Environment, KnowledgeAsset, PhysicalAsset

from .config import Config
from .technologies import ElectricVehicle, Technology
from .theories.network import SpatialKNNNetwork
from .theories.social import WordOfMouth

START_YEAR = 2022


class InformationCampaign(KnowledgeAsset):
    """A public campaign about one technology family, run in a single year"""

    def __init__(self, topic: str, year: int):
        super().__init__(topic, "information campaign")
        self.year = year

    def get_reliability(self) -> float:
        return 1.0

    def get_content(self) -> Dict[str, Any]:
        return {'technology': self.topic, 'year': self.year}


class CoAdoptionEnvironment(Environment):

    def __init__(self, config: Config, pv_net_bill: float, hp_savings: float):
        super().__init__()
        self.config = config
        self.pv_net_bill = pv_net_bill      # CHF / year after adopting PV
        self.hp_savings = hp_savings        # CHF / year from a heat pump
        self.year = START_YEAR
        self.technologies: Dict[str, Technology] = {}

    def technology(self, name: str) -> Technology:
        return self.technologies[name]

    def ev_for(self, car_size: str) -> Optional[ElectricVehicle]:
        """EV model matching a survey car-size answer ("Small car", ...)"""
        for tech in self.technologies.values():
            if isinstance(tech, ElectricVehicle) and tech.car_size == car_size:
                return tech
        return None

    @property
    def network(self) -> SpatialKNNNetwork:
        return self.networks[0]

    @property
    def word_of_mouth(self) -> WordOfMouth:
        return self.rules[0]

    def add_physical_asset(self, asset: PhysicalAsset) -> None:
        self.physical_assets.append(asset)
        self.technologies[asset.name] = asset

    def add_knowledge_asset(self, asset: KnowledgeAsset) -> None:
        self.knowledge_assets.append(asset)

    def get_available_options(self, agent_id: str, context: Dict[str, Any]) -> List[PhysicalAsset]:
        """Technologies the household may adopt now; context['household'] is the Household"""
        model, household = context['model'], context['household']
        options = []
        if model.pv_eligible(household):
            options.append(self.technology("PV"))
        if model.hp_eligible(household):
            options.append(self.technology("HP"))
        ev = self.ev_for(household.attributes.car_size)
        if ev is not None and household.needs_car():
            options.append(ev)
        return options

    def get_relevant_knowledge(self, agent_id: str, context: Dict[str, Any]) -> List[KnowledgeAsset]:
        """Campaigns running in context['year']"""
        year = context.get('year', self.year)
        return [k for k in self.knowledge_assets
                if isinstance(k, InformationCampaign) and k.year == year]

    def update_environment(self, current_time: int) -> None:
        """Advance prices, emissions and EV ranges by one year"""
        self.year = START_YEAR + current_time
        state = {'current_time': current_time, 'year': self.year}
        for process in self.exogenous_processes:
            state.update(process.update(current_time, state))
        for tech in self.technologies.values():
            tech.update_net_price()

    def add_communication(self, communication: Dict[str, Any]) -> None:
        self.communications.append(communication)
