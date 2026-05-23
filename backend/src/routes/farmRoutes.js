const express = require("express");
const router = express.Router();
const pool = require("../db/pool");
const authMiddleware = require("../middleware/authMiddleware");

/* =====================================================
   ADD FARM
   POST /api/farms
   Protected — farmer must be logged in
====================================================== */
router.post("/", authMiddleware, async (req, res) => {
  try {
    const { crop_name, land_area, soil_type, latitude, longitude } = req.body;
    const user_id = req.user.id;

    if (!crop_name) {
      return res.status(400).json({ error: "crop_name is required" });
    }

    const result = await pool.query(
      `INSERT INTO farms (user_id, crop_name, land_area, soil_type, latitude, longitude)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [user_id, crop_name, land_area || null, soil_type || null, latitude || null, longitude || null]
    );

    res.status(201).json({ success: true, farm: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/* =====================================================
   GET MY FARMS
   GET /api/farms
   Protected
====================================================== */
router.get("/", authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT * FROM farms WHERE user_id = $1 ORDER BY created_at DESC",
      [req.user.id]
    );
    res.json({ success: true, farms: result.rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/* =====================================================
   GET SINGLE FARM
   GET /api/farms/:id
====================================================== */
router.get("/:id", authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT * FROM farms WHERE id = $1 AND user_id = $2",
      [req.params.id, req.user.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Farm not found" });
    }
    res.json({ success: true, farm: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/* =====================================================
   UPDATE FARM
   PUT /api/farms/:id
====================================================== */
router.put("/:id", authMiddleware, async (req, res) => {
  try {
    const { crop_name, land_area, soil_type, latitude, longitude } = req.body;
    const result = await pool.query(
      `UPDATE farms SET crop_name=$1, land_area=$2, soil_type=$3, latitude=$4, longitude=$5
       WHERE id=$6 AND user_id=$7 RETURNING *`,
      [crop_name, land_area, soil_type, latitude, longitude, req.params.id, req.user.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Farm not found" });
    }
    res.json({ success: true, farm: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/* =====================================================
   DELETE FARM
   DELETE /api/farms/:id
====================================================== */
router.delete("/:id", authMiddleware, async (req, res) => {
  try {
    await pool.query(
      "DELETE FROM farms WHERE id=$1 AND user_id=$2",
      [req.params.id, req.user.id]
    );
    res.json({ success: true, message: "Farm deleted" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;