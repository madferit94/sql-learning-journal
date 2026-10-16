-- Schema only; obtain source data separately. CREATE DATABASE requires an unused database name.
SET NAMES utf8mb4;
SET SESSION sql_mode='STRICT_ALL_TABLES,NO_BACKSLASH_ESCAPES';
CREATE DATABASE retail_study CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
USE retail_study;
CREATE TABLE invoice_headers (
invoice_header_id INT NOT NULL PRIMARY KEY,
invoice_no VARCHAR(20) NOT NULL,
invoice_date DATETIME NOT NULL,
customer_id VARCHAR(20) NULL,
country VARCHAR(100) NOT NULL,
INDEX (invoice_no), INDEX (customer_id)
) ENGINE=InnoDB;
CREATE TABLE invoice_items (
source_row_id INT NOT NULL PRIMARY KEY,
invoice_header_id INT NOT NULL,
invoice_no VARCHAR(20) NOT NULL,
stock_code VARCHAR(30) NOT NULL,
description VARCHAR(500) NULL,
quantity INT NOT NULL,
invoice_date DATETIME NOT NULL,
unit_price DECIMAL(16,6) NOT NULL,
customer_id VARCHAR(20) NULL,
country VARCHAR(100) NOT NULL,
FOREIGN KEY (invoice_header_id) REFERENCES invoice_headers(invoice_header_id),
INDEX (invoice_no), INDEX (customer_id), INDEX (stock_code)
) ENGINE=InnoDB;

CREATE VIEW sales_items AS
SELECT * FROM invoice_items
WHERE quantity > 0 AND unit_price > 0 AND invoice_no NOT LIKE 'C%';
