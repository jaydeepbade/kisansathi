const express = require("express");
const router = express.Router();
const pool = require("../db/pool");
const authMiddleware = require("../middleware/authMiddleware");

/* =====================================================
   AI DISEASE SCAN (uses Claude / Gemini Vision)
   POST /api/disease/scan
   Body: { image_base64, crop_name, farmer_id (optional) }

   NOTE: Set ANTHROPIC_API_KEY in your .env
====================================================== */
router.post("/scan", async (req, res) => {
  try {
    const { image_base64, crop_name, farmer_id } = req.body;

    // ── Option A: Call Claude Vision API ──────────────
    // Uncomment this block when ANTHROPIC_API_KEY is set
    /*
    const Anthropic = require("@anthropic-ai/sdk");
    const client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

    const message = await client.messages.create({
      model: "claude-opus-4-5",
      max_tokens: 1024,
      messages: [
        {
          role: "user",
          content: [
            {
              type: "image",
              source: {
                type: "base64",
                media_type: "image/jpeg",
                data: image_base64,
              },
            },
            {
              type: "text",
              text: `You are an expert agricultural disease detection AI.
                     Analyze this ${crop_name || "crop"} image and respond ONLY in JSON:
                     {
                       "disease_name": "...",
                       "confidence": 0.95,
                       "severity": "low|medium|high",
                       "remedy": "...",
                       "prevention": "...",
                       "organic_solution": "..."
                     }`,
            },
          ],
        },
      ],
    });

    const aiResponse = JSON.parse(message.content[0].text);
    */

    // ── Option B: Demo/Mock response (use until API key ready) ──
    const aiResponse = {
      disease_name: crop_name
        ? `${crop_name} Leaf Blight`
        : "Tomato Leaf Blight",
      confidence: 0.92,
      severity: "medium",
      remedy: "Use Copper Oxychloride 3g/litre spray immediately",
      prevention: "Avoid excess watering, ensure good air circulation",
      organic_solution: "Neem oil spray (5ml/litre) twice a week",
    };

    // ── Save scan result to DB ─────────────────────────
    if (farmer_id || req.user?.id) {
      await pool.query(
        `INSERT INTO disease_scans
           (farmer_id, image_url, disease_name, confidence, remedy)
         VALUES ($1, $2, $3, $4, $5)`,
        [
          farmer_id || req.user?.id,
          "scan_" + Date.now(),
          aiResponse.disease_name,
          aiResponse.confidence,
          aiResponse.remedy,
        ]
      );
    }

    res.json({ success: true, result: aiResponse });
  } catch (err) {
    console.error("Disease scan error:", err.message);
    res.status(500).json({ error: err.message });
  }
});

/* =====================================================
   GET SCAN HISTORY (for a farmer)
   GET /api/disease/history
====================================================== */
router.get("/history", authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT * FROM disease_scans
       WHERE farmer_id = $1
       ORDER BY created_at DESC
       LIMIT 20`,
      [req.user.id]
    );
    res.json({ success: true, scans: result.rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/* =====================================================
   GET ALL SCANS (admin/demo)
   GET /api/disease/all
====================================================== */
router.get("/all", async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT ds.*, u.full_name, u.village
       FROM disease_scans ds
       LEFT JOIN users u ON ds.farmer_id = u.id
       ORDER BY ds.created_at DESC
       LIMIT 50`
    );
    res.json({ success: true, scans: result.rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;