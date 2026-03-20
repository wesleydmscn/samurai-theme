using System;
using System.Collections.Generic;
using System.Linq;

namespace Shop;

readonly record struct Money(decimal Amount, string Currency)
{
    public Money Add(Money other)
    {
        if (Currency != other.Currency) throw new InvalidOperationException("Currency mismatch");
        return new Money(Amount + other.Amount, Currency);
    }

    public Money Multiply(int factor) => new(Amount * factor, Currency);

    public override string ToString() => $"{Currency} {Amount:F2}";
}

sealed record Product(string Id, string Name, Money Price, int Stock);

sealed record CartItem(Product Product, int Qty)
{
    public Money Subtotal => Product.Price.Multiply(Qty);
}

interface IDiscountStrategy
{
    Money Apply(Money price);
}

sealed class PercentageDiscount(decimal percent) : IDiscountStrategy
{
    public Money Apply(Money price) =>
        price with { Amount = price.Amount * (1 - percent / 100m) };
}

sealed class FixedDiscount(decimal amount) : IDiscountStrategy
{
    public Money Apply(Money price) =>
        price with { Amount = Math.Max(0m, price.Amount - amount) };
}

sealed class Cart
{
    private readonly Dictionary<string, CartItem> _items = [];

    public void Add(Product product, int qty = 1)
    {
        _items[product.Id] = _items.TryGetValue(product.Id, out var existing)
            ? existing with { Qty = existing.Qty + qty }
            : new CartItem(product, qty);
    }

    public void Remove(string productId) => _items.Remove(productId);

    public Money Subtotal()
    {
        var zero = new Money(0m, "USD");
        return _items.Values.Aggregate(zero, (acc, item) => acc.Add(item.Subtotal));
    }

    public Money Total(IDiscountStrategy? discount = null)
    {
        var sub = Subtotal();
        return discount?.Apply(sub) ?? sub;
    }

    public bool IsEmpty => _items.Count == 0;
}

sealed class InMemoryRepository<T>
{
    private readonly Dictionary<string, T> _store = [];

    public void Save(string key, T entity) => _store[key] = entity;

    public T? Find(string key) => _store.GetValueOrDefault(key);

    public T FindOrThrow(string key) =>
        _store.TryGetValue(key, out var value)
            ? value
            : throw new KeyNotFoundException($"Not found: {key}");

    public IReadOnlyList<T> FindAll() => [.. _store.Values];
}

static class MathUtils
{
    public static IEnumerable<long> Fibonacci(int n)
    {
        long a = 0, b = 1;
        for (int i = 0; i < n; i++)
        {
            yield return a;
            (a, b) = (b, a + b);
        }
    }

    public static IEnumerable<int> Sieve(int limit)
    {
        var flags = new bool[limit + 1];
        Array.Fill(flags, true);
        flags[0] = flags[1] = false;
        for (int i = 2; i * i <= limit; i++)
        {
            if (!flags[i]) continue;
            for (int j = i * i; j <= limit; j += i) flags[j] = false;
        }
        return Enumerable.Range(0, limit + 1).Where(i => flags[i]);
    }
}

var repo = new InMemoryRepository<Product>();
repo.Save("1", new Product("1", "Laptop",   new Money(999.99m, "USD"), 10));
repo.Save("2", new Product("2", "Mouse",    new Money( 29.99m, "USD"), 50));
repo.Save("3", new Product("3", "Keyboard", new Money( 79.99m, "USD"), 30));

var cart = new Cart();
cart.Add(repo.FindOrThrow("1"), 1);
cart.Add(repo.FindOrThrow("2"), 2);

IDiscountStrategy discount = new PercentageDiscount(10m);
Console.WriteLine($"Subtotal:   {cart.Subtotal()}");
Console.WriteLine($"After 10%: {cart.Total(discount)}");

var affordable = repo.FindAll()
    .Where(p => p.Price.Amount < 100m)
    .OrderBy(p => p.Price.Amount)
    .Select(p => p.Name);

Console.WriteLine($"Affordable: {string.Join(", ", affordable)}");
Console.WriteLine($"Fibonacci(8): {string.Join(", ", MathUtils.Fibonacci(8))}");
Console.WriteLine($"Primes up to 30: {string.Join(", ", MathUtils.Sieve(30))}");
