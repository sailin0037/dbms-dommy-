
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

## 4. Inventory Reports

The SQL scripts in this module include analytical queries designed for supply chain and operations management:

1. **Seller Inventory & Restock Alert Report:** 
   - A dynamic operational report that compares an item's current `stock_quantity` against its specific `reorder_level`. It flags exactly which sellers need to restock which specific products, ordered by the most urgent shortages first.

---

## 5. Files in this Directory


inventory/
│
├── README.md                 # This documentation file
└── inventory_queries.sql     # SQL scripts specific to schema creation, dummy data, and reports for the inventory module

Here some reports 

report 1 
<img width="839" height="567" alt="image" src="https://github.com/user-attachments/assets/ea177a31-35c0-49b8-b4ec-66c429355c91" />

report 2
<img width="754" height="559" alt="image" src="https://github.com/user-attachments/assets/b9ab66b8-6898-4634-99c0-be9784929105" />

report 3 
<img width="555" height="309" alt="image" src="https://github.com/user-attachments/assets/d9ec700f-9ffc-4626-995a-b8e73a6675f7" />

report 4
<img width="962" height="103" alt="image" src="https://github.com/user-attachments/assets/167b0503-675e-4d05-851a-b844995326cb" />


