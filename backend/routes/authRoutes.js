const express = require("express");
const router = express.Router();
const User = require("../models/User");
const jwt = require("jsonwebtoken");
const verifyToken = require("../middleware/auth");

const { generateToken } = require("../config/agora");

// Login/Register combined logic
router.post("/login", async (req, res) => {
  try {
    const { email, name, googleId, role } = req.body;

    let user = await User.findOne({ email });

    if (!user) {
      user = await User.create({
        email,
        name,
        googleId,
        role,
        isRegistered: true
      });
      console.log(`New user registered: ${email}`);
    }

    const token = jwt.sign(
      { userId: user._id, role: user.role },
      process.env.JWT_SECRET || "supersecret",
      { expiresIn: "7d" }
    );

    res.json({
      message: "Login successful",
      user,
      token
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Get Agora Token
router.post("/agora-token", verifyToken, async (req, res) => {
  try {
    const { channelName } = req.body;
    const uid = 0; // UID 0 allows any user
    const token = generateToken(channelName, uid);
    res.json({ token });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Get Profile
router.get("/profile", verifyToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    if (!user) return res.status(404).json({ message: "User not found" });
    res.json(user);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Update Profile
router.put("/profile", verifyToken, async (req, res) => {
  try {
    const updates = req.body;
    const user = await User.findByIdAndUpdate(req.user.userId, updates, { new: true });
    res.json({ message: "Profile updated", user });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Update Location (Driver)
router.put("/location", verifyToken, async (req, res) => {
  try {
    const { lat, lng } = req.body;
    const driverId = req.user.userId;

    await User.findByIdAndUpdate(driverId, {
      location: {
        type: "Point",
        coordinates: [lng, lat]
      }
    });

    // Broadcast to active ride's rider
    const Ride = require("../models/Ride");
    const activeRide = await Ride.findOne({ 
      driver: driverId, 
      status: { $in: ["ACCEPTED", "STARTED"] } 
    });

    if (activeRide && req.io) {
      req.io.to(activeRide.rider.toString()).emit("driver-location-update", {
        lat,
        lng,
        rideId: activeRide._id
      });
    }

    res.json({ message: "Location updated" });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

module.exports = router;

