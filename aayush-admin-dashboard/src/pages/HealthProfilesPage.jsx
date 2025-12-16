import { useState, useEffect } from 'react';
import { Search, Eye, X } from 'lucide-react';

const API_URL = import.meta.env.VITE_API_URL;

// Define which keys belong to which category
const POSITIVE_KEYS = [
  'sugar', 'snacking', 'lateDinner', 'physicalActivity', 
  'screenTime', 'socialMedia', 'music', 'sleep'
];

const NEGATIVE_KEYS = [
  'alcohol', 'smoking', 'tobacco'
];

export default function HealthProfilesPage({ darkMode }) {
  const [profiles, setProfiles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedProfile, setSelectedProfile] = useState(null);

  useEffect(() => {
    fetchProfiles();
  }, []);

  const fetchProfiles = async () => {
    try {
      const res = await fetch(`${API_URL}/api/health`, {
        method: 'GET',
        credentials: 'include',
        headers: {
          'Content-Type': 'application/json'
        }
      });

      const data = await res.json();
      if (data.success) {
        setProfiles(data.data);
      }
    } catch (error) {
      console.error("Failed to fetch profiles", error);
    } finally {
      setLoading(false);
    }
  };

  const filteredProfiles = profiles.filter(p => 
    p.user_id?.firstName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    p.user_id?.email?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  // Helper to render a single response card
  const renderResponseCard = (key, value) => (
    <div key={key} className={`p-4 rounded-xl border ${darkMode ? 'border-gray-700 bg-gray-700/30' : 'border-gray-100 bg-gray-50'}`}>
      <p className={`text-xs font-medium uppercase tracking-wider mb-1 ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>
        {key.replace(/([A-Z])/g, ' $1').trim()}
      </p>
      <p className={`font-semibold ${darkMode ? 'text-white' : 'text-gray-900'}`}>
        {value || 'Not Answered'}
      </p>
    </div>
  );

  if (loading) {
    return <div className="p-8 text-center">Loading Health Data...</div>;
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className={`text-2xl font-bold ${darkMode ? 'text-white' : 'text-gray-800'}`}>
            Health Profiles
          </h1>
          <p className={`text-sm ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>
            View submitted Swasth Jeevanshaili forms
          </p>
        </div>
      </div>

      {/* Search Bar */}
      <div className="relative max-w-md">
        <Search className={`absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 ${darkMode ? 'text-gray-400' : 'text-gray-500'}`} />
        <input
          type="text"
          placeholder="Search by name or email..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className={`w-full pl-10 pr-4 py-3 rounded-xl border outline-none transition-colors ${
            darkMode 
              ? 'bg-gray-800 border-gray-700 text-white placeholder-gray-500 focus:border-teal-500' 
              : 'bg-white border-gray-200 text-gray-900 focus:border-teal-500'
          }`}
        />
      </div>

      {/* Table */}
      <div className={`rounded-xl border overflow-hidden ${darkMode ? 'bg-gray-800 border-gray-700' : 'bg-white border-gray-200 shadow-sm'}`}>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className={darkMode ? 'bg-gray-700/50' : 'bg-gray-50'}>
              <tr>
                <th className={`px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider ${darkMode ? 'text-gray-300' : 'text-gray-500'}`}>User</th>
                <th className={`px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider ${darkMode ? 'text-gray-300' : 'text-gray-500'}`}>Submitted On</th>
                <th className={`px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider ${darkMode ? 'text-gray-300' : 'text-gray-500'}`}>Risk Score</th>
                <th className={`px-6 py-4 text-right text-xs font-semibold uppercase tracking-wider ${darkMode ? 'text-gray-300' : 'text-gray-500'}`}>Actions</th>
              </tr>
            </thead>
            <tbody className={`divide-y ${darkMode ? 'divide-gray-700' : 'divide-gray-100'}`}>
              {filteredProfiles.map((profile) => (
                <tr key={profile._id} className={`group transition-colors ${darkMode ? 'hover:bg-gray-700/50' : 'hover:bg-gray-50'}`}>
                  <td className="px-6 py-4">
                    <div className="flex items-center space-x-3">
                      <div className={`w-8 h-8 rounded-full flex items-center justify-center font-bold text-xs ${darkMode ? 'bg-gray-700 text-gray-300' : 'bg-teal-100 text-teal-700'}`}>
                        {profile.user_id?.firstName?.[0] || '?'}
                      </div>
                      <div>
                        <p className={`text-sm font-medium ${darkMode ? 'text-white' : 'text-gray-900'}`}>
                          {profile.user_id?.firstName} {profile.user_id?.lastName}
                        </p>
                        <p className={`text-xs ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>
                          {profile.user_id?.email}
                        </p>
                      </div>
                    </div>
                  </td>
                  <td className={`px-6 py-4 text-sm ${darkMode ? 'text-gray-300' : 'text-gray-600'}`}>
                    {new Date(profile.date).toLocaleDateString()}
                  </td>
                  <td className="px-6 py-4">
                    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                      profile.totalScore > 50 
                        ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400'
                        : profile.totalScore > 20
                          ? 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400'
                          : 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400'
                    }`}>
                      Score: {profile.totalScore}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-right">
                    <button 
                      onClick={() => setSelectedProfile(profile)}
                      className={`p-2 rounded-lg transition-colors ${darkMode ? 'text-gray-400 hover:text-teal-400 hover:bg-gray-700' : 'text-gray-400 hover:text-teal-600 hover:bg-gray-100'}`}
                    >
                      <Eye className="w-5 h-5" />
                    </button>
                  </td>
                </tr>
              ))}
              {filteredProfiles.length === 0 && (
                <tr>
                  <td colSpan="4" className={`px-6 py-12 text-center ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>
                    No health profiles found.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Details Modal */}
      {selectedProfile && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
          <div className={`w-full max-w-2xl max-h-[85vh] overflow-y-auto rounded-2xl shadow-2xl ${darkMode ? 'bg-gray-800' : 'bg-white'}`}>
            {/* Modal Header */}
            <div className={`sticky top-0 z-10 px-6 py-4 border-b flex items-center justify-between ${darkMode ? 'bg-gray-800 border-gray-700' : 'bg-white border-gray-100'}`}>
              <div>
                <h3 className={`text-lg font-bold ${darkMode ? 'text-white' : 'text-gray-900'}`}>
                  Health Details: {selectedProfile.user_id?.firstName}
                </h3>
                <p className={`text-sm ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>
                   Total Score: <span className="font-bold">{selectedProfile.totalScore}</span>
                </p>
              </div>
              <button 
                onClick={() => setSelectedProfile(null)}
                className={`p-2 rounded-lg ${darkMode ? 'hover:bg-gray-700 text-gray-400' : 'hover:bg-gray-100 text-gray-500'}`}
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            
            {/* Modal Content */}
            <div className="p-6 space-y-8">
              
              {/* SECTION 1: POSITIVE HABITS */}
              <div>
                <h4 className="text-sm font-bold text-teal-600 dark:text-teal-400 uppercase tracking-wider mb-4 border-b border-teal-200 dark:border-teal-800 pb-2">
                  Positive Habits (सकारात्मक आदतें)
                </h4>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  {POSITIVE_KEYS.map(key => {
                    const value = selectedProfile.responses?.[key];
                    if (!value) return null; // Skip if not answered
                    return renderResponseCard(key, value);
                  })}
                </div>
              </div>

              {/* SECTION 2: NEGATIVE HABITS */}
              <div>
                <h4 className="text-sm font-bold text-red-600 dark:text-red-400 uppercase tracking-wider mb-4 border-b border-red-200 dark:border-red-800 pb-2">
                  Negative Habits (नकारात्मक आदतें)
                </h4>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  {NEGATIVE_KEYS.map(key => {
                     const value = selectedProfile.responses?.[key];
                     if (!value) return null; // Skip if not answered
                     return renderResponseCard(key, value);
                  })}
                </div>
              </div>

            </div>
          </div>
        </div>
      )}
    </div>
  );
}