<?php

declare(strict_types=1);

namespace Shop;

final readonly class Product
{
    public function __construct(
        public string $id,
        public string $name,
        public float  $price,
        public int    $stock,
    ) {}
}

final class CartItem
{
    public function __construct(
        public readonly Product $product,
        public int $qty,
    ) {}

    public function subtotal(): float
    {
        return $this->product->price * $this->qty;
    }
}

interface DiscountStrategy
{
    public function apply(float $price): float;
}

final readonly class PercentageDiscount implements DiscountStrategy
{
    public function __construct(private float $percent) {}

    public function apply(float $price): float
    {
        return $price * (1 - $this->percent / 100);
    }
}

final readonly class FixedDiscount implements DiscountStrategy
{
    public function __construct(private float $amount) {}

    public function apply(float $price): float
    {
        return max(0.0, $price - $this->amount);
    }
}

final class Cart
{
    /** @var array<string, CartItem> */
    private array $items = [];

    public function add(Product $product, int $qty = 1): void
    {
        if (isset($this->items[$product->id])) {
            $this->items[$product->id]->qty += $qty;
        } else {
            $this->items[$product->id] = new CartItem($product, $qty);
        }
    }

    public function subtotal(): float
    {
        return array_sum(array_map(fn (CartItem $i) => $i->subtotal(), $this->items));
    }

    public function total(?DiscountStrategy $discount = null): float
    {
        return $discount ? $discount->apply($this->subtotal()) : $this->subtotal();
    }

    public function isEmpty(): bool
    {
        return empty($this->items);
    }
}

/**
 * @template T
 */
final class InMemoryRepository
{
    /** @var array<string, T> */
    private array $store = [];

    /** @param T $entity */
    public function save(string $key, mixed $entity): void
    {
        $this->store[$key] = $entity;
    }

    /** @return T|null */
    public function find(string $key): mixed
    {
        return $this->store[$key] ?? null;
    }

    /** @return list<T> */
    public function findAll(): array
    {
        return array_values($this->store);
    }
}

function fibonacci(int $n): array
{
    $seq = [];
    [$a, $b] = [0, 1];
    for ($i = 0; $i < $n; $i++) {
        $seq[] = $a;
        [$a, $b] = [$b, $a + $b];
    }
    return $seq;
}

function sieve(int $limit): array
{
    $flags = array_fill(0, $limit + 1, true);
    $flags[0] = $flags[1] = false;
    for ($i = 2; $i <= (int) sqrt($limit); $i++) {
        if (!$flags[$i]) continue;
        for ($j = $i * $i; $j <= $limit; $j += $i) {
            $flags[$j] = false;
        }
    }
    return array_keys(array_filter($flags));
}

$repo = new InMemoryRepository();
$repo->save('1', new Product('1', 'Laptop',   999.99, 10));
$repo->save('2', new Product('2', 'Mouse',     29.99, 50));
$repo->save('3', new Product('3', 'Keyboard',  79.99, 30));

$cart = new Cart();
$cart->add($repo->find('1'), 1);
$cart->add($repo->find('2'), 2);

$discount = new PercentageDiscount(10);
printf("Subtotal:   $%.2f\n", $cart->subtotal());
printf("After 10%%: $%.2f\n", $cart->total($discount));

$affordable = array_filter($repo->findAll(), fn (Product $p) => $p->price < 100);
usort($affordable, fn ($a, $b) => $a->price <=> $b->price);
echo 'Affordable: ' . implode(', ', array_column($affordable, 'name')) . "\n";

echo 'Fibonacci(8): ' . implode(', ', fibonacci(8)) . "\n";
echo 'Primes up to 30: ' . implode(', ', sieve(30)) . "\n";
