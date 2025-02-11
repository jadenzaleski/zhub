/*
 * File: index.js
 * Created: 2/10/2025
 * Author: Jaden Zaleski
 *
 * Description:
 * Testing of the Dockerode library to interact with Docker containers.
 */

const express = require("express");
const Docker = require("dockerode");
const cors = require("cors");

const app = express();
const docker = new Docker({ socketPath: "/var/run/docker.sock" });

app.use(cors());
app.use(express.json());

// Get all running containers
app.get("/containers", async (req, res) => {
  try {
    const containers = await docker.listContainers({ all: true });
    res.json(containers);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Start a container
app.post("/start/:id", async (req, res) => {
  try {
    const container = docker.getContainer(req.params.id);
    await container.start();
    res.json({ message: `Container ${req.params.id} started` });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Stop a container
app.post("/stop/:id", async (req, res) => {
  try {
    const container = docker.getContainer(req.params.id);
    await container.stop();
    res.json({ message: `Container ${req.params.id} stopped` });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Run server
const PORT = 3000;
app.listen(PORT, () => console.log(`ZHub Backend running on port ${PORT}`));