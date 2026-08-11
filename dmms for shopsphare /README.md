
# ShopSphere E-Commerce Retail Database System

**Student Name:** Sriram  
**Register Number:** ASML2520  
**Project Type:** Advanced Relational Database Management System (RDBMS)  

---

## 1. Project Overview

ShopSphere is a comprehensive e-commerce retail database designed to manage real-time transactional data, user profiles, product catalogs, and complex order lifecycles. This project translates strict business requirements into a robust MySQL schema, emphasizing ACID (Atomicity, Consistency, Isolation, Durability) compliance, role-based security boundaries, and data privacy regulations.

Unlike standard CRUD applications, this system handles complex operational logic such as concurrent inventory locking, historic price preservation, and soft-deletion of user data for financial auditing.

---

## 2. Core Business Domains

The database schema is divided into four primary functional modules:

| Module | Description | Key Tables |
| :--- | :--- | :--- |
| **User Management** | Handles customer profiles, roles, and multiple shipping addresses. | `Users`, `Addresses` |
| **Product Catalog** | Manages inventory, categories, suppliers, and customer reviews. | `Products`, `Categories`, `Suppliers`, `ProductReviews` |
| **Order Lifecycle** | Core transaction engine managing carts, orders, and historic pricing. | `Orders`, `OrderItems` |
| **Payments & Shipping** | Manages 1:1 payment verification and logistics tracking. | `Payments`, `Shipments`, `AuditLogs` |

---

## 3. Advanced Database Features

### A. ACID Concurrency Control (Isolation)
To prevent overselling during simultaneous checkouts, the system utilizes a `SafeCheckout` stored procedure. It implements row-level locking using `SELECT ... FOR UPDATE`. If two users attempt to purchase the last available item at the same millisecond, the first transaction locks the row, processes the payment, and deducts the stock. The second transaction gracefully fails and rolls back.

### B. Historic Price Rule
The `OrderItems` table records the `UnitPrice` at the exact second of purchase. If a product's price changes in the future, past order receipts remain mathematically unchanged, ensuring accurate financial auditing.

### C. Privacy Compliance (Safe Deletion)
In compliance with data privacy regulations, user accounts cannot be hard-deleted. The `AnonymizeUser` stored procedure performs a "soft delete" by setting the `AccountStatus` to 'Inactive' and blanking out Personally Identifiable Information (PII) such as email and phone numbers, while preserving historical order data via `ON DELETE NO ACTION` constraints.

---

## 4. Business Intelligence Reports

The system includes predefined analytical queries to assist management:
1. **Low-Inventory Restock Alerts:** Identifies products with stock <= 10 units, joining product, category, and supplier data.
2. **VIP Customer Loyalty Report:** Retrieves the top 50 customers ranked by total successful order volume over the past 12 months.
3. **Category Sales Performance:** Calculates total revenue, items sold, and average review ratings per category.

---

## 5. Execution & Verification

The SQL script was successfully executed in MySQL Workbench without errors. The database schema, stored procedures, dummy data, and analytical reports were validated. 

Below are the execution logs and output screenshots verifying the successful creation and population of the ShopSphere database:

### Execution Log
![Execution Log - Database Created](assets/screenshot_1.png)

### Schema & Data Verification
![Schema and Data Verification](assets/screenshot_2.png)

### Report Outputs
![Analytical Report Outputs](assets/screenshot_3.png)


## 6. Repository Structure

shopsphere/
│
├── README.md                 # Project documentation (This file)
├── shopsphere.sql            # Core MySQL script (Schema, Procedures, Data, Reports)

   
