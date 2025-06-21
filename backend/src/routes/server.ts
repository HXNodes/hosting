import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import { authenticateJWT } from '../middleware/auth';

const router = Router();
const prisma = new PrismaClient();

router.use(authenticateJWT);

router.get('/', async (req, res) => {
  const userId = (req as any).user.id;
  const servers = await prisma.server.findMany({ where: { ownerId: userId } });
  res.json(servers);
});

router.post('/', async (req, res) => {
  const userId = (req as any).user.id;
  const { name, planId, gameType } = req.body;
  const plan = await prisma.plan.findUnique({ where: { id: planId } });
  if (!plan) {
    res.status(400).json({ error: 'Invalid plan' });
    return;
  }
  // Select least-loaded node (stub: pick first)
  const node = await prisma.node.findFirst();
  if (!node) {
    res.status(500).json({ error: 'No nodes available' });
    return;
  }
  // TODO: Call node-agent to provision Docker container
  const server = await prisma.server.create({
    data: {
      ownerId: userId,
      nodeId: node.id,
      planId: plan.id,
      name,
      status: 'provisioning',
      dockerId: '',
      gameType,
      ramMb: plan.ramMb,
      cpuPct: plan.cpuPct,
      diskGb: plan.diskGb,
      port: 25565, // stub
    },
  });
  res.status(201).json(server);
});

router.get('/:id', async (req, res) => {
  const userId = (req as any).user.id;
  const server = await prisma.server.findFirst({ where: { id: req.params.id, ownerId: userId } });
  if (!server) {
    res.status(404).json({ error: 'Not found' });
    return;
  }
  res.json(server);
});

router.delete('/:id', async (req, res) => {
  const userId = (req as any).user.id;
  const server = await prisma.server.findFirst({ where: { id: req.params.id, ownerId: userId } });
  if (!server) {
    res.status(404).json({ error: 'Not found' });
    return;
  }
  // TODO: Call node-agent to remove Docker container
  await prisma.server.delete({ where: { id: req.params.id } });
  res.json({ status: 'deleted' });
});

router.post('/:id/start', async (req, res) => {
  // TODO: Call node-agent to start container
  res.status(501).json({ error: 'Not implemented' });
});

router.post('/:id/stop', async (req, res) => {
  // TODO: Call node-agent to stop container
  res.status(501).json({ error: 'Not implemented' });
});

router.post('/:id/restart', async (req, res) => {
  // TODO: Call node-agent to restart container
  res.status(501).json({ error: 'Not implemented' });
});

export default router; 