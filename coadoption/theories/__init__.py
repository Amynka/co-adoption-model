"""
Behavioural and technological theories used by the co-adoption model, written
independently of it so they can be reused in other consumer-choice models built
on the consumer_choice_metamodel framework.

- choice:    random-utility (binary logit) choice with individual part-worths
- social:    peer effect (descriptive social norm) and affective word of mouth
- learning:  experience curves and linear technology trends
- lifecycle: durable goods that are replaced at the end of their lifetime
- network:   spatial k-nearest-neighbour social network on a torus
"""

from .choice import UtilityTerm, LinearUtility, logistic, constant
from .social import WordOfMouth, OPINION_VALENCES, adopter_share, clamp
from .learning import ExperienceCurve, LinearTrend, FixedValue
from .lifecycle import DurableGood
from .network import SpatialKNNNetwork, Zone

__all__ = [
    'UtilityTerm', 'LinearUtility', 'logistic', 'constant',
    'WordOfMouth', 'OPINION_VALENCES', 'adopter_share', 'clamp',
    'ExperienceCurve', 'LinearTrend', 'FixedValue',
    'DurableGood',
    'SpatialKNNNetwork', 'Zone',
]
