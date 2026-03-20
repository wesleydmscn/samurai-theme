use std::collections::HashMap;

#[derive(Debug, Clone)]
struct Product {
    id: String,
    name: String,
    price: f64,
    stock: u32,
}

impl Product {
    fn new(id: &str, name: &str, price: f64, stock: u32) -> Self {
        Self {
            id: id.to_owned(),
            name: name.to_owned(),
            price,
            stock,
        }
    }
}

#[derive(Debug, Clone)]
struct CartItem {
    product: Product,
    qty: u32,
}

impl CartItem {
    fn subtotal(&self) -> f64 {
        self.product.price * self.qty as f64
    }
}

trait Discount {
    fn apply(&self, price: f64) -> f64;
}

struct PercentageDiscount(f64);
struct FixedDiscount(f64);

impl Discount for PercentageDiscount {
    fn apply(&self, price: f64) -> f64 {
        price * (1.0 - self.0 / 100.0)
    }
}

impl Discount for FixedDiscount {
    fn apply(&self, price: f64) -> f64 {
        f64::max(0.0, price - self.0)
    }
}

struct Cart {
    items: HashMap<String, CartItem>,
}

impl Cart {
    fn new() -> Self {
        Self { items: HashMap::new() }
    }

    fn add(&mut self, product: Product, qty: u32) {
        self.items
            .entry(product.id.clone())
            .and_modify(|item| item.qty += qty)
            .or_insert(CartItem { product, qty });
    }

    fn subtotal(&self) -> f64 {
        self.items.values().map(|i| i.subtotal()).sum()
    }

    fn total(&self, discount: &dyn Discount) -> f64 {
        discount.apply(self.subtotal())
    }
}

struct Repository<T> {
    store: HashMap<String, T>,
}

impl<T: Clone> Repository<T> {
    fn new() -> Self {
        Self { store: HashMap::new() }
    }

    fn save(&mut self, key: &str, entity: T) {
        self.store.insert(key.to_owned(), entity);
    }

    fn find(&self, key: &str) -> Option<&T> {
        self.store.get(key)
    }

    fn find_all(&self) -> Vec<&T> {
        self.store.values().collect()
    }
}

fn fibonacci(n: usize) -> Vec<u64> {
    let mut seq = Vec::with_capacity(n);
    let (mut a, mut b) = (0u64, 1u64);
    for _ in 0..n {
        seq.push(a);
        (a, b) = (b, a + b);
    }
    seq
}

fn sieve(limit: usize) -> Vec<usize> {
    let mut flags = vec![true; limit + 1];
    flags[0] = false;
    if limit > 0 { flags[1] = false; }
    let mut i = 2;
    while i * i <= limit {
        if flags[i] {
            let mut j = i * i;
            while j <= limit {
                flags[j] = false;
                j += i;
            }
        }
        i += 1;
    }
    flags.iter().enumerate().filter(|(_, &f)| f).map(|(i, _)| i).collect()
}

fn safe_divide(a: f64, b: f64) -> Result<f64, &'static str> {
    if b == 0.0 { Err("division by zero") } else { Ok(a / b) }
}

fn main() {
    let mut repo = Repository::new();
    repo.save("1", Product::new("1", "Laptop",   999.99, 10));
    repo.save("2", Product::new("2", "Mouse",     29.99, 50));
    repo.save("3", Product::new("3", "Keyboard",  79.99, 30));

    let mut cart = Cart::new();
    if let Some(p) = repo.find("1") { cart.add(p.clone(), 1); }
    if let Some(p) = repo.find("2") { cart.add(p.clone(), 2); }

    let discount = PercentageDiscount(10.0);
    println!("Subtotal:   ${:.2}", cart.subtotal());
    println!("After 10%: ${:.2}", cart.total(&discount));

    let mut affordable: Vec<&Product> = repo
        .find_all()
        .into_iter()
        .filter(|p| p.price < 100.0)
        .collect();
    affordable.sort_by(|a, b| a.price.partial_cmp(&b.price).unwrap());

    let names: Vec<&str> = affordable.iter().map(|p| p.name.as_str()).collect();
    println!("Affordable: {}", names.join(", "));
    println!("Fibonacci(8): {:?}", fibonacci(8));
    println!("Primes up to 30: {:?}", sieve(30));

    match safe_divide(10.0, 3.0) {
        Ok(v)  => println!("10 / 3 = {:.4}", v),
        Err(e) => println!("Error: {}", e),
    }
}
