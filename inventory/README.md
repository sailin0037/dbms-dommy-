
# Product, Category, and Seller Inventory Management System

**Student Name:** Sriram  
**Register Number:** ASML2520  
**Project Type:** Relational Database Management System (RDBMS) Project  

---

## 1. Project Overview

This project demonstrates the design and implementation of a relational database for an e-commerce inventory environment. The system is built using MySQL Workbench and focuses on managing product catalogs, product categories, seller profiles, and multi-vendor inventory levels. 

The database enforces strict data integrity through primary and foreign key constraints, check constraints for non-negative pricing and stock, and cascading deletions to maintain relational consistency. It also includes analytical SQL queries to generate business-critical reports, such as low-stock alerts and category-wise sales summaries.

---

## 2. Database Schema Design

The database (`inventory_db`) consists of four primary tables. The schema is normalized to reduce data redundancy, particularly by linking the `inventory` table directly to both `products` and `sellers`.

| Table Name | Description | Key Constraints Implemented |
| :--- | :--- | :--- |
| `categories` | Stores product groupings. | `category_id` (Primary Key), `category_name` (Unique) |
| `products` | Stores individual product details. | `product_id` (Primary Key), `category_id` (Foreign Key), `CHECK (price >= 0)` |
| `sellers` | Stores vendor/supplier details. | `seller_id` (Primary Key), `store_name` (Unique), `contact_email` (Unique) |
| `inventory` | Tracks stock levels per seller per product. | `item_id` (Primary Key), `product_id` (Foreign Key), `seller_id` (Foreign Key), `sku` (Unique) |

### Entity Relationships
* **Categories to Products:** One-to-Many (1:N)
* **Sellers to Inventory:** One-to-Many (1:N)
* **Products to Inventory:** One-to-Many (1:N)
* *Note: `ON DELETE CASCADE` is applied to foreign keys to ensure that deleting a category automatically removes its associated products and inventory items.*

---

## 3. Analytical Reports

The SQL script concludes with four predefined reports to demonstrate data retrieval and aggregation:

1. **Complete Product Catalog:** Retrieves all product details alongside their category names and total inventory value using `INNER JOIN`.
2. **Category Summary Report:** Aggregates total product count, average price, total stock, and total inventory value per category using `GROUP BY` and aggregate functions (`SUM`, `AVG`, `COUNT`).
3. **Low-Stock Inventory Alert:** Filters and displays products with a total stock quantity of less than 25 units.
4. **Seller Inventory & Restock Alert:** A dynamic report comparing an item's current `stock_quantity` against its `reorder_level` to flag specific seller inventories that require restocking.

---

## 4. Execution Instructions

To execute this database script locally, please follow these steps:

1. **Prerequisites:** Ensure MySQL Server and MySQL Workbench are installed and running on your machine.
2. **Download Files:** Download the `inventory_system.sql` script from this repository.
3. **Open MySQL Workbench:** Connect to your local MySQL instance.
4. **Load Script:** Go to `File > Open SQL Script` and select `inventory_system.sql`.
5. **Execute:** 
   * To prevent SQL execution errors (such as Error Code 1046: No Database Selected), execute the **entire script at once** rather than line-by-line. 
   * Click the standard "Execute" button (lightning bolt icon) or press `Ctrl + Shift + Enter`.
6. **Verify:** Refresh the schemas panel to view `inventory_db`. Expand the tables to verify that the schema and dummy data have been populated successfully.

---

## 5. Folder Structure

The repository is structured as follows:

```text
product-category-db/
│
├── README.md                 # Project documentation
├── inventory_system.sql      # MySQL database script (Schema, Data, Reports)
└── assets/
    └── er_diagram.png        # Entity-Relationship diagram exported from Workbench
```

---

## 6. Technologies Used

* **Database Engine:** MySQL 8.0+
* **Database Design Tool:** MySQL Workbench
* **Query Language:** SQL (DDL, DML, DQL)
```

