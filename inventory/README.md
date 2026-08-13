
# Inventory Management Sub-System

**Student Name:** Sriram  
**Register Number:** ASML2520  
**Component Type:** Relational Database Sub-Module  

---

## 1. Overview

This directory contains the SQL scripts and logic for the **Inventory Management** sub-system of the e-commerce database. While the broader project handles general product catalogs and categories, this specific module tracks multi-vendor stock levels, Stock Keeping Units (SKUs), warehouse locations, and automated restock thresholds.

The system links specific products to registered sellers, allowing the platform to track exactly who is supplying what, how many units are currently available, and when a seller needs to be notified to restock.

---

## 2. Database Schema (Inventory Context)

This sub-system relies on two primary tables to manage vendor inventory independently of the main catalog pricing. 

| Table Name | Purpose | Key Constraints |
| :--- | :--- | :--- |
| `sellers` | Stores vendor/supplier profiles and contact routing info. | `seller_id` (Primary Key), `store_name` (Unique), `contact_email` (Unique) |
| `inventory` | Tracks specific stock levels, SKUs, and reorder thresholds per seller. | `item_id` (Primary Key), `product_id` (Foreign Key), `seller_id` (Foreign Key), `sku` (Unique) |

### Entity Relationships
* **Sellers to Inventory:** One-to-Many (1:N) - A single seller can supply multiple distinct inventory items.
* **Products to Inventory:** One-to-Many (1:N) - A single product catalog entry can be linked to multiple inventory records if multiple sellers supply the same item.
* *Note: `ON DELETE CASCADE` is applied to foreign keys linking back to both `products` and `sellers` to ensure orphaned inventory records are never created.*

---

## 3. Data Integrity & Business Rules

To enforce operational logic at the database engine level, the following constraints are implemented:

* **Unique Tracking:** Every inventory item must possess a unique `sku` (Stock Keeping Unit) to prevent duplicate vendor listings for the exact same item.
* **Domain Integrity:** `CHECK` constraints are utilized to ensure stock quantities and unit prices cannot be negative.
* **Automated Restock Logic:** The `reorder_level` column (defaulting to 10) is evaluated against the current `stock_quantity` to generate dynamic restock alerts without requiring manual monitoring.
* **Timestamping:** The `last_restocked` column automatically records the exact timestamp of the last inventory update, ensuring full auditability for supply chain tracking.

---

## 4. Inventory Reports & Outputs

The SQL scripts in this module include analytical queries designed for supply chain and operations management. Below are the executed results from MySQL Workbench:

### Report 1: Complete Product Catalog Report
Retrieves all product details alongside their corresponding category names and calculates the total inventory value.
<img width="839" height="567" alt="Report 1 Output" src="https://github.com/user-attachments/assets/ea177a31-35c0-49b8-b4ec-66c429355c91" />

### Report 2: Category Summary Report
Aggregates total product count, average price, total stock, and overall inventory value per category.
<img width="754" height="559" alt="Report 2 Output" src="https://github.com/user-attachments/assets/b9ab66b8-6898-4634-99c0-be9784929105" />

### Report 3: Low-Stock Inventory Alert Report
Filters and displays products with a total stock quantity of less than 25 units, ordered by ascending stock.
<img width="555" height="309" alt="Report 3 Output" src="https://github.com/user-attachments/assets/d9ec700f-9ffc-4626-995a-b8e73a6675f7" />

### Report 4: Seller Inventory & Restock Alert Report
A dynamic operational report that compares an item's current `stock_quantity` against its specific `reorder_level`. It flags exactly which sellers need to restock which specific products.
<img width="962" height="103" alt="Report 4 Output" src="https://github.com/user-attachments/assets/167b0503-675e-4d05-851a-b844995326cb" />

---

## 5. Files in this Directory

```text
inventory/
│
├── README.md                 # Project documentation and execution guide
└── inventory_queries.sql     # SQL scripts specific to schema creation, dummy data, and reports
```
```

