import kotlin.math.max
import kotlin.math.sqrt

data class Money(val amount: Double, val currency: String = "USD") {
    operator fun plus(other: Money): Money {
        require(currency == other.currency) { "Currency mismatch" }
        return copy(amount = amount + other.amount)
    }

    operator fun times(factor: Int) = copy(amount = amount * factor)

    override fun toString() = "$currency ${"%.2f".format(amount)}"
}

data class Product(val id: String, val name: String, val price: Money, val stock: Int)

data class CartItem(val product: Product, val qty: Int) {
    val subtotal: Money get() = product.price * qty
}

fun interface DiscountStrategy {
    fun apply(price: Money): Money
}

fun percentageDiscount(rate: Double) = DiscountStrategy { price ->
    price.copy(amount = price.amount * (1 - rate / 100))
}

fun fixedDiscount(amount: Double) = DiscountStrategy { price ->
    price.copy(amount = max(0.0, price.amount - amount))
}

class Cart {
    private val items = mutableMapOf<String, CartItem>()

    fun add(product: Product, qty: Int = 1) {
        items.merge(product.id, CartItem(product, qty)) { old, new ->
            old.copy(qty = old.qty + new.qty)
        }
    }

    fun remove(productId: String) { items.remove(productId) }

    fun subtotal(): Money = items.values.fold(Money(0.0)) { acc, item -> acc + item.subtotal }

    fun total(discount: DiscountStrategy? = null): Money =
        discount?.apply(subtotal()) ?: subtotal()

    val isEmpty: Boolean get() = items.isEmpty()
}

class InMemoryRepository<T> {
    private val store = mutableMapOf<String, T>()

    fun save(key: String, entity: T) { store[key] = entity }

    fun find(key: String): T? = store[key]

    fun findOrThrow(key: String): T =
        store[key] ?: throw NoSuchElementException("Not found: $key")

    fun findAll(): List<T> = store.values.toList()
}

sealed class Result<out T> {
    data class Success<T>(val value: T) : Result<T>()
    data class Failure(val error: String) : Result<Nothing>()
}

fun safeDivide(a: Double, b: Double): Result<Double> =
    if (b == 0.0) Result.Failure("Division by zero")
    else Result.Success(a / b)

fun fibonacci(n: Int): List<Long> = buildList {
    var (a, b) = 0L to 1L
    repeat(n) {
        add(a)
        val tmp = a + b
        a = b
        b = tmp
    }
}

fun sieve(limit: Int): List<Int> {
    val flags = BooleanArray(limit + 1) { it >= 2 }
    for (i in 2..sqrt(limit.toDouble()).toInt()) {
        if (!flags[i]) continue
        var j = i * i
        while (j <= limit) { flags[j] = false; j += i }
    }
    return flags.indices.filter { flags[it] }
}

fun main() {
    val repo = InMemoryRepository<Product>()
    repo.save("1", Product("1", "Laptop",   Money(999.99), 10))
    repo.save("2", Product("2", "Mouse",    Money( 29.99), 50))
    repo.save("3", Product("3", "Keyboard", Money( 79.99), 30))

    val cart = Cart().apply {
        add(repo.findOrThrow("1"), 1)
        add(repo.findOrThrow("2"), 2)
    }

    val discount = percentageDiscount(10.0)
    println("Subtotal:   ${cart.subtotal()}")
    println("After 10%: ${cart.total(discount)}")

    val affordable = repo.findAll()
        .filter { it.price.amount < 100.0 }
        .sortedBy { it.price.amount }
        .map { it.name }

    println("Affordable: ${affordable.joinToString(", ")}")
    println("Fibonacci(8): ${fibonacci(8)}")
    println("Primes up to 30: ${sieve(30)}")

    when (val result = safeDivide(10.0, 3.0)) {
        is Result.Success -> println("10 / 3 = ${"%.4f".format(result.value)}")
        is Result.Failure -> println("Error: ${result.error}")
    }
}
