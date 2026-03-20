import 'dart:math';

sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.error);
  final String error;
}

abstract interface class Discountable {
  double apply(double price);
}

final class PercentageDiscount implements Discountable {
  const PercentageDiscount(this.percent);
  final double percent;

  @override
  double apply(double price) => price * (1 - percent / 100);
}

final class FixedDiscount implements Discountable {
  const FixedDiscount(this.amount);
  final double amount;

  @override
  double apply(double price) => max(0, price - amount);
}

final class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
  });

  final String id;
  final String name;
  final double price;
  final int stock;

  @override
  String toString() => 'Product(id: $id, name: $name, price: $price)';
}

final class CartItem {
  const CartItem({required this.product, required this.quantity});
  final Product product;
  final int quantity;

  double get subtotal => product.price * quantity;
}

final class Cart {
  final _items = <String, CartItem>{};

  void add(Product product, {int qty = 1}) {
    _items.update(
      product.id,
      (existing) => CartItem(product: product, quantity: existing.quantity + qty),
      ifAbsent: () => CartItem(product: product, quantity: qty),
    );
  }

  void remove(String productId) => _items.remove(productId);

  double subtotal() => _items.values.fold(0, (sum, item) => sum + item.subtotal);

  double total({Discountable? discount}) {
    final sub = subtotal();
    return discount?.apply(sub) ?? sub;
  }

  bool get isEmpty => _items.isEmpty;

  List<CartItem> get items => List.unmodifiable(_items.values);
}

abstract interface class Repository<T> {
  T? findById(String id);
  void save(T entity);
  List<T> findAll();
}

final class InMemoryRepository<T> implements Repository<T> {
  final _store = <String, T>{};
  final String Function(T) _idOf;

  InMemoryRepository(this._idOf);

  @override
  T? findById(String id) => _store[id];

  @override
  void save(T entity) => _store[_idOf(entity)] = entity;

  @override
  List<T> findAll() => List.unmodifiable(_store.values);
}

List<int> fibonacci(int n) {
  if (n <= 0) return [];
  final seq = <int>[0, if (n > 1) 1];
  for (var i = 2; i < n; i++) seq.add(seq[i - 1] + seq[i - 2]);
  return seq;
}

List<int> primes(int limit) {
  final sieve = List.filled(limit + 1, true);
  sieve[0] = sieve[1] = false;
  for (var i = 2; i <= sqrt(limit); i++) {
    if (!sieve[i]) continue;
    for (var j = i * i; j <= limit; j += i) sieve[j] = false;
  }
  return [for (var i = 0; i <= limit; i++) if (sieve[i]) i];
}

Result<double> divide(double a, double b) {
  if (b == 0) return const Err('Division by zero');
  return Ok(a / b);
}

void main() {
  final repo = InMemoryRepository<Product>((p) => p.id);
  repo.save(const Product(id: '1', name: 'Laptop', price: 999.99, stock: 10));
  repo.save(const Product(id: '2', name: 'Mouse', price: 29.99, stock: 50));
  repo.save(const Product(id: '3', name: 'Keyboard', price: 79.99, stock: 30));

  final cart = Cart();
  cart.add(repo.findById('1')!, qty: 1);
  cart.add(repo.findById('2')!, qty: 2);

  const discount = PercentageDiscount(10);
  print('Subtotal: \$${cart.subtotal().toStringAsFixed(2)}');
  print('Total (10% off): \$${cart.total(discount: discount).toStringAsFixed(2)}');

  final affordable = repo.findAll()
      .where((p) => p.price < 100)
      .toList()
    ..sort((a, b) => a.price.compareTo(b.price));

  print('Affordable: ${affordable.map((p) => p.name).join(', ')}');
  print('Fibonacci(8): ${fibonacci(8)}');
  print('Primes up to 30: ${primes(30)}');

  final result = divide(10, 3);
  switch (result) {
    case Ok(:final value):
      print('10 / 3 = ${value.toStringAsFixed(4)}');
    case Err(:final error):
      print('Error: $error');
  }
}
