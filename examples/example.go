package main

import (
	"errors"
	"fmt"
	"math"
	"sort"
)

type Product struct {
	ID    string
	Name  string
	Price float64
	Stock int
}

type CartItem struct {
	Product  Product
	Quantity int
}

func (item CartItem) Subtotal() float64 {
	return item.Product.Price * float64(item.Quantity)
}

type Cart struct {
	items map[string]*CartItem
}

func NewCart() *Cart {
	return &Cart{items: make(map[string]*CartItem)}
}

func (c *Cart) Add(product Product, qty int) {
	if item, ok := c.items[product.ID]; ok {
		item.Quantity += qty
	} else {
		c.items[product.ID] = &CartItem{Product: product, Quantity: qty}
	}
}

func (c *Cart) Subtotal() float64 {
	var total float64
	for _, item := range c.items {
		total += item.Subtotal()
	}
	return total
}

func (c *Cart) Total(discount Discount) float64 {
	return discount.Apply(c.Subtotal())
}

type Discount interface {
	Apply(price float64) float64
}

type PercentageDiscount struct{ Rate float64 }
type FixedDiscount struct{ Amount float64 }
type NoDiscount struct{}

func (d PercentageDiscount) Apply(price float64) float64 {
	return price * (1 - d.Rate/100)
}

func (d FixedDiscount) Apply(price float64) float64 {
	return math.Max(0, price-d.Amount)
}

func (d NoDiscount) Apply(price float64) float64 { return price }

type Repository[T any] struct {
	store map[string]T
}

func NewRepository[T any]() *Repository[T] {
	return &Repository[T]{store: make(map[string]T)}
}

func (r *Repository[T]) Save(key string, entity T) {
	r.store[key] = entity
}

func (r *Repository[T]) Find(key string) (T, bool) {
	v, ok := r.store[key]
	return v, ok
}

func (r *Repository[T]) FindAll() []T {
	all := make([]T, 0, len(r.store))
	for _, v := range r.store {
		all = append(all, v)
	}
	return all
}

func fibonacci(n int) []int {
	seq := make([]int, n)
	a, b := 0, 1
	for i := range seq {
		seq[i] = a
		a, b = b, a+b
	}
	return seq
}

func sieve(limit int) []int {
	flags := make([]bool, limit+1)
	for i := 2; i <= limit; i++ {
		flags[i] = true
	}
	for i := 2; i*i <= limit; i++ {
		if !flags[i] {
			continue
		}
		for j := i * i; j <= limit; j += i {
			flags[j] = false
		}
	}
	primes := make([]int, 0)
	for i, ok := range flags {
		if ok {
			primes = append(primes, i)
		}
	}
	return primes
}

func safeDivide(a, b float64) (float64, error) {
	if b == 0 {
		return 0, errors.New("division by zero")
	}
	return a / b, nil
}

func main() {
	repo := NewRepository[Product]()
	repo.Save("1", Product{ID: "1", Name: "Laptop",   Price: 999.99, Stock: 10})
	repo.Save("2", Product{ID: "2", Name: "Mouse",    Price:  29.99, Stock: 50})
	repo.Save("3", Product{ID: "3", Name: "Keyboard", Price:  79.99, Stock: 30})

	cart := NewCart()
	if laptop, ok := repo.Find("1"); ok {
		cart.Add(laptop, 1)
	}
	if mouse, ok := repo.Find("2"); ok {
		cart.Add(mouse, 2)
	}

	discount := PercentageDiscount{Rate: 10}
	fmt.Printf("Subtotal:   $%.2f\n", cart.Subtotal())
	fmt.Printf("After 10%%: $%.2f\n", cart.Total(discount))

	all := repo.FindAll()
	affordable := make([]Product, 0)
	for _, p := range all {
		if p.Price < 100 {
			affordable = append(affordable, p)
		}
	}
	sort.Slice(affordable, func(i, j int) bool {
		return affordable[i].Price < affordable[j].Price
	})

	fmt.Print("Affordable:")
	for _, p := range affordable {
		fmt.Printf(" %s", p.Name)
	}
	fmt.Println()

	fmt.Println("Fibonacci(8):", fibonacci(8))
	fmt.Println("Primes up to 30:", sieve(30))

	if result, err := safeDivide(10, 3); err != nil {
		fmt.Println("Error:", err)
	} else {
		fmt.Printf("10 / 3 = %.4f\n", result)
	}
}
