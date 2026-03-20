import Foundation

struct Product: Identifiable, Hashable {
    let id: String
    let name: String
    let price: Decimal
    let stock: Int
}

struct CartItem {
    let product: Product
    var qty: Int

    var subtotal: Decimal { product.price * Decimal(qty) }
}

protocol DiscountStrategy {
    func apply(to price: Decimal) -> Decimal
}

struct PercentageDiscount: DiscountStrategy {
    let rate: Decimal

    func apply(to price: Decimal) -> Decimal {
        price * (1 - rate / 100)
    }
}

struct FixedDiscount: DiscountStrategy {
    let amount: Decimal

    func apply(to price: Decimal) -> Decimal {
        max(0, price - amount)
    }
}

final class Cart {
    private var items: [String: CartItem] = [:]

    func add(_ product: Product, qty: Int = 1) {
        items[product.id, default: CartItem(product: product, qty: 0)].qty += qty
    }

    func remove(productID: String) {
        items.removeValue(forKey: productID)
    }

    var subtotal: Decimal {
        items.values.reduce(0) { $0 + $1.subtotal }
    }

    func total(discount: DiscountStrategy? = nil) -> Decimal {
        discount?.apply(to: subtotal) ?? subtotal
    }

    var isEmpty: Bool { items.isEmpty }
}

enum RepositoryError: Error {
    case notFound(String)
}

final class InMemoryRepository<T> {
    private var store: [String: T] = [:]

    func save(_ entity: T, forKey key: String) {
        store[key] = entity
    }

    func find(_ key: String) -> T? {
        store[key]
    }

    func findOrThrow(_ key: String) throws -> T {
        guard let entity = store[key] else {
            throw RepositoryError.notFound(key)
        }
        return entity
    }

    var all: [T] { Array(store.values) }
}

enum Result<Success, Failure: Error> {
    case success(Success)
    case failure(Failure)

    func map<NewSuccess>(_ transform: (Success) -> NewSuccess) -> Result<NewSuccess, Failure> {
        switch self {
        case .success(let v): return .success(transform(v))
        case .failure(let e): return .failure(e)
        }
    }
}

func fibonacci(_ n: Int) -> [Int] {
    guard n > 0 else { return [] }
    var seq = [0, 1]
    while seq.count < n {
        seq.append(seq[seq.count - 1] + seq[seq.count - 2])
    }
    return Array(seq.prefix(n))
}

func sieve(upTo limit: Int) -> [Int] {
    var flags = Array(repeating: true, count: limit + 1)
    flags[0] = false
    if limit > 0 { flags[1] = false }
    var i = 2
    while i * i <= limit {
        if flags[i] {
            stride(from: i * i, through: limit, by: i).forEach { flags[$0] = false }
        }
        i += 1
    }
    return flags.indices.filter { flags[$0] }
}

let repo = InMemoryRepository<Product>()
repo.save(Product(id: "1", name: "Laptop",   price: 999.99, stock: 10), forKey: "1")
repo.save(Product(id: "2", name: "Mouse",    price:  29.99, stock: 50), forKey: "2")
repo.save(Product(id: "3", name: "Keyboard", price:  79.99, stock: 30), forKey: "3")

let cart = Cart()
if let laptop = repo.find("1") { cart.add(laptop, qty: 1) }
if let mouse  = repo.find("2") { cart.add(mouse,  qty: 2) }

let discount = PercentageDiscount(rate: 10)
print("Subtotal:   \(cart.subtotal)")
print("After 10%: \(cart.total(discount: discount))")

let affordable = repo.all
    .filter { $0.price < 100 }
    .sorted { $0.price < $1.price }
    .map(\.name)

print("Affordable: \(affordable.joined(separator: ", "))")
print("Fibonacci(8): \(fibonacci(8))")
print("Primes up to 30: \(sieve(upTo: 30))")
