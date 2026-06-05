const express = require("express");
const { createClient } = require("@clickhouse/client");

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3001;

const clickhouse = createClient({
  url: process.env.CLICKHOUSE_URL || "http://clickhouse:8123",
  username: process.env.CLICKHOUSE_USER || "root",
  password: process.env.CLICKHOUSE_PASSWORD || "123",
  database: process.env.CLICKHOUSE_DB || "database",
});

// Initialize a demo table
app.post("/init", async (req, res) => {
  try {
    await clickhouse.command({
      query: `
        CREATE TABLE IF NOT EXISTS events (
          id UInt64,
          name String,
          value Float64,
          created_at DateTime DEFAULT now()
        ) ENGINE = MergeTree()
        ORDER BY (id, created_at)
      `,
    });
    res.json({ status: "table created" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Insert rows: POST /insert  body: { rows: [{id, name, value}, ...] }
app.post("/insert", async (req, res) => {
  try {
    const rows = req.body.rows || [];
    await clickhouse.insert({
      table: "events",
      values: rows,
      format: "JSONEachRow",
    });
    res.json({ inserted: rows.length });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Generate N fake rows and insert them: POST /generate/:n
app.post("/generate/:n", async (req, res) => {
  try {
    const n = parseInt(req.params.n, 10) || 100;
    const rows = Array.from({ length: n }, (_, i) => ({
      id: Date.now() + i,
      name: `item_${Math.floor(Math.random() * 1000)}`,
      value: Math.random() * 100,
    }));
    await clickhouse.insert({
      table: "events",
      values: rows,
      format: "JSONEachRow",
    });
    res.json({ generated: n });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Query rows: GET /events?limit=10
app.get("/events", async (req, res) => {
  try {
    const limit = parseInt(req.query.limit, 10) || 10;
    const result = await clickhouse.query({
      query: "SELECT * FROM events ORDER BY created_at DESC LIMIT {limit:UInt32}",
      query_params: { limit },
      format: "JSONEachRow",
    });
    res.json(await result.json());
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.listen(PORT, () => {
  console.log(`Client listening on port ${PORT}`);
});

