"""
Co-adoption of low-carbon household energy technologies (PV, EVs, heat pumps).

An implementation of van der Kam et al. (2024) on the consumer_choice_metamodel
framework. The behavioural and technological theories it uses live in
coadoption.theories and can be reused in other models.

    from coadoption import CoAdoptionModel, Config, SurveyData

The names in __all__ are the public API. Submodules hold the same classes plus
internal helpers (names starting with an underscore).
"""

__version__ = "1.0.0"

from .config import Config
from .survey import SurveyData, Respondent
from .technologies import Technology, ElectricVehicle, ChoiceSituation, PV, EV, HP
from .household import House, HouseholdAttributes, HouseholdChoiceModule, Household
from .environment import CoAdoptionEnvironment, InformationCampaign
from .factory import SurveyHouseholdFactory
from .model import CoAdoptionModel
from .policies import (
    POLICIES, POLICY_NAMES, POLICY_LABELS_SHORT, N_POLICIES, Policy,
    policy_vector_to_config_kwargs, scenario_config,
)
from .runner import build_model, run_once, save_csv, plot_results, DEFAULT_DATA_PATH

__all__ = [
    'Config', 'SurveyData', 'Respondent',
    'Technology', 'ElectricVehicle', 'ChoiceSituation', 'PV', 'EV', 'HP',
    'House', 'HouseholdAttributes', 'HouseholdChoiceModule', 'Household',
    'CoAdoptionEnvironment', 'InformationCampaign', 'SurveyHouseholdFactory',
    'CoAdoptionModel',
    'POLICIES', 'POLICY_NAMES', 'POLICY_LABELS_SHORT', 'N_POLICIES', 'Policy',
    'policy_vector_to_config_kwargs', 'scenario_config',
    'build_model', 'run_once', 'save_csv', 'plot_results', 'DEFAULT_DATA_PATH',
]
