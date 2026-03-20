import { useState, useEffect } from 'react';
import { Search, Eye, X, FileHeart } from 'lucide-react';
import { authFetch } from '../utils/authFetch';

const API_URL = import.meta.env.VITE_API_URL;

export default function HealthProfilesPage({ darkMode }) {
  const [profiles, setProfiles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  
  // Modal State
  const [selectedProfile, setSelectedProfile] = useState(null);

  useEffect(() => {
    fetchProfiles();
  }, []);

  const fetchProfiles = async () => {
    try {
      // Assuming you store token in localStorage or cookie. 
      // Adjust authorization header logic based on your existing auth flow.
      // const token = localStorage.getItem('token') || sessionStorage.getItem('token'); 
      
      // const res = await fetch(`${API_URL}/api/health`, {
      //   headers: {
      //     'Authorization': `Bearer ${token}` // Ensure your Admin has a token
      //   }
      // });
      const res = await authFetch("/api/health");
   
      const data = await res.json();
      console.log(data);
      if (data.success) {
        setProfiles(data.data);
      }
    } catch (error) {
      console.error("Failed to fetch profiles", error);
    } finally {
      setLoading(false);
    }
  };  

  // Filter logic
//   const filteredProfiles = profiles.filter(p => 
//     p.user?.firstName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
//     p.user?.email?.toLowerCase().includes(searchTerm.toLowerCase())
//   );

//   if (loading) {
//     return <div className="p-8 text-center">Loading Health Data...</div>;
//   }

//   return (
//     <div className="space-y-6">
//       {/* Header */}
//       <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
//         <div>
//           <h1 className={`text-2xl font-bold ${darkMode ? 'text-white' : 'text-gray-800'}`}>
//             Health Profiles
//           </h1>
//           <p className={`text-sm ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>
//             View submitted Swasth Jeevanshaili forms
//           </p>
//         </div>
//       </div>

//       {/* Search Bar */}
//       <div className="relative max-w-md">
//         <Search className={`absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 ${darkMode ? 'text-gray-400' : 'text-gray-500'}`} />
//         <input
//           type="text"
//           placeholder="Search by name or email..."
//           value={searchTerm}
//           onChange={(e) => setSearchTerm(e.target.value)}
//           className={`w-full pl-10 pr-4 py-3 rounded-xl border outline-none transition-colors ${
//             darkMode 
//               ? 'bg-gray-800 border-gray-700 text-white placeholder-gray-500 focus:border-teal-500' 
//               : 'bg-white border-gray-200 text-gray-900 focus:border-teal-500'
//           }`}
//         />
//       </div>

//       {/* Table */}
//       <div className={`rounded-xl border overflow-hidden ${darkMode ? 'bg-gray-800 border-gray-700' : 'bg-white border-gray-200 shadow-sm'}`}>
//         <div className="overflow-x-auto">
//           <table className="w-full">
//             <thead className={darkMode ? 'bg-gray-700/50' : 'bg-gray-50'}>
//               <tr>
//                 <th className={`px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider ${darkMode ? 'text-gray-300' : 'text-gray-500'}`}>User</th>
//                 <th className={`px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider ${darkMode ? 'text-gray-300' : 'text-gray-500'}`}>Submitted On</th>
//                 <th className={`px-6 py-4 text-left text-xs font-semibold uppercase tracking-wider ${darkMode ? 'text-gray-300' : 'text-gray-500'}`}>Risk Score</th>
//                 <th className={`px-6 py-4 text-right text-xs font-semibold uppercase tracking-wider ${darkMode ? 'text-gray-300' : 'text-gray-500'}`}>Actions</th>
//               </tr>
//             </thead>
//             <tbody className={`divide-y ${darkMode ? 'divide-gray-700' : 'divide-gray-100'}`}>
//               {filteredProfiles.map((profile) => (
//                 <tr key={profile._id} className={`group transition-colors ${darkMode ? 'hover:bg-gray-700/50' : 'hover:bg-gray-50'}`}>
//                   <td className="px-6 py-4">
//                     <div className="flex items-center space-x-3">
//                       <div className={`w-8 h-8 rounded-full flex items-center justify-center font-bold text-xs ${darkMode ? 'bg-gray-700 text-gray-300' : 'bg-teal-100 text-teal-700'}`}>
//                         {profile.user_id?.firstName?.[0] || '?'}
//                       </div>
//                       <div>
//                         <p className={`text-sm font-medium ${darkMode ? 'text-white' : 'text-gray-900'}`}>
//                           {profile.user_id?.firstName} {profile.user_id?.lastName}
//                         </p>
//                         <p className={`text-xs ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>
//                           {profile.user_id?.email}
//                         </p>
//                       </div>
//                     </div>
//                   </td>
//                   <td className={`px-6 py-4 text-sm ${darkMode ? 'text-gray-300' : 'text-gray-600'}`}>
//                     {new Date(profile.date).toLocaleDateString()}
//                   </td>
//                   <td className="px-6 py-4">
//                     <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
//                       profile.totalScore > 50 
//                         ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400'
//                         : profile.totalScore > 20
//                           ? 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400'
//                           : 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400'
//                     }`}>
//                       Score: {profile.totalScore}
//                     </span>
//                   </td>
//                   <td className="px-6 py-4 text-right">
//                     <button 
//                       onClick={() => setSelectedProfile(profile)}
//                       className={`p-2 rounded-lg transition-colors ${darkMode ? 'text-gray-400 hover:text-teal-400 hover:bg-gray-700' : 'text-gray-400 hover:text-teal-600 hover:bg-gray-100'}`}
//                     >
//                       <Eye className="w-5 h-5" />
//                     </button>
//                   </td>
//                 </tr>
//               ))}
//               {filteredProfiles.length === 0 && (
//                 <tr>
//                   <td colSpan="4" className={`px-6 py-12 text-center ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>
//                     No health profiles found.
//                   </td>
//                 </tr>
//               )}
//             </tbody>
//           </table>
//         </div>
//       </div>

//       {/* Details Modal */}
//       {selectedProfile && (
//         <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
//           <div className={`w-full max-w-2xl max-h-[80vh] overflow-y-auto rounded-2xl shadow-2xl ${darkMode ? 'bg-gray-800' : 'bg-white'}`}>
//             <div className={`sticky top-0 z-10 px-6 py-4 border-b flex items-center justify-between ${darkMode ? 'bg-gray-800 border-gray-700' : 'bg-white border-gray-100'}`}>
//               <h3 className={`text-lg font-bold ${darkMode ? 'text-white' : 'text-gray-900'}`}>
//                 Health Details: {selectedProfile.user_id?.firstName}
//               </h3>
//               <button 
//                 onClick={() => setSelectedProfile(null)}
//                 className={`p-2 rounded-lg ${darkMode ? 'hover:bg-gray-700 text-gray-400' : 'hover:bg-gray-100 text-gray-500'}`}
//               >
//                 <X className="w-5 h-5" />
//               </button>
//             </div>
            
//             <div className="p-6">
//               <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
//                 {Object.entries(selectedProfile.responses || {}).map(([key, value]) => (
//                   <div key={key} className={`p-4 rounded-xl border ${darkMode ? 'border-gray-700 bg-gray-700/30' : 'border-gray-100 bg-gray-50'}`}>
//                     <p className={`text-xs font-medium uppercase tracking-wider mb-1 ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>
//                       {key.replace(/([A-Z])/g, ' $1').trim()} {/* Adds space before capitals */}
//                     </p>
//                     <p className={`font-semibold ${darkMode ? 'text-white' : 'text-gray-900'}`}>
//                       {value}
//                     </p>
//                   </div>
//                 ))}
//               </div>
//             </div>
//           </div>
//         </div>
//       )}
//     </div>
//   );
// }

 const filteredProfiles = profiles.filter(p =>
    p.user?.firstName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    p.user?.email?.toLowerCase().includes(searchTerm.toLowerCase())
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

      {/* Search */}
      <div className="relative max-w-md">
        <Search className={`absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 ${
          darkMode ? 'text-gray-400' : 'text-gray-500'
        }`} />
        <input
          type="text"
          placeholder="Search by name or email..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className={`w-full pl-10 pr-4 py-3 rounded-xl border outline-none ${
            darkMode
              ? 'bg-gray-800 border-gray-700 text-white'
              : 'bg-white border-gray-200 text-gray-900'
          }`}
        />
      </div>

      {/* Table */}
      <div className={`rounded-xl border overflow-hidden ${
        darkMode ? 'bg-gray-800 border-gray-700' : 'bg-white border-gray-200'
      }`}>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className={darkMode ? 'bg-gray-700/50' : 'bg-gray-50'}>
              <tr>
                <th className="px-6 py-4 text-left text-xs font-semibold">User</th>
                <th className="px-6 py-4 text-left text-xs font-semibold">Submitted On</th>
                <th className="px-6 py-4 text-left text-xs font-semibold">Risk Score</th>
                <th className="px-6 py-4 text-right text-xs font-semibold">Actions</th>
              </tr>
            </thead>

            <tbody className={`divide-y ${darkMode ? 'divide-gray-700' : 'divide-gray-100'}`}>
              {filteredProfiles.map(profile => (
                <tr
                  key={profile.id}
                  className={darkMode ? 'hover:bg-gray-700/50' : 'hover:bg-gray-50'}
                >
                  <td className="px-6 py-4">
                    <div className="flex items-center space-x-3">
                      <div className="w-8 h-8 rounded-full bg-teal-100 text-teal-700 flex items-center justify-center font-bold text-xs">
                        {profile.user?.firstName?.[0] || '?'}
                      </div>
                      <div>
                        <p className="text-sm font-medium">
                          {profile.user?.firstName} {profile.user?.lastName}
                        </p>
                        <p className="text-xs text-gray-500">
                          {profile.user?.email}
                        </p>
                      </div>
                    </div>
                  </td>

                  <td className="px-6 py-4 text-sm">
                    {new Date(profile.date).toLocaleDateString()}
                  </td>

                  <td className="px-6 py-4">
                    <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                      profile.totalScore > 50
                        ? 'bg-green-100 text-green-800'
                        : profile.totalScore > 20
                        ? 'bg-yellow-100 text-yellow-800'
                        : 'bg-red-100 text-red-800'
                    }`}>
                      Score: {profile.totalScore}
                    </span>
                  </td>

                  <td className="px-6 py-4 text-right">
                    <button onClick={() => setSelectedProfile(profile)}>
                      <Eye className="w-5 h-5" />
                    </button>
                  </td>
                </tr>
              ))}

              {filteredProfiles.length === 0 && (
                <tr>
                  <td colSpan="4" className="px-6 py-12 text-center text-gray-500">
                    No health profiles found.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal */}
      {selectedProfile && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="bg-white dark:bg-gray-800 max-w-2xl w-full rounded-xl">
            <div className="flex justify-between items-center px-6 py-4 border-b">
              <h3 className="font-bold text-lg">
                Health Details: {selectedProfile.user?.firstName}
              </h3>
              <button onClick={() => setSelectedProfile(null)}>
                <X />
              </button>
            </div>

            <div className="p-6">
              <p className="font-semibold mb-2">Responses</p>
              <pre className="whitespace-pre-wrap text-sm bg-gray-100 p-4 rounded">
                {selectedProfile.responses}
              </pre>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}