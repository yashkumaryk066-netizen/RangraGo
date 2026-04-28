const express = require("express");
const router = express.Router();
const User = require("../models/User");
const Ride = require("../models/Ride");
const verifyToken = require("../middleware/auth");
const mongoose = require("mongoose");

// Health check
router.get("/health", async (req, res) => {
  const dbStatus = mongoose.connection.readyState === 1 ? "Connected" : "Disconnected";
  res.json({
    status: "OK",
    database: dbStatus,
    timestamp: new Date()
  });
});

// Get rider stats
router.get("/stats", verifyToken, async (req, res) => {
  try {
    const userId = req.user.userId;
    const isDriver = req.user.role === "DRIVER";

    const filter = isDriver ? { driverId: userId } : { userId };

    const total = await Ride.countDocuments(filter);
    const completed = await Ride.countDocuments({ ...filter, status: "COMPLETED" });
    const cancelled = await Ride.countDocuments({ ...filter, status: "CANCELLED" });

    const completedRides = await Ride.find({ ...filter, status: "COMPLETED" });
    const totalEarnings = completedRides.reduce((sum, r) => sum + (r.fare || 0), 0);

    res.json({ total, completed, cancelled, totalEarnings });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
