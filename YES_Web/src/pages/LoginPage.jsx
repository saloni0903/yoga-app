import { useState } from "react";
import { Eye, EyeOff, Moon, Sun } from "lucide-react";
import { jwtDecode } from "jwt-decode";

const API_URL = import.meta.env.VITE_API_URL;

/*
===========================================
OLD IMPLEMENTATION (KEPT AS REQUESTED)
===========================================

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
        body: JSON.stringify({ Email: email, Password: password }),
      });
      const data = await res.json();
      console.log(data);
      console.log(data.data?.user);
      console.log(data.data?.user?.role);

      const token = data.token;
      const decoded = jwtDecode(token);
      console.log(decoded.role);

      if (!res.ok || data.data?.user?.role !== 'admin') {
        throw new Error(data.message || 'Login failed or user is not an admin.');
      }
      onLoginSuccess();
    } catch (err) {
      setLoginError(err.message || 'An unexpected error occurred.');
    } finally {
      setLoading(false);
    }
  };
}
*/

export default function LoginPage({ onLoginSuccess, darkMode, setDarkMode }) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [loginError, setLoginError] = useState("");
  const [loading, setLoading] = useState(false);

  const handleLogin = async (e) => {
    e.preventDefault();
    setLoginError("");
    setLoading(true);

    try {
      const res = await fetch(`${API_URL}/api/auth/login`, {
        method: "POST",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          Email: email,
          Password: password,
        }),
      });

      const data = await res.json();
      console.log("RAW RESPONSE:", data);

      const token = data.token;
      if (!token) {
        throw new Error("Token not returned from backend");
      }

      const decoded = jwtDecode(token);
      console.log("FULL DECODED TOKEN:", decoded);

      const userId = decoded.sub ?? null;
      const role = decoded.role || decoded.roles || decoded["http://schemas.microsoft.com/ws/2008/06/identity/claims/role"];

      const decodedEmail = decoded.email ?? null;

      console.log("USER ID:", userId);
      console.log("ROLE:", role);
      console.log("EMAIL:", decodedEmail);

      if (!res.ok || role !== "admin") {
        throw new Error("Login failed or user is not an admin.");
      }
      localStorage.setItem("admin_token", token);
      onLoginSuccess();
    } catch (err) {
      setLoginError(err.message || "An unexpected error occurred.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div
      className={`min-h-screen flex items-center justify-center transition-colors duration-300 ${
        darkMode
          ? "bg-gradient-to-br from-gray-900 via-gray-800 to-teal-900"
          : "bg-gradient-to-br from-teal-50 via-emerald-50 to-blue-50"
      }`}
    >
      <button
        onClick={() => setDarkMode(!darkMode)}
        className={`fixed top-6 right-6 p-3 rounded-full transition-all duration-300 ${
          darkMode
            ? "bg-gray-800 text-yellow-400 hover:bg-gray-700"
            : "bg-white text-gray-700 hover:bg-gray-50 shadow-lg"
        }`}
      >
        {darkMode ? <Sun className="w-5 h-5" /> : <Moon className="w-5 h-5" />}
      </button>

      <div className="max-w-md w-full mx-4">
        <div
          className={`p-8 rounded-3xl shadow-2xl backdrop-blur-sm transition-colors duration-300 ${
            darkMode
              ? "bg-gray-800/90 border border-gray-700"
              : "bg-white/95 border border-gray-100"
          }`}
        >
          <div className="text-center mb-8">
            <div className="inline-block mb-4 relative">
              <div className="absolute inset-0 bg-teal-500/20 blur-xl rounded-full"></div>
              {/* Ensure website_logo.jpg is in the public folder */}
              <img
                src="/website_logo.jpg"
                className="w-20 h-20 relative rounded-2xl shadow-lg"
                alt="YES Logo"
              />
            </div>
            <h1
              className={`text-4xl font-bold mb-2 bg-gradient-to-r from-teal-600 to-emerald-600 bg-clip-text text-transparent`}
            >
              YES
            </h1>
            <p
              className={`text-sm font-medium ${darkMode ? "text-gray-400" : "text-gray-500"}`}
            >
              Yoga Essentials and Suryanamaskara • Admin Portal
            </p>
          </div>

          <form onSubmit={handleLogin}>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              disabled={loading}
              required
              className="w-full mb-4 px-4 py-3 rounded-xl border-2"
              placeholder="Email"
            />

            <div className="relative mb-6">
              <input
                type={showPassword ? "text" : "password"}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                disabled={loading}
                required
                className="w-full px-4 py-3 rounded-xl border-2"
                placeholder="Password"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-4 top-3"
                tabIndex={-1}
              >
                {showPassword ? <EyeOff /> : <Eye />}
              </button>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full bg-teal-600 text-white py-3 rounded-xl"
            >
              {loading ? "Logging in…" : "Login"}
            </button>
          </form>

          {loginError && (
            <p className="mt-4 text-center text-red-600">{loginError}</p>
          )}
        </div>
      </div>
    </div>
  );
}
