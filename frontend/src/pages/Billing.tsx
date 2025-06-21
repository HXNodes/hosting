import { useEffect, useState } from 'react';
export default function Billing() {
  const [invoices, setInvoices] = useState<any[]>([]);
  useEffect(() => {
    const token = localStorage.getItem('token');
    fetch('/api/billing/invoices', { headers: { Authorization: `Bearer ${token}` } })
      .then(res => res.json()).then(setInvoices);
  }, []);
  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-4">Billing</h1>
      <ul>
        {invoices.map(inv => (
          <li key={inv.id} className="mb-2">{inv.id} — {inv.status} — ${inv.total}</li>
        ))}
      </ul>
    </div>
  );
} 