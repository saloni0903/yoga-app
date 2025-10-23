import { useState, useEffect } from 'react';
import LoginPage from './pages/LoginPage';
import DashboardLayout from './layouts/DashboardLayout';
import Spinner from './components/Spinner';

const API_URL = 'http://localhost:3000';

export default function App() {
  const [isVerifyingAuth, setIsVerifyingAuth] = useState(true);
  const [isLoggedIn, setIsLoggedIn] = useState(false);

  // Dark Mode state - Needs to be lifted or put in context later
  const [darkMode, setDarkMode] = useState(() => {
    const saved = sessionStorage.getItem('darkMode');
    return saved ? JSON.parse(saved) : false;
  });

  useEffect(() => {
    sessionStorage.setItem('darkMode', JSON.stringify(darkMode));
    // Apply class to body or html for global dark mode styling
    if (darkMode) {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  }, [darkMode]);

  useEffect(() => {
    const verifyLogin = async () => {
      try {
        const res = await fetch(`${API_URL}/api/auth/profile`, {
          credentials: 'include'
        });
        if (res.ok) {
          setIsLoggedIn(true);
        } else {
          setIsLoggedIn(false);
        }
      } catch (err) {
        setIsLoggedIn(false);
      } finally {
        setIsVerifyingAuth(false);
      }
    };
    verifyLogin();
  }, []);

  if (isVerifyingAuth) {
    return (
      <div className={`flex h-screen w-full items-center justify-center ${darkMode ? 'bg-gray-900' : 'bg-gray-100'}`}>
        <Spinner />
      </div>
    );
  }

  if (!isLoggedIn) {
    return <LoginPage 
             onLoginSuccess={() => setIsLoggedIn(true)} 
             darkMode={darkMode} 
             setDarkMode={setDarkMode} 
           />;
  }

  return <DashboardLayout 
           onLogout={() => setIsLoggedIn(false)} 
           darkMode={darkMode} 
           setDarkMode={setDarkMode} 
         />;
}