import { useState, useEffect } from 'react';
import { Users, BarChart3, Calendar, TrendingUp, Activity, Award, Clock } from 'lucide-react';
import Spinner from '../components/Spinner';

const API_URL = 'http://localhost:3000';

export default function DashboardPage({ darkMode }) { // Accept darkMode if needed for styling
  const [stats, setStats] = useState({
    totalParticipants: 0,
    totalInstructors: 0,
    sessionsToday: 0,
    totalAttendance: 0
  });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const loadStats = async () => {
      setLoading(true);
      setError(null); // Clear previous errors
      try {
        const res = await fetch(`${API_URL}/api/admin/stats`, { credentials: 'include' });
        
        // Handle 401 specifically if needed (e.g., redirect), though App.jsx should handle logout
        if (res.status === 401) {
          throw new Error('Unauthorized'); // Let App.jsx handle logout via verifyLogin check
        }
        if (!res.ok) {
          throw new Error(`API failed with status ${res.status}`);
        }

        const data = await res.json();
        
        if (data && data.data) {
          setStats({
            totalParticipants: data.data.totalParticipants ?? 0,
            totalInstructors: data.data.totalInstructors ?? 0,
            sessionsToday: data.data.sessionsToday ?? 0,
            totalAttendance: data.data.totalAttendance ?? 0,
          });
        } else {
           throw new Error('Invalid data structure received');
        }
      } catch (err) {
        console.error('Error loading stats:', err);
        setError(err.message);
        // Keep default stats (0s) on error
         setStats({ totalParticipants: 0, totalInstructors: 0, sessionsToday: 0, totalAttendance: 0 });
      } finally {
        setLoading(false);
      }
    };
    loadStats();
  }, []); // Fetch only once when the component mounts

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <Spinner />
      </div>
    );
  }

  if (error) {
     return (
       <div className={`p-4 rounded-md ${darkMode ? 'bg-red-900/30 text-red-400' : 'bg-red-100 text-red-700'}`} role="alert">
         Error loading dashboard data: {error}
       </div>
     );
  }

  return (
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
        {/* Card 1: Total Participants */}
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
        
        {/* Card 2: Active Instructors */}
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
          <p className="text-white/60 text-xs mt-2">Approved staff</p>
        </div>
        
        {/* Card 3: Sessions Today */}
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
          <p className="text-white/60 text-xs mt-2">Marked attendance</p>
        </div>
        
        {/* Card 4: Total Attendance */}
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
  );
}