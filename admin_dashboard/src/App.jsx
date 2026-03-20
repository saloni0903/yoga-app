import { useState, useEffect } from "react";
import LoginPage from "./pages/LoginPage";
import DashboardLayout from "./layouts/DashboardLayout";
import Spinner from "./components/Spinner";

const API_URL = import.meta.env.VITE_API_URL;

export default function App() {

  /* ---------- AUTH STATE (FROM SESSION FIRST) ---------- */
  const [isLoggedIn, setIsLoggedIn] = useState(() => {
    return sessionStorage.getItem("isLoggedIn") === "true";
  });

  const [isVerifyingAuth, setIsVerifyingAuth] = useState(() => {
    // If session already says logged in → no verification needed
    return sessionStorage.getItem("isLoggedIn") !== "true";
  });

  /* ---------- DARK MODE ---------- */
  const [darkMode, setDarkMode] = useState(() => {
    const saved = sessionStorage.getItem("darkMode");
    return saved ? JSON.parse(saved) : false;
  });

  useEffect(() => {
    sessionStorage.setItem("darkMode", JSON.stringify(darkMode));
    document.documentElement.classList.toggle("dark", darkMode);
  }, [darkMode]);

  /* ---------- VERIFY LOGIN ONLY IF NEEDED ---------- */
  useEffect(() => {
    if (!isVerifyingAuth) return; // ⛔ STOP API CALL

    const verifyLogin = async () => {
      try {
        const res = await fetch(`${API_URL}/api/auth/profile`, {
          credentials: "include",
        });

        if (res.ok) {
          sessionStorage.setItem("isLoggedIn", "true");
          setIsLoggedIn(true);
        } else {
          sessionStorage.removeItem("isLoggedIn");
          setIsLoggedIn(false);
        }
      } catch {
        sessionStorage.removeItem("isLoggedIn");
        setIsLoggedIn(false);
      } finally {
        setIsVerifyingAuth(false);
      }
    };

    verifyLogin();
  }, [isVerifyingAuth]);

  /* ---------- LOADING ---------- */
  if (isVerifyingAuth) {
    return (
      <div
        className={`flex h-screen w-full items-center justify-center ${
          darkMode ? "bg-gray-900" : "bg-gray-100"
        }`}
      >
        <Spinner />
      </div>
    );
  }

  /* ---------- NOT LOGGED IN ---------- */
  if (!isLoggedIn) {
    return (
      <LoginPage
        onLoginSuccess={() => {
          sessionStorage.setItem("isLoggedIn", "true");
          setIsLoggedIn(true);
        }}
        darkMode={darkMode}
        setDarkMode={setDarkMode}
      />
    );
  }

  /* ---------- LOGGED IN ---------- */
  return (
    <DashboardLayout
      onLogout={() => {
        sessionStorage.clear();
        setIsLoggedIn(false);
      }}
      darkMode={darkMode}
      setDarkMode={setDarkMode}
    />
  );
}
