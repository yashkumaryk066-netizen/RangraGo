const mongoose = require("mongoose");

const userSchema = new mongoose.Schema({
  email: {
    type: String,
    required: true,
    unique: true,
  },
  name: {
    type: String,
    required: true,
  },
  role: {
    type: String,
    enum: ["RIDER", "DRIVER"],
    default: "RIDER",
  },
  phone: {
    type: String,
    default: "",
  },
  profilePic: {
    type: String,
    default: "",
  },
  vehicleInfo: {
    model: String,
    number: String,
    type: {
      type: String,
      enum: ["BIKE", "CAR", "AUTO"],
      default: "CAR",
    },
  },
  isOnline: {
    type: Boolean,
    default: false,
  },
  googleId: {
    type: String,
  },
  isRegistered: {
    type: Boolean,
    default: false,
  },
  aadhaarNumber: {
    type: String,
    default: "",
  },
  licenseNumber: {
    type: String,
    default: "",
  },
  location: {
    type: { type: String, default: "Point" },
    coordinates: { type: [Number], default: [0, 0] }, // [lng, lat]
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

userSchema.index({ location: "2dsphere" });

module.exports = mongoose.model("User", userSchema);

