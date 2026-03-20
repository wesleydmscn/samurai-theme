#include <algorithm>
#include <cmath>
#include <format>
#include <functional>
#include <iostream>
#include <map>
#include <memory>
#include <numeric>
#include <optional>
#include <ranges>
#include <stdexcept>
#include <string>
#include <variant>
#include <vector>

template <typename T>
using Result = std::variant<T, std::string>;

template <typename T>
bool is_ok(const Result<T>& r) { return std::holds_alternative<T>(r); }

template <typename T>
const T& get_value(const Result<T>& r) { return std::get<T>(r); }

struct Product {
    std::string id;
    std::string name;
    double      price;
    int         stock;
};

struct CartItem {
    Product product;
    int     qty;
    double  subtotal() const { return product.price * qty; }
};

class Cart {
public:
    void add(const Product& product, int qty) {
        auto it = std::find_if(items_.begin(), items_.end(),
            [&](const CartItem& i) { return i.product.id == product.id; });
        if (it != items_.end()) it->qty += qty;
        else items_.push_back({product, qty});
    }

    double subtotal() const {
        return std::accumulate(items_.begin(), items_.end(), 0.0,
            [](double acc, const CartItem& i) { return acc + i.subtotal(); });
    }

    const std::vector<CartItem>& items() const { return items_; }

private:
    std::vector<CartItem> items_;
};

class DiscountStrategy {
public:
    virtual ~DiscountStrategy() = default;
    virtual double apply(double price) const = 0;
};

class PercentageDiscount : public DiscountStrategy {
public:
    explicit PercentageDiscount(double percent) : factor_(1.0 - percent / 100.0) {}
    double apply(double price) const override { return price * factor_; }
private:
    double factor_;
};

class FixedDiscount : public DiscountStrategy {
public:
    explicit FixedDiscount(double amount) : amount_(amount) {}
    double apply(double price) const override { return std::max(0.0, price - amount_); }
private:
    double amount_;
};

template <typename T>
class InMemoryRepository {
public:
    using IdExtractor = std::function<std::string(const T&)>;

    explicit InMemoryRepository(IdExtractor extractor) : extractor_(std::move(extractor)) {}

    void save(T entity) {
        store_[extractor_(entity)] = std::move(entity);
    }

    std::optional<std::reference_wrapper<const T>> find(const std::string& id) const {
        if (auto it = store_.find(id); it != store_.end())
            return std::cref(it->second);
        return std::nullopt;
    }

    std::vector<T> find_all() const {
        std::vector<T> result;
        result.reserve(store_.size());
        for (const auto& [_, v] : store_) result.push_back(v);
        return result;
    }

private:
    std::map<std::string, T> store_;
    IdExtractor              extractor_;
};

std::vector<long> fibonacci(int n) {
    std::vector<long> seq;
    seq.reserve(n);
    long a = 0, b = 1;
    for (int i = 0; i < n; i++) {
        seq.push_back(a);
        auto tmp = a + b;
        a = b;
        b = tmp;
    }
    return seq;
}

std::vector<int> sieve(int limit) {
    std::vector<bool> flags(limit + 1, true);
    flags[0] = flags[1] = false;
    for (int i = 2; i <= static_cast<int>(std::sqrt(limit)); i++) {
        if (!flags[i]) continue;
        for (int j = i * i; j <= limit; j += i) flags[j] = false;
    }
    std::vector<int> primes;
    for (int i = 2; i <= limit; i++) if (flags[i]) primes.push_back(i);
    return primes;
}

int main() {
    InMemoryRepository<Product> repo([](const Product& p) { return p.id; });
    repo.save({"1", "Laptop",   999.99, 10});
    repo.save({"2", "Mouse",     29.99, 50});
    repo.save({"3", "Keyboard",  79.99, 30});

    Cart cart;
    if (auto p = repo.find("1")) cart.add(p->get(), 1);
    if (auto p = repo.find("2")) cart.add(p->get(), 2);

    PercentageDiscount discount(10.0);
    auto subtotal   = cart.subtotal();
    auto discounted = discount.apply(subtotal);

    std::cout << std::format("Subtotal:   ${:.2f}\n", subtotal);
    std::cout << std::format("After 10%: ${:.2f}\n",  discounted);

    auto all = repo.find_all();
    auto affordable = all
        | std::views::filter([](const Product& p) { return p.price < 100.0; });

    std::vector<Product> sorted_affordable(affordable.begin(), affordable.end());
    std::sort(sorted_affordable.begin(), sorted_affordable.end(),
        [](const Product& a, const Product& b) { return a.price < b.price; });

    std::cout << "Affordable:";
    for (const auto& p : sorted_affordable) std::cout << " " << p.name;
    std::cout << "\n";

    auto fibs = fibonacci(8);
    std::cout << "Fibonacci(8):";
    for (auto v : fibs) std::cout << " " << v;
    std::cout << "\n";

    auto primes = sieve(30);
    std::cout << "Primes up to 30:";
    for (auto v : primes) std::cout << " " << v;
    std::cout << "\n";

    return 0;
}
