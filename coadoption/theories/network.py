"""
Spatial k-nearest-neighbour social network.

Agents are placed at random inside the ring of the world that matches their
region (e.g. urban core, suburban ring, rural outskirts) on a square torus, and
each agent is linked to its k nearest agents by toroidal Euclidean distance.
"""

import math
import random
from dataclasses import dataclass
from typing import Any, Dict, List, Optional, Tuple

from consumer_choice_metamodel import Network


@dataclass(frozen=True)
class Zone:
    """Ring of distances from the world centre: low < d <= high (None = unbounded)"""
    low: Optional[float] = None
    high: Optional[float] = None

    def contains(self, distance: float) -> bool:
        return ((self.low is None or distance > self.low)
                and (self.high is None or distance <= self.high))


# the original NetLogo world: urban core radius 18, suburban ring to 31, rural beyond
SWISS_ZONES: Dict[str, Zone] = {
    "urban": Zone(None, 18.0),
    "suburban": Zone(18.0, 31.0),
    "rural": Zone(31.0, None),
}


class SpatialKNNNetwork(Network):

    def __init__(self, k: int, rng: random.Random,
                 zones: Optional[Dict[str, Zone]] = None,
                 half_width: float = 38.0, max_tries: int = 500):
        self.k = k
        self.rng = rng
        self.zones = SWISS_ZONES if zones is None else zones
        self.half_width = half_width
        self.max_tries = max_tries
        self.positions: Dict[str, Tuple[float, float]] = {}
        self._neighbours: Optional[Dict[str, List[str]]] = None

    def add_agent(self, agent_id: str, properties: Dict[str, Any]) -> None:
        """Place the agent in the zone named by properties['region'] (rejection sampling);
        an unknown region keeps the last random draw"""
        zone = self.zones.get(str(properties.get('region', '')).strip().lower())
        for _ in range(self.max_tries):
            x = self.rng.uniform(-self.half_width, self.half_width)
            y = self.rng.uniform(-self.half_width, self.half_width)
            if zone is not None and zone.contains(math.hypot(x, y)):
                break
        self.positions[agent_id] = (x, y)
        self._neighbours = None

    def remove_agent(self, agent_id: str) -> None:
        self.positions.pop(agent_id, None)
        self._neighbours = None

    def get_neighbors(self, agent_id: str) -> List[str]:
        if self._neighbours is None:
            self._neighbours = self._link()
        return self._neighbours.get(agent_id, [])

    def get_network_properties(self, agent_id: str) -> Dict[str, Any]:
        return {'neighbors': self.get_neighbors(agent_id),
                'position': self.positions.get(agent_id)}

    def distance(self, a: Tuple[float, float], b: Tuple[float, float]) -> float:
        width = 2 * self.half_width
        dx = abs(a[0] - b[0])
        dy = abs(a[1] - b[1])
        if dx > width / 2:
            dx = width - dx
        if dy > width / 2:
            dy = width - dy
        return math.hypot(dx, dy)

    def _link(self) -> Dict[str, List[str]]:
        ids = list(self.positions)
        k = min(self.k, len(ids) - 1)
        links = {}
        for i, agent_id in enumerate(ids):
            here = self.positions[agent_id]
            ranked = sorted(
                (self.distance(here, self.positions[other]), j)
                for j, other in enumerate(ids) if j != i
            )
            links[agent_id] = [ids[j] for _, j in ranked[:k]]
        return links
