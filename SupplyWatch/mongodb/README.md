# MongoDB component

Stores unstructured supplier risk observations in `supplier_risk_notes`. Run `collections.js` in mongosh. For vector search, use MongoDB Atlas, create the index from `vector-index.json`, and store actual embeddings in an `embedding` field. The vector-search example is a template and requires a real query embedding.
