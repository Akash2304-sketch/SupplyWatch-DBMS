-- SupplyWatch | Demonstration reports and test cases
USE supplywatch_db;

-- A. Inventory risks: STOCKOUT, REORDER NOW, WATCH, HEALTHY
SELECT * FROM v_inventory_risk
ORDER BY FIELD(risk_level, 'STOCKOUT','REORDER NOW','WATCH','HEALTHY'),
         current_stock ASC;

-- B. Supplier performance, computed from actual recorded deliveries
SELECT * FROM v_supplier_performance
ORDER BY on_time_percentage DESC, late_deliveries ASC;

-- C. Open purchase orders and estimated order value
SELECT * FROM v_open_purchase_orders
ORDER BY expected_date;

-- D. Inventory valuation by category
SELECT * FROM v_inventory_valuation
ORDER BY total_inventory_value DESC;

-- E. Products whose stock is at/below reorder level
SELECT p.sku, p.product_name, i.current_stock, p.reorder_level,
       s.supplier_name AS preferred_supplier
FROM Product p
JOIN Inventory i ON i.product_id = p.product_id
LEFT JOIN Supplier s ON s.supplier_id = p.preferred_supplier_id
WHERE i.current_stock <= p.reorder_level
ORDER BY i.current_stock;

-- F. Late deliveries
SELECT po.order_number, s.supplier_name, po.expected_date,
       d.delivered_date, DATEDIFF(d.delivered_date, po.expected_date) AS days_late
FROM Delivery d
JOIN Purchase_Order po ON po.order_id = d.order_id
JOIN Supplier s ON s.supplier_id = po.supplier_id
WHERE d.delivered_date > po.expected_date
ORDER BY days_late DESC;

-- G. Supplier order spend
SELECT s.supplier_name,
       ROUND(SUM(oi.quantity * oi.unit_price), 2) AS total_order_value
FROM Supplier s
JOIN Purchase_Order po ON po.supplier_id = s.supplier_id
JOIN Order_Item oi ON oi.order_id = po.order_id
WHERE po.order_status <> 'CANCELLED'
GROUP BY s.supplier_id, s.supplier_name
ORDER BY total_order_value DESC;

-- H. Inventory transaction audit trail
SELECT it.transaction_id, p.sku, p.product_name, it.transaction_type,
       it.quantity, it.transaction_date, it.reference_type, it.reference_id
FROM Inventory_Transaction it
JOIN Product p ON p.product_id = it.product_id
ORDER BY it.transaction_date DESC, it.transaction_id DESC;

-- I. TEST: successful stock issue; product 2 should decrease by 2.
SELECT current_stock AS stock_before_test FROM Inventory WHERE product_id = 2;
CALL sp_record_stock_issue(2, 2, 'Demo test: issue two wireless mice');
SELECT current_stock AS stock_after_test FROM Inventory WHERE product_id = 2;

-- J. TEST: receive 10 units of product 4 against order 3.
-- Run only once; the procedure correctly prevents over-receipt.
CALL sp_receive_order(3, 4, 10, CURRENT_DATE);
SELECT po.order_number, po.order_status, oi.quantity, oi.received_quantity,
       i.current_stock
FROM Purchase_Order po
JOIN Order_Item oi ON oi.order_id = po.order_id
JOIN Inventory i ON i.product_id = oi.product_id
WHERE po.order_id = 3 AND oi.product_id = 4;

-- K. TEST: transaction rollback / constraint demonstration.
-- The following statement is intentionally commented out because it should fail:
-- CALL sp_record_stock_issue(5, 99999, 'Expected failure: insufficient stock');

-- L. Row counts for a quick smoke test
SELECT 'Supplier' AS table_name, COUNT(*) AS rows_loaded FROM Supplier
UNION ALL SELECT 'Product', COUNT(*) FROM Product
UNION ALL SELECT 'Inventory', COUNT(*) FROM Inventory
UNION ALL SELECT 'Purchase_Order', COUNT(*) FROM Purchase_Order
UNION ALL SELECT 'Order_Item', COUNT(*) FROM Order_Item
UNION ALL SELECT 'Delivery', COUNT(*) FROM Delivery
UNION ALL SELECT 'Inventory_Transaction', COUNT(*) FROM Inventory_Transaction
UNION ALL SELECT 'Supplier_Evaluation', COUNT(*) FROM Supplier_Evaluation;
