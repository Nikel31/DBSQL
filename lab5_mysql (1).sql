-- Лабораторная работа №5. 

CREATE DATABASE IF NOT EXISTS `shop_lab5`
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `shop_lab5`;

CREATE TABLE `employees` (
  `employee_id` INT NOT NULL AUTO_INCREMENT,
  `employee_name` VARCHAR(150) NOT NULL,
  `position` VARCHAR(100) NOT NULL,
  `phone` VARCHAR(30) NOT NULL,
  PRIMARY KEY (`employee_id`)
) ENGINE=InnoDB;

CREATE TABLE `payment_methods` (
  `method_id` INT NOT NULL AUTO_INCREMENT,
  `method_name` VARCHAR(80) NOT NULL,
  PRIMARY KEY (`method_id`), UNIQUE (`method_name`)
) ENGINE=InnoDB;

CREATE TABLE `categories` (
  `category_id` BIGINT NOT NULL AUTO_INCREMENT,
  `category_name` VARCHAR(100) NOT NULL,
  PRIMARY KEY (`category_id`), UNIQUE (`category_name`)
) ENGINE=InnoDB;

CREATE TABLE `manufacturers` (
  `manufacturer_id` BIGINT NOT NULL AUTO_INCREMENT,
  `manufacturer_name` VARCHAR(150) NOT NULL,
  PRIMARY KEY (`manufacturer_id`), UNIQUE (`manufacturer_name`)
) ENGINE=InnoDB;

CREATE TABLE `suppliers` (
  `supplier_id` INT NOT NULL AUTO_INCREMENT,
  `supplier_name` VARCHAR(150) NOT NULL,
  `inn` VARCHAR(12) NOT NULL,
  `phone` VARCHAR(30) NOT NULL,
  `email` VARCHAR(254) NOT NULL,
  `address` VARCHAR(255) NOT NULL,
  `bank_details` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`supplier_id`)
) ENGINE=InnoDB;

CREATE TABLE `clients` (
  `client_id` INT NOT NULL AUTO_INCREMENT,
  `client_name` VARCHAR(150) NOT NULL,
  `type` VARCHAR(50) NOT NULL,
  `phone` VARCHAR(30) NOT NULL,
  `email` VARCHAR(254) NOT NULL,
  `address` VARCHAR(255) NOT NULL,
  `details` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`client_id`)
) ENGINE=InnoDB;

CREATE TABLE `products` (
  `product_id` INT NOT NULL AUTO_INCREMENT,
  `article` VARCHAR(50) NOT NULL,
  `product_name` VARCHAR(150) NOT NULL,
  `unit` VARCHAR(30) NOT NULL,
  `specs` TEXT NOT NULL,
  `purchase_price` DECIMAL(10,2) NOT NULL,
  `retail_price` DECIMAL(10,2) NOT NULL,
  `category_id` BIGINT NOT NULL,
  `manufacturer_id` BIGINT NOT NULL,
  PRIMARY KEY (`product_id`), UNIQUE (`article`),
  CONSTRAINT `chk_product_purchase_price` CHECK (`purchase_price` >= 0),
  CONSTRAINT `chk_product_retail_price` CHECK (`retail_price` >= 0),
  CONSTRAINT `fk_products_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`category_id`),
  CONSTRAINT `fk_products_manufacturer` FOREIGN KEY (`manufacturer_id`) REFERENCES `manufacturers` (`manufacturer_id`)
) ENGINE=InnoDB;

CREATE TABLE `warehouse` (
  `product_id` INT NOT NULL,
  `curr_stock` INT NOT NULL DEFAULT 0,
  `min_stock` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`product_id`),
  CONSTRAINT `fk_warehouse_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE,
  CONSTRAINT `chk_warehouse_stock` CHECK (`curr_stock` >= 0 AND `min_stock` >= 0)
) ENGINE=InnoDB;

