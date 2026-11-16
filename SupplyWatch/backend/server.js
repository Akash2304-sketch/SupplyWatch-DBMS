
import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import { pool } from "./db/mysql.js";
import { getMongoDb } from "./db/mongo.js";

dotenv.config();

const app = express();

app.use(
  cors({
    origin: process.env.FRONTEND_ORIGIN || "http://localhost:3000",
  })
);

app.use(express.json());

// -----------------------------------------
// HEALTH CHECK
// -----------------------------------------

app.get("/api/health", async (_req, res) => {
  let mysqlStatus = "connected";
  let mongoStatus = "not configured";

  try {
    await pool.query("SELECT 1");
  } catch {
    mysqlStatus = "disconnected";
  }

  try {
    const db = await getMongoDb();

    if (db) {
      await db.command({ ping: 1 });
      mongoStatus = "connected";
    }
  } catch {
    mongoStatus = "disconnected";
  }

  res.json({
    status: mysqlStatus === "connected" ? "ok" : "degraded",
    mysql: mysqlStatus,
    mongodb: mongoStatus,
  });
});

// -----------------------------------------
// DASHBOARD
// -----------------------------------------

app.get("/api/dashboard", async (_req, res) => {
  try {
    const [[supplierRows]] = await pool.query(`
      SELECT
        COUNT(*) AS total_suppliers,
        SUM(supplier_status = 'ACTIVE') AS active_suppliers
      FROM Supplier
    `);

    const [[productRows]] = await pool.query(`
      SELECT COUNT(*) AS total_products
      FROM Product
      WHERE active = TRUE
    `);

    const [[inventoryRows]] = await pool.query(`
      SELECT
        COALESCE(SUM(i.current_stock), 0) AS total_units,
        COALESCE(
          ROUND(SUM(i.current_stock * p.unit_price), 2),
          0
        ) AS inventory_value
      FROM Inventory i
      JOIN Product p ON p.product_id = i.product_id
      WHERE p.active = TRUE
    `);

    const [[orderRows]] = await pool.query(`
      SELECT COUNT(*) AS open_orders
      FROM Purchase_Order
      WHERE order_status IN ('PLACED', 'PARTIALLY_RECEIVED')
    `);

    const [risk] = await pool.query(`
      SELECT
        risk_level,
        COUNT(*) AS count
      FROM v_inventory_risk
      GROUP BY risk_level
    `);

    // Corrected: performance_score does not exist in the view.
    const [supplierPerformance] = await pool.query(`
      SELECT
        supplier_name,
        completed_deliveries,
        on_time_deliveries,
        on_time_percentage,
        late_deliveries,
        open_orders
      FROM v_supplier_performance
      ORDER BY on_time_percentage DESC, supplier_name
    `);

    const [recentOrders] = await pool.query(`
      SELECT
        order_number,
        supplier_name,
        expected_date,
        order_status,
        days_past_expected,
        order_value
      FROM v_open_purchase_orders
      ORDER BY expected_date
      LIMIT 8
    `);

    res.json({
      metrics: {
        ...supplierRows,
        ...productRows,
        ...inventoryRows,
        ...orderRows,
      },
      risk,
      supplierPerformance,
      recentOrders,
    });
  } catch (error) {
    console.error("Dashboard API error:", error);

    res.status(500).json({
      error: "Unable to load dashboard.",
      detail: error.message,
    });
  }
});

// -----------------------------------------
// INVENTORY
// -----------------------------------------

app.get("/api/inventory", async (_req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT *
      FROM v_inventory_risk
      ORDER BY
        FIELD(
          risk_level,
          'STOCKOUT',
          'REORDER NOW',
          'WATCH',
          'HEALTHY'
        ),
        current_stock
    `);

    res.json(rows);
  } catch (error) {
    console.error("Inventory API error:", error);
    res.status(500).json({ error: error.message });
  }
});

// -----------------------------------------
// SUPPLIERS
// -----------------------------------------

app.get("/api/suppliers", async (_req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT *
      FROM v_supplier_performance
      ORDER BY supplier_name
    `);

    res.json(rows);
  } catch (error) {
    console.error("Suppliers API error:", error);
    res.status(500).json({ error: error.message });
  }
});

// -----------------------------------------
// PURCHASE ORDERS
// -----------------------------------------

app.get("/api/orders", async (_req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT *
      FROM v_open_purchase_orders
      ORDER BY expected_date
    `);

    res.json(rows);
  } catch (error) {
    console.error("Orders API error:", error);
    res.status(500).json({ error: error.message });
  }
});

// -----------------------------------------
// RISK NOTES - GET
// -----------------------------------------

app.get("/api/risk-notes", async (_req, res) => {
  try {
    const db = await getMongoDb();

    if (!db) {
      return res.json([]);
    }

    const rows = await db
      .collection("supplier_risk_notes")
      .find({})
      .sort({ createdAt: -1 })
      .limit(50)
      .toArray();

    res.json(rows);
  } catch (error) {
    console.error("Risk notes API error:", error);
    res.status(500).json({ error: error.message });
  }
});

// -----------------------------------------
// RISK NOTES - POST
// -----------------------------------------

app.post("/api/risk-notes", async (req, res) => {
  try {
    const {
      supplierId,
      supplierName,
      category,
      note,
      severity,
    } = req.body;

    if (!supplierName || !note) {
      return res.status(400).json({
        error: "supplierName and note are required",
      });
    }

    const db = await getMongoDb();

    if (!db) {
      return res.status(503).json({
        error: "MongoDB is not configured",
      });
    }

    const doc = {
      supplierId: supplierId || null,
      supplierName,
      category: category || "GENERAL",
      note,
      severity: severity || "MEDIUM",
      createdAt: new Date(),
    };

    const result = await db
      .collection("supplier_risk_notes")
      .insertOne(doc);

    res.status(201).json({
      ...doc,
      _id: result.insertedId,
    });
  } catch (error) {
    console.error("Create risk note API error:", error);
    res.status(500).json({ error: error.message });
  }
});

// -----------------------------------------
// START SERVER
// -----------------------------------------

const PORT = process.env.PORT || 5001;

app.listen(PORT, () => {
  console.log(`SupplyWatch API running on http://localhost:${PORT}`);
});
