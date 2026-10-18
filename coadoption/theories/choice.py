"""
Random-utility choice with individual part-worths.

Each decision maker has their own coefficients (part-worths), e.g. estimated
from a discrete choice experiment with a hierarchical Bayes / mixed logit
model. The utility of an option is a linear combination of attribute levels,

    U = sum_k  beta_k * x_k

and the adoption probability is the logistic transform of U. An option is
adopted when that probability reaches a threshold.
"""

import math
from collections import OrderedDict
from dataclasses import dataclass
from typing import Any, Callable, Dict, Iterable, List, Optional, Tuple

from consumer_choice_metamodel import EvaluationDimension

# attribute level of a term in a choice situation; None makes the term contribute 0.0
# whatever its coefficient (e.g. an "owns a heat pump" bonus for a household without one)
AttributeLevel = Callable[[Any], Optional[float]]


def constant(situation: Any) -> float:
    """Attribute level of an intercept (alternative-specific constant)"""
    return 1.0


@dataclass(frozen=True)
class UtilityTerm:
    """One coefficient-times-attribute term of a linear utility function"""
    dimension: EvaluationDimension
    coefficient: str              # name of the part-worth (e.g. a survey column)
    level: AttributeLevel


class LinearUtility:
    """
    Linear-in-parameters utility function.

    Terms are summed in the order given, so results are reproducible to the
    last bit across implementations that use the same order.
    """

    def __init__(self, terms: Iterable[UtilityTerm]):
        self.terms: Tuple[UtilityTerm, ...] = tuple(terms)

    def contributions(self, coefficients: Callable[[str], float],
                      situation: Any) -> List[Tuple[UtilityTerm, float]]:
        """Each term with its contribution beta_k * x_k"""
        result = []
        for term in self.terms:
            level = term.level(situation)
            value = 0.0 if level is None else coefficients(term.coefficient) * level
            result.append((term, value))
        return result

    def utility(self, coefficients: Callable[[str], float], situation: Any) -> float:
        """Total utility U"""
        return sum(value for _, value in self.contributions(coefficients, situation))

    def by_dimension(self, coefficients: Callable[[str], float],
                     situation: Any) -> Dict[EvaluationDimension, float]:
        """Utility split by evaluation dimension (sums to U up to rounding)"""
        totals: Dict[EvaluationDimension, float] = OrderedDict()
        for term, value in self.contributions(coefficients, situation):
            totals[term.dimension] = totals.get(term.dimension, 0.0) + value
        return totals


def logistic(utility: float) -> float:
    """Binary logit choice probability 1 / (1 + exp(-U))"""
    try:
        return 1.0 / (1.0 + math.exp(-utility))
    except OverflowError:       # U very negative
        return 0.0
