import { useState, useEffect } from 'react';
import { LogOut, Users, BarChart3, Calendar, TrendingUp } from 'lucide-react';

const API_URL = 'http://localhost:3000';

export default function App() {
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [currentView, setCurrentView] = useState('dashboard');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loginError, setLoginError] = useState('');
  const [stats, setStats] = useState({
    totalParticipants: 0,
    totalInstructors: 0,
    sessionsToday: 0,
    totalAttendance: 0
  });
  const [instructors, setInstructors] = useState([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const token = localStorage.getItem('adminToken');
    if (token) {
      setIsLoggedIn(true);
      loadDashboardData();
    }
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
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password, role: 'admin' }),
      });
      
      const data = await res.json();
      
      if (!res.ok || data.data?.user?.role !== 'admin') {
        throw new Error(data.message || 'Login failed. Not an admin.');
      }
      
      localStorage.setItem('adminToken', data.data.token);
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
    localStorage.removeItem('adminToken');
    setIsLoggedIn(false);
    setCurrentView('dashboard');
  };

  const loadStats = async () => {
    try {
      const token = localStorage.getItem('adminToken');
      const res = await fetch(`${API_URL}/api/admin/stats`, {
        headers: { 'Authorization': `Bearer ${token}` }
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
      const token = localStorage.getItem('adminToken');
      const res = await fetch(`${API_URL}/api/admin/instructors`, {
        headers: { 'Authorization': `Bearer ${token}` }
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
      const token = localStorage.getItem('adminToken');
      await fetch(`${API_URL}/api/admin/instructors/${id}/status`, {
        method: 'PUT',
        headers: { 
          'Content-Type': 'application/json', 
          'Authorization': `Bearer ${token}` 
        },
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
      const token = localStorage.getItem('adminToken');
      await fetch(`${API_URL}/api/admin/instructors/${id}`, {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${token}` },
      });
      loadInstructors();
    } catch (err) {
      console.error('Error deleting instructor:', err);
    }
  };

  if (!isLoggedIn) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-teal-50 via-white to-emerald-50">
        <div className="max-w-md w-full mx-4">
          <div className="bg-white p-8 rounded-2xl shadow-xl border border-gray-100">
            <div className="text-center mb-8">
              <div className="inline-block p-3 bg-teal-100 rounded-full mb-4">
                <Users className="w-8 h-8 text-teal-600" />
              </div>
              <h1 className="text-3xl font-bold text-gray-800 mb-2">Aayush Admin</h1>
              <p className="text-gray-500">Yoga Platform Management</p>
            </div>
            
            <div>
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Email Address
                </label>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 focus:border-transparent transition"
                  required
                  disabled={loading}
                />
              </div>
              
              <div className="mb-6">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Password
                </label>
                <input
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && handleLogin(e)}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 focus:border-transparent transition"
                  required
                  disabled={loading}
                />
              </div>
              
              <button
                onClick={handleLogin}
                disabled={loading}
                className="w-full bg-teal-600 hover:bg-teal-700 text-white font-semibold py-3 rounded-lg transition duration-200 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {loading ? 'Logging in...' : 'Login to Dashboard'}
              </button>
            </div>
            
            {loginError && (
              <div className="mt-4 p-3 bg-red-50 border border-red-200 rounded-lg">
                <p className="text-red-600 text-sm text-center">{loginError}</p>
              </div>
            )}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="flex h-screen bg-gray-50">
      <div className="w-64 bg-white shadow-lg flex flex-col border-r border-gray-200">
        <div className="p-6 border-b border-gray-200">
          <div className="flex items-center space-x-3">
            <div className="p-2 bg-teal-100 rounded-lg">
              <Users className="w-6 h-6 text-teal-600" />
            </div>
            <h2 className="text-xl font-bold text-gray-800">Aayush Admin</h2>
          </div>
        </div>
        
        <nav className="flex-grow p-4 space-y-2">
          <button
            onClick={() => setCurrentView('dashboard')}
            className={`w-full flex items-center space-x-3 px-4 py-3 rounded-lg transition ${
              currentView === 'dashboard'
                ? 'bg-teal-50 text-teal-700 font-medium'
                : 'text-gray-600 hover:bg-gray-50'
            }`}
          >
            <BarChart3 className="w-5 h-5" />
            <span>Dashboard</span>
          </button>
          
          <button
            onClick={() => setCurrentView('instructors')}
            className={`w-full flex items-center space-x-3 px-4 py-3 rounded-lg transition ${
              currentView === 'instructors'
                ? 'bg-teal-50 text-teal-700 font-medium'
                : 'text-gray-600 hover:bg-gray-50'
            }`}
          >
            <Users className="w-5 h-5" />
            <span>Instructors</span>
          </button>
        </nav>
        
        <div className="p-4 border-t border-gray-200">
          <button
            onClick={handleLogout}
            className="w-full flex items-center space-x-3 px-4 py-3 text-red-600 hover:bg-red-50 rounded-lg transition"
          >
            <LogOut className="w-5 h-5" />
            <span>Logout</span>
          </button>
        </div>
      </div>

      <div className="flex-1 overflow-auto">
        <div className="p-8">
          {currentView === 'dashboard' && (
            <div>
              <div className="mb-8">
                <h3 className="text-3xl font-bold text-gray-800 mb-2">Dashboard Overview</h3>
                <p className="text-gray-500">Welcome back! Here's what's happening today.</p>
              </div>
              
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-200 hover:shadow-md transition">
                  <div className="flex items-center justify-between mb-4">
                    <div className="p-3 bg-blue-100 rounded-lg">
                      <Users className="w-6 h-6 text-blue-600" />
                    </div>
                  </div>
                  <h4 className="text-gray-500 text-sm font-medium mb-1">Total Participants</h4>
                  <p className="text-3xl font-bold text-gray-800">{stats.totalParticipants}</p>
                </div>
                
                <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-200 hover:shadow-md transition">
                  <div className="flex items-center justify-between mb-4">
                    <div className="p-3 bg-teal-100 rounded-lg">
                      <TrendingUp className="w-6 h-6 text-teal-600" />
                    </div>
                  </div>
                  <h4 className="text-gray-500 text-sm font-medium mb-1">Active Instructors</h4>
                  <p className="text-3xl font-bold text-gray-800">{stats.totalInstructors}</p>
                </div>
                
                <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-200 hover:shadow-md transition">
                  <div className="flex items-center justify-between mb-4">
                    <div className="p-3 bg-purple-100 rounded-lg">
                      <Calendar className="w-6 h-6 text-purple-600" />
                    </div>
                  </div>
                  <h4 className="text-gray-500 text-sm font-medium mb-1">Sessions Today</h4>
                  <p className="text-3xl font-bold text-gray-800">{stats.sessionsToday}</p>
                </div>
                
                <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-200 hover:shadow-md transition">
                  <div className="flex items-center justify-between mb-4">
                    <div className="p-3 bg-green-100 rounded-lg">
                      <BarChart3 className="w-6 h-6 text-green-600" />
                    </div>
                  </div>
                  <h4 className="text-gray-500 text-sm font-medium mb-1">Total Attendance</h4>
                  <p className="text-3xl font-bold text-gray-800">{stats.totalAttendance}</p>
                </div>
              </div>
            </div>
          )}

          {currentView === 'instructors' && (
            <div>
              <div className="mb-6">
                <h3 className="text-3xl font-bold text-gray-800 mb-2">Instructor Management</h3>
                <p className="text-gray-500">Manage and monitor all yoga instructors.</p>
              </div>
              
              <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
                <div className="overflow-x-auto">
                  <table className="w-full">
                    <thead className="bg-gray-50 border-b border-gray-200">
                      <tr>
                        <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">Name</th>
                        <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">Email</th>
                        <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">Status</th>
                        <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">Actions</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-200">
                      {instructors.map((instructor) => {
                        const statusStyles = {
                          pending: 'bg-yellow-100 text-yellow-800',
                          approved: 'bg-green-100 text-green-800',
                          suspended: 'bg-orange-100 text-orange-800',
                          rejected: 'bg-red-100 text-red-800',
                        };

                        return (
                          <tr key={instructor._id} className="hover:bg-gray-50 transition">
                            <td className="px-6 py-4 text-sm font-medium text-gray-800">
                              {instructor.firstName} {instructor.lastName}
                            </td>
                            <td className="px-6 py-4 text-sm text-gray-600">{instructor.email}</td>
                            <td className="px-6 py-4">
                              <span className={`px-3 py-1 text-xs font-semibold rounded-full ${statusStyles[instructor.status]}`}>
                                {instructor.status.charAt(0).toUpperCase() + instructor.status.slice(1)}
                              </span>
                            </td>
                            <td className="px-6 py-4 text-sm space-x-3">
                              {instructor.status === 'pending' && (
                                <>
                                  <button
                                    onClick={() => updateInstructorStatus(instructor._id, 'approved')}
                                    className="text-green-600 hover:text-green-700 font-medium hover:underline"
                                  >
                                    Approve
                                  </button>
                                  <span className="text-gray-300">|</span>
                                  <button
                                    onClick={() => updateInstructorStatus(instructor._id, 'rejected')}
                                    className="text-red-600 hover:text-red-700 font-medium hover:underline"
                                  >
                                    Reject
                                  </button>
                                </>
                              )}
                              {instructor.status === 'approved' && (
                                <button
                                  onClick={() => updateInstructorStatus(instructor._id, 'suspended')}
                                  className="text-orange-600 hover:text-orange-700 font-medium hover:underline"
                                >
                                  Suspend
                                </button>
                              )}
                              {instructor.status === 'suspended' && (
                                <button
                                  onClick={() => updateInstructorStatus(instructor._id, 'approved')}
                                  className="text-green-600 hover:text-green-700 font-medium hover:underline"
                                >
                                  Re-Approve
                                </button>
                              )}
                              <span className="text-gray-300">|</span>
                              <button
                                onClick={() => deleteInstructor(instructor._id)}
                                className="text-red-600 hover:text-red-700 font-medium hover:underline"
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
                    <div className="text-center py-12">
                      <Users className="w-12 h-12 text-gray-300 mx-auto mb-3" />
                      <p className="text-gray-500">No instructors found</p>
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