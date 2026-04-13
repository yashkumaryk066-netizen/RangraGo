const express = require("express");
const router = express.Router();
const Ride = require("../models/Ride");
const verifyToken = require("../middleware/auth");

// Create Ride (Passenger)
router.post("/", verifyToken, async (req, res) => {
  try {
    const fare = Math.floor(100 + Math.random() * 400);
    const ride = await Ride.create({
      ...req.body,
      userId: req.user.userId,
      fare
    });
    
    // Notify all online drivers
    req.io.to("online-drivers").emit("new-ride", ride);
    
    res.status(201).json(ride);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// Accept Ride (Driver)
router.post("/:id/accept", verifyToken, async (req, res) => {
  try {
    const ride = await Ride.findById(req.params.id);
    
    if (!ride) return res.status(404).json({ message: "Ride not found" });
    if (ride.status !== "REQUESTED") return res.status(400).json({ message: "Ride already taken" });

    const { fare: customFare } = req.body;
    
    ride.status = "ACCEPTED";
    ride.driverId = req.user.userId;
    if (customFare) ride.fare = customFare;
    await ride.save();
    
    req.io.to(ride.userId).emit("ride-accepted", {
      rideId: ride._id,
      driverId: req.user.userId,
      status: "ACCEPTED",
      otp: ride.otp,
      fare: ride.fare
    });

    // Notify ALL other drivers to remove this ride from their list
    req.io.to("online-drivers").emit("ride-taken", { rideId: ride._id });
    
    res.json(ride);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// Start Ride (Driver + OTP)
router.post("/:id/start", verifyToken, async (req, res) => {
  try {
    const { otp } = req.body;
    const ride = await Ride.findById(req.params.id);
    
    if (!ride) return res.status(404).json({ message: "Ride not found" });
    if (ride.otp !== otp) return res.status(400).json({ message: "Invalid OTP" });

    ride.status = "STARTED";
    await ride.save();

    req.io.to(ride.userId).emit("ride-started", { rideId: ride._id });
    res.json(ride);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// Complete Ride (Driver)
router.post("/:id/complete", verifyToken, async (req, res) => {
  try {
    const ride = await Ride.findById(req.params.id);
    if (!ride) return res.status(404).json({ message: "Ride not found" });

    ride.status = "COMPLETED";
    ride.paymentStatus = "PAID";
    await ride.save();

    req.io.to(ride.userId).emit("ride-completed", { rideId: ride._id, fare: ride.fare });
    res.json(ride);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// Cancel Ride
router.post("/:id/cancel", verifyToken, async (req, res) => {
  try {
    const ride = await Ride.findById(req.params.id);
    if (!ride) return res.status(404).json({ message: "Ride not found" });

    ride.status = "CANCELLED";
    await ride.save();

    const notifyId = req.user.userId === ride.userId ? ride.driverId : ride.userId;
    if (notifyId) req.io.to(notifyId).emit("ride-cancelled", { rideId: ride._id });

    res.json({ message: "Ride cancelled" });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// Get History
router.get("/history", verifyToken, async (req, res) => {
  try {
    const filter = req.user.role === "DRIVER" ? { driverId: req.user.userId } : { userId: req.user.userId };
    const rides = await Ride.find(filter).sort({ createdAt: -1 });
    res.json(rides);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Get all active rides (for online drivers)
router.get("/active", verifyToken, async (req, res) => {
  try {
    const rides = await Ride.find({ status: "REQUESTED" });
    res.json(rides);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
