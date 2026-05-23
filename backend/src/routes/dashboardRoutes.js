const express = require("express");

const router = express.Router();

router.get("/", (req, res) => {
  res.json({
    weather: "Heavy rain expected tomorrow",
    cropHealth: "Tomato crops healthy",
    irrigation: "Soil moisture low",
    marketPrice: "₹18/kg",
  });
});

module.exports = router;