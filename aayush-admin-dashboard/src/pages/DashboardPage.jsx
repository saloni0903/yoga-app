import { useState, useEffect } from 'react';
import {
  Users, BarChart3, Calendar, TrendingUp, Activity, Award, Clock,
  UserPlus, ChevronRight, Zap, UserCheck, Trophy
} from 'lucide-react';
import { Link } from 'react-router-dom';
import Spinner from '../components/Spinner'; // This will now resolve correctly
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer
} from 'recharts';

const API_URL = import.meta.env.VITE_API_URL;

/**
 * Formats a date string to a simple "Month Day" format.
 * e.g., "Oct 24"
 */
const formatDateSimple = (dateString) => {
  if (!dateString) return '';
  try {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-IN', { month: 'short', day: 'numeric' });
  } catch {
    return 'Invalid Date';
  }
};

/**
 * Converts a date string to a relative time.
 * e.g., "5m ago", "2h ago", "3d ago"
 */
const timeAgo = (dateString) => {
  if (!dateString) return '';
  try {
    const date = new Date(dateString);
    const seconds = Math.floor((new Date() - date) / 1000);
    let interval = seconds / 31536000;
    if (interval > 1) return Math.floor(interval) + "y ago";
    interval = seconds / 2592000;
    if (interval > 1) return Math.floor(interval) + "mo ago";
    interval = seconds / 86400;
    if (interval > 1) return Math.floor(interval) + "d ago";
    interval = seconds / 3600;
    if (interval > 1) return Math.floor(interval) + "h ago";
    interval = seconds / 60;
    if (interval > 1) return Math.floor(interval) + "m ago";
    return Math.floor(seconds) + "s ago";
  } catch {
    return 'just now';
  }
};


