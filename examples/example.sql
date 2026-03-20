CREATE TABLE customers (
    id         SERIAL PRIMARY KEY,
    email      VARCHAR(255) NOT NULL UNIQUE,
    name       VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE products (
    id          SERIAL         PRIMARY KEY,
    name        VARCHAR(100)   NOT NULL,
    price       NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
    stock       INTEGER        NOT NULL DEFAULT 0 CHECK (stock >= 0),
    category    VARCHAR(50),
    created_at  TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

CREATE TABLE orders (
    id          SERIAL       PRIMARY KEY,
    customer_id INTEGER      NOT NULL REFERENCES customers (id) ON DELETE RESTRICT,
    status      VARCHAR(20)  NOT NULL DEFAULT 'pending'
                             CHECK (status IN ('pending', 'paid', 'shipped', 'cancelled')),
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE order_items (
    id         SERIAL         PRIMARY KEY,
    order_id   INTEGER        NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
    product_id INTEGER        NOT NULL REFERENCES products (id) ON DELETE RESTRICT,
    quantity   INTEGER        NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(10, 2) NOT NULL CHECK (unit_price >= 0)
);

CREATE INDEX idx_orders_customer    ON orders (customer_id);
CREATE INDEX idx_order_items_order  ON order_items (order_id);
CREATE INDEX idx_order_items_product ON order_items (product_id);
CREATE INDEX idx_products_category  ON products (category);

INSERT INTO customers (email, name) VALUES
    ('alice@example.com', 'Alice'),
    ('bob@example.com',   'Bob'),
    ('carol@example.com', 'Carol');

INSERT INTO products (name, price, stock, category) VALUES
    ('Laptop',    999.99,  10, 'Electronics'),
    ('Mouse',      29.99,  50, 'Electronics'),
    ('Keyboard',   79.99,  30, 'Electronics'),
    ('Desk',      349.00,   5, 'Furniture'),
    ('Chair',     199.00,   8, 'Furniture');

INSERT INTO orders (customer_id, status) VALUES
    (1, 'paid'),
    (1, 'shipped'),
    (2, 'pending');

INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
    (1, 1, 1, 999.99),
    (1, 2, 2,  29.99),
    (2, 3, 1,  79.99),
    (3, 4, 1, 349.00),
    (3, 5, 2, 199.00);

SELECT
    o.id                                        AS order_id,
    c.name                                      AS customer,
    o.status,
    SUM(oi.quantity * oi.unit_price)            AS total,
    COUNT(oi.id)                                AS item_count,
    o.created_at
FROM orders o
JOIN customers   c  ON c.id  = o.customer_id
JOIN order_items oi ON oi.order_id = o.id
GROUP BY o.id, c.name, o.status, o.created_at
ORDER BY o.created_at DESC;

WITH customer_totals AS (
    SELECT
        c.id,
        c.name,
        c.email,
        COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS lifetime_value,
        COUNT(DISTINCT o.id)                           AS order_count
    FROM customers c
    LEFT JOIN orders      o  ON o.customer_id = c.id AND o.status != 'cancelled'
    LEFT JOIN order_items oi ON oi.order_id   = o.id
    GROUP BY c.id, c.name, c.email
),
ranked AS (
    SELECT
        *,
        RANK() OVER (ORDER BY lifetime_value DESC) AS rank
    FROM customer_totals
)
SELECT * FROM ranked WHERE rank <= 10;

SELECT
    p.category,
    p.name,
    p.price,
    AVG(p.price) OVER (PARTITION BY p.category)           AS avg_category_price,
    p.price - AVG(p.price) OVER (PARTITION BY p.category) AS diff_from_avg,
    RANK()       OVER (PARTITION BY p.category ORDER BY p.price DESC) AS price_rank
FROM products p
ORDER BY p.category, price_rank;

SELECT
    p.name,
    p.stock,
    COALESCE(SUM(oi.quantity), 0) AS units_sold
FROM products p
LEFT JOIN order_items oi ON oi.product_id = p.id
LEFT JOIN orders       o ON o.id = oi.order_id AND o.status != 'cancelled'
GROUP BY p.id, p.name, p.stock
HAVING p.stock < 20 OR COALESCE(SUM(oi.quantity), 0) > 5
ORDER BY units_sold DESC;

CREATE OR REPLACE FUNCTION place_order(
    p_customer_id INTEGER,
    p_items       JSONB
) RETURNS INTEGER AS $$
DECLARE
    v_order_id   INTEGER;
    v_item       JSONB;
    v_product    products%ROWTYPE;
BEGIN
    INSERT INTO orders (customer_id) VALUES (p_customer_id) RETURNING id INTO v_order_id;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
        SELECT * INTO v_product FROM products WHERE id = (v_item->>'product_id')::INTEGER FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Product % not found', v_item->>'product_id';
        END IF;

        IF v_product.stock < (v_item->>'quantity')::INTEGER THEN
            RAISE EXCEPTION 'Insufficient stock for product %', v_product.name;
        END IF;

        INSERT INTO order_items (order_id, product_id, quantity, unit_price)
        VALUES (v_order_id, v_product.id, (v_item->>'quantity')::INTEGER, v_product.price);

        UPDATE products SET stock = stock - (v_item->>'quantity')::INTEGER WHERE id = v_product.id;
    END LOOP;

    RETURN v_order_id;
END;
$$ LANGUAGE plpgsql;

CREATE VIEW order_summary AS
SELECT
    o.id,
    c.name                               AS customer_name,
    o.status,
    SUM(oi.quantity * oi.unit_price)     AS total,
    o.created_at
FROM orders o
JOIN customers   c  ON c.id = o.customer_id
JOIN order_items oi ON oi.order_id = o.id
GROUP BY o.id, c.name, o.status, o.created_at;
