// Run in mongosh after selecting the supplywatch_nosql database.
db.createCollection("supplier_risk_notes");
db.supplier_risk_notes.createIndex({ supplierName: 1, createdAt: -1 });
db.supplier_risk_notes.createIndex({ severity: 1, category: 1 });
