require "bigdecimal"
require "bigdecimal/util"

module Discountable
  def apply_discount(price)
    raise NotImplementedError, "#{self.class}#apply_discount not implemented"
  end
end

class PercentageDiscount
  include Discountable

  def initialize(percent)
    @factor = (1 - percent / 100.0).to_d
  end

  def apply_discount(price)
    (price * @factor).round(2)
  end
end

class FixedDiscount
  include Discountable

  def initialize(amount)
    @amount = amount.to_d
  end

  def apply_discount(price)
    [price - @amount, 0].max
  end
end

Product = Data.define(:id, :name, :price, :stock)

class Cart
  def initialize
    @items = Hash.new(0)
  end

  def add(product, qty = 1)
    raise ArgumentError, "Quantity must be positive" unless qty.positive?

    @items[product] += qty
    self
  end

  def remove(product)
    @items.delete(product)
    self
  end

  def subtotal
    @items.sum { |product, qty| product.price * qty }
  end

  def total(discount: nil)
    discount ? discount.apply_discount(subtotal) : subtotal
  end

  def empty?
    @items.empty?
  end

  def to_a
    @items.map { |product, qty| { product: product, qty: qty } }
  end
end

class InMemoryRepository
  include Enumerable

  def initialize
    @store = {}
  end

  def save(entity)
    @store[entity.id] = entity
    entity
  end

  def find(id)
    @store[id]
  end

  def find!(id)
    @store.fetch(id) { raise KeyError, "Not found: #{id}" }
  end

  def delete(id)
    @store.delete(id)
  end

  def each(&block)
    @store.values.each(&block)
  end
end

module Fibonacci
  def self.sequence(n)
    Enumerator.new do |y|
      a, b = 0, 1
      loop do
        y << a
        a, b = b, a + b
      end
    end.take(n)
  end
end

module Primes
  def self.sieve(limit)
    flags = Array.new(limit + 1, true)
    flags[0] = flags[1] = false
    (2..Math.sqrt(limit)).each do |i|
      next unless flags[i]

      (i * i..limit).step(i) { |j| flags[j] = false }
    end
    flags.each_index.select { |i| flags[i] }
  end
end

repo = InMemoryRepository.new
repo.save(Product.new(id: "1", name: "Laptop", price: "999.99".to_d, stock: 10))
repo.save(Product.new(id: "2", name: "Mouse", price: "29.99".to_d, stock: 50))
repo.save(Product.new(id: "3", name: "Keyboard", price: "79.99".to_d, stock: 30))

cart = Cart.new
cart.add(repo.find!("1"), 1).add(repo.find!("2"), 2)

discount = PercentageDiscount.new(10)
puts "Subtotal: $#{cart.subtotal}"
puts "Total after 10% off: $#{cart.total(discount: discount)}"

affordable = repo.select { |p| p.price < 100 }.sort_by(&:price).map(&:name)
puts "Affordable: #{affordable.join(", ")}"

puts "Fibonacci(8): #{Fibonacci.sequence(8).join(", ")}"
puts "Primes up to 30: #{Primes.sieve(30).join(", ")}"
