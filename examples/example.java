import java.util.*;
import java.util.stream.*;

public class example {

    public interface Discountable {
        double applyDiscount(double price);
    }

    public enum DiscountType implements Discountable {
        NONE {
            @Override
            public double applyDiscount(double price) { return price; }
        },
        TEN_PERCENT {
            @Override
            public double applyDiscount(double price) { return price * 0.9; }
        },
        FIXED_FIVE {
            @Override
            public double applyDiscount(double price) { return Math.max(0, price - 5.0); }
        }
    }

    public static final class Product {
        private final String id;
        private final String name;
        private final double price;
        private int stock;

        public Product(String id, String name, double price, int stock) {
            this.id = id;
            this.name = name;
            this.price = price;
            this.stock = stock;
        }

        public String getId() { return id; }
        public String getName() { return name; }
        public double getPrice() { return price; }
        public int getStock() { return stock; }

        public void decrementStock(int qty) {
            if (qty > stock) throw new IllegalStateException("Insufficient stock for: " + name);
            stock -= qty;
        }

        @Override
        public String toString() {
            return String.format("Product{id='%s', name='%s', price=%.2f}", id, name, price);
        }
    }

    public static final class OrderItem {
        private final Product product;
        private final int quantity;

        public OrderItem(Product product, int quantity) {
            this.product = product;
            this.quantity = quantity;
        }

        public double subtotal() { return product.getPrice() * quantity; }
        public Product getProduct() { return product; }
        public int getQuantity() { return quantity; }
    }

    public static final class Order {
        private final String id;
        private final List<OrderItem> items;
        private final Discountable discount;

        private Order(Builder builder) {
            this.id = UUID.randomUUID().toString();
            this.items = Collections.unmodifiableList(new ArrayList<>(builder.items));
            this.discount = builder.discount;
        }

        public String getId() { return id; }

        public double total() {
            double subtotal = items.stream().mapToDouble(OrderItem::subtotal).sum();
            return discount.applyDiscount(subtotal);
        }

        public static class Builder {
            private final List<OrderItem> items = new ArrayList<>();
            private Discountable discount = DiscountType.NONE;

            public Builder addItem(Product product, int qty) {
                items.add(new OrderItem(product, qty));
                return this;
            }

            public Builder withDiscount(Discountable discount) {
                this.discount = discount;
                return this;
            }

            public Order build() {
                if (items.isEmpty()) throw new IllegalStateException("Order must have at least one item");
                return new Order(this);
            }
        }
    }

    public interface ProductRepository {
        Optional<Product> findById(String id);
        void save(Product product);
        List<Product> findAll();
    }

    public static class InMemoryProductRepository implements ProductRepository {
        private final Map<String, Product> store = new HashMap<>();

        @Override
        public Optional<Product> findById(String id) {
            return Optional.ofNullable(store.get(id));
        }

        @Override
        public void save(Product product) {
            store.put(product.getId(), product);
        }

        @Override
        public List<Product> findAll() {
            return Collections.unmodifiableList(new ArrayList<>(store.values()));
        }
    }

    static List<Integer> primes(int limit) {
        return IntStream.rangeClosed(2, limit)
            .filter(n -> IntStream.rangeClosed(2, (int) Math.sqrt(n)).allMatch(i -> n % i != 0))
            .boxed()
            .collect(Collectors.toList());
    }

    static List<Long> fibonacci(int n) {
        List<Long> seq = new ArrayList<>();
        long a = 0, b = 1;
        for (int i = 0; i < n; i++) {
            seq.add(a);
            long tmp = a + b;
            a = b;
            b = tmp;
        }
        return seq;
    }

    public static void main(String[] args) {
        ProductRepository repo = new InMemoryProductRepository();
        repo.save(new Product("1", "Laptop", 999.99, 10));
        repo.save(new Product("2", "Mouse", 29.99, 50));
        repo.save(new Product("3", "Keyboard", 79.99, 30));

        Product laptop = repo.findById("1").orElseThrow();
        Product mouse = repo.findById("2").orElseThrow();

        Order order = new Order.Builder()
            .addItem(laptop, 1)
            .addItem(mouse, 2)
            .withDiscount(DiscountType.TEN_PERCENT)
            .build();

        System.out.printf("Order %s total: $%.2f%n", order.getId(), order.total());

        List<String> affordable = repo.findAll().stream()
            .filter(p -> p.getPrice() < 100.0)
            .sorted(Comparator.comparingDouble(Product::getPrice))
            .map(Product::getName)
            .collect(Collectors.toList());

        System.out.println("Affordable products: " + affordable);
        System.out.println("Fibonacci(8): " + fibonacci(8));
        System.out.println("Primes up to 30: " + primes(30));
    }
}
