"""
Survey data: one respondent per household agent, accessed by column name.

The survey holds both respondent characteristics (ownership, region, perceived
benefits and risks, emotions, ...) and each respondent's individual choice-model
coefficients (part-worths) for PV, heat pumps and three EV sizes.
"""

from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, List, Union

import pandas as pd

UNKNOWN_YEAR = "Je ne me souviens pas"     # survey answer "I don't remember"

# word-of-mouth emotion deltas per technology family and valence
WOM_COLUMNS: Dict[str, Dict[str, str]] = {
    "PV": {"positive": "emoPVposWOM", "negative": "emoPVnegWOM"},
    "HP": {"positive": "emoHPposWOM", "negative": "emoHPnegWOM"},
    "EV": {"positive": "emoEVposWOM", "negative": "emoEVnegWOM"},
}

# columns with the opinions of current owners (word-of-mouth content)
OPINION_COLUMNS = {"PV": "PVWoMowners", "EV": "EVWoMowners", "HP": "HPWoMowners"}


class Respondent:
    """One survey row. value() keeps text answers; number() returns a float."""

    def __init__(self, values: Dict[str, Any]):
        self._values = values
        self._numbers: Dict[str, float] = {}

    def value(self, column: str) -> Any:
        """Raw answer; numeric text is converted to float"""
        v = self._values[column]
        if isinstance(v, str):
            try:
                return float(v)
            except ValueError:
                return v
        return v

    def raw(self, column: str) -> Any:
        """Answer exactly as read from the CSV"""
        return self._values[column]

    def text(self, column: str) -> str:
        return str(self.value(column))

    def number(self, column: str) -> float:
        """Numeric answer or coefficient; blank answers count as 0.0 (cached)"""
        if column not in self._numbers:
            v = self.value(column)
            self._numbers[column] = float(v) if v not in ("", " ", None) else 0.0
        return self._numbers[column]


@dataclass
class SurveyData:
    frame: pd.DataFrame
    opinions: Dict[str, List[Any]]     # technology family -> owners' opinions
    car_purchase_frequencies: List[Any]

    @classmethod
    def load(cls, path: Union[str, Path]) -> "SurveyData":
        frame = pd.read_csv(path)
        columns = list(frame.columns)
        required = list(OPINION_COLUMNS.values()) + ["CarPurchaseFrequency"]
        missing = [c for c in required if c not in columns]
        if missing:
            raise ValueError(f"survey {path} lacks columns: {', '.join(missing)}")
        raw = frame.values.tolist()

        def answers(column: str) -> List[Any]:
            idx = columns.index(column)
            return [row[idx] for row in raw
                    if str(row[idx]).strip() not in (column, " ", "", "nan")]

        return cls(
            frame=frame,
            opinions={family: answers(col) for family, col in OPINION_COLUMNS.items()},
            car_purchase_frequencies=answers("CarPurchaseFrequency"),
        )

    def __len__(self) -> int:
        return len(self.frame)

    def respondents(self, rows: pd.DataFrame) -> List[Respondent]:
        columns = list(self.frame.columns)
        return [Respondent(dict(zip(columns, list(row)))) for _, row in rows.iterrows()]
