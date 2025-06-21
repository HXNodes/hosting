import React, { useState, useEffect } from 'react';
import { useParams, Link } from 'react-router-dom';
import { ArrowLeft, Play, Pause, RotateCcw, Settings, Terminal, Folder, Trash2, Cpu, Memory, Users, Clock } from 'lucide-react';
import toast from 'react-hot-toast';

interface Server {
  id: string;
  name: string;
  status: 'running' | 'stopped' | 'starting' | 'stopping';
  game: string;
  players: number;
  maxPlayers: number;
  cpu: number;
  memory: number;
  uptime: string;
  port: number;
  ip: string;
  version: string;
  createdAt: string;
}

const ServerDetails: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const [server, setServer] = useState<Server | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (id) {
      fetchServer();
    }
  }, [id]);

  const fetchServer = async () => {
    try {
      const token = localStorage.getItem('token');
      const response = await fetch(`/api/servers/${id}`, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });

      if (response.ok) {
        const data = await response.json();
        setServer(data.server);
      } else {
        toast.error('Failed to fetch server details');
      }
    } catch (error) {
      toast.error('Network error');
    } finally {
      setLoading(false);
    }
  };

  const handleServerAction = async (action: 'start' | 'stop' | 'restart' | 'delete') => {
    if (!server) return;

    try {
      const token = localStorage.getItem('token');
      const response = await fetch(`/api/servers/${server.id}/${action}`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });

      if (response.ok) {
        toast.success(`Server ${action}ed successfully`);
        if (action === 'delete') {
          window.location.href = '/dashboard';
        } else {
          fetchServer();
        }
      } else {
        toast.error(`Failed to ${action} server`);
      }
    } catch (error) {
      toast.error('Network error');
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'running': return 'text-green-500';
      case 'stopped': return 'text-red-500';
      case 'starting': return 'text-yellow-500';
      case 'stopping': return 'text-orange-500';
      default: return 'text-gray-500';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'running': return '🟢';
      case 'stopped': return '🔴';
      case 'starting': return '🟡';
      case 'stopping': return '🟠';
      default: return '⚪';
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500"></div>
      </div>
    );
  }

  if (!server) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <div className="text-center">
          <h2 className="text-2xl font-bold text-white mb-4">Server not found</h2>
          <Link to="/dashboard" className="text-blue-500 hover:text-blue-400">
            Back to Dashboard
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-900">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <div className="flex items-center space-x-4">
            <Link
              to="/dashboard"
              className="text-gray-400 hover:text-white transition-colors"
            >
              <ArrowLeft className="h-6 w-6" />
            </Link>
            <div>
              <h1 className="text-3xl font-bold text-white">{server.name}</h1>
              <p className="text-gray-400">{server.game}</p>
            </div>
          </div>
          
          <div className="flex items-center space-x-3">
            <div className="flex items-center space-x-2">
              <span className="text-lg">{getStatusIcon(server.status)}</span>
              <span className={`text-sm font-medium ${getStatusColor(server.status)}`}>
                {server.status.charAt(0).toUpperCase() + server.status.slice(1)}
              </span>
            </div>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="bg-gray-800 rounded-lg p-6 mb-8">
          <div className="flex flex-wrap items-center justify-between">
            <div className="flex items-center space-x-4 mb-4 sm:mb-0">
              <h2 className="text-xl font-semibold text-white">Quick Actions</h2>
            </div>
            
            <div className="flex items-center space-x-3">
              {server.status === 'running' ? (
                <button
                  onClick={() => handleServerAction('stop')}
                  className="bg-yellow-600 hover:bg-yellow-700 text-white px-4 py-2 rounded-lg flex items-center space-x-2 transition-colors"
                >
                  <Pause className="h-4 w-4" />
                  <span>Stop</span>
                </button>
              ) : (
                <button
                  onClick={() => handleServerAction('start')}
                  className="bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded-lg flex items-center space-x-2 transition-colors"
                >
                  <Play className="h-4 w-4" />
                  <span>Start</span>
                </button>
              )}
              
              <button
                onClick={() => handleServerAction('restart')}
                className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg flex items-center space-x-2 transition-colors"
              >
                <RotateCcw className="h-4 w-4" />
                <span>Restart</span>
              </button>
              
              <button
                onClick={() => handleServerAction('delete')}
                className="bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded-lg flex items-center space-x-2 transition-colors"
              >
                <Trash2 className="h-4 w-4" />
                <span>Delete</span>
              </button>
            </div>
          </div>
        </div>

        {/* Server Info Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
          {/* Server Information */}
          <div className="bg-gray-800 rounded-lg p-6">
            <h3 className="text-lg font-semibold text-white mb-4">Server Information</h3>
            <div className="space-y-4">
              <div className="flex justify-between">
                <span className="text-gray-400">Status</span>
                <span className={`font-medium ${getStatusColor(server.status)}`}>
                  {server.status.charAt(0).toUpperCase() + server.status.slice(1)}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-400">Game</span>
                <span className="text-white">{server.game}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-400">Version</span>
                <span className="text-white">{server.version}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-400">IP Address</span>
                <span className="text-white">{server.ip}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-400">Port</span>
                <span className="text-white">{server.port}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-400">Created</span>
                <span className="text-white">{new Date(server.createdAt).toLocaleDateString()}</span>
              </div>
            </div>
          </div>

          {/* Resource Usage */}
          <div className="bg-gray-800 rounded-lg p-6">
            <h3 className="text-lg font-semibold text-white mb-4">Resource Usage</h3>
            <div className="space-y-6">
              <div>
                <div className="flex justify-between mb-2">
                  <span className="text-gray-400">CPU Usage</span>
                  <span className="text-white">{server.cpu}%</span>
                </div>
                <div className="w-full bg-gray-700 rounded-full h-2">
                  <div 
                    className="bg-blue-500 h-2 rounded-full transition-all duration-300"
                    style={{ width: `${server.cpu}%` }}
                  ></div>
                </div>
              </div>
              
              <div>
                <div className="flex justify-between mb-2">
                  <span className="text-gray-400">Memory Usage</span>
                  <span className="text-white">{server.memory}%</span>
                </div>
                <div className="w-full bg-gray-700 rounded-full h-2">
                  <div 
                    className="bg-green-500 h-2 rounded-full transition-all duration-300"
                    style={{ width: `${server.memory}%` }}
                  ></div>
                </div>
              </div>
              
              <div>
                <div className="flex justify-between mb-2">
                  <span className="text-gray-400">Players</span>
                  <span className="text-white">{server.players}/{server.maxPlayers}</span>
                </div>
                <div className="w-full bg-gray-700 rounded-full h-2">
                  <div 
                    className="bg-purple-500 h-2 rounded-full transition-all duration-300"
                    style={{ width: `${(server.players / server.maxPlayers) * 100}%` }}
                  ></div>
                </div>
              </div>
              
              <div className="flex justify-between">
                <span className="text-gray-400">Uptime</span>
                <span className="text-white">{server.uptime}</span>
              </div>
            </div>
          </div>
        </div>

        {/* Quick Access */}
        <div className="bg-gray-800 rounded-lg p-6">
          <h3 className="text-lg font-semibold text-white mb-4">Quick Access</h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <Link
              to={`/server/${server.id}/console`}
              className="bg-gray-700 hover:bg-gray-600 p-4 rounded-lg flex items-center space-x-3 transition-colors"
            >
              <Terminal className="h-6 w-6 text-green-500" />
              <div>
                <div className="text-white font-medium">Console</div>
                <div className="text-gray-400 text-sm">Access server console</div>
              </div>
            </Link>
            
            <Link
              to={`/server/${server.id}/files`}
              className="bg-gray-700 hover:bg-gray-600 p-4 rounded-lg flex items-center space-x-3 transition-colors"
            >
              <Folder className="h-6 w-6 text-purple-500" />
              <div>
                <div className="text-white font-medium">File Manager</div>
                <div className="text-gray-400 text-sm">Manage server files</div>
              </div>
            </Link>
            
            <Link
              to={`/server/${server.id}/settings`}
              className="bg-gray-700 hover:bg-gray-600 p-4 rounded-lg flex items-center space-x-3 transition-colors"
            >
              <Settings className="h-6 w-6 text-blue-500" />
              <div>
                <div className="text-white font-medium">Settings</div>
                <div className="text-gray-400 text-sm">Configure server</div>
              </div>
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ServerDetails; 