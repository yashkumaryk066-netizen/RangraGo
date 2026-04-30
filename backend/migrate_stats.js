const mongoose = require("mongoose");
const User = require("./models/User");
const Ride = require("./models/Ride");
require("dotenv").config();

async function migrate() {
  try {
    await mongoose.connect(process.env.MONGO_URI || "mongodb://127.0.0.1:27017/rangra");
    console.log("Connected to MongoDB for migration...");

    const drivers = await User.find({ role: "DRIVER" });
    console.log(`Found ${drivers.length} drivers. Starting migration...`);

    for (const driver of drivers) {
      const completedRides = await Ride.find({ 
        driverId: driver._id.toString(), 
        status: "COMPLETED" 
      });

      const totalEarnings = completedRides.reduce((sum, r) => sum + (r.fare || 0), 0);
      const count = completedRides.length;

      await User.findByIdAndUpdate(driver._id, {
        totalEarnings,
        completedRides: count
      });

      console.log(`Updated driver ${driver.email}: ${count} rides, ₹${totalEarnings}`);
    }

    console.log("Migration completed successfully.");
    process.exit(0);
  } catch (error) {
    console.error("Migration failed:", error);
    process.exit(1);
  }
}

migrate();
