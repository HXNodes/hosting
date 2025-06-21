import { useEffect, useRef, useState } from 'react';
import { io, Socket } from 'socket.io-client';

export default function ServerConsole({ containerId }: { containerId: string }) {
  const [logs, setLogs] = useState<string[]>([]);
  const [input, setInput] = useState('');
  const socketRef = useRef<Socket | null>(null);
  const logRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const socket = io('/', {
      path: '/ws/console',
      query: { containerId },
      transports: ['websocket']
    });
    socketRef.current = socket;
    socket.on('log', (msg: string) => setLogs(logs => [...logs, msg]));
    return () => { socket.disconnect(); };
  }, [containerId]);

  useEffect(() => {
    logRef.current?.scrollTo(0, logRef.current.scrollHeight);
  }, [logs]);

  const sendCommand = (e: React.FormEvent) => {
    e.preventDefault();
    if (input.trim() && socketRef.current) {
      socketRef.current.emit('input', input);
      setInput('');
    }
  };

  return (
    <div className="p-4">
      <h2 className="text-xl font-bold mb-2">Live Console</h2>
      <div ref={logRef} className="bg-black text-green-400 h-64 overflow-y-auto p-2 mb-2 rounded">
        {logs.map((l, i) => <div key={i}>{l}</div>)}
      </div>
      <form onSubmit={sendCommand} className="flex gap-2">
        <input className="flex-1 border p-2 rounded" value={input} onChange={e => setInput(e.target.value)} placeholder="Type command..." />
        <button className="bg-blue-600 text-white px-3 py-1 rounded" type="submit">Send</button>
      </form>
    </div>
  );
} 