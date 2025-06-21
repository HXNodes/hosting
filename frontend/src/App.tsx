import { BrowserRouter as Router, Routes, Route, useParams } from 'react-router-dom';
import Home from './pages/Home';
import Login from './pages/Login';
import Register from './pages/Register';
import Dashboard from './pages/Dashboard';
import Billing from './pages/Billing';
import AdminPanel from './pages/AdminPanel';
import ResourceGraphs from './pages/ResourceGraphs';
import ServerDetails from './pages/ServerDetails';
import Nav from './components/Nav';

function ServerDetailsWrapper() {
  const { id } = useParams();
  if (!id) return <div>Invalid server</div>;
  return <ServerDetails serverId={id} />;
}

function App() {
  return (
    <Router>
      <Nav />
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/login" element={<Login />} />
        <Route path="/register" element={<Register />} />
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/billing" element={<Billing />} />
        <Route path="/admin" element={<AdminPanel />} />
        <Route path="/resources" element={<ResourceGraphs />} />
        <Route path="/servers/:id" element={<ServerDetailsWrapper />} />
      </Routes>
    </Router>
  );
}

export default App; 