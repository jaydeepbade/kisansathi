const express = require("express");
const router = express.Router();
const pool = require("../db/pool");
const authMiddleware = require("../middleware/authMiddleware");

/* =====================================================
   SAVE IoT SENSOR DATA
   POST /api/iot
   Body: { farm_id, moisture, temperature, humidity, nitrogen }
====================================================== */
router.post("/", async (req, res) => {
  try {
    const { farm_id, moisture, temperature, humidity, nitrogen } = req.body;

    const result = await pool.query(
      `INSERT INTO iot_data (farm_id, moisture, temperature, humidity, nitrogen)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [farm_id, moisture, temperature, humidity, nitrogen]
    );

    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/* =====================================================
   GET LATEST IoT DATA FOR A FARM
   GET /api/iot/:farm_id
====================================================== */
router.get("/:farm_id", authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT * FROM iot_data
       WHERE farm_id = $1
       ORDER BY created_at DESC
       LIMIT 10`,
      [req.params.farm_id]
    );

    // Also compute averages for dashboard
    const avg = await pool.query(
      `SELECT
         ROUND(AVG(moisture)::numeric, 2)     AS avg_moisture,
         ROUND(AVG(temperature)::numeric, 2)  AS avg_temperature,
         ROUND(AVG(humidity)::numeric, 2)     AS avg_humidity,
         ROUND(AVG(nitrogen)::numeric, 2)     AS avg_nitrogen
       FROM iot_data WHERE farm_id = $1`,
      [req.params.farm_id]
    );

    res.json({
      success: true,
      latest: result.rows,
      averages: avg.rows[0],
      irrigationNeeded: avg.rows[0]?.avg_moisture < 30,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/* =====================================================
   SIMULATE IoT DATA (demo endpoint for judges)
   GET /api/iot/simulate/:farm_id
====================================================== */
router.get("/simulate/:farm_id", async (req, res) => {
  try {
    const simData = {
      farm_id: req.params.farm_id,
      moisture: (Math.random() * 60 + 10).toFixed(1),
      temperature: (Math.random() * 15 + 20).toFixed(1),
      humidity: (Math.random() * 40 + 40).toFixed(1),
      nitrogen: (Math.random() * 80 + 20).toFixed(1),
      timestamp: new Date().toISOString(),
    };

    // Save simulated data
    await pool.query(
      `INSERT INTO iot_data (farm_id, moisture, temperature, humidity, nitrogen)
       VALUES ($1, $2, $3, $4, $5)`,
      [simData.farm_id, simData.moisture, simData.temperature, simData.humidity, simData.nitrogen]
    );

    res.json({
      success: true,
      simulated: true,
      data: simData,
      alert: simData.moisture < 30 ? "⚠️ Low soil moisture — irrigation needed!" : "✅ Soil moisture is healthy",
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;