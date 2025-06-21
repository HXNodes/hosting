import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import authRoutes from './routes/auth';
import serverRoutes from './routes/server';
import billingRoutes from './routes/billing';
import adminRoutes from './routes/admin';
import filesRoutes from './routes/files';
import { registerConsoleWS } from './ws/console';
import { registerResourceWS as registerResourceWSMain } from './ws/resources';
import { setResourceWS } from './ws/resourceWSInstance';
import nodeAgentRoutes from './routes/nodeagent';

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

app.use('/api/auth', authRoutes);
app.use('/api/servers', serverRoutes);
app.use('/api/billing', billingRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/files', filesRoutes);

const PORT = process.env.PORT || 4000;

app.get('/api/health', (_req, res) => {
  res.json({ status: 'ok', time: new Date() });
});

const server = app.listen(PORT, () => {
  console.log(`Backend API running on port ${PORT}`);
});

registerConsoleWS(server);
const resourceWS = registerResourceWSMain(server);
setResourceWS(resourceWS);
app.use('/api/nodeagent', nodeAgentRoutes); 