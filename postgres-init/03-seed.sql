-- Синтетические данные для демо. Детерминированные (generate_series + остатки),
-- чтобы наполнение было воспроизводимым на любой машине студента.

-- ===== Клиенты: 50 =====
INSERT INTO ods.customers (customer_id, full_name, email, country, signup_date)
SELECT
    1000 + i                                        AS customer_id,
    'Customer ' || i                                AS full_name,
    'customer' || i || '@example.com'               AS email,
    (ARRAY['RU','US','DE','FR','NL'])[1 + (i % 5)]  AS country,
    DATE '2026-01-01' + (i % 200)                   AS signup_date
FROM generate_series(1, 50) AS i;

-- ===== Товары: 20 =====
INSERT INTO ods.products (product_id, name, category, unit_price_minor, currency)
SELECT
    i                                                                   AS product_id,
    (ARRAY['Phone','Laptop','Headphones','Keyboard','Monitor','Mouse',
           'Charger','Case','Speaker','Watch'])[1 + ((i - 1) % 10)]
        || '-' || i::text                                               AS name,
    (ARRAY['Electronics','Accessories','Peripherals'])[1 + ((i - 1) % 3)] AS category,
    1000 + ((i * 271) % 90000)                                          AS unit_price_minor,
    'RUB'                                                               AS currency
FROM generate_series(1, 20) AS i;

-- ===== Заказы: 2000, распределение статусов по остатку =====
INSERT INTO ods.orders (order_id, customer_id, order_ts, status, paid_at, amount_minor, currency)
SELECT
    i                                                     AS order_id,
    1000 + (1 + ((i * 7) % 50))                          AS customer_id,
    TIMESTAMPTZ '2026-10-01 00:00:00+00'
        + ((i * 47) % (30 * 24 * 60)) * interval '1 minute' AS order_ts,
    CASE
        WHEN i % 10 = 0 THEN 'cancelled'
        WHEN i % 10 = 9 THEN 'refunded'
        WHEN i % 10 = 8 THEN 'pending'
        ELSE 'paid'
    END                                                  AS status,
    CASE
        WHEN i % 10 = 0 OR i % 10 = 8 THEN NULL
        ELSE TIMESTAMPTZ '2026-10-01 00:00:00+00'
             + ((i * 47) % (30 * 24 * 60)) * interval '1 minute'
             + interval '5 minutes'
    END                                                  AS paid_at,
    500 + ((i * 37) % 90000)                             AS amount_minor,
    'RUB'                                                AS currency
FROM generate_series(1, 2000) AS i;

-- ===== Позиции заказов: 1-3 на заказ =====
INSERT INTO ods.order_items (order_item_id, order_id, product_id, quantity, line_amount_minor)
SELECT
    o.order_id * 10 + k                      AS order_item_id,
    o.order_id                               AS order_id,
    x.product_id                             AS product_id,
    x.qty                                    AS quantity,
    p.unit_price_minor * x.qty               AS line_amount_minor
FROM ods.orders o
CROSS JOIN LATERAL generate_series(1, 1 + (o.order_id % 3)) AS k
CROSS JOIN LATERAL (
    SELECT 1 + ((o.order_id + k) % 20) AS product_id,
           1 + ((o.order_id + k) % 3)  AS qty
) AS x
JOIN ods.products p ON p.product_id = x.product_id;

-- ===== STG: сырые события (каждый пятый заказ как JSON) =====
INSERT INTO stg.orders_raw (order_id, payload, source_file, ingested_at)
SELECT
    o.order_id,
    jsonb_build_object(
        'order_id',    o.order_id,
        'customer_id', o.customer_id,
        'status',      o.status,
        'amount',      o.amount_minor,
        'currency',    o.currency,
        'order_ts',    o.order_ts
    )                                    AS payload,
    'orders_' || to_char(o.order_ts, 'YYYYMMDD') || '.json' AS source_file,
    o.order_ts + interval '10 minutes'   AS ingested_at
FROM ods.orders o
WHERE o.order_id % 5 = 0;

-- ===== DM: витрина оплаченных заказов по дням =====
INSERT INTO dm.orders_daily (order_date, paid_orders_count, gross_amount_minor, currency)
SELECT
    (paid_at AT TIME ZONE 'UTC')::date AS order_date,
    COUNT(*)                           AS paid_orders_count,
    SUM(amount_minor)                  AS gross_amount_minor,
    'RUB'                              AS currency
FROM ods.orders
WHERE status = 'paid' AND paid_at IS NOT NULL
GROUP BY 1
ORDER BY 1;
