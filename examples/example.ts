import { EventEmitter } from "events";

type Result<T> = { ok: true; value: T } | { ok: false; error: string };

interface Product {
  id: string;
  name: string;
  price: number;
  stock: number;
}

interface Repository<T> {
  findById(id: string): T | undefined;
  save(entity: T): void;
  delete(id: string): void;
}

class InMemoryRepository<T extends { id: string }> implements Repository<T> {
  private store = new Map<string, T>();

  findById(id: string): T | undefined {
    return this.store.get(id);
  }

  save(entity: T): void {
    this.store.set(entity.id, entity);
  }

  delete(id: string): void {
    this.store.delete(id);
  }

  findAll(): T[] {
    return Array.from(this.store.values());
  }
}

class OrderBuilder {
  private items: Array<{ product: Product; qty: number }> = [];

  add(product: Product, qty: number): this {
    this.items.push({ product, qty });
    return this;
  }

  build(): Result<{ total: number; items: typeof this.items }> {
    if (this.items.length === 0) return { ok: false, error: "No items" };
    const total = this.items.reduce((sum, i) => sum + i.product.price * i.qty, 0);
    return { ok: true, value: { total, items: this.items } };
  }
}

function* fibonacci(): Generator<number> {
  let [a, b] = [0, 1];
  while (true) {
    yield a;
    [a, b] = [b, a + b];
  }
}

function take<T>(n: number, gen: Generator<T>): T[] {
  const result: T[] = [];
  for (const value of gen) {
    result.push(value);
    if (result.length >= n) break;
  }
  return result;
}

interface DiscountStrategy {
  apply(price: number): number;
}

const tenPercent: DiscountStrategy = { apply: (p) => p * 0.9 };
const fiveOff: DiscountStrategy = { apply: (p) => Math.max(0, p - 5) };

const repo = new InMemoryRepository<Product>();
repo.save({ id: "1", name: "Laptop", price: 999, stock: 5 });
repo.save({ id: "2", name: "Mouse", price: 29, stock: 50 });

const laptop = repo.findById("1")!;
const order = new OrderBuilder().add(laptop, 2).build();

if (order.ok) {
  const discounted = tenPercent.apply(order.value.total);
  console.log(`Total: $${order.value.total}, After discount: $${discounted}`);
}

const fibs = take(8, fibonacci());
console.log("Fibonacci:", fibs.join(", "));
