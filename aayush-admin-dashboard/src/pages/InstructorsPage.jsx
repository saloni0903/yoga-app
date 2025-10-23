import { useState, useEffect } from 'react';
import Spinner from '../components/Spinner';

const API_URL = 'http://localhost:3000';

export default function InstructorsPage({ darkMode }) { // Accept darkMode if needed
  const [instructors, setInstructors] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const loadInstructors = async () => {
    // Keep loading true while fetching
    setError(null);
    try {
      const res = await fetch(`${API_URL}/api/admin/instructors`, { credentials: 'include' });
      
      if (res.status === 401) {
         throw new Error('Unauthorized'); // Let App.jsx handle logout
      }
      if (!res.ok) {
        throw new Error(`API failed with status ${res.status}`);
      }

      const data = await res.json();
      
      if (data && Array.isArray(data.data)) {
        setInstructors(data.data);
      } else {
        console.error('Received invalid instructors data from API:', data);
        setInstructors([]);
        throw new Error('Invalid data structure for instructors');
      }
    } catch (err) {
      console.error('Error loading instructors:', err);
      setError(err.message);
      setInstructors([]); // Clear instructors on error
    } finally {
      // Only set loading false *after* fetch completes (success or error)
       if(loading) setLoading(false); // Only update if still loading
    }
  };


  useEffect(() => {
     setLoading(true); // Ensure loading is true initially
    loadInstructors();
  }, []); // Fetch only once on mount

  const updateInstructorStatus = async (id, status) => {
    // Consider adding a local loading state per row if needed
    setError(null);
    try {
      const res = await fetch(`${API_URL}/api/admin/instructors/${id}/status`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({ status }),
      });
       if (!res.ok) {
         const errorData = await res.json().catch(() => ({ message: 'Failed to update status' }));
         throw new Error(errorData.message || `API failed with status ${res.status}`);
       }
      loadInstructors(); // Refresh the list
    } catch (err) {
      console.error('Error updating instructor status:', err);
       setError(`Failed to update status for instructor ${id}: ${err.message}`);
    }
  };

  const deleteInstructor = async (id) => {
    if (!window.confirm('Are you sure you want to permanently remove this instructor?')) return;
    setError(null);
    try {
      const res = await fetch(`${API_URL}/api/admin/instructors/${id}`, {
        method: 'DELETE',
        credentials: 'include',
      });
       if (!res.ok) {
         const errorData = await res.json().catch(() => ({ message: 'Failed to delete instructor' }));
         throw new Error(errorData.message || `API failed with status ${res.status}`);
       }
      loadInstructors(); // Refresh the list
    } catch (err) {
      console.error('Error deleting instructor:', err);
       setError(`Failed to delete instructor ${id}: ${err.message}`);
    }
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <Spinner />
      </div>
    );
  }

  // Display general error above the table
   const renderError = () => {
     if (!error) return null;
     return (
       <div className={`mb-4 p-4 rounded-md ${darkMode ? 'bg-red-900/30 text-red-400' : 'bg-red-100 text-red-700'}`} role="alert">
         {error}
       </div>
     );
   };

  return (
    <div>
      <div className="mb-6">
        <h3 className={`text-3xl lg:text-4xl font-bold mb-2 ${darkMode ? 'text-white' : 'text-gray-800'}`}>
          Instructor Management
        </h3>
        <p className={darkMode ? 'text-gray-400' : 'text-gray-500'}>
          Manage and monitor all yoga instructors in your studio.
        </p>
      </div>
      
      {renderError()} 

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
                // Default status if missing, though it shouldn't be
                const currentStatus = instructor.status || 'pending'; 
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
                      {instructor.firstName || 'N/A'} {instructor.lastName || ''}
                    </td>
                    <td className={`px-4 sm:px-6 py-4 text-sm ${darkMode ? 'text-gray-300' : 'text-gray-600'}`}>
                      {instructor.email || 'N/A'}
                    </td>
                    <td className="px-4 sm:px-6 py-4">
                      <span className={`px-3 py-1.5 text-xs font-bold rounded-full ${statusStyles[currentStatus]}`}>
                        {currentStatus.charAt(0).toUpperCase() + currentStatus.slice(1)}
                      </span>
                    </td>
                    <td className="px-4 sm:px-6 py-4 text-sm space-x-2 sm:space-x-3 whitespace-nowrap">
                      {currentStatus === 'pending' && (
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
                      {currentStatus === 'approved' && (
                        <button
                          onClick={() => updateInstructorStatus(instructor._id, 'suspended')}
                          className={`font-semibold hover:underline ${
                            darkMode ? 'text-orange-400 hover:text-orange-300' : 'text-orange-600 hover:text-orange-700'
                          }`}
                        >
                          Suspend
                        </button>
                      )}
                      {currentStatus === 'suspended' && (
                        <button
                          onClick={() => updateInstructorStatus(instructor._id, 'approved')}
                          className={`font-semibold hover:underline ${
                            darkMode ? 'text-green-400 hover:text-green-300' : 'text-green-600 hover:text-green-700'
                          }`}
                        >
                          Re-Approve
                        </button>
                      )}
                      {(currentStatus === 'rejected' || currentStatus === 'suspended' || currentStatus === 'approved') && (
                          <span className={darkMode ? 'text-gray-600' : 'text-gray-300'}>|</span>
                      )}
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
          
          {instructors.length === 0 && !loading && !error && ( // Only show if not loading and no error
            <div className="text-center py-16">
              <div className="relative inline-block mb-6">
                <div className="absolute inset-0 bg-teal-500/10 blur-2xl rounded-full"></div>
                <img src="/website_logo.jpg" alt="No Data" className="relative mx-auto w-24 h-24 opacity-40 rounded-2xl" />
              </div>
              <p className={`text-lg font-medium ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>
                No instructors found
              </p>
              <p className={`text-sm mt-2 ${darkMode ? 'text-gray-500' : 'text-gray-400'}`}>
                Instructor applications will appear here when submitted.
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}