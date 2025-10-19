import { useState, useEffect } from 'react';
import { LogOut, Users, BarChart3, Calendar, TrendingUp, Eye, EyeOff, Moon, Sun, Menu, X, Activity, Award, Clock } from 'lucide-react';

const API_URL = 'https://yoga-app-7drp.onrender.com';

export default function App() {
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [currentView, setCurrentView] = useState('dashboard');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loginError, setLoginError] = useState('');
  const [darkMode, setDarkMode] = useState(() => {
    const saved = sessionStorage.getItem('darkMode');
    return saved ? JSON.parse(saved) : false;
  });
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [stats, setStats] = useState({
    totalParticipants: 0,
    totalInstructors: 0,
    sessionsToday: 0,
    totalAttendance: 0
  });
  const [instructors, setInstructors] = useState([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    sessionStorage.setItem('darkMode', JSON.stringify(darkMode));
  }, [darkMode]);

  useEffect(() => {
    const verifyLogin = async () => {
      try {
        const res = await fetch(`${API_URL}/api/auth/profile`, {
          credentials: 'include' // This tells the browser to send the httpOnly cookie
        });
        if (res.ok) {
          setIsLoggedIn(true);
          // NOTE: We don't need to call loadDashboardData() here.
          // The other useEffect depending on `isLoggedIn` will automatically trigger it.
        } else {
          setIsLoggedIn(false);
        }
      } catch (err) {
        setIsLoggedIn(false);
      }
    };
    verifyLogin();
  }, []);

  useEffect(() => {
    if (isLoggedIn) {
      if (currentView === 'dashboard') {
        loadStats();
      } else if (currentView === 'instructors') {
        loadInstructors();
      }
    }
  }, [isLoggedIn, currentView]);

  const loadDashboardData = async () => {
    await loadStats();
    await loadInstructors();
  };

  const handleLogin = async (e) => {
    e.preventDefault();
    setLoginError('');
    setLoading(true);
    
    try {
      const res = await fetch(`${API_URL}/api/auth/login`, {
        method: 'POST',
        credentials: 'include',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password, role: 'admin' }),
      });
      
      const data = await res.json();
      
      if (!res.ok || data.data?.user?.role !== 'admin') {
        throw new Error(data.message || 'Login failed. Not an admin.');
      }
      
      // sessionStorage.setItem('adminToken', data.data.token);
      setIsLoggedIn(true);
      setEmail('');
      setPassword('');
    } catch (err) {
      setLoginError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleLogout = () => {
    // sessionStorage.removeItem('adminToken');
    setIsLoggedIn(false);
    setCurrentView('dashboard');
  };

  const loadStats = async () => {
    try {
      // const token = sessionStorage.getItem('adminToken');
      const res = await fetch(`${API_URL}/api/admin/stats`, {
        // headers: { 'Authorization': `Bearer ${token}` }
        credentials: 'include'
      });
      
      if (res.status === 401) {
        handleLogout();
        return;
      }
      
      const data = await res.json();
      setStats(data.data);
    } catch (err) {
      console.error('Error loading stats:', err);
    }
  };

  const loadInstructors = async () => {
    try {
      // const token = sessionStorage.getItem('adminToken');
      const res = await fetch(`${API_URL}/api/admin/instructors`, {
        // headers: { 'Authorization': `Bearer ${token}` }
        credentials: 'include'
      });
      
      if (res.status === 401) {
        handleLogout();
        return;
      }
      
      const data = await res.json();
      setInstructors(data.data);
    } catch (err) {
      console.error('Error loading instructors:', err);
    }
  };

  const updateInstructorStatus = async (id, status) => {
    try {
      // const token = sessionStorage.getItem('adminToken');
      await fetch(`${API_URL}/api/admin/instructors/${id}/status`, {
        method: 'PUT',
        // headers: { 
        //   'Content-Type': 'application/json', 
        //   'Authorization': `Bearer ${token}` 
        // },
        credentials: 'include',
        body: JSON.stringify({ status }),
      });
      loadInstructors();
    } catch (err) {
      console.error('Error updating instructor status:', err);
    }
  };

  const deleteInstructor = async (id) => {
    if (!window.confirm('Are you sure you want to permanently remove this instructor?')) return;
    
    try {
      // const token = sessionStorage.getItem('adminToken');
      await fetch(`${API_URL}/api/admin/instructors/${id}`, {
        method: 'DELETE',
        // headers: { 'Authorization': `Bearer ${token}` },
        credentials: 'include',
      });
      loadInstructors();
    } catch (err) {
      console.error('Error deleting instructor:', err);
    }
  };

  if (!isLoggedIn) {
    return (
      <div className={`min-h-screen flex items-center justify-center transition-colors duration-300 ${
        darkMode 
          ? 'bg-gradient-to-br from-gray-900 via-gray-800 to-teal-900' 
          : 'bg-gradient-to-br from-teal-50 via-emerald-50 to-blue-50'
      }`}>
        <button
          onClick={() => setDarkMode(!darkMode)}
          className={`fixed top-6 right-6 p-3 rounded-full transition-all duration-300 ${
            darkMode 
              ? 'bg-gray-800 text-yellow-400 hover:bg-gray-700' 
              : 'bg-white text-gray-700 hover:bg-gray-50 shadow-lg'
          }`}
        >
          {darkMode ? <Sun className="w-5 h-5" /> : <Moon className="w-5 h-5" />}
        </button>

        <div className="max-w-md w-full mx-4">
          <div className={`p-8 rounded-3xl shadow-2xl backdrop-blur-sm transition-colors duration-300 ${
            darkMode 
              ? 'bg-gray-800/90 border border-gray-700' 
              : 'bg-white/95 border border-gray-100'
          }`}>
            <div className="text-center mb-8">
              <div className="inline-block mb-4 relative">
                <div className="absolute inset-0 bg-teal-500/20 blur-xl rounded-full"></div>
                <img src="website_logo.jpg" className="w-20 h-20 relative rounded-2xl shadow-lg" alt="YES Logo" />
              </div>
              <h1 className={`text-4xl font-bold mb-2 bg-gradient-to-r from-teal-600 to-emerald-600 bg-clip-text text-transparent`}>
                YES
              </h1>
              <p className={`text-sm font-medium ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>
                Yoga Essentials and Suryanamaskara • Admin Portal
              </p>
            </div>
            
            <form onSubmit={handleLogin}>
              <div className="mb-5">
                <label className={`block text-sm font-semibold mb-2 ${darkMode ? 'text-gray-300' : 'text-gray-700'}`}>
                  Email Address
                </label>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className={`w-full px-4 py-3.5 rounded-xl transition-all duration-200 ${
                    darkMode
                      ? 'bg-gray-700 border-gray-600 text-white placeholder-gray-400 focus:border-teal-500'
                      : 'bg-gray-50 border-gray-200 text-gray-800 placeholder-gray-400 focus:border-teal-500'
                  } border-2 focus:outline-none focus:ring-4 focus:ring-teal-500/20`}
                  placeholder="admin@yes.com"
                  required
                  disabled={loading}
                />
              </div>
              
              <div className="mb-6 relative">
                <label className={`block text-sm font-semibold mb-2 ${darkMode ? 'text-gray-300' : 'text-gray-700'}`}>
                  Password
                </label>
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && handleLogin(e)}
                  className={`w-full px-4 py-3.5 rounded-xl pr-12 transition-all duration-200 ${
                    darkMode
                      ? 'bg-gray-700 border-gray-600 text-white placeholder-gray-400 focus:border-teal-500'
                      : 'bg-gray-50 border-gray-200 text-gray-800 placeholder-gray-400 focus:border-teal-500'
                  } border-2 focus:outline-none focus:ring-4 focus:ring-teal-500/20`}
                  placeholder="••••••••"
                  required
                  disabled={loading}
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className={`absolute right-4 top-[42px] transition-colors ${
                    darkMode ? 'text-gray-400 hover:text-gray-300' : 'text-gray-500 hover:text-gray-700'
                  }`}
                  tabIndex={-1}
                >
                  {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                </button>
              </div>
              
              <button
                type="submit"
                disabled={loading}
                className="w-full bg-gradient-to-r from-teal-600 to-emerald-600 hover:from-teal-700 hover:to-emerald-700 text-white font-semibold py-4 rounded-xl transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed shadow-lg hover:shadow-xl transform hover:-translate-y-0.5"
              >
                {loading ? (
                  <span className="flex items-center justify-center">
                    <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                    Logging in...
                  </span>
                ) : 'Login'}
              </button>
            </form>
            
            {loginError && (
              <div className={`mt-5 p-4 rounded-xl ${
                darkMode ? 'bg-red-900/30 border border-red-800' : 'bg-red-50 border border-red-200'
              }`}>
                <p className={`text-sm text-center font-medium ${darkMode ? 'text-red-400' : 'text-red-600'}`}>
                  {loginError}
                </p>
              </div>
            )}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className={`flex h-screen transition-colors duration-300 ${darkMode ? 'bg-gray-900' : 'bg-gray-50'}`}>
      {/* Mobile Overlay */}
      {sidebarOpen && (
        <div 
          className="fixed inset-0 bg-black/50 z-40 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        ></div>
      )}

      {/* Sidebar */}
      <div className={`fixed lg:static inset-y-0 left-0 z-50 w-72 flex flex-col transition-all duration-300 ${
        darkMode ? 'bg-gray-800 border-gray-700' : 'bg-white border-gray-200'
      } shadow-2xl border-r transform ${sidebarOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'}`}>
        <div className={`p-6 border-b ${darkMode ? 'border-gray-700' : 'border-gray-200'}`}>
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <img src="website_logo.jpg" alt="Logo" className="w-12 h-12 rounded-xl shadow-md" />
              <div>
                <h2 className={`text-xl font-bold ${darkMode ? 'text-white' : 'text-gray-800'}`}>YES</h2>
                <p className={`text-xs ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>Admin Portal</p>
              </div>
            </div>
            <button
              onClick={() => setSidebarOpen(false)}
              className="lg:hidden p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700"
            >
              <X className="w-5 h-5" />
            </button>
          </div>
        </div>
        
        <nav className="flex-grow p-4 space-y-2">
          <button
            onClick={() => {
              setCurrentView('dashboard');
              setSidebarOpen(false);
            }}
            className={`w-full flex items-center space-x-3 px-4 py-3.5 rounded-xl transition-all duration-200 ${
              currentView === 'dashboard'
                ? darkMode 
                  ? 'bg-teal-600 text-white shadow-lg shadow-teal-500/30'
                  : 'bg-gradient-to-r from-teal-500 to-emerald-500 text-white shadow-lg shadow-teal-500/30'
                : darkMode
                  ? 'text-gray-300 hover:bg-gray-700'
                  : 'text-gray-600 hover:bg-gray-100'
            }`}
          >
            <BarChart3 className="w-5 h-5" />
            <span className="font-medium">Dashboard</span>
          </button>
          
          <button
            onClick={() => {
              setCurrentView('instructors');
              setSidebarOpen(false);
            }}
            className={`w-full flex items-center space-x-3 px-4 py-3.5 rounded-xl transition-all duration-200 ${
              currentView === 'instructors'
                ? darkMode 
                  ? 'bg-teal-600 text-white shadow-lg shadow-teal-500/30'
                  : 'bg-gradient-to-r from-teal-500 to-emerald-500 text-white shadow-lg shadow-teal-500/30'
                : darkMode
                  ? 'text-gray-300 hover:bg-gray-700'
                  : 'text-gray-600 hover:bg-gray-100'
            }`}
          >
            <Users className="w-5 h-5" />
            <span className="font-medium">Instructors</span>
          </button>
        </nav>

        <div className={`p-4 border-t ${darkMode ? 'border-gray-700' : 'border-gray-200'} space-y-2`}>
          <button
            onClick={() => setDarkMode(!darkMode)}
            className={`w-full flex items-center space-x-3 px-4 py-3.5 rounded-xl transition-all duration-200 ${
              darkMode ? 'text-gray-300 hover:bg-gray-700' : 'text-gray-600 hover:bg-gray-100'
            }`}
          >
            {darkMode ? <Sun className="w-5 h-5" /> : <Moon className="w-5 h-5" />}
            <span className="font-medium">{darkMode ? 'Light Mode' : 'Dark Mode'}</span>
          </button>
          
          <button
            onClick={handleLogout}
            className={`w-full flex items-center space-x-3 px-4 py-3.5 rounded-xl transition-all duration-200 ${
              darkMode 
                ? 'text-red-400 hover:bg-red-900/20' 
                : 'text-red-600 hover:bg-red-50'
            }`}
          >
            <LogOut className="w-5 h-5" />
            <span className="font-medium">Logout</span>
          </button>
        </div>
      </div>

      {/* Main Content */}
      <div className="flex-1 overflow-auto">
        {/* Mobile Header */}
        <div className={`lg:hidden sticky top-0 z-30 px-4 py-4 border-b backdrop-blur-sm ${
          darkMode 
            ? 'bg-gray-800/95 border-gray-700' 
            : 'bg-white/95 border-gray-200'
        }`}>
          <div className="flex items-center justify-between">
            <button
              onClick={() => setSidebarOpen(true)}
              className={`p-2 rounded-lg ${darkMode ? 'hover:bg-gray-700' : 'hover:bg-gray-100'}`}
            >
              <Menu className="w-6 h-6" />
            </button>
            <div className="flex items-center space-x-2">
              <img src="website_logo.jpg" alt="Logo" className="w-8 h-8 rounded-lg" />
              <span className={`font-bold ${darkMode ? 'text-white' : 'text-gray-800'}`}>YES</span>
            </div>
            <div className="w-10"></div>
          </div>
        </div>

        <div className="p-4 sm:p-6 lg:p-8">
          {currentView === 'dashboard' && (
            <div>
              <div className="mb-8">
                <h3 className={`text-3xl lg:text-4xl font-bold mb-2 ${darkMode ? 'text-white' : 'text-gray-800'}`}>
                  Dashboard Overview
                </h3>
                <p className={darkMode ? 'text-gray-400' : 'text-gray-500'}>
                  Welcome back! Monitor your yoga studio's performance.
                </p>
              </div>
              
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 lg:gap-6">
                <div className={`p-6 rounded-2xl shadow-lg transition-all duration-300 hover:shadow-xl hover:-translate-y-1 ${
                  darkMode 
                    ? 'bg-gradient-to-br from-blue-600 to-blue-700 border border-blue-500/20' 
                    : 'bg-gradient-to-br from-blue-500 to-blue-600 text-white'
                }`}>
                  <div className="flex items-center justify-between mb-4">
                    <div className="p-3 bg-white/20 backdrop-blur-sm rounded-xl">
                      <Users className="w-7 h-7 text-white" />
                    </div>
                    <Activity className="w-5 h-5 text-white/60" />
                  </div>
                  <h4 className="text-white/80 text-sm font-semibold mb-1">Total Participants</h4>
                  <p className="text-4xl font-bold text-white">{stats.totalParticipants}</p>
                  <p className="text-white/60 text-xs mt-2">Active members</p>
                </div>
                
                <div className={`p-6 rounded-2xl shadow-lg transition-all duration-300 hover:shadow-xl hover:-translate-y-1 ${
                  darkMode 
                    ? 'bg-gradient-to-br from-teal-600 to-emerald-700 border border-teal-500/20' 
                    : 'bg-gradient-to-br from-teal-500 to-emerald-600 text-white'
                }`}>
                  <div className="flex items-center justify-between mb-4">
                    <div className="p-3 bg-white/20 backdrop-blur-sm rounded-xl">
                      <Award className="w-7 h-7 text-white" />
                    </div>
                    <TrendingUp className="w-5 h-5 text-white/60" />
                  </div>
                  <h4 className="text-white/80 text-sm font-semibold mb-1">Active Instructors</h4>
                  <p className="text-4xl font-bold text-white">{stats.totalInstructors}</p>
                  <p className="text-white/60 text-xs mt-2">Teaching staff</p>
                </div>
                
                <div className={`p-6 rounded-2xl shadow-lg transition-all duration-300 hover:shadow-xl hover:-translate-y-1 ${
                  darkMode 
                    ? 'bg-gradient-to-br from-purple-600 to-purple-700 border border-purple-500/20' 
                    : 'bg-gradient-to-br from-purple-500 to-purple-600 text-white'
                }`}>
                  <div className="flex items-center justify-between mb-4">
                    <div className="p-3 bg-white/20 backdrop-blur-sm rounded-xl">
                      <Calendar className="w-7 h-7 text-white" />
                    </div>
                    <Clock className="w-5 h-5 text-white/60" />
                  </div>
                  <h4 className="text-white/80 text-sm font-semibold mb-1">Sessions Today</h4>
                  <p className="text-4xl font-bold text-white">{stats.sessionsToday}</p>
                  <p className="text-white/60 text-xs mt-2">Scheduled classes</p>
                </div>
                
                <div className={`p-6 rounded-2xl shadow-lg transition-all duration-300 hover:shadow-xl hover:-translate-y-1 ${
                  darkMode 
                    ? 'bg-gradient-to-br from-green-600 to-green-700 border border-green-500/20' 
                    : 'bg-gradient-to-br from-green-500 to-green-600 text-white'
                }`}>
                  <div className="flex items-center justify-between mb-4">
                    <div className="p-3 bg-white/20 backdrop-blur-sm rounded-xl">
                      <BarChart3 className="w-7 h-7 text-white" />
                    </div>
                    <TrendingUp className="w-5 h-5 text-white/60" />
                  </div>
                  <h4 className="text-white/80 text-sm font-semibold mb-1">Total Attendance</h4>
                  <p className="text-4xl font-bold text-white">{stats.totalAttendance}</p>
                  <p className="text-white/60 text-xs mt-2">All-time check-ins</p>
                </div>
              </div>
            </div>
          )}

          {currentView === 'instructors' && (
            <div>
              <div className="mb-6">
                <h3 className={`text-3xl lg:text-4xl font-bold mb-2 ${darkMode ? 'text-white' : 'text-gray-800'}`}>
                  Instructor Management
                </h3>
                <p className={darkMode ? 'text-gray-400' : 'text-gray-500'}>
                  Manage and monitor all yoga instructors in your studio.
                </p>
              </div>
              
              <div className={`rounded-2xl shadow-lg overflow-hidden ${
                darkMode ? 'bg-gray-800 border border-gray-700' : 'bg-white border border-gray-200'
              }`}>
                <div className="overflow-x-auto">
                  <table className="w-full">
                    <thead className={darkMode ? 'bg-gray-700/50' : 'bg-gray-50'}>
                      <tr>
                        <th className={`px-4 sm:px-6 py-4 text-left text-xs font-bold uppercase tracking-wider ${
                          darkMode ? 'text-gray-300' : 'text-gray-600'
                        }`}>Name</th>
                        <th className={`px-4 sm:px-6 py-4 text-left text-xs font-bold uppercase tracking-wider ${
                          darkMode ? 'text-gray-300' : 'text-gray-600'
                        }`}>Email</th>
                        <th className={`px-4 sm:px-6 py-4 text-left text-xs font-bold uppercase tracking-wider ${
                          darkMode ? 'text-gray-300' : 'text-gray-600'
                        }`}>Status</th>
                        <th className={`px-4 sm:px-6 py-4 text-left text-xs font-bold uppercase tracking-wider ${
                          darkMode ? 'text-gray-300' : 'text-gray-600'
                        }`}>Actions</th>
                      </tr>
                    </thead>
                    <tbody className={`divide-y ${darkMode ? 'divide-gray-700' : 'divide-gray-200'}`}>
                      {instructors.map((instructor) => {
                        const statusStyles = {
                          pending: darkMode ? 'bg-yellow-900/40 text-yellow-300 border border-yellow-700/50' : 'bg-yellow-100 text-yellow-800',
                          approved: darkMode ? 'bg-green-900/40 text-green-300 border border-green-700/50' : 'bg-green-100 text-green-800',
                          suspended: darkMode ? 'bg-orange-900/40 text-orange-300 border border-orange-700/50' : 'bg-orange-100 text-orange-800',
                          rejected: darkMode ? 'bg-red-900/40 text-red-300 border border-red-700/50' : 'bg-red-100 text-red-800',
                        };

                        return (
                          <tr key={instructor._id} className={`transition-colors ${
                            darkMode ? 'hover:bg-gray-700/50' : 'hover:bg-gray-50'
                          }`}>
                            <td className={`px-4 sm:px-6 py-4 text-sm font-medium ${darkMode ? 'text-white' : 'text-gray-800'}`}>
                              {instructor.firstName} {instructor.lastName}
                            </td>
                            <td className={`px-4 sm:px-6 py-4 text-sm ${darkMode ? 'text-gray-300' : 'text-gray-600'}`}>
                              {instructor.email}
                            </td>
                            <td className="px-4 sm:px-6 py-4">
                              <span className={`px-3 py-1.5 text-xs font-bold rounded-full ${statusStyles[instructor.status]}`}>
                                {instructor.status.charAt(0).toUpperCase() + instructor.status.slice(1)}
                              </span>
                            </td>
                            <td className="px-4 sm:px-6 py-4 text-sm space-x-2 sm:space-x-3">
                              {instructor.status === 'pending' && (
                                <>
                                  <button
                                    onClick={() => updateInstructorStatus(instructor._id, 'approved')}
                                    className={`font-semibold hover:underline ${
                                      darkMode ? 'text-green-400 hover:text-green-300' : 'text-green-600 hover:text-green-700'
                                    }`}
                                  >
                                    Approve
                                  </button>
                                  <span className={darkMode ? 'text-gray-600' : 'text-gray-300'}>|</span>
                                  <button
                                    onClick={() => updateInstructorStatus(instructor._id, 'rejected')}
                                    className={`font-semibold hover:underline ${
                                      darkMode ? 'text-red-400 hover:text-red-300' : 'text-red-600 hover:text-red-700'
                                    }`}
                                  >
                                    Reject
                                  </button>
                                </>
                              )}
                              {instructor.status === 'approved' && (
                                <button
                                  onClick={() => updateInstructorStatus(instructor._id, 'suspended')}
                                  className={`font-semibold hover:underline ${
                                    darkMode ? 'text-orange-400 hover:text-orange-300' : 'text-orange-600 hover:text-orange-700'
                                  }`}
                                >
                                  Suspend
                                </button>
                              )}
                              {instructor.status === 'suspended' && (
                                <button
                                  onClick={() => updateInstructorStatus(instructor._id, 'approved')}
                                  className={`font-semibold hover:underline ${
                                    darkMode ? 'text-green-400 hover:text-green-300' : 'text-green-600 hover:text-green-700'
                                  }`}
                                >
                                  Re-Approve
                                </button>
                              )}
                              <span className={darkMode ? 'text-gray-600' : 'text-gray-300'}>|</span>
                              <button
                                onClick={() => deleteInstructor(instructor._id)}
                                className={`font-semibold hover:underline ${
                                  darkMode ? 'text-red-400 hover:text-red-300' : 'text-red-600 hover:text-red-700'
                                }`}
                              >
                                Delete
                              </button>
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                  
                  {instructors.length === 0 && (
                    <div className="text-center py-16">
                      <div className="relative inline-block mb-6">
                        <div className="absolute inset-0 bg-teal-500/10 blur-2xl rounded-full"></div>
                        <img src="website_logo.jpg" alt="No Data" className="relative mx-auto w-24 h-24 opacity-40 rounded-2xl" />
                      </div>
                      <p className={`text-lg font-medium ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>
                        No instructors found
                      </p>
                      <p className={`text-sm mt-2 ${darkMode ? 'text-gray-500' : 'text-gray-400'}`}>
                        Instructor applications will appear here
                      </p>
                    </div>
                  )}
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}