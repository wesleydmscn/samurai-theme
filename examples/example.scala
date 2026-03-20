import scala.math.sqrt

final case class Product(id: String, name: String, price: Double, stock: Int)
final case class CartItem(product: Product, qty: Int):
  def subtotal: Double = product.price * qty

enum Discount:
  case Percentage(rate: Double)
  case Fixed(amount: Double)
  case None

object Discount:
  def apply(d: Discount, price: Double): Double = d match
    case Percentage(rate) => price * (1 - rate / 100)
    case Fixed(amount)    => math.max(0, price - amount)
    case None             => price

final class Cart:
  private var items: Map[String, CartItem] = Map.empty

  def add(product: Product, qty: Int = 1): Unit =
    items = items.updatedWith(product.id):
      case Some(item) => Some(item.copy(qty = item.qty + qty))
      case None       => Some(CartItem(product, qty))

  def subtotal: Double = items.values.map(_.subtotal).sum

  def total(discount: Discount = Discount.None): Double =
    Discount(discount, subtotal)

final class InMemoryRepository[T]:
  private var store: Map[String, T] = Map.empty

  def save(key: String, entity: T): Unit = store = store + (key -> entity)

  def find(key: String): Option[T] = store.get(key)

  def findAll: List[T] = store.values.toList

object Fibonacci:
  def take(n: Int): List[Long] =
    Iterator
      .iterate((0L, 1L)) { case (a, b) => (b, a + b) }
      .map(_._1)
      .take(n)
      .toList

object Primes:
  def sieve(limit: Int): List[Int] =
    val flags = Array.fill(limit + 1)(true)
    flags(0) = false
    flags(1) = false
    for i <- 2 to sqrt(limit.toDouble).toInt do
      if flags(i) then
        var j = i * i
        while j <= limit do
          flags(j) = false
          j += i
    (2 to limit).filter(flags).toList

@main def run(): Unit =
  val repo = InMemoryRepository[Product]()
  repo.save("1", Product("1", "Laptop",   999.99, 10))
  repo.save("2", Product("2", "Mouse",     29.99, 50))
  repo.save("3", Product("3", "Keyboard",  79.99, 30))

  val cart = Cart()
  repo.find("1").foreach(cart.add(_, 1))
  repo.find("2").foreach(cart.add(_, 2))

  val discount = Discount.Percentage(10)
  println(f"Subtotal:   $$${cart.subtotal}%.2f")
  println(f"After 10%%: $$${cart.total(discount)}%.2f")

  val affordable = repo.findAll
    .filter(_.price < 100)
    .sortBy(_.price)
    .map(_.name)

  println(s"Affordable: ${affordable.mkString(", ")}")
  println(s"Fibonacci(8): ${Fibonacci.take(8).mkString(", ")}")
  println(s"Primes up to 30: ${Primes.sieve(30).mkString(", ")}")

  val result: Either[String, Double] =
    if 3 != 0 then Right(10.0 / 3)
    else Left("Division by zero")

  result match
    case Right(v) => println(f"10 / 3 = $v%.4f")
    case Left(e)  => println(s"Error: $e")
