import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';
import Nav from './components/Nav';
import Home from './pages/Home';
import Login from './pages/Login';
import Register from './pages/Register';
import Dashboard from './pages/Dashboard';
import ServerDetails from './pages/ServerDetails';
import ServerConsole from './pages/ServerConsole';
import FileManager from './pages/FileManager';
import Billing from './pages/Billing';
import ResourceGraphs from './pages/ResourceGraphs';
import AdminPanel from './pages/AdminPanel';
import './index.css';

function App() {
  return (
    <Router>
      <div className="min-h-screen bg-gray-900 text-white">
        <Nav />
        <main className="pt-16">
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/login" element={<Login />} />
            <Route path="/register" element={<Register />} />
            <Route path="/dashboard" element={<Dashboard />} />
            <Route path="/server/:id" element={<ServerDetails />} />
            <Route path="/server/:id/console" element={<ServerConsole />} />
            <Route path="/server/:id/files" element={<FileManager />} />
            <Route path="/billing" element={<Billing />} />
            <Route path="/graphs" element={<ResourceGraphs />} />
            <Route path="/admin" element={<AdminPanel />} />
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </main>
        <Toaster position="top-right" />
      </div>
    </Router>
  );
}

export default App; 