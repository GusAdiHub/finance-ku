"use client";

import React, { createContext, useContext, useEffect, useState } from "react";
import { User, Group } from "./types";
import { api } from "./api";

interface AuthContextType {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (data: any) => Promise<void>;
  register: (data: any) => Promise<void>;
  logout: () => Promise<void>;
  activeScope: "personal" | "family";
  setActiveScope: (scope: "personal" | "family") => void;
  selectedGroup: Group | null;
  setSelectedGroup: (group: Group | null) => void;
  userGroups: Group[];
  refreshUser: () => Promise<void>;
  refreshGroups: () => Promise<void>;
  elderlyMode: boolean;
  toggleElderlyMode: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

function cleanGroups(groups: Group[]): Group[] {
  return (groups || []).map((g) => {
    if (g.name && (g.name.includes("Cemara") || g.name.toLowerCase().includes("keluarga cemara"))) {
      // Background sync rename if legacy group is found
      try {
        api.updateGroup(g.id, {
          name: "Panitia Event & Proyek",
          description: "[ANGGARAN:10000000] Kas operasional dan bukti nota belanja panitia event",
        });
      } catch {
        // Ignored
      }
      return {
        ...g,
        name: "Panitia Event & Proyek",
        description: g.description?.includes("Cemara")
          ? "[ANGGARAN:10000000] Kas operasional dan bukti nota belanja panitia event"
          : g.description,
      };
    }
    return g;
  });
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [token, setToken] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [activeScope, setActiveScope] = useState<"personal" | "family">("personal");
  const [userGroups, setUserGroups] = useState<Group[]>([]);
  const [selectedGroup, setSelectedGroup] = useState<Group | null>(null);
  const [elderlyMode, setElderlyMode] = useState<boolean>(false);

  useEffect(() => {
    // Load local storage preferences
    const storedToken = localStorage.getItem("token");
    const storedScope = localStorage.getItem("active_scope") as "personal" | "family" | null;
    const storedElderly = localStorage.getItem("elderly_mode") === "true";

    if (storedToken) {
      setToken(storedToken);
    }
    if (storedScope) {
      setActiveScope(storedScope);
    }
    if (storedElderly) {
      setElderlyMode(true);
      document.documentElement.classList.add("elderly-mode");
    }

    initAuth(storedToken);
  }, []);

  const initAuth = async (currentToken: string | null) => {
    if (!currentToken) {
      setIsLoading(false);
      return;
    }
    try {
      const userData = await api.getMe();
      setUser(userData);
      const groups = await api.getGroups();
      const sanitized = cleanGroups(groups);
      setUserGroups(sanitized);
      if (sanitized.length > 0) {
        setSelectedGroup(sanitized[0]);
      }
    } catch (err) {
      console.error("Auth init error:", err);
      localStorage.removeItem("token");
      setToken(null);
      setUser(null);
    } finally {
      setIsLoading(false);
    }
  };

  const login = async (credentials: any) => {
    const res = await api.login(credentials);
    localStorage.setItem("token", res.access_token);
    setToken(res.access_token);
    setUser(res.user);

    try {
      const groups = await api.getGroups();
      const sanitized = cleanGroups(groups);
      setUserGroups(sanitized);
      if (sanitized.length > 0) {
        setSelectedGroup(sanitized[0]);
      }
    } catch {
      // Ignored
    }
  };

  const register = async (data: any) => {
    const res = await api.register(data);
    localStorage.setItem("token", res.access_token);
    setToken(res.access_token);
    setUser(res.user);
  };

  const logout = async () => {
    try {
      await api.logout();
    } catch {
      // Ignored
    }
    localStorage.removeItem("token");
    setToken(null);
    setUser(null);
    setUserGroups([]);
    setSelectedGroup(null);
    window.location.href = "/login";
  };

  const refreshUser = async () => {
    try {
      const u = await api.getMe();
      setUser(u);
    } catch {
      // Ignored
    }
  };

  const refreshGroups = async () => {
    try {
      const groups = await api.getGroups();
      const sanitized = cleanGroups(groups);
      setUserGroups(sanitized);
      if (sanitized.length > 0 && !selectedGroup) {
        setSelectedGroup(sanitized[0]);
      } else if (selectedGroup) {
        const found = sanitized.find((g: Group) => g.id === selectedGroup.id);
        setSelectedGroup(found || sanitized[0] || null);
      }
    } catch {
      // Ignored
    }
  };

  const handleSetActiveScope = (scope: "personal" | "family") => {
    setActiveScope(scope);
    localStorage.setItem("active_scope", scope);
  };

  const toggleElderlyMode = () => {
    const nextState = !elderlyMode;
    setElderlyMode(nextState);
    localStorage.setItem("elderly_mode", String(nextState));
    if (nextState) {
      document.documentElement.classList.add("elderly-mode");
    } else {
      document.documentElement.classList.remove("elderly-mode");
    }
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        token,
        isAuthenticated: !!token && !!user,
        isLoading,
        login,
        register,
        logout,
        activeScope,
        setActiveScope: handleSetActiveScope,
        selectedGroup,
        setSelectedGroup,
        userGroups,
        refreshUser,
        refreshGroups,
        elderlyMode,
        toggleElderlyMode,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
}
