import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';

export default function Dashboard() {
  const [servers, setServers] = useState<any[]>([]);
  const [error, setError] = useState('');

  useEffect(() => {
    const token = localStorage.getItem('token');
    if (!token) {
      window.location.href = '/login';
      return;
    }
    fetch('/api/servers', {
      headers: { Authorization: `Bearer ${token}` }
    })
      .then(res => res.json())
      .then(data => setServers(data))
      .catch(() => setError('Failed to load servers'));
  }, []);

  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold mb-4">Dashboard</h1>
      {error && <div className="text-red-500 mb-2">{error}</div>}
      <ul>
        {servers.map(s => (
          <li key={s.id} className="mb-2 p-2 border rounded bg-white dark:bg-gray-800">
            <b>
              <Link to={`/servers/${s.id}`}>{s.name}</Link>
            </b> — {s.status} — {s.gameType}
          </li>
        ))}
      </ul>
    </div>
  );
} 