import { useEffect, useState } from 'react';

export default function Home() {
  const [status, setStatus] = useState('');

  useEffect(() => {
    fetch('/api/health')
      .then(res => res.json())
      .then(data => setStatus(data.status))
      .catch(() => setStatus('offline'));
  }, []);

  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-gray-50 dark:bg-gray-900">
      <h1 className="text-4xl font-bold mb-4">Welcome to hxnodes</h1>
      <p className="mb-2">Game server management & billing platform</p>
      <span className={`px-3 py-1 rounded text-white ${status === 'ok' ? 'bg-green-500' : 'bg-red-500'}`}>Backend: {status || 'checking...'}</span>
    </div>
  );
} 