"""
The 14 binary policy levers of the paper's scenario analysis.

A scenario is a vector of 0/1 flags, one per policy in POLICIES order. Policies
are applied in that order to the baseline parameters (no interventions, low
savings, no GHG improvement); the neighbourhood battery builds on the PV
savings level, so order matters.
"""

from dataclasses import dataclass
from typing import Any, Callable, Dict, List, Sequence, Tuple

from .config import Config

BASELINE: Dict[str, Any] = dict(
    subsidy_PV=0.0,
    subsidy_EV=0.0,
    subsidy_heat_pump=0.0,
    bundle_bonus=0.0,
    savings_EV="low",          # 3.3 / 3.7 / 4.1 CHF/100 km
    savings_heat_pump=2090.0,
    PV_net_bill_after_adoption=-489.0,
    PV_self_sufficiency_potential_global=0.3,
    learning_rate_life_cycle_ghg_PV=0.0,   # no GHG improvement in baseline
    learning_rate_life_cycle_ghg_EV=0.0,
    learning_rate_life_cycle_ghg_heat_pump=0.0,
    tenants_can_install=False,
    historic_houses_can_install_PV=False,
    stimulate_social_interaction=0.0,
    word_of_mouth=True,
    neighbourhood_effect=True,
    replacement_time=True,
)


@dataclass(frozen=True)
class Policy:
    name: str                                   # as shown in the paper's figures
    label: str                                  # short axis label
    apply: Callable[[Dict[str, Any]], None]     # edits Config keyword arguments


def _set(**values: Any) -> Callable[[Dict[str, Any]], None]:
    return lambda kw: kw.update(values)


def _neighbourhood_battery(kw: Dict[str, Any]) -> None:
    # raises self-sufficiency and PV savings
    kw["PV_self_sufficiency_potential_global"] = min(
        1.0, kw["PV_self_sufficiency_potential_global"] + 0.2)
    kw["PV_net_bill_after_adoption"] = kw["PV_net_bill_after_adoption"] + 73.5


POLICIES: Tuple[Policy, ...] = (
    Policy("Subsidy PV (30%)", "Subsidy PV (30%)", _set(subsidy_PV=30.0)),
    Policy("Subsidy EV (30%)", "Subsidy EV (30%)", _set(subsidy_EV=30.0)),
    Policy("Subsidy HP (30%)", "Subsidy HP (30%)", _set(subsidy_heat_pump=30.0)),
    Policy("Bundle Bonus (30%)", "Bundle Bonus (30%)", _set(bundle_bonus=30.0)),
    Policy("High savings EV", "High savings EV", _set(savings_EV="high")),
    Policy("High savings HP (+600)", "High savings HP", _set(savings_heat_pump=2090.0 + 600.0)),
    Policy("High savings PV (net bill +73.5)", "High savings PV",
           _set(PV_net_bill_after_adoption=-489.0 + 73.5)),     # lower net bill
    Policy("GHG standards PV (−2%/yr)", "GHG std. PV", _set(learning_rate_life_cycle_ghg_PV=0.02)),
    Policy("GHG standards EV (−1%/yr)", "GHG std. EV", _set(learning_rate_life_cycle_ghg_EV=0.01)),
    Policy("GHG standards HP (−2%/yr)", "GHG std. HP",
           _set(learning_rate_life_cycle_ghg_heat_pump=0.02)),
    Policy("Neighbourhood battery (+20% self-suff)", "Nbhd battery", _neighbourhood_battery),
    Policy("Tenants can install", "Tenants install", _set(tenants_can_install=True)),
    Policy("Historic houses can install", "Historic install",
           _set(historic_houses_can_install_PV=True)),
    Policy("Stimulate social interaction", "Social interaction",
           _set(stimulate_social_interaction=0.14)),   # adds ~0.14 to NMD (0-1 scale)
)

POLICY_NAMES: List[str] = [p.name for p in POLICIES]
POLICY_LABELS_SHORT: List[str] = [p.label for p in POLICIES]
N_POLICIES = len(POLICIES)   # 14  →  2^14 = 16 384 scenarios


def policy_vector_to_config_kwargs(vec: Sequence[int]) -> Dict[str, Any]:
    """Config keyword overrides for a binary policy vector (length 14)"""
    if len(vec) != N_POLICIES:
        raise ValueError(f"expected {N_POLICIES} policy flags, got {len(vec)}")
    kw = dict(BASELINE)
    for policy, on in zip(POLICIES, vec):
        if on:
            policy.apply(kw)
    return kw


def scenario_config(vec: Sequence[int], **overrides: Any) -> Config:
    """Config for a policy vector, e.g. scenario_config(vec, households=300)"""
    return Config(**{**policy_vector_to_config_kwargs(vec), **overrides})
