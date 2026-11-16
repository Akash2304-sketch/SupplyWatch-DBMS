-- SupplyWatch | Deterministic demo data
USE supplywatch_db;
START TRANSACTION;

INSERT INTO Supplier
(supplier_id, supplier_name, contact_person, phone, email, address, standard_lead_days, supplier_status)
VALUES
(1,'Northstar Industrial Supplies','Meera Rao','9000000001','meera@northstar.example','Bengaluru, Karnataka',4,'ACTIVE'),
(2,'Apex Components Pvt Ltd','Rahul Nair','9000000002','rahul@apex.example','Mysuru, Karnataka',7,'ACTIVE'),
(3,'GreenRoute Packaging','Sana Khan','9000000003','sana@greenroute.example','Chennai, Tamil Nadu',5,'ACTIVE'),
(4,'Metro Office Systems','Vikram Das','9000000004','vikram@metro.example','Hyderabad, Telangana',10,'ACTIVE'),
(5,'Legacy Parts Co','Nithin Shetty','9000000005','nithin@legacy.example','Pune, Maharashtra',12,'INACTIVE');

INSERT INTO Product
(product_id, sku, product_name, category, unit_price, reorder_level, preferred_supplier_id, active)
VALUES
(1,'CAB-USB-C','USB-C Cable','Electronics',249.00,25,1,TRUE),
(2,'MOU-WL-01','Wireless Mouse','Electronics',699.00,15,2,TRUE),
(3,'PPR-A4-500','A4 Paper Ream','Stationery',285.00,40,4,TRUE),
(4,'BOX-MED-20','Medium Shipping Box','Packaging',42.00,100,3,TRUE),
(5,'SSD-1TB','1 TB SSD','Electronics',5499.00,8,2,TRUE),
(6,'LBL-ROLL','Shipping Label Roll','Packaging',175.00,20,3,TRUE),
(7,'KEY-MECH','Mechanical Keyboard','Electronics',1899.00,10,1,TRUE),
(8,'PEN-BLUE-10','Blue Pen Pack','Stationery',95.00,30,4,TRUE);

INSERT INTO Inventory (product_id, current_stock) VALUES
(1,18),(2,32),(3,12),(4,145),(5,5),(6,9),(7,14),(8,55);

INSERT INTO Purchase_Order
(order_id, order_number, supplier_id, order_date, expected_date, order_status, notes)
VALUES
(1,'SW-PO-1001',1,'2026-09-01','2026-09-05','COMPLETED','USB cables and keyboards'),
(2,'SW-PO-1002',2,'2026-09-03','2026-09-10','COMPLETED','Mouse and SSD replenishment'),
(3,'SW-PO-1003',3,'2026-09-07','2026-09-12','PLACED','Packaging restock'),
(4,'SW-PO-1004',4,'2026-09-10','2026-09-20','PARTIALLY_RECEIVED','Stationery replenishment'),
(5,'SW-PO-1005',2,'2026-09-15','2026-09-22','PLACED','Urgent SSD purchase'),
(6,'SW-PO-1006',1,'2026-09-20','2026-09-24','COMPLETED','Cable restock'),
(7,'SW-PO-1007',3,'2026-09-25','2026-09-30','CANCELLED','Cancelled due to changed demand');

INSERT INTO Order_Item (order_id, product_id, quantity, unit_price, received_quantity) VALUES
(1,1,50,230.00,50),(1,7,10,1780.00,10),
(2,2,25,650.00,25),(2,5,8,5200.00,8),
(3,4,200,39.00,0),(3,6,40,160.00,0),
(4,3,60,270.00,20),(4,8,50,88.00,20),
(5,5,12,5200.00,0),
(6,1,30,225.00,30),
(7,4,100,39.00,0);

INSERT INTO Delivery (delivery_id, order_id, delivered_date, delivery_status, notes) VALUES
(1,1,'2026-09-04','ON_TIME','Delivered one day early'),
(2,2,'2026-09-13','LATE','Three days late'),
(3,3,NULL,'PENDING','Awaiting dispatch'),
(4,4,NULL,'PENDING','Partial receipt; remaining items pending'),
(5,5,NULL,'PENDING','Supplier confirmation pending'),
(6,6,'2026-09-24','ON_TIME','Delivered on expected date'),
(7,7,NULL,'NOT_DELIVERED','Order cancelled');

-- Opening balances are documented as adjustments; no stock is added by this seed insert.
INSERT INTO Inventory_Transaction
(product_id, transaction_type, quantity, transaction_date, reference_type, reference_id, notes)
VALUES
(1,'ADJUSTMENT',18,'2026-08-31 09:00:00','OPENING_BALANCE','OPEN-1','Opening stock baseline'),
(2,'ADJUSTMENT',32,'2026-08-31 09:00:00','OPENING_BALANCE','OPEN-2','Opening stock baseline'),
(3,'ADJUSTMENT',12,'2026-08-31 09:00:00','OPENING_BALANCE','OPEN-3','Opening stock baseline'),
(4,'ADJUSTMENT',145,'2026-08-31 09:00:00','OPENING_BALANCE','OPEN-4','Opening stock baseline'),
(5,'ADJUSTMENT',5,'2026-08-31 09:00:00','OPENING_BALANCE','OPEN-5','Opening stock baseline'),
(6,'ADJUSTMENT',9,'2026-08-31 09:00:00','OPENING_BALANCE','OPEN-6','Opening stock baseline'),
(7,'ADJUSTMENT',14,'2026-08-31 09:00:00','OPENING_BALANCE','OPEN-7','Opening stock baseline'),
(8,'ADJUSTMENT',55,'2026-08-31 09:00:00','OPENING_BALANCE','OPEN-8','Opening stock baseline');

INSERT INTO Supplier_Evaluation
(supplier_id, evaluation_date, on_time_percentage, performance_score, remarks)
VALUES
(1,'2026-09-30',100.00,96.00,'Consistent and on-time deliveries'),
(2,'2026-09-30',50.00,68.00,'One delayed delivery in the sample period'),
(3,'2026-09-30',NULL,72.00,'Insufficient completed deliveries for on-time calculation'),
(4,'2026-09-30',NULL,75.00,'Insufficient completed deliveries for on-time calculation'),
(5,'2026-09-30',0.00,40.00,'Inactive supplier; historical score only');

COMMIT;
