import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import { authenticateJWT } from '../middleware/auth';

const router = Router();
const prisma = new PrismaClient();

router.get('/plans', async (_req, res) => {
  const plans = await prisma.plan.findMany({ where: { isActive: true } });
  res.json(plans);
});

router.post('/order', authenticateJWT, async (req, res) => {
  const userId = (req as any).user.id;
  const { planId, paymentMethod } = req.body;
  const plan = await prisma.plan.findUnique({ where: { id: planId } });
  if (!plan) {
    res.status(400).json({ error: 'Invalid plan' });
    return;
  }
  // Create order and invoice (stub)
  const order = await prisma.order.create({
    data: {
      userId,
      planId,
      status: 'pending',
      totalPrice: plan.price,
      paymentMethod,
    },
  });
  // Invoice stub
  await prisma.invoice.create({
    data: {
      orderId: order.id,
      userId,
      pdfUrl: '',
      status: 'unpaid',
      dueDate: new Date(),
      total: plan.price,
      tax: 0,
    },
  });
  res.status(201).json({ orderId: order.id });
});

router.get('/invoices', authenticateJWT, async (req, res) => {
  const userId = (req as any).user.id;
  const invoices = await prisma.invoice.findMany({ where: { userId } });
  res.json(invoices);
});

router.post('/payment/webhook', async (req, res) => {
  // Payment provider webhook stub
  res.json({ status: 'ok' });
});

export default router; 