import { Server as IOServer } from 'socket.io';

let nodeStats: Record<string, any> = {};

export function registerResourceWS(httpServer: any) {
  const io = new IOServer(httpServer, { path: '/ws/resources', cors: { origin: '*' } });

  io.on('connection', socket => {
    socket.emit('stats', nodeStats);
  });

  // Expose a function for node agents to report stats
  return {
    updateNodeStats: (nodeId: string, stats: any) => {
      nodeStats[nodeId] = stats;
      io.emit('stats', nodeStats);
    }
  };
} 