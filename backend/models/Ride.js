const mongoose = require("mongoose");

const rideSchema = new mongoose.Schema({
  userId: {
    type: String,
    required: true,
  },
  driverId: {
    type: String,
    default: null,
  },
  pickup: {
    type: String,
    required: true,
  },
  pickupCoords: {
    lat: { type: Number, required: true },
    lng: { type: Number, required: true },
  },
  drop: {
    type: String,
    required: true,
  },
  dropCoords: {
    lat: { type: Number, required: true },
    lng: { type: Number, required: true },
  },
  status: {
    type: String,
    enum: ["REQUESTED", "ACCEPTED", "STARTED", "COMPLETED", "CANCELLED"],
    default: "REQUESTED",
  },
  vehicleType: {
    type: String,
    default: "BIKE",
  },
  fare: {
    type: Number,
    default: 0,
  },
  distance: {
    type: String, // e.g. "5.4 km"
    default: "",
  },
  duration: {
    type: String, // e.g. "15 mins"
    default: "",
  },
  otp: {
    type: String,
    default: () => Math.floor(1000 + Math.random() * 9000).toString(),
  },
  paymentStatus: {
    type: String,
    enum: ["PENDING", "PAID"],
    default: "PENDING",
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model("Ride", rideSchema);

