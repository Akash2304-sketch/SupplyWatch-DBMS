# SupplyWatch
## Supplier Performance & Inventory Risk Intelligence System

**Type:** DBMS mini-project / portfolio SQL project  
**Database:** MySQL 8.0+ (InnoDB, utf8mb4)  
**Application interface:** SQL only  
**Dataset:** Synthetic demo data; not production or real supplier information.

## Problem statement
Businesses need to track stock availability, purchase orders, supplier delivery reliability, and possible stockout risks. SupplyWatch provides a relational data model and SQL-based reporting to support these activities.

## Features
- Supplier and product master data
- Inventory balance and movement ledger
- Purchase orders and line items
- Delivery status derived from expected and actual dates
- Inventory risk classification (`STOCKOUT`, `REORDER NOW`, `WATCH`, `HEALTHY`)
- Supplier on-time delivery metrics from recorded deliveries
- Inventory valuation and open-order reports
- Stored procedures for receiving goods and issuing stock
- Transactions, rollback-on-error, constraints, foreign keys, and indexes
- Views for reusable reporting

## Requirements
- MySQL Server 8.0 or newer
- MySQL Workbench or MySQL CLI
- Use a development database only: the schema script drops project tables before recreating them.

## Setup (recommended order)
1. Open MySQL Workbench and connect to your local server.
2. Run `01_schema.sql`.
3. Run `02_seed_data.sql`.
4. Run `03_views.sql`.
5. Run `04_triggers.sql`.
6. Run `05_procedures.sql`.
7. Run selected report queries from `06_reports_and_tests.sql`.

Run each file completely. Some clients require enabling execution of all statements in a script. In MySQL Workbench, open the file and click the lightning-bolt execute button.

## Quick smoke test
After setup:
```sql
USE supplywatch_db;
SHOW TABLES;
SELECT * FROM v_inventory_risk;
SELECT * FROM v_supplier_performance;
SELECT * FROM v_open_purchase_orders;
```
Expected base row counts after seeding: 5 suppliers, 8 products, 8 inventory rows, 7 purchase orders, 11 order items, 7 delivery records, 8 inventory opening-balance transactions, 5 supplier evaluations.

## Test stored procedures
**Warning:** these tests change demo data. Run against your local demo database only.

```sql
-- Issue 2 units from product 2 (wireless mouse)
CALL sp_record_stock_issue(2, 2, 'Demo stock issue');

-- Receive 10 units of product 4 against purchase order 3
CALL sp_receive_order(3, 4, 10, CURRENT_DATE);

-- Check updated stock and order status
SELECT * FROM Inventory WHERE product_id = 4;
SELECT * FROM Purchase_Order WHERE order_id = 3;
SELECT * FROM Order_Item WHERE order_id = 3;
```
`sp_receive_order` prevents receipt quantities exceeding the quantity ordered and rolls back if an error occurs. Re-running the same receive call will add another 10 units until the order quantity is fully received; it will then reject further receipt attempts.

## Data model
- Supplier 1—N Purchase_Order
- Supplier 1—N Product (as preferred supplier, optional)
- Product 1—1 Inventory
- Purchase_Order 1—N Order_Item
- Product 1—N Order_Item
- Purchase_Order 1—0..1 Delivery
- Product 1—N Inventory_Transaction
- Supplier 1—N Supplier_Evaluation

## Important implementation notes
- The demo schema is designed for a student project, not production deployment.
- Delivery is simplified to one delivery record per order. A real system that supports multiple partial shipments should use a separate delivery header and delivery-item table.
- The opening balance rows in `Inventory_Transaction` document the opening inventory; they do not recalculate the seeded inventory balance.
- Inventory mutations should be performed through the provided stored procedures to keep the stock balance and movement ledger aligned.
- The trigger recalculates delivery status based on the actual delivery date and expected date. It does not manage inventory itself.
- `Supplier_Evaluation` supports dated/manual evaluation snapshots. The live supplier performance view is calculated from delivery records and should be preferred for current on-time metrics.
- All sample records are fictional and intended only for testing.

## Resume-ready description (edit to reflect your actual work)
**SupplyWatch — Supplier Performance & Inventory Risk Intelligence System | MySQL**
Designed a normalized relational database for supplier, product, inventory, purchase-order, delivery, and stock-movement data. Implemented referential integrity, constraints, indexes, SQL views, and transactional stored procedures to track stock issues and receipts. Built reporting queries for inventory risk classification, supplier on-time delivery rates, late orders, open purchase orders, and inventory valuation.

## Suggested team split
- Member 1: ER diagram, relational schema, normalization, keys and constraints
- Member 2: sample data, joins, aggregations, reporting queries and views
- Member 3: stored procedures, transactions, triggers and test cases
- Member 4 (if applicable): documentation, validation, demo script and viva preparation

Every member should understand the overall schema, not only their assigned section.

## Suggested viva topics
1. Why is `Order_Item` a separate table?
2. Difference between primary key, unique key and foreign key.
3. Why use InnoDB?
4. What does normalization prevent?
5. Difference between a view and a table.
6. What is an index and what is its trade-off?
7. Why use a transaction in stock receipt?
8. How does the procedure prevent over-receipt?
9. How is on-time delivery percentage calculated?
10. What are the limitations of the one-delivery-per-order model?

## Suggested future enhancements
- Multiple deliveries and partial shipments
- Role-based access and audit users
- Forecasting demand using historical consumption
- Supplier risk score combining delays, quality issues and lead-time variability
- Automated reorder recommendations based on lead time and average demand
- A Python or web UI if the assignment permits it
