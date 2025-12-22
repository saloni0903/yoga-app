import React, { useState, useEffect } from 'react';
import { MapContainer, TileLayer, Marker } from 'react-leaflet'; // Popup removed
import L from 'leaflet';
import Spinner from '../components/Spinner';
import { Users, Clock, X } from 'lucide-react'; // Added icons
import { Link } from 'react-router-dom'; // Added Link

const API_URL = import.meta.env.VITE_API_URL;

// Fix for default icon issue with webpack/bundlers
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
});


export default function GroupsMapPage({ darkMode }) {
  const [groups, setGroups] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // --- NEW: State for the details panel ---
  const [selectedGroup, setSelectedGroup] = useState(null);
  const [groupDetails, setGroupDetails] = useState(null);
  const [detailsLoading, setDetailsLoading] = useState(false);

  // Default map center (e.g., Bhopal)
  const defaultPosition = [23.2599, 77.4126]; 

  useEffect(() => {
    const fetchGroups = async () => {
      setLoading(true);
      setError(null);
      try {
        const res = await fetch(`${API_URL}/api/groups`, { credentials: 'include' }); 
        if (!res.ok) {
           const errorData = await res.json().catch(() => ({}));
          throw new Error(errorData.message || `API failed with status ${res.status}`);
        }
        const data = await res.json();
        
        if (data && data.data && Array.isArray(data.data.groups)) { 
           const groupsArray = data.data.groups;
           
           const validGroups = groupsArray.filter(group => 
             group.location && 
             Array.isArray(group.location.coordinates) && 
             group.location.coordinates.length === 2 &&
             typeof group.location.coordinates[0] === 'number' &&
             typeof group.location.coordinates[1] === 'number'
           );
           setGroups(validGroups);
            if (validGroups.length !== groupsArray.length) {
              console.warn("Some groups were filtered out due to missing or invalid location data.");
            }
        } else {
          console.error('Received invalid data structure:', data);
          setGroups([]);
          throw new Error('Invalid data structure for groups received from API');
        }
      } catch (err) {
        console.error('Error loading groups:', err);
        setError(err.message);
        setGroups([]);
      } finally {
        setLoading(false);
      }
    };
    fetchGroups();
  }, []);

  // --- NEW: Handler to fetch details when a marker is clicked ---
  const handleMarkerClick = async (group) => {
    // If the same marker is clicked, close the panel
    if (selectedGroup && selectedGroup._id === group._id) {
      handleClosePanel();
      return;
    }

    setSelectedGroup(group);
    setDetailsLoading(true);
    setGroupDetails(null); // Clear previous details
    try {
      // Fetch detailed info for the clicked group, including member count
      const res = await fetch(`${API_URL}/api/groups/${group._id}`, { credentials: 'include' });
      if (!res.ok) throw new Error('Failed to fetch group details');
      const data = await res.json();
      if (data.success) {
        setGroupDetails(data.data);
      }
    } catch (err) {
      console.error("Error fetching group details:", err);
      // You could set a panel-specific error state here
    } finally {
      setDetailsLoading(false);
    }
  };

  // --- NEW: Handler to close the panel ---
  const handleClosePanel = () => {
    setSelectedGroup(null);
    setGroupDetails(null);
  };

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
         Error loading groups data: {error}
       </div>
     );
  }

  return (
    <div> {/* Main page wrapper */}
      <div className="mb-6">
        <h3 className={`text-3xl lg:text-4xl font-bold mb-2 ${darkMode ? 'text-white' : 'text-gray-800'}`}>
          Yoga Groups Map
        </h3>
        <p className={darkMode ? 'text-gray-400' : 'text-gray-500'}>
          Visualizing group locations across the region.
        </p>
      </div>

      {/* Map Container */}
      <div className={`rounded-lg shadow-lg overflow-hidden ${darkMode ? 'border border-gray-700' : 'border border-gray-200'}`} style={{ height: '600px', width: '100%' }}>
        <MapContainer 
            center={defaultPosition} 
            zoom={10}
            scrollWheelZoom={true} 
            style={{ height: '100%', width: '100%' }}
        >
          <TileLayer
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          />
          {groups.map(group => (
            <Marker 
              key={group._id} 
              position={[group.location.coordinates[1], group.location.coordinates[0]]} 
              // --- CHANGED: Added event handler ---
              eventHandlers={{
                click: () => handleMarkerClick(group),
              }}
            >
              {/* --- REMOVED: Popup is gone --- */}
            </Marker>
          ))}
        </MapContainer>
      </div>

      {/* --- NEW: Group Details Panel (Appears below map) --- */}
      {selectedGroup && (
        <div 
          className={`w-full max-w-full p-6 mt-6 overflow-y-auto rounded-lg shadow-lg animate-fade-in
                      ${darkMode ? 'bg-gray-800 border border-gray-700' : 'bg-white border border-gray-200'}`}
          // Simple fade-in animation
          style={{ animation: 'fadeIn 0.5s ease-in-out' }}
        >
          {/* Header with Close Button */}
          <div className="flex justify-between items-center mb-6">
            <h4 className={`text-2xl font-bold ${darkMode ? 'text-white' : 'text-gray-800'}`}>
              {selectedGroup.group_name}
            </h4>
            <button 
              onClick={handleClosePanel}
              className={`p-2 rounded-full ${darkMode ? 'text-gray-400 hover:bg-gray-700' : 'text-gray-600 hover:bg-gray-100'}`}
              aria-label="Close panel"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          {/* Details Section */}
          <div className="space-y-5">
            {/* Basic Info (available immediately) */}
            <div>
              <span className={`text-xs font-semibold uppercase ${darkMode ? 'text-teal-400' : 'text-teal-600'}`}>Instructor</span>
              <p className={`text-lg ${darkMode ? 'text-gray-200' : 'text-gray-700'}`}>
                {selectedGroup.instructor_id?.fullName || 'N/A'}
              </p>
            </div>
            <div>
              <span className={`text-xs font-semibold uppercase ${darkMode ? 'text-teal-400' : 'text-teal-600'}`}>Location</span>
              <p className={`text-sm ${darkMode ? 'text-gray-300' : 'text-gray-600'}`}>
                {selectedGroup.location.address}
              </p>
            </div>

            {/* Details from fetch (loads after click) */}
            {detailsLoading && (
              <div className="flex justify-center py-6">
                <Spinner />
              </div>
            )}

            {groupDetails && (
              <>
                <hr className={darkMode ? 'border-gray-700' : 'border-gray-200'} />
                <div className="flex items-center space-x-3">
                  <Users className={`w-5 h-5 ${darkMode ? 'text-gray-400' : 'text-gray-500'}`} />
                  <span className={darkMode ? 'text-gray-300' : 'text-gray-700'}>
                    {groupDetails.memberCount} {groupDetails.memberCount === 1 ? 'Participant' : 'Participants'}
                  </span>
                </div>
                <div className="flex items-center space-x-3">
                  <Clock className={`w-5 h-5 ${darkMode ? 'text-gray-400' : 'text-gray-500'}`} />
                  <span className={darkMode ? 'text-gray-300' : 'text-gray-700'}>
                    {groupDetails.schedule.days.join(', ')} ({groupDetails.schedule.startTime} - {groupDetails.schedule.endTime})
                  </span>
                </div>
                <div>
                  <span className={`text-xs font-semibold uppercase ${darkMode ? 'text-teal-400' : 'text-teal-600'}`}>Style</span>
                  <p className={`text-sm ${darkMode ? 'text-gray-300' : 'text-gray-600'}`}>
                    {groupDetails.yoga_style ? groupDetails.yoga_style.charAt(0).toUpperCase() + groupDetails.yoga_style.slice(1) : 'N/A'}
                  </p>
                </div>
                
                <Link
                  to={`/groups/${selectedGroup._id}`} // (Assuming you create this page later)
                  className={`block w-full text-center px-4 py-3 rounded-lg font-semibold
                              ${darkMode ? 'bg-teal-600 text-white hover:bg-teal-500' : 'bg-teal-600 text-white hover:bg-teal-700'}`}
                >
                  View Full Group Details
                </Link>
              </>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
