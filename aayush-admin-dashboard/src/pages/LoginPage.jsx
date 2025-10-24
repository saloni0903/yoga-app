import { useState } from 'react';
import { Eye, EyeOff, Moon, Sun } from 'lucide-react';

const API_URL = import.meta.env.VITE_API_URL;

export default function LoginPage({ onLoginSuccess, darkMode, setDarkMode }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loginError, setLoginError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleLogin = async (e) => {
    e.preventDefault();
    setLoginError('');
    setLoading(true);
    try {
      const res = await fetch(`${API_URL}/api/auth/login`, {
        method: 'POST',
        credentials: 'include',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password, role: 'admin' }),
      });
      const data = await res.json();
      if (!res.ok || data.data?.user?.role !== 'admin') {
        throw new Error(data.message || 'Login failed or user is not an admin.');
      }
      onLoginSuccess(); // Notify App.jsx
    } catch (err) {
      setLoginError(err.message || 'An unexpected error occurred.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className={`min-h-screen flex items-center justify-center transition-colors duration-300 ${
      darkMode 
        ? 'bg-gradient-to-br from-gray-900 via-gray-800 to-teal-900' 
        : 'bg-gradient-to-br from-teal-50 via-emerald-50 to-blue-50'
    }`}>
      <button
        onClick={() => setDarkMode(!darkMode)}
        className={`fixed top-6 right-6 p-3 rounded-full transition-all duration-300 ${
          darkMode 
            ? 'bg-gray-800 text-yellow-400 hover:bg-gray-700' 
            : 'bg-white text-gray-700 hover:bg-gray-50 shadow-lg'
        }`}
        aria-label={darkMode ? "Switch to light mode" : "Switch to dark mode"}
      >
        {darkMode ? <Sun className="w-5 h-5" /> : <Moon className="w-5 h-5" />}
      </button>

      <div className="max-w-md w-full mx-4">
        <div className={`p-8 rounded-3xl shadow-2xl backdrop-blur-sm transition-colors duration-300 ${
          darkMode 
            ? 'bg-gray-800/90 border border-gray-700' 
            : 'bg-white/95 border border-gray-100'
        }`}>
          <div className="text-center mb-8">
            <div className="inline-block mb-4 relative">
              <div className="absolute inset-0 bg-teal-500/20 blur-xl rounded-full"></div>
              {/* Ensure website_logo.jpg is in the public folder */}
              <img src="/website_logo.jpg" className="w-20 h-20 relative rounded-2xl shadow-lg" alt="YES Logo" />
            </div>
            <h1 className={`text-4xl font-bold mb-2 bg-gradient-to-r from-teal-600 to-emerald-600 bg-clip-text text-transparent`}>
              YES
            </h1>
            <p className={`text-sm font-medium ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>
              Yoga Essentials and Suryanamaskara • Admin Portal
            </p>
          </div>
          
          <form onSubmit={handleLogin}>
            <div className="mb-5">
              <label htmlFor="email" className={`block text-sm font-semibold mb-2 ${darkMode ? 'text-gray-300' : 'text-gray-700'}`}>
                Email Address
              </label>
              <input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className={`w-full px-4 py-3.5 rounded-xl transition-all duration-200 ${
                  darkMode
                    ? 'bg-gray-700 border-gray-600 text-white placeholder-gray-400 focus:border-teal-500'
                    : 'bg-gray-50 border-gray-200 text-gray-800 placeholder-gray-400 focus:border-teal-500'
                } border-2 focus:outline-none focus:ring-4 focus:ring-teal-500/20`}
                placeholder="admin@yes.com"
                required
                disabled={loading}
                autoComplete="email"
              />
            </div>
            
            <div className="mb-6 relative">
              <label htmlFor="password" className={`block text-sm font-semibold mb-2 ${darkMode ? 'text-gray-300' : 'text-gray-700'}`}>
                Password
              </label>
              <input
                id="password"
                type={showPassword ? 'text' : 'password'}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && !loading && handleLogin(e)}
                className={`w-full px-4 py-3.5 rounded-xl pr-12 transition-all duration-200 ${
                  darkMode
                    ? 'bg-gray-700 border-gray-600 text-white placeholder-gray-400 focus:border-teal-500'
                    : 'bg-gray-50 border-gray-200 text-gray-800 placeholder-gray-400 focus:border-teal-500'
                } border-2 focus:outline-none focus:ring-4 focus:ring-teal-500/20`}
                placeholder="••••••••"
                required
                disabled={loading}
                autoComplete="current-password"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className={`absolute right-4 top-[42px] transition-colors ${
                  darkMode ? 'text-gray-400 hover:text-gray-300' : 'text-gray-500 hover:text-gray-700'
                }`}
                tabIndex={-1}
                aria-label={showPassword ? "Hide password" : "Show password"}
              >
                {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
              </button>
            </div>
            
            <button
              type="submit"
              disabled={loading}
              className="w-full bg-gradient-to-r from-teal-600 to-emerald-600 hover:from-teal-700 hover:to-emerald-700 text-white font-semibold py-4 rounded-xl transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed shadow-lg hover:shadow-xl transform hover:-translate-y-0.5"
            >
              {loading ? (
                <span className="flex items-center justify-center">
                  <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  Logging in...
                </span>
              ) : 'Login'}
            </button>
          </form>
          
          {loginError && (
            <div className={`mt-5 p-4 rounded-xl ${
              darkMode ? 'bg-red-900/30 border border-red-800' : 'bg-red-50 border border-red-200'
            }`} role="alert">
              <p className={`text-sm text-center font-medium ${darkMode ? 'text-red-400' : 'text-red-600'}`}>
                {loginError}
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}