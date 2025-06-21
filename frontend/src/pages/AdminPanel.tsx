import { useEffect, useState } from 'react';
export default function AdminPanel() {
  const [plans, setPlans] = useState<any[]>([]);
  useEffect(() => {
    const token = localStorage.getItem('token');
    fetch('/api/admin/plans', { headers: { Authorization: `Bearer ${token}` } })
      .then(res => res.json()).then(setPlans);
  }, []);
  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-4">Admin Panel</h1>
      <h2 className="text-xl font-bold mb-2">Plans</h2>
      <ul>
        {plans.map(plan => (
          <li key={plan.id}>{plan.name} — {plan.ramMb}MB RAM — ${plan.price}</li>
        ))}
      </ul>
    </div>
  );
} 