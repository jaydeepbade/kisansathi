const express = require("express");
const cors = require("cors");
require("dotenv").config();

// ✅ app MUST be declared first
const app = express();

// ── Middleware ─────────────────────────────────────────
app.use(cors());
app.use(express.json());

// ── DB pool (import after app) ─────────────────────────
const pool = require("./db/pool");

// ── Routes ─────────────────────────────────────────────
const authRoutes        = require("./routes/authRoutes");
const farmRoutes        = require("./routes/farmRoutes");
const marketplaceRoutes = require("./routes/marketplaceRoutes");
const diseaseRoutes     = require("./routes/diseaseRoutes");
const iotRoutes         = require("./routes/iotRoutes");
const predictRoutes     = require("./routes/predictRoutes");

app.use("/api/auth",        authRoutes);
app.use("/api/marketplace", marketplaceRoutes);
app.use("/api/farms",       farmRoutes);
app.use("/api/disease",     diseaseRoutes);
app.use("/api/iot",         iotRoutes);
app.use("/api/predict",     predictRoutes);

// ── Root ───────────────────────────────────────────────
app.get("/", (req, res) => {
  res.json({ message: "FarmSaathi Backend Running ✅", version: "1.0.0" });
});

// ── Dashboard (static demo data) ──────────────────────
app.get("/api/dashboard", (req, res) => {
  res.json({
    weatherAlert: "Heavy rain expected tomorrow",
    cropHealth: "Tomato crops are healthy",
    irrigationAlert: "Soil moisture is low",
    marketPrice: "₹18/kg",
  });
});

// ── DB Connection Test ─────────────────────────────────
app.get("/test-db", async (req, res) => {
  try {
    const result = await pool.query("SELECT NOW()");
    res.json({ success: true, message: "DB connected ✅", time: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ── Weather API ────────────────────────────────────────
app.get("/api/weather", (req, res) => {
  res.json({
    location: "Pune",
    temperature: "28°C",
    humidity: "70%",
    rainChance: "80%",
    alert: "Heavy rainfall likely tomorrow",
  });
});

// ── Smart Farm API ─────────────────────────────────────
app.get("/api/smartfarm", (req, res) => {
  res.json({
    soilMoisture: "34%",
    humidity: "72%",
    temperature: "29°C",
    nitrogenLevel: "Medium",
    irrigationRecommendation: "Irrigation required in next 6 hours",
  });
});

// ── Crop DNA API ───────────────────────────────────────
app.get("/api/cropdna", (req, res) => {
  res.json({
    crop: "Tomato",
    freshnessScore: "94%",
    moistureLevel: "Optimal",
    pesticideRisk: "Low",
    qualityGrade: "A+",
  });
});

// ── Start Server ───────────────────────────────────────
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});