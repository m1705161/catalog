-- Структура таблиц по слоям + комментарии.
-- Комментарии COMMENT ON попадают в каталог OpenMetadata при ingestion,
-- поэтому на каждую таблицу и колонку есть осмысленное описание.

-- ===== STG: сырой слой =====
CREATE TABLE IF NOT EXISTS stg.orders_raw (
    order_id      bigint,
    payload       jsonb,
    source_file   text,
    ingested_at   timestamptz
);
COMMENT ON TABLE  stg.orders_raw IS 'Сырые события заказов, как пришли из источника, без очистки.';
COMMENT ON COLUMN stg.orders_raw.order_id    IS 'Идентификатор заказа из источника.';
COMMENT ON COLUMN stg.orders_raw.payload     IS 'Исходный JSON события заказа целиком.';
COMMENT ON COLUMN stg.orders_raw.source_file IS 'Имя файла-источника, из которого загружена строка.';
COMMENT ON COLUMN stg.orders_raw.ingested_at IS 'Момент загрузки строки в stg-слой.';

-- ===== ODS: очищенный слой =====
CREATE TABLE IF NOT EXISTS ods.customers (
    customer_id   bigint PRIMARY KEY,
    full_name     text NOT NULL,
    email         text NOT NULL,
    country       text NOT NULL,
    signup_date   date NOT NULL
);
COMMENT ON TABLE  ods.customers IS 'Справочник клиентов после нормализации.';
COMMENT ON COLUMN ods.customers.customer_id   IS 'Суррогатный ключ клиента.';
COMMENT ON COLUMN ods.customers.full_name     IS 'Полное имя клиента.';
COMMENT ON COLUMN ods.customers.email         IS 'Email клиента.';
COMMENT ON COLUMN ods.customers.country       IS 'Страна клиента (ISO-код).';
COMMENT ON COLUMN ods.customers.signup_date   IS 'Дата регистрации клиента.';

CREATE TABLE IF NOT EXISTS ods.products (
    product_id       bigint PRIMARY KEY,
    name             text NOT NULL,
    category         text NOT NULL,
    unit_price_minor bigint NOT NULL,
    currency         text NOT NULL
);
COMMENT ON TABLE  ods.products IS 'Справочник товаров.';
COMMENT ON COLUMN ods.products.product_id        IS 'Суррогатный ключ товара.';
COMMENT ON COLUMN ods.products.name              IS 'Наименование товара.';
COMMENT ON COLUMN ods.products.category          IS 'Категория товара.';
COMMENT ON COLUMN ods.products.unit_price_minor  IS 'Цена за единицу в минорных единицах (копейки).';
COMMENT ON COLUMN ods.products.currency          IS 'Валюта цены.';

CREATE TABLE IF NOT EXISTS ods.orders (
    order_id      bigint PRIMARY KEY,
    customer_id   bigint NOT NULL REFERENCES ods.customers(customer_id),
    order_ts      timestamptz NOT NULL,
    status        text NOT NULL,
    paid_at       timestamptz,
    amount_minor  bigint NOT NULL,
    currency      text NOT NULL
);
COMMENT ON TABLE  ods.orders IS 'Очищенные заказы: одна строка на заказ.';
COMMENT ON COLUMN ods.orders.order_id     IS 'Ключ заказа.';
COMMENT ON COLUMN ods.orders.customer_id  IS 'Клиент, оформивший заказ.';
COMMENT ON COLUMN ods.orders.order_ts     IS 'Время оформления заказа.';
COMMENT ON COLUMN ods.orders.status       IS 'Статус заказа: paid / cancelled / refunded / pending.';
COMMENT ON COLUMN ods.orders.paid_at      IS 'Время фактической оплаты; NULL, если заказ не оплачен.';
COMMENT ON COLUMN ods.orders.amount_minor IS 'Сумма заказа в минорных единицах (копейки).';
COMMENT ON COLUMN ods.orders.currency     IS 'Валюта заказа.';

CREATE TABLE IF NOT EXISTS ods.order_items (
    order_item_id     bigint PRIMARY KEY,
    order_id          bigint NOT NULL REFERENCES ods.orders(order_id),
    product_id        bigint NOT NULL REFERENCES ods.products(product_id),
    quantity          int NOT NULL,
    line_amount_minor bigint NOT NULL
);
COMMENT ON TABLE  ods.order_items IS 'Позиции заказов.';
COMMENT ON COLUMN ods.order_items.order_item_id     IS 'Ключ позиции.';
COMMENT ON COLUMN ods.order_items.order_id          IS 'Заказ, к которому относится позиция.';
COMMENT ON COLUMN ods.order_items.product_id        IS 'Товар в позиции.';
COMMENT ON COLUMN ods.order_items.quantity          IS 'Количество единиц товара.';
COMMENT ON COLUMN ods.order_items.line_amount_minor IS 'Сумма по строке в минорных единицах (копейки).';

-- ===== DM: витрина данных =====
CREATE TABLE IF NOT EXISTS dm.orders_daily (
    order_date         date PRIMARY KEY,
    paid_orders_count  bigint NOT NULL,
    gross_amount_minor bigint NOT NULL,
    currency           text NOT NULL
);
COMMENT ON TABLE  dm.orders_daily IS 'Витрина: оплаченные заказы по дням.';
COMMENT ON COLUMN dm.orders_daily.order_date         IS 'Дата оплаты.';
COMMENT ON COLUMN dm.orders_daily.paid_orders_count  IS 'Число оплаченных заказов за дату.';
COMMENT ON COLUMN dm.orders_daily.gross_amount_minor IS 'Сумма оплаченных заказов в минорных единицах (копейки).';
COMMENT ON COLUMN dm.orders_daily.currency           IS 'Валюта.';
