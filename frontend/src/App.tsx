import React from 'react'

function App() {
  return (
    <div className="min-h-screen bg-gray-900 text-white">
      <div className="container mx-auto px-4 py-8">
        <h1 className="text-4xl font-bold text-center mb-8">
          hxnodes - Game Server Management
        </h1>
        <div className="bg-gray-800 rounded-lg p-6 max-w-md mx-auto">
          <p className="text-center text-gray-300">
            Welcome to hxnodes! Your game server management panel is being set up.
          </p>
          <div className="mt-4 text-center">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500 mx-auto"></div>
            <p className="mt-2 text-sm text-gray-400">Loading...</p>
          </div>
        </div>
      </div>
    </div>
  )
}

export default App 