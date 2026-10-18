"""
Social influence.

- Peer effect: the share of adopters in the population enters utility as a
  descriptive social norm (weighted by the individual's peer coefficient).
- Affective word of mouth: after adopting, an agent shares its experience
  (positive, negative or mixed) with some of its network neighbours, whose
  emotion towards the technology moves by their own positive / negative delta.
"""

import random
from typing import Any, Callable, Dict, List, Tuple

from consumer_choice_metamodel import Network, RulesOfInteraction

POSITIVE = "positive"
NEGATIVE = "negative"

# which emotional effects an opinion triggers, applied in this order
OPINION_VALENCES: Dict[str, Tuple[str, ...]] = {
    "PositiveFeedback": (POSITIVE,),
    "NegativeFeedback": (NEGATIVE,),
    "MixedFeedback": (POSITIVE, NEGATIVE),
}


def adopter_share(adopters: int, population: int) -> float:
    """Descriptive norm: fraction of the population that has adopted"""
    return adopters / population


def clamp(value: float, low: float = 0.0, high: float = 1.0) -> float:
    return max(low, min(high, value))


class WordOfMouth(RulesOfInteraction):
    """
    Word of mouth along a social network.

    contacts(agent_id) gives how many neighbours an agent talks to per
    adoption; listeners are drawn without replacement from its neighbours.
    """

    def __init__(self, network: Network, contacts: Callable[[str], int]):
        self.network = network
        self.contacts = contacts

    def can_interact(self, agent_a: str, agent_b: str, context: Dict[str, Any]) -> bool:
        return agent_b in self.network.get_neighbors(agent_a)

    def get_interaction_effects(self, agent_a: str, agent_b: str,
                                interaction_type: str) -> Dict[str, Any]:
        """interaction_type is the speaker's opinion, e.g. "MixedFeedback" """
        return {'valences': OPINION_VALENCES.get(interaction_type, ())}

    def listeners(self, speaker_id: str, rng: random.Random) -> List[str]:
        neighbours = self.network.get_neighbors(speaker_id)
        return rng.sample(neighbours, min(self.contacts(speaker_id), len(neighbours)))

    def spread(self, speaker_id: str, opinion: str, rng: random.Random,
               apply: Callable[[str, str], None]) -> List[str]:
        """
        Tell listeners about the speaker's opinion; apply(listener_id, valence)
        changes each listener. Listeners are drawn even for neutral opinions,
        which keeps the random number sequence independent of opinions.
        """
        listeners = self.listeners(speaker_id, rng)
        for valence in self.get_interaction_effects(speaker_id, "", opinion)['valences']:
            for listener_id in listeners:
                apply(listener_id, valence)
        return listeners
