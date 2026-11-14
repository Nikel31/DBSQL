-- часть 2 select 
-- 1 закупщик

SELECT
    p.article,
    p.product_name,
    c.category_name,
    p.specs,
    p.retail_price,
    w.curr_stock
FROM products p
JOIN categories c
    ON p.category_id = c.category_id
JOIN warehouse w
    ON p.product_id = w.product_id
WHERE w.curr_stock > 0
ORDER BY p.product_name;

-- 2 прождажник

SELECT
    sup.supplier_name,
    r.receipt_id,
    r.receipt_date,
    p.product_name,
    rc.quantity,
    rc.price AS purchase_price,
    rc.total_amount
FROM suppliers sup
JOIN receipts r
    ON sup.supplier_id = r.supplier_id
JOIN receipts_composition rc
    ON r.receipt_id = rc.receipt_id
JOIN products p
    ON rc.product_id = p.product_id
ORDER BY r.receipt_date DESC;

-- 3 кладовщик (остатки)

SELECT
    p.article,
    p.product_name,
    c.category_name,
    p.unit,
    w.curr_stock,
    w.min_stock
FROM warehouse w
JOIN products p
    ON w.product_id = p.product_id
JOIN categories c
    ON p.category_id = c.category_id
ORDER BY p.product_name;

-- 4 директор (топ 10 по продажам)

SELECT
    p.article,
    p.product_name,
    SUM(sc.quantity) AS sold_quantity,
    SUM(sc.total_amount) AS total_revenue
FROM products p
JOIN sales_composition sc
    ON p.product_id = sc.product_id
JOIN sales s
    ON sc.sale_id = s.sale_id
WHERE s.status = 'Оплачена'
GROUP BY
    p.product_id,
    p.article,
    p.product_name
ORDER BY sold_quantity DESC
LIMIT 10;

--ПОДЗАПРОСЫ

-- IN (менеджер по продажам | выводит список клиентов, у которых есть хотя бы одна продажа.)

SELECT client_id, client_name, phone
FROM `clients`
WHERE client_id IN (
    SELECT client_id FROM `sales` WHERE client_id IS NOT NULL
    )
ORDER BY client_name;

-- ALL (руководитель | товары дороже всех товаров категории «Рукава»)

SELECT product_name, retail_price
FROM `products`
WHERE retail_price > ALL (
        SELECT retail_price FROM `products` WHERE category_id = 1
);

-- CASE (кладовщик | статус остатка)

SELECT p.product_name,
       w.curr_stock,
       w.min_stock,
       CASE
           WHEN w.curr_stock < w.min_stock        THEN 'Мало'
           WHEN w.curr_stock > w.min_stock * 3    THEN 'Много'
           ELSE 'Норма'
       END AS stock_status
FROM   `warehouse` w
JOIN   `products` p ON p.product_id = w.product_id;

-- IF (менеджер по продажам | помечает клиента как «постоянного»)

SELECT client_name,
       COUNT(sale_id) AS sales_count,
       IF(COUNT(sale_id) > 1, 'Постоянный', 'Разовый') AS segment
FROM   `clients` c
LEFT JOIN `sales` s ON s.client_id = c.client_id
GROUP BY c.client_id, client_name;

-- CREATE VIEW (кладовщик | создаёт виртуальную таблицу с остатками)

CREATE OR REPLACE VIEW `v_warehouse` AS
SELECT p.product_name, w.curr_stock, w.min_stock
FROM   `warehouse` w
JOIN   `products` p ON p.product_id = w.product_id;

-- Использование:
SELECT * FROM `v_warehouse` WHERE curr_stock < min_stock;

-- WITH (Руководитель | сначала считает выручку по сотрудникам, потом фильтрует.)

WITH `emp_sales` AS (
    SELECT e.employee_name, SUM(sc.total_amount) AS revenue
    FROM   `employees` e
    JOIN   `sales` s ON s.employee_id = e.employee_id
    JOIN   `sales_composition` sc ON sc.sale_id = s.sale_id
    GROUP BY e.employee_id, e.employee_name
)
SELECT employee_name, revenue
FROM   `emp_sales`
WHERE  revenue > 1000
ORDER BY revenue DESC;

-- EXPLAIN и CREATE INDEX 

-- запрос до оптимизации
EXPLAIN
SELECT client_id, client_name, phone
FROM   clients
WHERE  client_name = 'ООО СтройМашСервис';

-- создаем индекс
CREATE INDEX idx_clients_name ON clients(client_name);

-- запрос после оптимизации
EXPLAIN
SELECT client_id, client_name, phone
FROM   clients
WHERE  client_name = 'ООО СтройМашСервис';

-- START TRANSACTION (Менеджер по продажам | атомарно создаёт продажу и уменьшает остаток)

START TRANSACTION;

INSERT INTO `sales` (`sale_date`, `status`, `employee_id`, `method_id`, `client_id`)
VALUES ('2026-11-07', 'Оплачена', 2, 2, 1);

UPDATE `warehouse`
SET    `curr_stock` = `curr_stock` - 1
WHERE  `product_id` = 1;

COMMIT;

-- PREPARE / EXECUTE / DEALLOCATE (Менеджер по продажам | шаблон запроса с параметрами — категория и лимит)

PREPARE `stmt_find` FROM
    'SELECT product_name, retail_price, curr_stock
     FROM   `products` p
     JOIN   `warehouse` w ON w.product_id = p.product_id
     WHERE  category_id = ? AND curr_stock > 0
     LIMIT ?';

SET @cat = 2;
SET @lim = 5;

EXECUTE `stmt_find` USING @cat, @lim;

DEALLOCATE PREPARE `stmt_find`;