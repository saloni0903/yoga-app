import React, { useState, useEffect } from 'react';
import Spinner from '../components/Spinner';

const API_URL = import.meta.env.VITE_API_URL;

// Helper function to format date/time
const formatDate = (dateString) => {
  if (!dateString) return 'N/A';
  try {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-IN', { 
      year: 'numeric', month: 'short', day: 'numeric', 
      hour: '2-digit', minute: '2-digit', hour12: true 
    });
  } catch (e) {
    console.error("Error formatting date:", dateString, e); // Use 'e'
    return 'Invalid Date';
}
};

export default function SessionsPage({ darkMode }) {
  const [sessions, setSessions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchPastSessions = async () => {
      setLoading(true);
      setError(null);
      try {
        // Assuming an endpoint that returns attendance records, sorted by date descending
        // This endpoint needs population to get group/user names
        const res = await fetch(`${API_URL}/api/admin/sessions`, {
          credentials: 'include' 
        }); 

        if (!res.ok) {
          const errorData = await res.json().catch(() => ({}));
          throw new Error(errorData.message || `API failed with status ${res.status}`);
        }
        const data = await res.json();
        
        if (data && Array.isArray(data.data)) {
          // You might need further processing/grouping depending on your API response
          setSessions(data.data); 
        } else {
          setSessions([]);
           throw new Error('Invalid data structure for sessions received');
        }
      } catch (err) {
        console.error('Error loading past sessions:', err);
        setError(err.message);
        setSessions([]);
      } finally {
        setLoading(false);
      }
    };
    fetchPastSessions();
  }, []); // Fetch only once

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
         Error loading session data: {error}
       </div>
     );
  }

  return (
    <div>
      <div className="mb-6">
        <h3 className={`text-3xl lg:text-4xl font-bold mb-2 ${darkMode ? 'text-white' : 'text-gray-800'}`}>
          Past Session Records
        </h3>
        <p className={darkMode ? 'text-gray-400' : 'text-gray-500'}>
          History of attendance marked across all groups.
        </p>
      </div>

      {sessions.length === 0 ? (
        <div className={`text-center py-16 rounded-lg ${darkMode ? 'bg-gray-800' : 'bg-gray-50'}`}>
           <p className={`text-lg font-medium ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>
             No past session records found.
           </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {sessions.map((session) => (
            <div 
              key={session._id} 
              className={`rounded-xl shadow-lg p-6 transition-all duration-300 ${
                darkMode 
                  ? 'bg-gray-800 border border-gray-700 hover:border-teal-600' 
                  : 'bg-white border border-gray-200 hover:border-teal-500'
              }`}
            >
              <h4 className={`text-xl font-semibold mb-3 ${darkMode ? 'text-teal-400' : 'text-teal-600'}`}>
                {session.group_id?.group_name || 'Group Not Found'} 
              </h4>
              <div className="space-y-2 text-sm">
                <p className={darkMode ? 'text-gray-300' : 'text-gray-700'}>
                  <span className="font-medium">Participant:</span> {session.user_id?.firstName || 'N/A'} {session.user_id?.lastName || ''}
                </p>
                <p className={darkMode ? 'text-gray-400' : 'text-gray-500'}>
                  <span className="font-medium">Instructor:</span> {session.group_id?.instructor_id?.firstName || 'N/A'} {session.group_id?.instructor_id?.lastName || ''}
                </p>
                <p className={darkMode ? 'text-gray-400' : 'text-gray-500'}>
                  <span className="font-medium">Marked At:</span> {formatDate(session.marked_at)}
                </p>
                 <p className={darkMode ? 'text-gray-400' : 'text-gray-500'}>
                  <span className="font-medium">Location:</span> {
                    // 1. Try to get the address string from the Session-specific location
                    session.location?.address 
                      ? session.location.address 
                      
                    // 2. If not found, try the Group's default location address
                    : (session.group_id?.location?.address 
                        ? session.group_id.location.address 
                        
                    // 3. Fallback: If no address string exists, show Coordinates (Lat, Long)
                    : (session.group_id?.location?.coordinates 
                        ? `${session.group_id.location.coordinates[1].toFixed(4)}, ${session.group_id.location.coordinates[0].toFixed(4)}`
                        : 'Online / N/A'))
                  }
                </p>
                 {/* Add more fields as needed, e.g., session.status if applicable */}
              </div>
            </div>
          ))}
        </div>
      )}
      {/* Consider adding pagination if the list becomes long */}
    </div>
  );
}