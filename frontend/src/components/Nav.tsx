import { Link } from 'react-router-dom';
export default function Nav() {
  const token = localStorage.getItem('token');
  return (
    <nav className="p-4 bg-gray-200 dark:bg-gray-800 flex gap-4">
      <Link to="/">Home</Link>
      {token ? (
        <>
          <Link to="/dashboard">Dashboard</Link>
          <Link to="/billing">Billing</Link>
          <Link to="/admin">Admin</Link>
          <button onClick={() => { localStorage.removeItem('token'); window.location.href = '/login'; }}>Logout</button>
        </>
      ) : (
        <>
          <Link to="/login">Login</Link>
          <Link to="/register">Register</Link>
        </>
      )}
    </nav>
  );
} 