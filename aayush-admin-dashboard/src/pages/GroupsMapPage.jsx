import React, { useState, useEffect } from 'react';
import { MapContainer, TileLayer, Marker, Popup } from 'react-leaflet';
import L from 'leaflet'; // Import Leaflet library itself for custom icon
import Spinner from '../components/Spinner';

const API_URL = import.meta.env.VITE_API_URL;

// Optional: Define a custom icon (ensure the path is correct or use a default)
// const customIcon = new L.Icon({
//   iconUrl: '/path/to/your/marker-icon.png', // Needs to be in public folder
//   iconSize: [25, 41],
//   iconAnchor: [12, 41],
//   popupAnchor: [1, -34],
//   shadowUrl: '/path/to/your/marker-shadow.png', // Needs to be in public folder
//   shadowSize: [41, 41]
// });

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

  // Default map center (e.g., Bhopal) - Adjust as needed
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
        
        // --- CORRECTED CHECK ---
        // Ensure data structure has data.data.groups which is an array
        if (data && data.data && Array.isArray(data.data.groups)) { 
           const groupsArray = data.data.groups;

           console.log("Groups received from backend:", JSON.stringify(groupsArray, null, 2));
           
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
          // If the structure is wrong, throw the error
          console.error('Received invalid data structure:', data); // Log what was received
          setGroups([]); // Set to empty on error
          throw new Error('Invalid data structure for groups received from API');
        }
      } catch (err) {
        console.error('Error loading groups:', err);
        setError(err.message);
        setGroups([]); // Ensure groups is empty on error
      } finally {
        setLoading(false);
      }
    };
    fetchGroups();
  }, []);

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
    <div>
      <div className="mb-6">
        <h3 className={`text-3xl lg:text-4xl font-bold mb-2 ${darkMode ? 'text-white' : 'text-gray-800'}`}>
          Yoga Groups Map
        </h3>
        <p className={darkMode ? 'text-gray-400' : 'text-gray-500'}>
          Visualizing group locations across the region.
        </p>
      </div>

      <div className={`rounded-lg shadow-lg overflow-hidden ${darkMode ? 'border border-gray-700' : 'border border-gray-200'}`} style={{ height: '600px', width: '100%' }}>
         {/* Set height explicitly for the map container */}
        <MapContainer 
            center={defaultPosition} 
            zoom={10} // Adjust default zoom level
            scrollWheelZoom={true} 
            style={{ height: '100%', width: '100%' }}
        >
          <TileLayer
            // Using OpenStreetMap tiles. Consider Mapbox or others for production.
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          />
          {groups.map(group => (
            <Marker 
              key={group._id} 
              // Leaflet expects [latitude, longitude]
              position={[group.location.coordinates[1], group.location.coordinates[0]]} 
              // icon={customIcon} // Optional custom icon
            >
              <Popup>
                <b>{group.group_name || 'Unnamed Group'}</b><br />
                Style: {group.yoga_style || 'N/A'}<br />
                Type: {group.groupType || 'N/A'}<br />
                Address: {group.location.address || 'N/A'} 
              </Popup>
            </Marker>
          ))}
        </MapContainer>
      </div>
    </div>
  );
}