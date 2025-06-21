import { useEffect, useState } from 'react';
import FileManager from './FileManager';
import ServerConsole from './ServerConsole';

type Server = {
  id: string;
  name: string;
  status: string;
  gameType: string;
  dockerId: string;
};

export default function ServerDetails({ serverId }: { serverId: string }) {
  const [server, setServer] = useState<Server | null>(null);
  const [tab, setTab] = useState<'console' | 'files' | 'stats'>('console');
  const token = localStorage.getItem('token');

  useEffect(() => {
    fetch(`/api/servers/${serverId}`, {
      headers: { Authorization: `Bearer ${token}` }
    })
      .then(res => res.json())
      .then(setServer);
  }, [serverId, token]);

  if (!server) return <div>Loading...</div>;

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-4">{server.name}</h1>
      <div className="mb-4 flex gap-4">
        <button onClick={() => setTab('console')} className={tab === 'console' ? 'font-bold' : ''}>Console</button>
        <button onClick={() => setTab('files')} className={tab === 'files' ? 'font-bold' : ''}>Files</button>
        <button onClick={() => setTab('stats')} className={tab === 'stats' ? 'font-bold' : ''}>Stats</button>
      </div>
      {tab === 'console' && <ServerConsole containerId={server.dockerId} />}
      {tab === 'files' && <FileManager serverId={server.id} />}
      {tab === 'stats' && (
        <div>
          <div>Status: {server.status}</div>
          <div>Game: {server.gameType}</div>
          {/* Add resource graphs here if desired */}
        </div>
      )}
    </div>
  );
} 