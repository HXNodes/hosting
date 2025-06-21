import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import { authenticateJWT } from '../middleware/auth';

const router = Router();
const prisma = new PrismaClient();

router.use(authenticateJWT);

router.get('/plans', async (_req, res) => {
  const plans = await prisma.plan.findMany();
  res.json(plans);
});

router.post('/plans', async (req, res) => {
  const { name, description, ramMb, cpuPct, diskGb, price, billingCycle, gameTypes, maxServersPerUser } = req.body;
  const plan = await prisma.plan.create({
    data: { name, description, ramMb, cpuPct, diskGb, price, billingCycle, gameTypes, maxServersPerUser } });
  res.status(201).json(plan);
});

router.put('/plans/:id', async (req, res) => {
  const { id } = req.params;
  const data = req.body;
  const plan = await prisma.plan.update({ where: { id }, data });
  res.json(plan);
});

router.delete('/plans/:id', async (req, res) => {
  const { id } = req.params;
  await prisma.plan.delete({ where: { id } });
  res.json({ status: 'deleted' });
});

router.get('/nodes', async (_req, res) => {
  const nodes = await prisma.node.findMany();
  res.json(nodes);
});

router.post('/nodes', async (req, res) => {
  const { name, ipAddress, apiKey, cpuTotal, ramTotal, diskTotal, location } = req.body;
  const node = await prisma.node.create({ data: { name, ipAddress, apiKey, status: 'online', cpuTotal, ramTotal, diskTotal, location } });
  res.status(201).json(node);
});

router.put('/nodes/:id', async (req, res) => {
  const { id } = req.params;
  const data = req.body;
  const node = await prisma.node.update({ where: { id }, data });
  res.json(node);
});

router.delete('/nodes/:id', async (req, res) => {
  const { id } = req.params;
  await prisma.node.delete({ where: { id } });
  res.json({ status: 'deleted' });
});

router.get('/users', async (_req, res) => {
  const users = await prisma.user.findMany({ select: { id: true, email: true, name: true, isActive: true } });
  res.json(users);
});

router.put('/users/:id/suspend', async (req, res) => {
  const { id } = req.params;
  await prisma.user.update({ where: { id }, data: { isActive: false } });
  res.json({ status: 'suspended' });
});

router.put('/users/:id/unsuspend', async (req, res) => {
  const { id } = req.params;
  await prisma.user.update({ where: { id }, data: { isActive: true } });
  res.json({ status: 'unsuspended' });
});

export default router; 