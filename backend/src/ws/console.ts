import { Server as IOServer } from 'socket.io';
import Docker from 'dockerode';

export function registerConsoleWS(httpServer: any) {
  const io = new IOServer(httpServer, { path: '/ws/console', cors: { origin: '*' } });
  const docker = new Docker();

  io.on('connection', socket => {
    const { containerId } = socket.handshake.query;
    if (!containerId) return socket.disconnect();
    const container = docker.getContainer(containerId as string);
    container.attach({ stream: true, stdout: true, stderr: true, stdin: true }, (err, stream) => {
      if (err) return socket.emit('error', 'Attach failed');
      stream.on('data', data => socket.emit('log', data.toString()));
      socket.on('input', (cmd: string) => stream.write(cmd + '\n'));
      socket.on('disconnect', () => stream.end());
    });
  });
} 