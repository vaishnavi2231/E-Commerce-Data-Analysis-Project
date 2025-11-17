
-- Creating a schema.sql to load the table into db
-- Create schema for the project
CREATE SCHEMA IF NOT EXISTS olist;

-- Use this schema for all tables
SET search_path TO olist;

-- 1. ---------CUSTOMERS TABLE-----------

CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50) NOT NULL,
    customer_zip_code_prefix INT NOT NULL,
    customer_city VARCHAR(100) NOT NULL,
    customer_state CHAR(2) NOT NULL CHECK (customer_state ~ '^[A-Z]{2}$')
);



-- 2. ---------SELLERS TABLE---------

CREATE TABLE sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix INT NOT NULL,
    seller_city VARCHAR(100) NOT NULL,
    seller_state CHAR(2) NOT NULL CHECK (seller_state ~ '^[A-Z]{2}$')
);


-- 3. ---------GEOLOCATION TABLE---------
-- (Stand-alone lookup table; not every ZIP is unique)

CREATE TABLE geolocation (
    geolocation_id SERIAL PRIMARY KEY,
    geolocation_zip_code_prefix INT NOT NULL,
    geolocation_lat DECIMAL(15,12) NOT NULL,
    geolocation_lng DECIMAL(15,12) NOT NULL,
    geolocation_city VARCHAR(100) NOT NULL,
    geolocation_state CHAR(2) NOT NULL CHECK (geolocation_state ~ '^[A-Z]{2}$')
);


-- 4. ---------PRODUCT CATEGORY TRANSLATION---------

CREATE TABLE product_category_translation (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100) NOT NULL
);



-- 5. ---------PRODUCTS TABLE---------

CREATE TABLE products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_length INT,
    product_description_length INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT,

    FOREIGN KEY (product_category_name)
        REFERENCES product_category_translation(product_category_name)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);



-- 6. ---------ORDERS TABLE---------
-- 
CREATE TABLE orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50) NOT NULL,
    order_status VARCHAR(20) NOT NULL,
    order_purchase_timestamp TIMESTAMP NOT NULL,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP NOT NULL,

    FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);



-- 7. ---------ORDER ITEMS --------
-- Weak Entity with shared primary key of Orders

CREATE TABLE order_items (
    order_id VARCHAR(50) NOT NULL,
    order_item_id INT NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    seller_id VARCHAR(50) NOT NULL,
    shipping_limit_date TIMESTAMP NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    freight_value DECIMAL(10,2) NOT NULL,

    PRIMARY KEY (order_id, order_item_id),

    FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    FOREIGN KEY (seller_id)
        REFERENCES sellers(seller_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);


-- 8. ---------ORDER PAYMENTS ---------
-- (Weak Entity)

CREATE TABLE order_payments (
    order_id VARCHAR(50) NOT NULL,
    payment_sequential INT NOT NULL,
    payment_type VARCHAR(20) NOT NULL,
    payment_installments INT NOT NULL,
    payment_value DECIMAL(10,2) NOT NULL,

    PRIMARY KEY (order_id, payment_sequential),

    FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);


-- 9. ---------ORDER REVIEWS---------

CREATE TABLE order_reviews (
    review_id VARCHAR(50) PRIMARY KEY,
    order_id VARCHAR(50) NOT NULL,
    review_score INT CHECK (review_score BETWEEN 1 AND 5),
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP,

    FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);


CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
CREATE INDEX idx_order_items_seller_id ON order_items(seller_id);
CREATE INDEX idx_payments_order_id ON order_payments(order_id);
CREATE INDEX idx_reviews_order_id ON order_reviews(order_id);
CREATE INDEX idx_products_category_name ON products(product_category_name);
CREATE INDEX idx_customers_zip ON customers(customer_zip_code_prefix);
CREATE INDEX idx_sellers_zip ON sellers(seller_zip_code_prefix);
CREATE INDEX idx_geo_zip ON geolocation(geolocation_zip_code_prefix);

