import React from 'react';
import { Link } from 'react-router-dom';
import { Server, Zap, Shield, CreditCard, BarChart3, Users } from 'lucide-react';

const Home: React.FC = () => {
  return (
    <div className="min-h-screen bg-gray-900">
      {/* Hero Section */}
      <div className="relative overflow-hidden">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-24">
          <div className="text-center">
            <h1 className="text-4xl md:text-6xl font-bold text-white mb-6">
              Game Server Management
              <span className="text-blue-500"> Made Simple</span>
            </h1>
            <p className="text-xl text-gray-300 mb-8 max-w-3xl mx-auto">
              Deploy, manage, and scale your game servers with ease. 
              Complete control with powerful tools and real-time monitoring.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Link
                to="/register"
                className="bg-blue-600 hover:bg-blue-700 text-white px-8 py-3 rounded-lg font-semibold text-lg transition-colors"
              >
                Get Started Free
              </Link>
              <Link
                to="/login"
                className="border border-gray-600 hover:border-gray-500 text-white px-8 py-3 rounded-lg font-semibold text-lg transition-colors"
              >
                Sign In
              </Link>
            </div>
          </div>
        </div>
      </div>

      {/* Features Section */}
      <div className="py-24 bg-gray-800">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-3xl md:text-4xl font-bold text-white mb-4">
              Everything You Need
            </h2>
            <p className="text-xl text-gray-300">
              Powerful features to manage your game servers efficiently
            </p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
            <div className="bg-gray-700 p-6 rounded-lg">
              <Server className="h-12 w-12 text-blue-500 mb-4" />
              <h3 className="text-xl font-semibold text-white mb-2">Server Management</h3>
              <p className="text-gray-300">
                Deploy and manage multiple game servers with one-click installation and automated updates.
              </p>
            </div>

            <div className="bg-gray-700 p-6 rounded-lg">
              <Zap className="h-12 w-12 text-green-500 mb-4" />
              <h3 className="text-xl font-semibold text-white mb-2">Real-time Monitoring</h3>
              <p className="text-gray-300">
                Monitor server performance, resource usage, and player activity in real-time with detailed graphs.
              </p>
            </div>

            <div className="bg-gray-700 p-6 rounded-lg">
              <Shield className="h-12 w-12 text-purple-500 mb-4" />
              <h3 className="text-xl font-semibold text-white mb-2">Security & Backup</h3>
              <p className="text-gray-300">
                Automatic backups, DDoS protection, and secure access controls to keep your servers safe.
              </p>
            </div>

            <div className="bg-gray-700 p-6 rounded-lg">
              <CreditCard className="h-12 w-12 text-yellow-500 mb-4" />
              <h3 className="text-xl font-semibold text-white mb-2">Flexible Billing</h3>
              <p className="text-gray-300">
                Pay-as-you-go pricing with multiple payment methods and detailed usage tracking.
              </p>
            </div>

            <div className="bg-gray-700 p-6 rounded-lg">
              <BarChart3 className="h-12 w-12 text-red-500 mb-4" />
              <h3 className="text-xl font-semibold text-white mb-2">Analytics</h3>
              <p className="text-gray-300">
                Comprehensive analytics and reporting to optimize your server performance and costs.
              </p>
            </div>

            <div className="bg-gray-700 p-6 rounded-lg">
              <Users className="h-12 w-12 text-indigo-500 mb-4" />
              <h3 className="text-xl font-semibold text-white mb-2">Team Management</h3>
              <p className="text-gray-300">
                Manage team access, permissions, and collaboration tools for your server infrastructure.
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* CTA Section */}
      <div className="py-24 bg-gray-900">
        <div className="max-w-4xl mx-auto text-center px-4 sm:px-6 lg:px-8">
          <h2 className="text-3xl md:text-4xl font-bold text-white mb-6">
            Ready to Get Started?
          </h2>
          <p className="text-xl text-gray-300 mb-8">
            Join thousands of game developers and server administrators who trust hxnodes.
          </p>
          <Link
            to="/register"
            className="bg-blue-600 hover:bg-blue-700 text-white px-8 py-4 rounded-lg font-semibold text-lg transition-colors inline-block"
          >
            Start Your Free Trial
          </Link>
        </div>
      </div>

      {/* Footer */}
      <footer className="bg-gray-800 border-t border-gray-700 py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center">
            <div className="flex items-center justify-center space-x-2 mb-4">
              <Server className="h-6 w-6 text-blue-500" />
              <span className="text-xl font-bold text-white">hxnodes</span>
            </div>
            <p className="text-gray-300 mb-4">
              Professional game server management platform
            </p>
            <div className="flex justify-center space-x-6 text-sm text-gray-400">
              <a href="#" className="hover:text-white">Privacy Policy</a>
              <a href="#" className="hover:text-white">Terms of Service</a>
              <a href="#" className="hover:text-white">Support</a>
              <a href="#" className="hover:text-white">Documentation</a>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
};

export default Home; 