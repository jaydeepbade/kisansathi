const express = require("express");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const pool = require("../config/db");

const router = express.Router();

/* REGISTER */
router.post("/register", async (req, res) => {
  try {
    const { full_name, phone, password, role } = req.body;

    // ✅ VALIDATION (VERY IMPORTANT)
    if (!full_name || !phone || !password || !role) {
      return res.status(400).json({
        error: "All fields are required (full_name, phone, password, role)"
      });
    }

    // extra safety
    if (typeof password !== "string") {
      return res.status(400).json({
        error: "Password must be a string"
      });
    }

    const hashed = await bcrypt.hash(password, 10);

    const result = await pool.query(
      `INSERT INTO users (full_name, phone, password, role)
       VALUES ($1,$2,$3,$4)
       RETURNING id, full_name, phone, role`,
      [full_name, phone, hashed, role]
    );

    return res.json(result.rows[0]);

  } catch (err) {
    console.error("REGISTER ERROR:", err);

    return res.status(500).json({
      error: err.message
    });
  }
});
/* LOGIN */
router.post("/login", async (req, res) => {
  try {
    const { phone, password } = req.body;

    const user = await pool.query(
      `SELECT * FROM users WHERE phone=$1`,
      [phone]
    );

    if (user.rows.length === 0)
      return res.status(400).json({ error: "User not found" });

    const valid = await bcrypt.compare(
      password,
      user.rows[0].password
    );

    if (!valid)
      return res.status(400).json({ error: "Wrong password" });

    const token = jwt.sign(
      { id: user.rows[0].id, role: user.rows[0].role },
      process.env.JWT_SECRET
    );

    res.json({
      token,
      user: user.rows[0]
    });
  } catch (err) {
    res.status(500).json({ error: "Login failed" });
  }
});

module.exports = router;