const express = require('express');
const Docker = require('dockerode');
const dotenv = require('dotenv');
const axios = require('axios');

dotenv.config();

const app = express();
app.use(express.json());
const PORT = process.env.AGENT_PORT || 5001;
const docker = new Docker();

app.get('/health', (req, res) => {
  res.json({ status: 'ok', node: process.env.NODE_NAME || 'unnamed', time: new Date() });
});

app.post('/container/create', (req, res) => {
  // Stub: create Docker container
  res.json({ status: 'created', containerId: 'abc123' });
});

app.post('/container/start', (req, res) => {
  // Stub: start Docker container
  res.json({ status: 'started' });
});

app.post('/container/stop', (req, res) => {
  // Stub: stop Docker container
  res.json({ status: 'stopped' });
});

setInterval(async () => {
  // Gather stats (CPU, RAM, Disk, etc.)
  const stats = { cpu: Math.random() * 100, ram: Math.random() * 100, disk: Math.random() * 100 };
  try {
    await axios.post('http://localhost:4000/api/nodeagent/stats', {
      nodeId: process.env.NODE_NAME || 'localnode',
      stats
    });
  } catch (e) {
    // Ignore errors
  }
}, 5000);

app.listen(PORT, () => {
  console.log(`Node agent running on port ${PORT}`);
}); 