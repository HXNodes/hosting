import { useState } from 'react';
export default function Register() {
  const [email, setEmail] = useState('');
  const [name, setName] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    const res = await fetch('/api/auth/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password, name })
    });
    if (res.ok) window.location.href = '/login';
    else setError((await res.json()).error || 'Registration failed');
  };
  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-gray-50 dark:bg-gray-900">
      <form onSubmit={handleRegister} className="bg-white dark:bg-gray-800 p-6 rounded shadow w-80">
        <h2 className="text-2xl font-bold mb-4">Register</h2>
        <input type="text" placeholder="Name" value={name} onChange={e => setName(e.target.value)} className="mb-2 w-full p-2 rounded border" required />
        <input type="email" placeholder="Email" value={email} onChange={e => setEmail(e.target.value)} className="mb-2 w-full p-2 rounded border" required />
        <input type="password" placeholder="Password" value={password} onChange={e => setPassword(e.target.value)} className="mb-2 w-full p-2 rounded border" required />
        {error && <div className="text-red-500 mb-2">{error}</div>}
        <button type="submit" className="w-full bg-blue-600 text-white py-2 rounded">Register</button>
      </form>
    </div>
  );
} 