import { useState } from 'react';
import { LogOut, Users, BarChart3, Moon, Sun, Menu, X, Map, Clock, HeartPulse } from 'lucide-react'; // Added Map, Clock
import DashboardPage from '../pages/DashboardPage';
import InstructorsPage from '../pages/InstructorsPage';
import GroupsMapPage from '../pages/GroupsMapPage';
import SessionsPage from '../pages/SessionsPage';
import HealthProfilesPage from '../pages/HealthProfilesPage';

export default function DashboardLayout({ onLogout, darkMode, setDarkMode }) {
  const [currentView, setCurrentView] = useState('dashboard');
  const [sidebarOpen, setSidebarOpen] = useState(false);

  const renderCurrentView = () => {
    switch (currentView) {
      case 'dashboard':
        return <DashboardPage darkMode={darkMode} />;
      case 'instructors':
        return <InstructorsPage darkMode={darkMode} />;
      case 'map':
        return <GroupsMapPage darkMode={darkMode} />;
      case 'sessions':
        return <SessionsPage darkMode={darkMode} />;
      case 'health': // ESIS: Health Profiles View
        return <HealthProfilesPage darkMode={darkMode} />;
      default:
        return <DashboardPage darkMode={darkMode} />;
    }
  };

  return (
    <div className={`flex h-screen transition-colors duration-300 ${darkMode ? 'bg-gray-900' : 'bg-gray-100'}`}>
      {/* Mobile Overlay */}
      {sidebarOpen && (
        <div 
          className="fixed inset-0 bg-black/50 z-40 lg:hidden"
          onClick={() => setSidebarOpen(false)}
          aria-hidden="true"
        ></div>
      )}

      {/* Sidebar */}
      <div className={`fixed lg:static inset-y-0 left-0 z-50 w-72 flex flex-col transition-all duration-300 ${
        darkMode ? 'bg-gray-800 border-gray-700' : 'bg-white border-gray-200'
      } shadow-2xl border-r transform ${sidebarOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'}`}>
        <div className={`p-6 border-b ${darkMode ? 'border-gray-700' : 'border-gray-200'}`}>
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <img src="/website_logo.jpg" alt="YES Logo" className="w-12 h-12 rounded-xl shadow-md" />
              <div>
                <h2 className={`text-xl font-bold ${darkMode ? 'text-white' : 'text-gray-800'}`}>YES</h2>
                <p className={`text-xs ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>Admin Portal</p>
              </div>
            </div>
            <button
              onClick={() => setSidebarOpen(false)}
              className={`lg:hidden p-2 rounded-lg ${darkMode ? 'text-gray-300 hover:bg-gray-700' : 'text-gray-600 hover:bg-gray-100'}`}
              aria-label="Close sidebar"
            >
              <X className="w-5 h-5" />
            </button>
          </div>
        </div>
        
        <nav className="flex-grow p-4 space-y-2">
          {/* Dashboard Button */}
          <button
            onClick={() => { setCurrentView('dashboard'); setSidebarOpen(false); }}
            className={`w-full flex items-center space-x-3 px-4 py-3.5 rounded-xl transition-all duration-200 ${
              currentView === 'dashboard'
                ? darkMode
                  ? 'bg-teal-600 text-white shadow-lg shadow-teal-500/30'
                  : 'bg-gradient-to-r from-teal-500 to-emerald-500 text-white shadow-lg shadow-teal-500/30'
                : darkMode
                  ? 'text-gray-300 hover:bg-gray-700 hover:text-white'
                  : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900'
            }`}
          >
            <BarChart3 className="w-5 h-5" />
            <span className="font-medium">Dashboard</span>
          </button>
          
          {/* Instructors Button */}
          <button
            onClick={() => { setCurrentView('instructors'); setSidebarOpen(false); }}
            className={`w-full flex items-center space-x-3 px-4 py-3.5 rounded-xl transition-all duration-200 ${
              currentView === 'instructors'
                ? darkMode
                  ? 'bg-teal-600 text-white shadow-lg shadow-teal-500/30'
                  : 'bg-gradient-to-r from-teal-500 to-emerald-500 text-white shadow-lg shadow-teal-500/30'
                : darkMode
                  ? 'text-gray-300 hover:bg-gray-700 hover:text-white'
                  : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900'
            }`}
          >
            <Users className="w-5 h-5" />
            <span className="font-medium">Instructors</span>
          </button>

          {/* Groups Map Button */}
           <button
             onClick={() => { setCurrentView('map'); setSidebarOpen(false); }}
             className={`w-full flex items-center space-x-3 px-4 py-3.5 rounded-xl transition-all duration-200 ${
               currentView === 'map'
                 ? darkMode
                   ? 'bg-teal-600 text-white shadow-lg shadow-teal-500/30'
                   : 'bg-gradient-to-r from-teal-500 to-emerald-500 text-white shadow-lg shadow-teal-500/30'
                 : darkMode
                   ? 'text-gray-300 hover:bg-gray-700 hover:text-white'
                   : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900'
             }`}
           >
             <Map className="w-5 h-5" />
             <span className="font-medium">Groups Map</span>
           </button>

          {/* Past Sessions Button */}
           <button
             onClick={() => { setCurrentView('sessions'); setSidebarOpen(false); }}
             className={`w-full flex items-center space-x-3 px-4 py-3.5 rounded-xl transition-all duration-200 ${
               currentView === 'sessions'
                 ? darkMode
                   ? 'bg-teal-600 text-white shadow-lg shadow-teal-500/30'
                   : 'bg-gradient-to-r from-teal-500 to-emerald-500 text-white shadow-lg shadow-teal-500/30'
                 : darkMode
                   ? 'text-gray-300 hover:bg-gray-700 hover:text-white'
                   : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900'
             }`}
           >
             <Clock className="w-5 h-5" />
             <span className="font-medium">Past Sessions</span>
           </button>

           {/* ESIS */}
          <button
            onClick={() => { setCurrentView('health'); setSidebarOpen(false); }}
            className={`w-full flex items-center space-x-3 px-4 py-3.5 rounded-xl transition-all duration-200 ${
              currentView === 'health'
                ? darkMode
                  ? 'bg-teal-600 text-white shadow-lg shadow-teal-500/30'
                  : 'bg-gradient-to-r from-teal-500 to-emerald-500 text-white shadow-lg shadow-teal-500/30'
                : darkMode
                  ? 'text-gray-300 hover:bg-gray-700 hover:text-white'
                  : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900'
            }`}
          >
            <HeartPulse className="w-5 h-5" />
            <span className="font-medium">Health Data</span>
          </button>

        </nav>
        
        <div className={`p-4 border-t ${darkMode ? 'border-gray-700' : 'border-gray-200'} space-y-2`}>
          <button
            onClick={() => setDarkMode(!darkMode)}
            className={`w-full flex items-center space-x-3 px-4 py-3.5 rounded-xl transition-all duration-200 ${
              darkMode ? 'text-gray-300 hover:bg-gray-700 hover:text-white' : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900'
            }`}
            aria-label={darkMode ? "Switch to light mode" : "Switch to dark mode"}
          >
            {darkMode ? <Sun className="w-5 h-5" /> : <Moon className="w-5 h-5" />}
            <span className="font-medium">{darkMode ? 'Light Mode' : 'Dark Mode'}</span>
          </button>
          
          <button
            onClick={onLogout}
            className={`w-full flex items-center space-x-3 px-4 py-3.5 rounded-xl transition-all duration-200 ${
              darkMode 
                ? 'text-red-400 hover:bg-red-900/20 hover:text-red-300' 
                : 'text-red-600 hover:bg-red-50 hover:text-red-700'
            }`}
          >
            <LogOut className="w-5 h-5" />
            <span className="font-medium">Logout</span>
          </button>
        </div>
      </div>

      {/* Main Content */}
      <main className="flex-1 overflow-auto">
        {/* Mobile Header */}
        <div className={`lg:hidden sticky top-0 z-30 px-4 py-4 border-b backdrop-blur-sm ${
          darkMode 
            ? 'bg-gray-800/95 border-gray-700' 
            : 'bg-white/95 border-gray-200'
        }`}>
          <div className="flex items-center justify-between">
            <button
              onClick={() => setSidebarOpen(true)}
              className={`p-2 rounded-lg ${darkMode ? 'text-gray-300 hover:bg-gray-700' : 'text-gray-600 hover:bg-gray-100'}`}
              aria-label="Open sidebar"
            >
              <Menu className="w-6 h-6" />
            </button>
            <div className="flex items-center space-x-2">
              <img src="/website_logo.jpg" alt="YES Logo" className="w-8 h-8 rounded-lg" />
              <span className={`font-bold ${darkMode ? 'text-white' : 'text-gray-800'}`}>YES</span>
            </div>
            {/* Placeholder for potential right-side icons */}
            <div className="w-10"></div> 
          </div>
        </div>

        <div className="p-4 sm:p-6 lg:p-8">
          {renderCurrentView()}
        </div>
      </main>
    </div>
  );
}