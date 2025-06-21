import { Router } from 'express';
import { resourceWS } from '../ws/resourceWSInstance';
const router = Router();

router.post('/stats', (req, res) => {
  // req.body: { nodeId, stats }
  resourceWS.updateNodeStats(req.body.nodeId, req.body.stats);
  res.json({ status: 'ok' });
});

export default router; 