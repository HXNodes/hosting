import React, { useState, useEffect, useRef } from 'react';
import { useParams, Link } from 'react-router-dom';
import { ArrowLeft, Send, Download, Upload, Trash2 } from 'lucide-react';
import toast from 'react-hot-toast';

const ServerConsole: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const [messages, setMessages] = useState<string[]>([]);
  const [input, setInput] = useState('');
  const [connected, setConnected] = useState(false);
  const [loading, setLoading] = useState(true);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const wsRef = useRef<WebSocket | null>(null);

  useEffect(() => {
    if (id) {
      connectWebSocket();
    }
    return () => {
      if (wsRef.current) {
        wsRef.current.close();
      }
    };
  }, [id]);

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const connectWebSocket = () => {
    try {
      const token = localStorage.getItem('token');
      const ws = new WebSocket(`ws://${window.location.host}/ws/console/${id}?token=${token}`);
      
      ws.onopen = () => {
        setConnected(true);
        setLoading(false);
        toast.success('Connected to server console');
      };

      ws.onmessage = (event) => {
        const message = event.data;
        setMessages(prev => [...prev, message]);
      };

      ws.onclose = () => {
        setConnected(false);
        toast.error('Disconnected from server console');
      };

      ws.onerror = (error) => {
        console.error('WebSocket error:', error);
        toast.error('Failed to connect to console');
        setLoading(false);
      };

      wsRef.current = ws;
    } catch (error) {
      console.error('WebSocket connection error:', error);
      toast.error('Failed to connect to console');
      setLoading(false);
    }
  };

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const sendCommand = () => {
    if (!input.trim() || !connected) return;

    if (wsRef.current && wsRef.current.readyState === WebSocket.OPEN) {
      wsRef.current.send(input);
      setInput('');
    }
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      sendCommand();
    }
  };

  const clearConsole = () => {
    setMessages([]);
    toast.success('Console cleared');
  };

  const downloadLogs = () => {
    const logContent = messages.join('\n');
    const blob = new Blob([logContent], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `server-${id}-logs.txt`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
    toast.success('Logs downloaded');
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
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center space-x-4">
            <Link
              to={`/server/${id}`}
              className="text-gray-400 hover:text-white transition-colors"
            >
              <ArrowLeft className="h-6 w-6" />
            </Link>
            <div>
              <h1 className="text-2xl font-bold text-white">Server Console</h1>
              <p className="text-gray-400">Real-time server console output</p>
            </div>
          </div>
          
          <div className="flex items-center space-x-3">
            <div className={`flex items-center space-x-2 ${connected ? 'text-green-500' : 'text-red-500'}`}>
              <div className={`w-3 h-3 rounded-full ${connected ? 'bg-green-500' : 'bg-red-500'}`}></div>
              <span className="text-sm font-medium">
                {connected ? 'Connected' : 'Disconnected'}
              </span>
            </div>
            
            <button
              onClick={downloadLogs}
              className="bg-blue-600 hover:bg-blue-700 text-white px-3 py-2 rounded-lg flex items-center space-x-2 transition-colors"
              title="Download Logs"
            >
              <Download className="h-4 w-4" />
              <span className="hidden sm:inline">Download</span>
            </button>
            
            <button
              onClick={clearConsole}
              className="bg-red-600 hover:bg-red-700 text-white px-3 py-2 rounded-lg flex items-center space-x-2 transition-colors"
              title="Clear Console"
            >
              <Trash2 className="h-4 w-4" />
              <span className="hidden sm:inline">Clear</span>
            </button>
          </div>
        </div>

        {/* Console Output */}
        <div className="bg-gray-800 rounded-lg overflow-hidden mb-4">
          <div className="px-4 py-3 border-b border-gray-700 bg-gray-700">
            <h3 className="text-sm font-medium text-gray-300">Console Output</h3>
          </div>
          
          <div className="h-96 overflow-y-auto p-4 font-mono text-sm">
            <div className="space-y-1">
              {messages.map((message, index) => (
                <div key={index} className="text-gray-300 whitespace-pre-wrap">
                  {message}
                </div>
              ))}
              <div ref={messagesEndRef} />
            </div>
            
            {messages.length === 0 && (
              <div className="text-gray-500 text-center py-8">
                No console output yet. Start your server to see logs here.
              </div>
            )}
          </div>
        </div>

        {/* Command Input */}
        <div className="bg-gray-800 rounded-lg p-4">
          <div className="flex space-x-3">
            <div className="flex-1">
              <input
                type="text"
                value={input}
                onChange={(e) => setInput(e.target.value)}
                onKeyPress={handleKeyPress}
                placeholder="Enter command..."
                disabled={!connected}
                className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent disabled:opacity-50 disabled:cursor-not-allowed"
              />
            </div>
            <button
              onClick={sendCommand}
              disabled={!connected || !input.trim()}
              className="bg-green-600 hover:bg-green-700 disabled:bg-gray-600 disabled:cursor-not-allowed text-white px-4 py-2 rounded-lg flex items-center space-x-2 transition-colors"
            >
              <Send className="h-4 w-4" />
              <span>Send</span>
            </button>
          </div>
          
          {!connected && (
            <div className="mt-3 text-sm text-yellow-500">
              ⚠️ Console is disconnected. Make sure your server is running.
            </div>
          )}
        </div>

        {/* Quick Commands */}
        <div className="bg-gray-800 rounded-lg p-4 mt-4">
          <h3 className="text-sm font-medium text-gray-300 mb-3">Quick Commands</h3>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-2">
            {[
              { label: 'Status', command: 'status' },
              { label: 'Players', command: 'list' },
              { label: 'Save', command: 'save-all' },
              { label: 'Stop', command: 'stop' }
            ].map((cmd) => (
              <button
                key={cmd.command}
                onClick={() => {
                  setInput(cmd.command);
                  if (connected) {
                    setTimeout(() => sendCommand(), 100);
                  }
                }}
                disabled={!connected}
                className="bg-gray-700 hover:bg-gray-600 disabled:bg-gray-600 disabled:cursor-not-allowed text-white px-3 py-2 rounded text-sm transition-colors"
              >
                {cmd.label}
              </button>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

export default ServerConsole; 