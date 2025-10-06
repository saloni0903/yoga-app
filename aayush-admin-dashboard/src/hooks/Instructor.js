// hooks/useInstructors.js
import { useState, useEffect } from 'react';

const API_URL = 'https://yoga-app-7drp.onrender.com';

export function useInstructors() {
  const [instructors, setInstructors] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const fetchInstructors = async () => {
    setLoading(true);
    setError(null);
    try {
      const token = localStorage.getItem('adminToken');
      const res = await fetch(`${API_URL}/api/admin/instructors`, {
        headers: { 'Authorization': `Bearer ${token}` }
      });

      if (!res.ok) {
        throw new Error('Failed to fetch instructors');
      }
      
      const data = await res.json();
      setInstructors(data.data);
    } catch (err) {
      setError(err.message);
      console.error('Error loading instructors:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchInstructors();
  }, []);

  // You can also return functions to update/delete instructors here
  // and they would call fetchInstructors() again to refresh the data.

  return { instructors, loading, error, refreshInstructors: fetchInstructors };
}