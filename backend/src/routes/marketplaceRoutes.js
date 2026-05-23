const express = require("express");
const pool = require("../config/db");

const router = express.Router();

// GET ALL LISTINGS
router.get("/", async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT * FROM marketplace_listings ORDER BY created_at DESC"
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: "Fetch failed" });
  }
});

// CREATE LISTING
router.post("/create", async (req, res) => {
  try {
    const {
      farmer_id,
      crop_name,
      quantity,
      expected_price,
      quality_grade
    } = req.body;

    const result = await pool.query(
      `INSERT INTO marketplace_listings
      (farmer_id, crop_name, quantity, expected_price, quality_grade)
      VALUES ($1,$2,$3,$4,$5)
      RETURNING *`,
      [farmer_id, crop_name, quantity, expected_price, quality_grade]
    );

    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: "Create failed" });
  }
});

module.exports = router;