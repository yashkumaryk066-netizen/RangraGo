const express = require("express");
const router = express.Router();
const Ride = require("../models/Ride");
const User = require("../models/User");
const verifyToken = require("../middleware/auth");

// Helper for distance calculation (Haversine formula)
function getDistance(p1, p2) {
  if (!p1.latitude || !p1.longitude || !p2.latitude || !p2.longitude) return 999999;
  const R = 6371e3; // metres
  const φ1 = p1.latitude * Math.PI/180;
  const φ2 = p2.latitude * Math.PI/180;
  const Δφ = (p2.latitude-p1.latitude) * Math.PI/180;
  const Δλ = (p2.longitude-p1.longitude) * Math.PI/180;

  const a = Math.sin(Δφ/2) * Math.sin(Δφ/2) +
          Math.cos(φ1) * Math.cos(φ2) *
          Math.sin(Δλ/2) * Math.sin(Δλ/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));

  return R * c; // in metres
}

// 1. Create Ride (Passenger)
router.post("/", verifyToken, async (req, res) => {
  try {
    const { vehicleType, distanceKm, pickupCoords } = req.body;
    
    let baseFare = 20;
    let ratePerKm = 5;
    switch (vehicleType?.toUpperCase()) {
      case "AUTO": baseFare = 30; ratePerKm = 10; break;
      case "CAR": baseFare = 50; ratePerKm = 15; break;
      case "PRIME": baseFare = 80; ratePerKm = 25; break;
      default: baseFare = 20; ratePerKm = 5;
    }
    const distance = parseFloat(distanceKm) || 0;
    const fare = Math.round(baseFare + (distance * ratePerKm));

    const ride = await Ride.create({
      ...req.body,
      userId: req.user.userId,
      fare
    });
    
    // Notify nearby drivers (within 5km)
    const nearbyDrivers = await User.find({
      role: "DRIVER",
      isOnline: true,
      location: {
        $near: {
          $geometry: {
            type: "Point",
            coordinates: [pickupCoords.lng, pickupCoords.lat]
          },
          $maxDistance: 5000
        }
      }
    });

    nearbyDrivers.forEach(driver => {
      req.io.to(driver._id.toString()).emit("new-ride", ride);
    });
    
    res.status(201).json(ride);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// 2. Accept Ride (Driver)
router.post("/:id/accept", verifyToken, async (req, res) => {
  try {
    if (req.user.role !== "DRIVER") {
      return res.status(403).json({ message: "Only drivers can accept rides" });
    }

    const { fare: customFare } = req.body;
    
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
      drop: ride.drop,
      pickupCoords: ride.pickupCoords,
      dropCoords: ride.dropCoords,
    });

    req.io.to("online-drivers").emit("ride-taken", { rideId: ride._id });
    
    res.json(ride);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// 3. Start Ride (Driver + OTP)
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

// 4. Complete Ride (Driver - Restricted to 200m)
router.post("/:id/complete", verifyToken, async (req, res) => {
  try {
    const { currentLat, currentLng } = req.body;
    const ride = await Ride.findById(req.params.id);
    if (!ride) return res.status(404).json({ message: "Ride not found" });

    // GEOCONTAINMENT CHECK: Must be within 200m of drop-off
    if (currentLat && currentLng) {
      const distance = getDistance(
        { latitude: currentLat, longitude: currentLng },
        { latitude: ride.dropCoords.lat, longitude: ride.dropCoords.lng }
      );
      
      if (distance > 200) {
        return res.status(403).json({ 
          message: `Too far from destination (${Math.round(distance)}m). Reach within 200m to complete.` 
        });
      }
    }

    ride.status = "COMPLETED";
    ride.paymentStatus = "PAID";
    await ride.save();

    if (ride.driverId) {
      await User.findByIdAndUpdate(ride.driverId, {
        $inc: { totalEarnings: ride.fare || 0, completedRides: 1 }
      });
    }

    req.io.to(ride.userId).emit("ride-completed", { rideId: ride._id, fare: ride.fare });
    res.json(ride);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// 5. Cancel Ride (Restricted once STARTED)
router.post("/:id/cancel", verifyToken, async (req, res) => {
  try {
    const ride = await Ride.findById(req.params.id);
    if (!ride) return res.status(404).json({ message: "Ride not found" });

    if (ride.status === "STARTED") {
      return res.status(403).json({ message: "Ride has already started. Cannot cancel now." });
    }

    ride.status = "CANCELLED";
    await ride.save();

    const notifyId = req.user.userId === ride.userId ? ride.driverId : ride.userId;
    if (notifyId) req.io.to(notifyId).emit("ride-cancelled", { rideId: ride._id });

    res.json({ message: "Ride cancelled" });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// 6. Get History
router.get("/history", verifyToken, async (req, res) => {
  try {
    const filter = req.user.role === "DRIVER" ? { driverId: req.user.userId } : { userId: req.user.userId };
    const rides = await Ride.find(filter).sort({ createdAt: -1 });
    res.json(rides);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// 7. Get Active Rides (Filtered by Driver's Vehicle Type)
router.get("/active", verifyToken, async (req, res) => {
  try {
    const driver = await User.findById(req.user.userId);
    if (!driver || driver.role !== "DRIVER") {
      return res.status(403).json({ message: "Only drivers can access active requests" });
    }

    const type = driver.vehicleInfo?.type || "CAR";
    let typeQuery = { $in: [type] };
    if (type === "PRIME") typeQuery = { $in: ["PRIME", "CAR"] };

    const rides = await Ride.find({ status: "REQUESTED", vehicleType: typeQuery });
    res.json(rides);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
