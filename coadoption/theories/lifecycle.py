"""
Durable goods and replacement timing.

A durable good (car, heating system) is kept until it reaches the end of its
lifetime; only then does its owner face a replacement decision. This is what
makes adoption opportunities lumpy in time.
"""

from dataclasses import dataclass


@dataclass
class DurableGood:
    lifetime: int
    owned: bool = False
    age: int = 0

    def install(self) -> None:
        """Buy a new one"""
        self.owned = True
        self.age = 0

    def age_one_period(self) -> bool:
        """Age by one period; returns True if the good was retired just now"""
        if not self.owned:
            return False
        self.age += 1
        if self.age >= self.lifetime:
            self.owned = False
            return True
        return False
