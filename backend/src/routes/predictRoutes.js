const express = require("express");
const router = express.Router();
const pool = require("../db/pool");

/* =====================================================
   CROP YIELD PREDICTION
   POST /api/predict/yield
   Body: { crop_name, soil_type, land_area, rainfall_mm,
           temperature, humidity, nitrogen }

   This calls the Python ML service (FastAPI on port 8000)
   OR returns rule-based prediction if ML service is down.
====================================================== */
router.post("/yield", async (req, res) => {
  try {
    const {
      crop_name,
      soil_type,
      land_area,
      rainfall_mm,
      temperature,
      humidity,
      nitrogen,
    } = req.body;

    // ── Try calling Python ML service ─────────────────
    let prediction = null;
    try {
      const fetch = (...args) =>
        import("node-fetch").then(({ default: f }) => f(...args));

      const mlResponse = await fetch("http://localhost:8000/predict/yield", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(req.body),
        signal: AbortSignal.timeout(3000), // 3s timeout
      });

      if (mlResponse.ok) {
        prediction = await mlResponse.json();
      }
    } catch (mlErr) {
      console.log("ML service not available, using rule-based fallback");
    }

    // ── Rule-based fallback (always works for demo) ───
    if (!prediction) {
      prediction = ruleBasedYieldPredict({
        crop_name,
        soil_type,
        land_area: parseFloat(land_area) || 1,
        rainfall_mm: parseFloat(rainfall_mm) || 800,
        temperature: parseFloat(temperature) || 28,
        humidity: parseFloat(humidity) || 65,
        nitrogen: parseFloat(nitrogen) || 50,
      });
    }

    res.json({ success: true, prediction });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/* =====================================================
   MARKET PRICE PREDICTION
   POST /api/predict/price
   Body: { crop_name, month, quality_grade, location }
====================================================== */
router.post("/price", async (req, res) => {
  try {
    const { crop_name, month, quality_grade, location } = req.body;

    let prediction = null;

    // Try ML service
    try {
      const fetch = (...args) =>
        import("node-fetch").then(({ default: f }) => f(...args));

      const mlResponse = await fetch("http://localhost:8000/predict/price", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(req.body),
        signal: AbortSignal.timeout(3000),
      });

      if (mlResponse.ok) {
        prediction = await mlResponse.json();
      }
    } catch {
      console.log("ML service not available, using price fallback");
    }

    // Rule-based fallback
    if (!prediction) {
      prediction = ruleBasedPricePredict({ crop_name, month, quality_grade });
    }

    res.json({ success: true, prediction });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/* =====================================================
   IRRIGATION RECOMMENDATION
   POST /api/predict/irrigation
   Body: { moisture, temperature, humidity, crop_name }
====================================================== */
router.post("/irrigation", async (req, res) => {
  try {
    const { moisture, temperature, humidity, crop_name } = req.body;

    const m = parseFloat(moisture);
    const t = parseFloat(temperature);
    const h = parseFloat(humidity);

    let recommendation;
    if (m < 25) {
      recommendation = {
        action: "IRRIGATE NOW",
        urgency: "high",
        water_amount_litres_per_acre: 800,
        reason: `Soil moisture critically low at ${m}%`,
        next_check_hours: 6,
      };
    } else if (m < 40) {
      recommendation = {
        action: "IRRIGATE SOON",
        urgency: "medium",
        water_amount_litres_per_acre: 400,
        reason: `Soil moisture at ${m}% — monitor closely`,
        next_check_hours: 12,
      };
    } else {
      recommendation = {
        action: "NO IRRIGATION NEEDED",
        urgency: "low",
        water_amount_litres_per_acre: 0,
        reason: `Soil moisture healthy at ${m}%`,
        next_check_hours: 24,
      };
    }

    res.json({ success: true, recommendation });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/* =====================================================
   FULL FARM ANALYSIS (combines all predictions)
   GET /api/predict/analysis/:farm_id
====================================================== */
router.get("/analysis/:farm_id", async (req, res) => {
  try {
    // Get latest IoT data for farm
    const iotResult = await pool.query(
      `SELECT * FROM iot_data WHERE farm_id=$1 ORDER BY created_at DESC LIMIT 1`,
      [req.params.farm_id]
    );

    const farmResult = await pool.query(
      "SELECT * FROM farms WHERE id=$1",
      [req.params.farm_id]
    );

    if (farmResult.rows.length === 0) {
      return res.status(404).json({ error: "Farm not found" });
    }

    const farm = farmResult.rows[0];
    const iot = iotResult.rows[0] || {
      moisture: 45, temperature: 28, humidity: 65, nitrogen: 50
    };

    const yieldPred = ruleBasedYieldPredict({
      crop_name: farm.crop_name,
      soil_type: farm.soil_type,
      land_area: parseFloat(farm.land_area) || 1,
      rainfall_mm: 800,
      temperature: parseFloat(iot.temperature),
      humidity: parseFloat(iot.humidity),
      nitrogen: parseFloat(iot.nitrogen),
    });

    const pricePred = ruleBasedPricePredict({
      crop_name: farm.crop_name,
      month: new Date().getMonth() + 1,
    });

    const irrigationRec = {
      action: iot.moisture < 30 ? "IRRIGATE NOW" : "NO IRRIGATION NEEDED",
      urgency: iot.moisture < 30 ? "high" : "low",
      moisture_level: iot.moisture,
    };

    res.json({
      success: true,
      farm,
      iot_latest: iot,
      yield_prediction: yieldPred,
      price_prediction: pricePred,
      irrigation: irrigationRec,
      overall_health_score: computeHealthScore(iot),
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/* =====================================================
   HELPER: Rule-based yield prediction
====================================================== */
function ruleBasedYieldPredict({ crop_name, soil_type, land_area, rainfall_mm, temperature, humidity, nitrogen }) {
  const BASE_YIELDS = {
    tomato: 25000, onion: 20000, wheat: 4500,
    rice: 6000, sugarcane: 70000, cotton: 1800,
    default: 8000,
  };

  const crop = (crop_name || "default").toLowerCase();
  let baseYield = BASE_YIELDS[crop] || BASE_YIELDS.default;

  // Modifiers
  let modifier = 1.0;
  if (rainfall_mm > 600 && rainfall_mm < 1200) modifier += 0.1;
  if (temperature > 20 && temperature < 35) modifier += 0.05;
  if (humidity > 50 && humidity < 80) modifier += 0.05;
  if (nitrogen > 40) modifier += 0.1;
  if (soil_type === "loamy") modifier += 0.15;

  const estimatedYield = Math.round(baseYield * modifier * land_area);
  const estimatedRevenue = estimatedYield * getPricePerKg(crop);

  return {
    crop_name: crop_name || "Unknown",
    land_area_acres: land_area,
    estimated_yield_kg: estimatedYield,
    estimated_revenue_inr: estimatedRevenue,
    price_per_kg: getPricePerKg(crop),
    confidence: 0.78,
    factors: {
      soil_modifier: soil_type === "loamy" ? "optimal" : "average",
      water_modifier: rainfall_mm > 600 ? "good" : "low",
      nutrient_modifier: nitrogen > 40 ? "sufficient" : "deficient",
    },
    recommendation:
      nitrogen < 40
        ? "Apply nitrogen-rich fertilizer to boost yield by ~10%"
        : "Current conditions are optimal for high yield",
  };
}

/* =====================================================
   HELPER: Rule-based price prediction
====================================================== */
function ruleBasedPricePredict({ crop_name, month, quality_grade }) {
  const BASE_PRICES = {
    tomato: 18, onion: 22, wheat: 25, rice: 30,
    sugarcane: 3.5, cotton: 65, default: 20,
  };

  const crop = (crop_name || "default").toLowerCase();
  let basePrice = BASE_PRICES[crop] || BASE_PRICES.default;

  // Seasonal modifier
  const seasonalMod = [1.1, 1.1, 0.9, 0.9, 1.2, 1.3, 0.8, 0.8, 1.0, 1.0, 1.1, 1.2];
  const mod = seasonalMod[(month || new Date().getMonth() + 1) - 1];

  // Quality modifier
  const qualityMod = quality_grade === "Grade A" ? 1.15 : quality_grade === "Grade B" ? 0.9 : 1.0;

  const predictedPrice = +(basePrice * mod * qualityMod).toFixed(2);
  const lowRange = +(predictedPrice * 0.85).toFixed(2);
  const highRange = +(predictedPrice * 1.15).toFixed(2);

  return {
    crop_name: crop_name || "Unknown",
    predicted_price_per_kg: predictedPrice,
    price_range: { low: lowRange, high: highRange },
    currency: "INR",
    best_selling_month: getBestMonth(crop),
    market_trend: mod > 1 ? "📈 Prices rising this month" : "📉 Prices lower this season",
    recommendation: `Best time to sell: ${getBestMonth(crop)} — expected ₹${highRange}/kg`,
    confidence: 0.72,
  };
}

function getPricePerKg(crop) {
  const prices = {
    tomato: 18, onion: 22, wheat: 25, rice: 30,
    sugarcane: 3.5, cotton: 65, default: 20,
  };
  return prices[crop] || prices.default;
}

function getBestMonth(crop) {
  const months = {
    tomato: "November–January", onion: "April–June",
    wheat: "March–April", rice: "October–November",
    sugarcane: "October–December", default: "October–December",
  };
  return months[crop] || months.default;
}

function computeHealthScore(iot) {
  let score = 100;
  if (iot.moisture < 25 || iot.moisture > 80) score -= 20;
  if (iot.temperature > 40 || iot.temperature < 10) score -= 15;
  if (iot.humidity < 30 || iot.humidity > 90) score -= 10;
  if (iot.nitrogen < 20) score -= 15;
  return Math.max(0, score);
}

module.exports = router;