export default function DashboardPage({ darkMode }) {
  // Main KPI stats
  const [stats, setStats] = useState({
    totalParticipants: 0,
    totalInstructors: 0,
    sessionsToday: 0,
    totalAttendance: 0
  });
  // Widget 1: Pending Instructors
  const [pendingInstructors, setPendingInstructors] = useState([]);
  // Widget 2: Attendance Chart
  const [chartData, setChartData] = useState([]);
  // Widget 3: Activity Feed
  const [activityFeed, setActivityFeed] = useState([]);
  // Widget 4: Top Groups
  const [topGroups, setTopGroups] = useState([]);

  // Page-wide loading and error states
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const loadDashboardData = async () => {
      setLoading(true);
      setError(null);
      try {
        // Fetch all 5 data points concurrently
        const statsPromise = fetch(`${API_URL}/api/admin/stats`, { credentials: 'include' });
        const pendingPromise = fetch(`${API_URL}/api/admin/instructors?status=pending&limit=5&sort=-createdAt`, { credentials: 'include' });
        const chartPromise = fetch(`${API_URL}/api/admin/stats/attendance-over-time?period=30d`, { credentials: 'include' });
        const activityPromise = fetch(`${API_URL}/api/admin/activity-feed?limit=7`, { credentials: 'include' });
        const topGroupsPromise = fetch(`${API_URL}/api/admin/stats/top-groups?limit=5`, { credentials: 'include' });

        const [statsRes, pendingRes, chartRes, activityRes, topGroupsRes] = await Promise.all([
          statsPromise,
          pendingPromise,
          chartPromise,
          activityPromise,
          topGroupsPromise
        ]);

        // --- 1. Check for Unauthorized on ALL requests first ---
        if ([statsRes, pendingRes, chartRes, activityRes, topGroupsRes].some(res => res.status === 401)) {
          throw new Error('Unauthorized');
        }

        // --- 2. Handle Stats (Critical) ---
        if (!statsRes.ok) {
          throw new Error(`Stats API failed with status ${statsRes.status}`);
        }
        const statsData = await statsRes.json();
        if (statsData && statsData.data) {
          setStats({
            totalParticipants: statsData.data.totalParticipants ?? 0,
            totalInstructors: statsData.data.totalInstructors ?? 0,
            sessionsToday: statsData.data.sessionsToday ?? 0,
            totalAttendance: statsData.data.totalAttendance ?? 0,
          });
        } else {
          throw new Error('Invalid stats data structure received');
        }

        // --- 3. Handle Pending Instructors (Non-Critical) ---
        if (!pendingRes.ok) {
          console.error(`Pending Instructors API failed with status ${pendingRes.status}`);
          setPendingInstructors([]);
        } else {
          const pendingData = await pendingRes.json();
          if (pendingData && Array.isArray(pendingData.data)) {
            setPendingInstructors(pendingData.data);
          } else {
            console.error('Invalid pending instructors data structure');
            setPendingInstructors([]);
          }
        }

        // --- 4. Handle Chart (Non-Critical) ---
        if (!chartRes.ok) {
          console.error(`Chart API failed with status ${chartRes.status}`);
          setChartData([]);
        } else {
          const chartDataRes = await chartRes.json();
          if (chartDataRes && Array.isArray(chartDataRes.data)) {
            setChartData(chartDataRes.data);
          } else {
            console.error('Invalid chart data structure');
            setChartData([]);
          }
        }

        // --- 5. Handle Activity Feed (Non-Critical) ---
        if (!activityRes.ok) {
          console.error(`Activity Feed API failed with status ${activityRes.status}`);
          setActivityFeed([]);
        } else {
          const activityData = await activityRes.json();
          if (activityData && Array.isArray(activityData.data)) {
            setActivityFeed(activityData.data);
          } else {
            console.error('Invalid activity feed data structure');
            setActivityFeed([]);
          }
        }

        // --- 6. Handle Top Groups (Non-Critical) ---
        if (!topGroupsRes.ok) {
          console.error(`Top Groups API failed with status ${topGroupsRes.status}`);
          setTopGroups([]);
        } else {
          const topGroupsData = await topGroupsRes.json();
          if (topGroupsData && Array.isArray(topGroupsData.data)) {
            setTopGroups(topGroupsData.data);
          } else {
            console.error('Invalid top groups data structure');
            setTopGroups([]);
          }
        }

      } catch (err) {
        console.error('Error loading dashboard data:', err);
        setError(err.message);
        // Reset all states on error
        setStats({ totalParticipants: 0, totalInstructors: 0, sessionsToday: 0, totalAttendance: 0 });
        setPendingInstructors([]);
        setChartData([]);
        setActivityFeed([]);
        setTopGroups([]);
      } finally {
        setLoading(false);
      }
    };
    loadDashboardData();
  }, []);

  /**
   * Renders a single activity feed item based on its type.
   */
  const renderActivityItem = (item) => {
    let icon;
    let text;

    switch (item.type) {
      case 'USER_REGISTERED':
        icon = <UserPlus className="w-4 h-4 text-blue-500" />;
        text = <p><strong>{item.details.name}</strong> just registered as a participant.</p>;
        break;
      case 'SESSION_COMPLETED':
        icon = <Activity className="w-4 h-4 text-green-500" />;
        text = <p><strong>{item.details.groupName}</strong> (w/ {item.details.instructorName}) just completed a session.</p>;
        break;
      case 'INSTRUCTOR_APPROVED':
        icon = <UserCheck className="w-4 h-4 text-teal-500" />;
        text = <p>You approved <strong>{item.details.name}</strong> as an instructor.</p>;
        break;
      default:
        icon = <Zap className="w-4 h-4 text-gray-400" />;
        text = <p>An unknown event occurred.</p>;
    }

    return (
      <div key={item.id} className="flex space-x-3 pb-3 border-b border-gray-200 dark:border-gray-700 last:pb-0 last:border-b-0">
        <div className={`mt-1 p-1.5 rounded-full h-fit ${darkMode ? 'bg-gray-700' : 'bg-gray-100'}`}>
          {icon}
        </div>
        <div className="flex-1">
          <div className={`text-sm ${darkMode ? 'text-gray-300' : 'text-gray-700'}`}>
            {text}
          </div>
          <p className={`text-xs ${darkMode ? 'text-gray-500' : 'text-gray-400'}`}>
            {timeAgo(item.timestamp)}
          </p>
        </div>
      </div>
    );
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <Spinner darkMode={darkMode} />
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

      {/* --- Main 4 KPI Cards --- */}
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

      {/* --- Attendance Chart (Full Width) --- */}
      <div className={`mt-8 rounded-2xl shadow-lg p-6 h-80 ${
        darkMode ? 'bg-gray-800 border border-gray-700' : 'bg-white border border-gray-200'
      }`}>
        <h4 className={`text-lg font-semibold mb-4 ${darkMode ? 'text-white' : 'text-gray-800'}`}>
          Attendance (Last 30 Days)
        </h4>
        {chartData.length > 0 ? (
          <ResponsiveContainer width="100%" height="100%" maxHeight={280}>
            <LineChart
              data={chartData}
              margin={{ top: 5, right: 20, left: -20, bottom: 5 }}
            >
              <CartesianGrid
                strokeDasharray="3 3"
                stroke={darkMode ? '#374151' : '#e5e7eb'} // gray-700 : gray-200
              />
              <XAxis
                dataKey="date"
                fontSize={12}
                tickLine={false}
                axisLine={false}
                stroke={darkMode ? '#9ca3af' : '#6b7281'} // gray-400 : gray-500
              />
              <YAxis
                fontSize={12}
                tickLine={false}
                axisLine={false}
                stroke={darkMode ? '#9ca3af' : '#6b7281'} // gray-400 : gray-500
              />
              <Tooltip
                contentStyle={{
                  backgroundColor: darkMode ? '#1f2937' : '#ffffff', // gray-800 : white
                  borderColor: darkMode ? '#374151' : '#e5e7eb', // gray-700 : gray-200
                  borderRadius: '0.5rem',
                }}
                labelStyle={{ color: darkMode ? '#f9fafb' : '#111827' }} // gray-50 : gray-900
              />
              <Line
                type="monotone"
                dataKey="attendance"
                stroke={darkMode ? '#2dd4bf' : '#0d9488'} // teal-400 : teal-600
                strokeWidth={2}
                dot={false}
                activeDot={{ r: 6, stroke: darkMode ? '#2dd4bf' : '#0d9488' }}
              />
            </LineChart>
          </ResponsiveContainer>
        ) : (
          <div className="flex items-center justify-center h-full text-gray-400">
            No attendance data available.
          </div>
        )}
      </div>

      {/* --- 3-Column Widget Grid --- */}
      <div className="mt-6 grid grid-cols-1 lg:grid-cols-3 gap-6">

        {/* --- WIDGET 1: PENDING INSTRUCTORS --- */}
        <div className={`lg:col-span-1 rounded-2xl shadow-lg p-6 transition-colors duration-300 ${
          darkMode ? 'bg-gray-800 border border-gray-700' : 'bg-white border border-gray-200'
        }`}>
          <div className="flex justify-between items-center mb-4">
            <h4 className={`text-lg font-semibold ${darkMode ? 'text-white' : 'text-gray-800'}`}>
              Instructor Approvals ({pendingInstructors.length})
            </h4>
            <Link
              to="/instructors"
              className={`text-sm font-medium flex items-center transition-colors ${
                darkMode ? 'text-teal-400 hover:text-teal-300' : 'text-teal-600 hover:text-teal-700'
              }`}
            >
              Manage All <ChevronRight className="w-4 h-4 ml-1" />
            </Link>
          </div>
          <div className="space-y-4 max-h-96 overflow-y-auto">
            {pendingInstructors.length > 0 ? (
              pendingInstructors.map(inst => (
                <div key={inst._id} className="flex items-center space-x-3 p-2 rounded-lg transition-colors hover:bg-gray-50 dark:hover:bg-gray-700/50">
                  <div className={`p-2 rounded-full ${darkMode ? 'bg-gray-700' : 'bg-yellow-100'}`}>
                    <UserPlus className={`w-5 h-5 ${darkMode ? 'text-yellow-400' : 'text-yellow-600'}`} />
                  </div>
                  <div className="flex-grow">
                    <p className={`text-sm font-medium ${darkMode ? 'text-gray-100' : 'text-gray-800'}`}>
                      {inst.firstName || ''} {inst.lastName || 'N/A'}
                    </p>
                    <p className={`text-xs ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>
                      Applied {timeAgo(inst.createdAt)}
                    </p>
                  </div>
                  <Link to={`/instructors/${inst._id}`}
                    className={`p-1 rounded-full ${darkMode ? 'text-teal-400 hover:bg-gray-700' : 'text-teal-600 hover:bg-gray-100'}`}
                  >
                    <ChevronRight className='w-4 h-4' />
                  </Link>
                </div>
              ))
            ) : (
              <div className={`text-center py-4 rounded-xl ${darkMode ? 'bg-gray-700/50' : 'bg-gray-50'}`}>
                <Award className={`w-6 h-6 mx-auto mb-2 ${darkMode ? 'text-green-400' : 'text-green-600'}`} />
                <p className={`text-sm ${darkMode ? 'text-gray-300' : 'text-gray-600'}`}>
                  No pending approvals. Great job!
                </p>
              </div>
            )}
          </div>
        </div>

        {/* --- WIDGET 2: RECENT ACTIVITY --- */}
        <div className={`lg:col-span-1 rounded-2xl shadow-lg p-6 ${
          darkMode ? 'bg-gray-800 border border-gray-700' : 'bg-white border border-gray-200'
        }`}>
          <h4 className={`text-lg font-semibold mb-4 ${darkMode ? 'text-white' : 'text-gray-800'}`}>
            Recent Activity
          </h4>
          <div className="space-y-3 max-h-96 overflow-y-auto">
            {activityFeed.length > 0 ? (
              activityFeed.map(item => renderActivityItem(item))
            ) : (
              <div className={`text-center py-4 rounded-xl ${darkMode ? 'bg-gray-700/50' : 'bg-gray-50'}`}>
                <p className={`text-sm ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>
                  No recent activity.
                </p>
              </div>
            )}
          </div>
        </div>

        {/* --- WIDGET 3: TOP GROUPS --- */}
        <div className={`lg:col-span-1 rounded-2xl shadow-lg p-6 ${
          darkMode ? 'bg-gray-800 border border-gray-700' : 'bg-white border border-gray-200'
        }`}>
          <h4 className={`text-lg font-semibold mb-4 ${darkMode ? 'text-white' : 'text-gray-800'}`}>
            Top Groups (Weekly)
          </h4>
          <div className="space-y-4 max-h-96 overflow-y-auto">
            {topGroups.length > 0 ? (
              topGroups.map((group, index) => (
                <div key={group.id} className="flex items-center space-x-3 p-2 rounded-lg transition-colors hover:bg-gray-50 dark:hover:bg-gray-700/50">
                  <div className={`p-2 rounded-full ${darkMode ? 'bg-gray-700' : 'bg-gray-100'}`}>
                    <Trophy className={`w-5 h-5 ${
                      index === 0 ? 'text-yellow-500' : (index === 1 ? 'text-gray-400' : (index === 2 ? 'text-orange-600' : 'text-gray-400'))
                    }`} />
                  </div>
                  <div className="flex-grow">
                    <p className={`text-sm font-medium ${darkMode ? 'text-gray-100' : 'text-gray-800'}`}>
                      {group.name || 'Unknown Group'}
                    </p>
                    <p className={`text-xs ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>
                      {group.attendanceCount} check-ins
                    </p>
                  </div>
                  <Link to={`/groups/${group.id}`} // Assumes you'll have a /groups/:id route
                    className={`p-1 rounded-full ${darkMode ? 'text-teal-400 hover:bg-gray-700' : 'text-teal-600 hover:bg-gray-100'}`}
                  >
                    <ChevronRight className='w-4 h-4' />
                  </Link>
                </div>
              ))
            ) : (
              <div className={`text-center py-4 rounded-xl ${darkMode ? 'bg-gray-700/50' : 'bg-gray-50'}`}>
                <p className={`text-sm ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>
                  No group data yet.
                </p>
              </div>
            )}
          </div>
        </div>

      </div>
    </div>
  );
}

