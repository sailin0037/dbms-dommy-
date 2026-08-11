
# Product, Category, and Seller Inventory Management System

**Student Name:** Sriram  
**Register Number:** ASML2520  
**Project Domain:** Relational Database Management Systems (RDBMS)  
**Database Engine:** MySQL 8.0+ / MySQL Workbench  

---

## Table of Contents
1. [Project Overview](#1-project-overview)
2. [Database Architecture](#2-database-architecture)
3. [Data Integrity & Constraints](#3-data-integrity--constraints)
4. [Business Intelligence Reports](#4-business-intelligence-reports)
5. [Execution Instructions](#5-execution-instructions)
6. [Repository Structure](#6-repository-structure)

---

## 1. Project Overview

This project presents the design and implementation of a robust Relational Database Management System (RDBMS) tailored for an e-commerce retail environment. The system is engineered to manage product catalogs, product categories, seller profiles, and multi-vendor inventory levels. 

By leveraging strict relational mapping and ACID-compliant constraints, the database ensures high data integrity, prevents anomalous data entries, and automates referential consistency. The schema is normalized to eliminate data redundancy, linking specific products to multi-vendor inventory tracking using unique Stock Keeping Units (SKUs).

---

## 2. Database Architecture

The database (`inventory_db`) consists of four primary tables interconnected via One-to-Many (1:N) relationships. The architecture separates general product catalog information from specific warehouse/seller inventory data to maintain structural normalization.

| Table Name | Purpose | Primary Key | Key Foreign Keys |
| :--- | :--- | :--- | :--- |
| `categories` | Groups products into distinct classifications (e.g., Electronics). | `category_id` | None |
| `products` | Stores core product details, baseline pricing, and categorization. | `product_id` | `category_id` |
| `sellers` | Maintains vendor/supplier profiles and contact routing information. | `seller_id` | None |
| `inventory` | Tracks specific stock levels, SKUs, and reorder thresholds per seller. | `item_id` | `product_id`, `seller_id` |

### Entity-Relationship (ER) Diagram
An Entity-Relationship diagram was generated using MySQL Workbench's Reverse Engineering feature to visually map the foreign key constraints and table structures.

*(Note: Ensure the `er_diagram.png` is placed inside the `assets/` folder in the repository root).*

---

## 3. Data Integrity & Constraints

To enforce business rules at the database engine level, the following constraints are implemented:

* **Referential Integrity:** `ON DELETE CASCADE` and `ON UPDATE CASCADE` are applied to foreign keys. Deleting a category automatically removes associated products and their inventory records.
* **Domain Integrity:** `CHECK` constraints are utilized to prevent illogical data entry (e.g., `CHECK (price >= 0)` and `CHECK (stock_quantity >= 0)`).
* **Entity Integrity:** `UNIQUE` constraints are enforced on `category_name`, `store_name`, `contact_email`, and `sku` to prevent duplicate records.
* **Default Values:** Default timestamps (`CURRENT_TIMESTAMP`) and default stock levels (`DEFAULT 0`) are configured to ensure data consistency upon insertion.

---

## 4. Business Intelligence Reports

The SQL script concludes with four predefined analytical reports demonstrating complex data retrieval, aggregation, and filtering logic:

1. **Complete Product Catalog Report:** 
   - Retrieves all product details alongside their corresponding category names and calculates the total inventory value (`price * stock_quantity`) using an `INNER JOIN`.
2. **Category Summary Report:** 
   - Aggregates total product count, average price, total stock, and overall inventory value per category using `GROUP BY` and aggregate functions (`SUM`, `AVG`, `COUNT`).
3. **Low-Stock Inventory Alert:** 
   - Filters and displays products with a total stock quantity of less than 25 units, ordered by ascending stock to prioritize urgent restocking.
4. **Seller Inventory & Restock Alert:** 
   - A dynamic operational report that compares an item's current `stock_quantity` against its specific `reorder_level` to flag exactly which sellers need to restock which specific products.

---

## 5. Execution Instructions

To replicate and execute this database environment locally, follow these steps precisely:

1. **Prerequisites:** Ensure MySQL Server (8.0 or higher) and MySQL Workbench are installed on your local machine.
2. **Acquire Script:** Download the `inventory_system.sql` script from this repository.
3. **Load Environment:** Open MySQL Workbench and connect to your local MySQL instance.
4. **Open Script:** Navigate to `File > Open SQL Script` and select `inventory_system.sql`.
5. **Execute Safely:** 
   * **Important:** Do not execute the script line-by-line, as this will trigger `Error Code: 1046 (No database selected)`.
   * Execute the **entire script at once** by clicking the standard "Execute" button (lightning bolt icon) or by pressing `Ctrl + Shift + Enter` (Windows) / `Cmd + Shift + Enter` (Mac).
6. **Verify Output:** Refresh the Schemas panel on the left sidebar. Expand `inventory_db` to view the 4 tables. Execute the `SELECT` statements at the bottom of the script to view the analytical reports.

---

## 6. Repository Structure

The repository is organized cleanly to separate documentation, source code, and visual assets:

```text
product-category-db/
│
├── README.md                 # Project documentation and execution guide
├── inventory_system.sql      # Core SQL script (DDL, DML, Constraints, Reports)
└── assets/
    └── er_diagram.png        # Exported Entity-Relationship diagram from Workbench
