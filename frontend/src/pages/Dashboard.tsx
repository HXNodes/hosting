import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { Server, Plus, Play, Pause, Trash2, Settings, Terminal, Folder } from 'lucide-react';
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
}

const Dashboard: React.FC = () => {
  const [servers, setServers] = useState<Server[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchServers();
  }, []);

  const fetchServers = async () => {
    try {
      const token = localStorage.getItem('token');
      const response = await fetch('/api/servers', {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });

      if (response.ok) {
        const data = await response.json();
        setServers(data.servers || []);
      } else {
        toast.error('Failed to fetch servers');
      }
    } catch (error) {
      toast.error('Network error');
    } finally {
      setLoading(false);
    }
  };

  const handleServerAction = async (serverId: string, action: 'start' | 'stop' | 'restart' | 'delete') => {
    try {
      const token = localStorage.getItem('token');
      const response = await fetch(`/api/servers/${serverId}/${action}`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });

      if (response.ok) {
        toast.success(`Server ${action}ed successfully`);
        fetchServers();
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

  return (
    <div className="min-h-screen bg-gray-900">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="flex justify-between items-center mb-8">
          <div>
            <h1 className="text-3xl font-bold text-white">Dashboard</h1>
            <p className="text-gray-400 mt-2">Manage your game servers</p>
          </div>
          <Link
            to="/server/new"
            className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg flex items-center space-x-2 transition-colors"
          >
            <Plus className="h-5 w-5" />
            <span>New Server</span>
          </Link>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <div className="bg-gray-800 p-6 rounded-lg">
            <div className="flex items-center">
              <Server className="h-8 w-8 text-blue-500" />
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-400">Total Servers</p>
                <p className="text-2xl font-bold text-white">{servers.length}</p>
              </div>
            </div>
          </div>
          <div className="bg-gray-800 p-6 rounded-lg">
            <div className="flex items-center">
              <Play className="h-8 w-8 text-green-500" />
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-400">Running</p>
                <p className="text-2xl font-bold text-white">
                  {servers.filter(s => s.status === 'running').length}
                </p>
              </div>
            </div>
          </div>
          <div className="bg-gray-800 p-6 rounded-lg">
            <div className="flex items-center">
              <Pause className="h-8 w-8 text-red-500" />
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-400">Stopped</p>
                <p className="text-2xl font-bold text-white">
                  {servers.filter(s => s.status === 'stopped').length}
                </p>
              </div>
            </div>
          </div>
          <div className="bg-gray-800 p-6 rounded-lg">
            <div className="flex items-center">
              <div className="h-8 w-8 bg-purple-500 rounded-full flex items-center justify-center">
                <span className="text-white text-sm font-bold">👥</span>
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-400">Total Players</p>
                <p className="text-2xl font-bold text-white">
                  {servers.reduce((sum, server) => sum + server.players, 0)}
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Servers List */}
        <div className="bg-gray-800 rounded-lg overflow-hidden">
          <div className="px-6 py-4 border-b border-gray-700">
            <h2 className="text-xl font-semibold text-white">Your Servers</h2>
          </div>
          
          {servers.length === 0 ? (
            <div className="p-12 text-center">
              <Server className="h-16 w-16 text-gray-600 mx-auto mb-4" />
              <h3 className="text-lg font-medium text-gray-400 mb-2">No servers yet</h3>
              <p className="text-gray-500 mb-6">Create your first game server to get started</p>
              <Link
                to="/server/new"
                className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-lg inline-flex items-center space-x-2"
              >
                <Plus className="h-5 w-5" />
                <span>Create Server</span>
              </Link>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-700">
                <thead className="bg-gray-700">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                      Server
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                      Status
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                      Players
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                      Resources
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                      Uptime
                    </th>
                    <th className="px-6 py-3 text-right text-xs font-medium text-gray-300 uppercase tracking-wider">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-gray-800 divide-y divide-gray-700">
                  {servers.map((server) => (
                    <tr key={server.id} className="hover:bg-gray-700">
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div>
                          <div className="text-sm font-medium text-white">{server.name}</div>
                          <div className="text-sm text-gray-400">{server.game}</div>
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="flex items-center">
                          <span className="text-lg mr-2">{getStatusIcon(server.status)}</span>
                          <span className={`text-sm font-medium ${getStatusColor(server.status)}`}>
                            {server.status.charAt(0).toUpperCase() + server.status.slice(1)}
                          </span>
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-white">
                          {server.players}/{server.maxPlayers}
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-gray-300">
                          <div>CPU: {server.cpu}%</div>
                          <div>RAM: {server.memory}%</div>
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-300">
                        {server.uptime}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                        <div className="flex items-center justify-end space-x-2">
                          <Link
                            to={`/server/${server.id}`}
                            className="text-blue-400 hover:text-blue-300 p-1"
                            title="View Details"
                          >
                            <Settings className="h-4 w-4" />
                          </Link>
                          <Link
                            to={`/server/${server.id}/console`}
                            className="text-green-400 hover:text-green-300 p-1"
                            title="Console"
                          >
                            <Terminal className="h-4 w-4" />
                          </Link>
                          <Link
                            to={`/server/${server.id}/files`}
                            className="text-purple-400 hover:text-purple-300 p-1"
                            title="File Manager"
                          >
                            <Folder className="h-4 w-4" />
                          </Link>
                          {server.status === 'running' ? (
                            <button
                              onClick={() => handleServerAction(server.id, 'stop')}
                              className="text-yellow-400 hover:text-yellow-300 p-1"
                              title="Stop Server"
                            >
                              <Pause className="h-4 w-4" />
                            </button>
                          ) : (
                            <button
                              onClick={() => handleServerAction(server.id, 'start')}
                              className="text-green-400 hover:text-green-300 p-1"
                              title="Start Server"
                            >
                              <Play className="h-4 w-4" />
                            </button>
                          )}
                          <button
                            onClick={() => handleServerAction(server.id, 'delete')}
                            className="text-red-400 hover:text-red-300 p-1"
                            title="Delete Server"
                          >
                            <Trash2 className="h-4 w-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default Dashboard; 