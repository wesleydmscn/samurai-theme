from __future__ import annotations

import math
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Generator, Generic, TypeVar

T = TypeVar("T")


@dataclass(frozen=True)
class Product:
    id: str
    name: str
    price: float
    stock: int


@dataclass
class CartItem:
    product: Product
    qty: int

    @property
    def subtotal(self) -> float:
        return self.product.price * self.qty


class DiscountStrategy(ABC):
    @abstractmethod
    def apply(self, price: float) -> float: ...


@dataclass(frozen=True)
class PercentageDiscount(DiscountStrategy):
    percent: float

    def apply(self, price: float) -> float:
        return price * (1 - self.percent / 100)


@dataclass(frozen=True)
class FixedDiscount(DiscountStrategy):
    amount: float

    def apply(self, price: float) -> float:
        return max(0.0, price - self.amount)


class Cart:
    def __init__(self) -> None:
        self._items: dict[str, CartItem] = {}

    def add(self, product: Product, qty: int = 1) -> None:
        if product.id in self._items:
            self._items[product.id].qty += qty
        else:
            self._items[product.id] = CartItem(product, qty)

    def remove(self, product_id: str) -> None:
        self._items.pop(product_id, None)

    @property
    def subtotal(self) -> float:
        return sum(item.subtotal for item in self._items.values())

    def total(self, discount: DiscountStrategy | None = None) -> float:
        return discount.apply(self.subtotal) if discount else self.subtotal

    @property
    def is_empty(self) -> bool:
        return not self._items


class InMemoryRepository(Generic[T]):
    def __init__(self) -> None:
        self._store: dict[str, T] = {}

    def save(self, entity: T, key: str) -> None:
        self._store[key] = entity

    def find(self, key: str) -> T | None:
        return self._store.get(key)

    def find_all(self) -> list[T]:
        return list(self._store.values())


def fibonacci(n: int) -> Generator[int, None, None]:
    a, b = 0, 1
    for _ in range(n):
        yield a
        a, b = b, a + b


def sieve(limit: int) -> list[int]:
    flags = bytearray([1]) * (limit + 1)
    flags[0] = flags[1] = 0
    for i in range(2, math.isqrt(limit) + 1):
        if flags[i]:
            flags[i * i :: i] = bytearray(len(flags[i * i :: i]))
    return [i for i, f in enumerate(flags) if f]


repo: InMemoryRepository[Product] = InMemoryRepository()
repo.save(Product("1", "Laptop",   999.99, 10), "1")
repo.save(Product("2", "Mouse",     29.99, 50), "2")
repo.save(Product("3", "Keyboard",  79.99, 30), "3")

cart = Cart()
cart.add(repo.find("1"))  # type: ignore[arg-type]
cart.add(repo.find("2"), qty=2)  # type: ignore[arg-type]

discount = PercentageDiscount(10)
print(f"Subtotal:   ${cart.subtotal:.2f}")
print(f"After 10%:  ${cart.total(discount):.2f}")

affordable = sorted(
    (p for p in repo.find_all() if p.price < 100),
    key=lambda p: p.price,
)
print("Affordable:", ", ".join(p.name for p in affordable))
print("Fibonacci(8):", list(fibonacci(8)))
print("Primes up to 30:", sieve(30))
