const express = require("express");
const http = require("http");
const { Server } = require("socket.io");
const cors = require("cors");
const connectDB = require("./config/db");
const rideRoutes = require("./routes/rideRoutes");
const authRoutes = require("./routes/authRoutes");
const statsRoutes = require("./routes/statsRoutes");
require("dotenv").config();

const app = express();
const server = http.createServer(app);

// Connect to Database
connectDB();

// Middleware
app.use(cors());
app.use(express.json());
app.use((req, res, next) => {
  console.log(`${req.method} ${req.url}`);
  next();
});

// Routes

app.use("/api/auth", authRoutes);
app.use("/api/stats", statsRoutes);
app.use("/api/rides", (req, res, next) => {
  req.io = io;
  next();
}, rideRoutes);

// Socket.io Setup
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  },
});

io.on("connection", (socket) => {
  console.log("A user connected:", socket.id);

  socket.on("join", (userId) => {
    socket.join(userId);
    console.log(`User ${userId} joined their private room.`);
  });

  // Driver status update
  socket.on("update-status", ({ userId, isOnline }) => {
    if (isOnline) {
      socket.join("online-drivers");
      console.log(`Driver ${userId} is now Online.`);
    } else {
      socket.leave("online-drivers");
      console.log(`Driver ${userId} is now Offline.`);
    }
  });

  // Call user signaling
  socket.on("call-user", ({ to, from, rideId }) => {
    console.log(`Call request from ${from} to ${to} for ride ${rideId}`);
    io.to(to).emit("incoming-call", { from, rideId });
  });

  // Accept call signaling
  socket.on("accept-call", ({ to, rideId }) => {
    console.log(`Call accepted by ${to} for ride ${rideId}`);
    io.to(to).emit("call-accepted", { rideId });
  });

  // Reject call signaling
  socket.on("reject-call", ({ to }) => {
    console.log(`Call rejected by recipient.`);
    io.to(to).emit("call-rejected");
  });

  socket.on("disconnect", () => {
    console.log("User disconnected:", socket.id);
  });
});

const PORT = process.env.PORT || 5000;
server.listen(PORT, "0.0.0.0", () => {
  console.log(`Server running on port ${PORT}`);
});
