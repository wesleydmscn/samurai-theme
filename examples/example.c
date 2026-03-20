#include <math.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_PRODUCTS  64
#define MAX_CART      32
#define NAME_LEN      64
#define ID_LEN        16

typedef struct {
    char   id[ID_LEN];
    char   name[NAME_LEN];
    double price;
    int    stock;
} Product;

typedef struct {
    Product *product;
    int      qty;
} CartItem;

typedef struct {
    CartItem items[MAX_CART];
    int      count;
} Cart;

typedef struct {
    Product products[MAX_PRODUCTS];
    int     count;
} ProductRepository;

typedef enum {
    DISCOUNT_NONE,
    DISCOUNT_PERCENTAGE,
    DISCOUNT_FIXED,
} DiscountType;

typedef struct {
    DiscountType type;
    double       value;
} Discount;

void repo_save(ProductRepository *repo, const char *id, const char *name,
               double price, int stock)
{
    if (repo->count >= MAX_PRODUCTS) return;
    Product *p = &repo->products[repo->count++];
    strncpy(p->id,   id,   ID_LEN   - 1);
    strncpy(p->name, name, NAME_LEN - 1);
    p->price = price;
    p->stock = stock;
}

Product *repo_find(ProductRepository *repo, const char *id)
{
    for (int i = 0; i < repo->count; i++) {
        if (strcmp(repo->products[i].id, id) == 0)
            return &repo->products[i];
    }
    return NULL;
}

bool cart_add(Cart *cart, Product *product, int qty)
{
    for (int i = 0; i < cart->count; i++) {
        if (cart->items[i].product == product) {
            cart->items[i].qty += qty;
            return true;
        }
    }
    if (cart->count >= MAX_CART) return false;
    cart->items[cart->count++] = (CartItem){.product = product, .qty = qty};
    return true;
}

double cart_subtotal(const Cart *cart)
{
    double total = 0.0;
    for (int i = 0; i < cart->count; i++)
        total += cart->items[i].product->price * cart->items[i].qty;
    return total;
}

double apply_discount(Discount d, double price)
{
    switch (d.type) {
    case DISCOUNT_PERCENTAGE: return price * (1.0 - d.value / 100.0);
    case DISCOUNT_FIXED:      return price - d.value < 0.0 ? 0.0 : price - d.value;
    default:                  return price;
    }
}

void fibonacci(int n, long *out)
{
    long a = 0, b = 1;
    for (int i = 0; i < n; i++) {
        out[i] = a;
        long tmp = a + b;
        a = b;
        b = tmp;
    }
}

bool *sieve(int limit)
{
    bool *flags = calloc(limit + 1, sizeof(bool));
    if (!flags) return NULL;
    for (int i = 2; i <= limit; i++) flags[i] = true;
    for (int i = 2; i <= (int)sqrt((double)limit); i++) {
        if (!flags[i]) continue;
        for (int j = i * i; j <= limit; j += i)
            flags[j] = false;
    }
    return flags;
}

static int compare_price(const void *a, const void *b)
{
    const Product *pa = (const Product *)a;
    const Product *pb = (const Product *)b;
    return (pa->price > pb->price) - (pa->price < pb->price);
}

int main(void)
{
    ProductRepository repo = {.count = 0};
    repo_save(&repo, "1", "Laptop",   999.99, 10);
    repo_save(&repo, "2", "Mouse",     29.99, 50);
    repo_save(&repo, "3", "Keyboard",  79.99, 30);

    Cart cart = {.count = 0};
    Product *laptop   = repo_find(&repo, "1");
    Product *mouse    = repo_find(&repo, "2");

    cart_add(&cart, laptop, 1);
    cart_add(&cart, mouse,  2);

    double subtotal = cart_subtotal(&cart);
    Discount d = {DISCOUNT_PERCENTAGE, 10.0};
    double discounted = apply_discount(d, subtotal);

    printf("Subtotal:   $%.2f\n", subtotal);
    printf("After 10%%: $%.2f\n", discounted);

    Product affordable[MAX_PRODUCTS];
    int acount = 0;
    for (int i = 0; i < repo.count; i++) {
        if (repo.products[i].price < 100.0)
            affordable[acount++] = repo.products[i];
    }
    qsort(affordable, acount, sizeof(Product), compare_price);
    printf("Affordable:");
    for (int i = 0; i < acount; i++) printf(" %s", affordable[i].name);
    printf("\n");

    long fibs[8];
    fibonacci(8, fibs);
    printf("Fibonacci(8):");
    for (int i = 0; i < 8; i++) printf(" %ld", fibs[i]);
    printf("\n");

    bool *primes = sieve(30);
    printf("Primes up to 30:");
    for (int i = 2; i <= 30; i++) if (primes[i]) printf(" %d", i);
    printf("\n");
    free(primes);

    return 0;
}