CREATE TABLE `receipts` (
  `receipt_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `receipt_date` DATE NOT NULL,
  `supplier_id` INT NOT NULL,
  `employee_id` INT NOT NULL,
  PRIMARY KEY (`receipt_id`),
  CONSTRAINT `fk_receipts_supplier` FOREIGN KEY (`supplier_id`) REFERENCES `suppliers` (`supplier_id`),
  CONSTRAINT `fk_receipts_employee` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`employee_id`)
) ENGINE=InnoDB;

CREATE TABLE `receipts_composition` (
  `receipt_id` INT UNSIGNED NOT NULL,
  `product_id` INT NOT NULL,
  `quantity` INT NOT NULL,
  `price` DECIMAL(10,2) NOT NULL,
  `total_amount` DECIMAL(12,2) GENERATED ALWAYS AS (`quantity` * `price`) STORED,
  PRIMARY KEY (`receipt_id`, `product_id`),
  CONSTRAINT `fk_receipt_items_receipt` FOREIGN KEY (`receipt_id`) REFERENCES `receipts` (`receipt_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_receipt_items_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`),
  CONSTRAINT `chk_receipt_quantity` CHECK (`quantity` > 0),
  CONSTRAINT `chk_receipt_price` CHECK (`price` >= 0)
) ENGINE=InnoDB;

CREATE TABLE `sales` (
  `sale_id` BIGINT NOT NULL AUTO_INCREMENT,
  `sale_date` DATE NOT NULL,
  `status` VARCHAR(30) NOT NULL,
  `employee_id` INT NOT NULL,
  `method_id` INT NOT NULL,
  `client_id` INT NULL,
  PRIMARY KEY (`sale_id`),
  CONSTRAINT `fk_sales_employee` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`employee_id`),
  CONSTRAINT `fk_sales_method` FOREIGN KEY (`method_id`) REFERENCES `payment_methods` (`method_id`),
  CONSTRAINT `fk_sales_client` FOREIGN KEY (`client_id`) REFERENCES `clients` (`client_id`)
) ENGINE=InnoDB;

CREATE TABLE `sales_composition` (
  `sale_id` BIGINT NOT NULL,
  `product_id` INT NOT NULL,
  `quantity` INT NOT NULL,
  `price` DECIMAL(10,2) NOT NULL,
  `total_amount` DECIMAL(12,2) GENERATED ALWAYS AS (`quantity` * `price`) STORED,
  PRIMARY KEY (`sale_id`, `product_id`),
  CONSTRAINT `fk_sale_items_sale` FOREIGN KEY (`sale_id`) REFERENCES `sales` (`sale_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_sale_items_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`),
  CONSTRAINT `chk_sale_quantity` CHECK (`quantity` > 0),
  CONSTRAINT `chk_sale_price` CHECK (`price` >= 0)
) ENGINE=InnoDB;

-- Демонстрационные данные.
INSERT INTO `employees` (`employee_name`, `position`, `phone`) VALUES
('Иван Петров', 'Менеджер', '+7-900-111-22-33'),
('Мария Соколова', 'Продавец', '+7-900-222-33-44'),
('Алексей Смирнов', 'Кладовщик', '+7-900-333-44-55');

INSERT INTO `payment_methods` (`method_name`) VALUES ('Наличные'), ('Банковская карта'), ('Перевод');
INSERT INTO `categories` (`category_name`) VALUES ('Рукава высокого давления'), ('Гидронасосы и гидромоторы'), ('Гидроцилиндры и уплотнения'), ('Гидравлическая техника');
INSERT INTO `manufacturers` (`manufacturer_name`) VALUES ('ГидроПром'), ('Bosch Rexroth'), ('Parker Hannifin'), ('Danfoss');
INSERT INTO `suppliers` (`supplier_name`,`inn`,`phone`,`email`,`address`,`bank_details`) VALUES
('ООО УралГидроСнаб', '6601000001', '+7-343-100-00-01', 'sales@uralhydro.example', 'Екатеринбург', 'р/с 40700000000000000001'),
('ООО ГидроКомплект', '6601000002', '+7-343-100-00-02', 'info@gidrokomplekt.example', 'Екатеринбург', 'р/с 40700000000000000002');
INSERT INTO `clients` (`client_name`,`type`,`phone`,`email`,`address`,`details`) VALUES
('ООО СтройМашСервис', 'Юридическое лицо', '+7-900-444-55-66', 'service@example.ru', 'Екатеринбург', 'Ремонт строительной техники'),
('ИП Васильев', 'Индивидуальный предприниматель', '+7-900-555-66-77', 'vasiliev@example.ru', 'Екатеринбург', 'Обслуживание спецтехники');

INSERT INTO `products` (`article`,`product_name`,`unit`,`specs`,`purchase_price`,`retail_price`,`category_id`,`manufacturer_id`) VALUES
('HOS-010','РВД 2SN DN10','м','Рабочее давление 330 бар, фитинги DKOL',850.00,1350.00,1,1),
('PMP-025','Гидронасос шестеренный 25 см³/об','шт.','Рабочее давление до 250 бар, вал цилиндрический',18500.00,24900.00,2,2),
('SEAL-080','Комплект уплотнений гидроцилиндра','компл.','Для цилиндра диаметром 80 мм, NBR/PU',1450.00,2390.00,3,3),
('JACK-10T','Домкрат гидравлический 10 т','шт.','Высота подхвата 230 мм, ход 150 мм',6200.00,8900.00,4,4);
INSERT INTO `warehouse` (`product_id`,`curr_stock`,`min_stock`) VALUES (1,120,30),(2,8,5),(3,24,6),(4,3,4);

INSERT INTO `receipts` (`receipt_date`,`supplier_id`,`employee_id`) VALUES
('2026-10-01',1,3),('2026-10-05',2,3);
INSERT INTO `receipts_composition` (`receipt_id`,`product_id`,`quantity`,`price`) VALUES
(1,1,100,12.00),(1,2,30,220.00),(2,3,10,650.00),(2,4,3,5200.00);

INSERT INTO `sales` (`sale_date`,`status`,`employee_id`,`method_id`,`client_id`) VALUES
('2026-10-10','Оплачена',2,1,2),('2026-10-12','Оплачена',1,2,1),('2026-10-15','В обработке',2,3,1);
INSERT INTO `sales_composition` (`sale_id`,`product_id`,`quantity`,`price`) VALUES
(1,1,5,25.00),(1,2,2,320.00),(2,3,2,990.00),(2,4,1,7990.00),(3,2,5,320.00);

ALTER TABLE `products` ADD COLUMN `description` VARCHAR(255) NULL AFTER `specs`;

START TRANSACTION;
UPDATE `warehouse` SET `curr_stock` = `curr_stock` + 1 WHERE `product_id` = 1;
DELETE FROM `clients` WHERE `client_id` = 999999;
ROLLBACK;

DESCRIBE `employees`;
DESCRIBE `payment_methods`;
DESCRIBE `categories`;
DESCRIBE `manufacturers`;
DESCRIBE `suppliers`;
DESCRIBE `clients`;
DESCRIBE `products`;
DESCRIBE `warehouse`;
DESCRIBE `receipts`;
DESCRIBE `receipts_composition`;
DESCRIBE `sales`;
DESCRIBE `sales_composition`;

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