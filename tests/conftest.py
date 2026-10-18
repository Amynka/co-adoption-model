import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from coadoption import CoAdoptionModel, Config, SurveyData  # noqa: E402

DATA_PATH = ROOT / "data" / "surveyData.csv"


@pytest.fixture(scope="session")
def survey():
    return SurveyData.load(DATA_PATH)


@pytest.fixture
def make_model(survey):
    def _make(seed=0, **config):
        model = CoAdoptionModel(survey, seed=seed)
        model.initialize_model(Config(**config))
        return model
    return _make
