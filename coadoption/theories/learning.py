"""
Technology learning as exogenous processes.

- ExperienceCurve: a value (price, life-cycle emissions) falls by a constant
  rate per period down to a floor.
- LinearTrend: a value (e.g. EV range) grows by a constant increment up to a cap.
- FixedValue: a value that is held constant from the first update (for
  extreme-scenario tests).
"""

from typing import Any, Dict, Iterable, List, Optional

from consumer_choice_metamodel import ExogenousProcess


class _ValueProcess(ExogenousProcess):

    def __init__(self, name: str, initial: float, assets: Iterable[str] = ()):
        self.name = name
        self.value = initial
        self.assets = list(assets)

    def affects_assets(self) -> List[str]:
        return list(self.assets)

    def _changes(self) -> Dict[str, Any]:
        return {self.name: self.value}


class ExperienceCurve(_ValueProcess):
    """value_t = max(value_{t-1} * (1 - rate), floor)

    With reset_to set, the value restarts from reset_to before every update.
    """

    def __init__(self, name: str, initial: float, rate: float, floor: float,
                 assets: Iterable[str] = (), reset_to: Optional[float] = None):
        super().__init__(name, initial, assets)
        self.rate = rate
        self.floor = floor
        self.reset_to = reset_to

    def update(self, current_time: int, environment_state: Dict[str, Any]) -> Dict[str, Any]:
        if self.reset_to is not None:
            self.value = self.reset_to
        self.value = max(self.value * (1 - self.rate), self.floor)
        return self._changes()


class LinearTrend(_ValueProcess):
    """value_t = min(value_{t-1} + increment, cap)"""

    def __init__(self, name: str, initial: float, increment: float, cap: float,
                 assets: Iterable[str] = ()):
        super().__init__(name, initial, assets)
        self.increment = increment
        self.cap = cap

    def update(self, current_time: int, environment_state: Dict[str, Any]) -> Dict[str, Any]:
        self.value = min(self.value + self.increment, self.cap)
        return self._changes()


class FixedValue(_ValueProcess):
    """Starts at initial, then stays at fixed from the first update on"""

    def __init__(self, name: str, initial: float, fixed: float, assets: Iterable[str] = ()):
        super().__init__(name, initial, assets)
        self.fixed = fixed

    def update(self, current_time: int, environment_state: Dict[str, Any]) -> Dict[str, Any]:
        self.value = self.fixed
        return self._changes()
