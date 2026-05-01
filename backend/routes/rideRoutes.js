const express = require("express");
const router = express.Router();
const Ride = require("../models/Ride");
const User = require("../models/User");
const verifyToken = require("../middleware/auth");

// Create Ride (Passenger)
router.post("/", verifyToken, async (req, res) => {
  try {
    const { vehicleType, distanceKm, pickupCoords } = req.body;
    
    // 1. Calculate Fare
    let baseFare = 20;
    let ratePerKm = 5;
    switch (vehicleType) {
      case "Auto": baseFare = 30; ratePerKm = 10; break;
      case "Car": baseFare = 50; ratePerKm = 15; break;
      case "Prime": baseFare = 80; ratePerKm = 25; break;
      default: baseFare = 20; ratePerKm = 5;
    }
    const distance = parseFloat(distanceKm) || 0;
    const fare = Math.round(baseFare + (distance * ratePerKm));

    // 2. Save Ride to DB
    const ride = await Ride.create({
      ...req.body,
      userId: req.user.userId,
      fare
    });
    
    // 3. GEO-FILTERING: Find nearby online drivers (within 5km)
    // pickupCoords = { lat, lng }
    const nearbyDrivers = await User.find({
      role: "DRIVER",
      isOnline: true,
      location: {
        $near: {
          $geometry: {
            type: "Point",
            coordinates: [pickupCoords.lng, pickupCoords.lat] // [lng, lat]
          },
          $maxDistance: 5000 // 5 Kilometers
        }
      }
    });

    // 4. Notify ONLY those nearby drivers
    nearbyDrivers.forEach(driver => {
      req.io.to(driver._id.toString()).emit("new-ride", ride);
    });
    
    res.status(201).json(ride);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// Accept Ride (Driver)
router.post("/:id/accept", verifyToken, async (req, res) => {
  try {
    // 1. Ensure user is a DRIVER
    if (req.user.role !== "DRIVER") {
      return res.status(403).json({ message: "Only drivers can accept rides" });
    }

    const { fare: customFare } = req.body;
    
    // 2. ATOMIC UPDATE: Find REQUESTED ride and update to ACCEPTED in one step
    // This prevents race conditions where two drivers accept at the same time
    const ride = await Ride.findOneAndUpdate(
      { _id: req.params.id, status: "REQUESTED" },
      { 
        status: "ACCEPTED", 
        driverId: req.user.userId,
        ...(customFare && { fare: customFare })
      },
      { new: true }
    );
    
    if (!ride) return res.status(400).json({ message: "Ride not available or already taken" });

    // 3. Notify Peers
    const driver = await User.findById(req.user.userId);
    const rider = await User.findById(ride.userId);
    
    req.io.to(ride.userId).emit("ride-accepted", {
      rideId: ride._id,
      driverId: req.user.userId,
      driverName: driver?.name || "Driver",
      driverPhone: driver?.phone || "",
      driverVehicle: driver?.vehicleInfo || {},
      status: "ACCEPTED",
      otp: ride.otp,
      fare: ride.fare
    });

    req.io.to(req.user.userId).emit("rider-info", {
      rideId: ride._id,
      riderName: rider?.name || "Rider",
      riderPhone: rider?.phone || "",
      pickup: ride.pickup,
      drop: ride.drop
    });

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

    // Update driver stats
    if (ride.driverId) {
      await User.findByIdAndUpdate(ride.driverId, {
        $inc: { 
          totalEarnings: ride.fare || 0,
          completedRides: 1
        }
      });
    }

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
