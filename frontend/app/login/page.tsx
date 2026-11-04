"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useAuth } from "@/lib/auth-context";
import { Wallet, LogIn, Lock, User, AlertCircle } from "lucide-react";

export default function LoginPage() {
  const router = useRouter();
  const { login, isAuthenticated, isLoading } = useAuth();

  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [rememberUsername, setRememberUsername] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  useEffect(() => {
    if (!isLoading && isAuthenticated) {
      router.push("/");
    }
  }, [isLoading, isAuthenticated, router]);

  // Load remembered username from localStorage on mount
  useEffect(() => {
    try {
      const saved = localStorage.getItem("sakuku_saved_username");
      if (saved) {
        setUsername(saved);
        setRememberUsername(true);
      }
    } catch {
      // Ignored for restricted storage
    }
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage(null);
    setIsSubmitting(true);

    try {
      const trimmedUser = username.trim();
      await login({ username: trimmedUser, password });

      try {
        if (rememberUsername) {
          localStorage.setItem("sakuku_saved_username", trimmedUser);
        } else {
          localStorage.removeItem("sakuku_saved_username");
        }
      } catch {
        // Ignored
      }

      router.push("/");
    } catch (err: any) {
      setErrorMessage(
        err.message || "Gagal masuk. Periksa kembali username atau kata sandi Anda."
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="w-full flex items-center justify-center p-4 min-h-screen">
      <div className="w-full max-w-md bg-white/85 backdrop-blur-2xl rounded-2xl p-6 sm:p-8 border-3 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.95),8px_8px_0px_0px_#000] my-auto">
        {/* Brand */}
        <div className="text-center mb-8">
          <div className="w-14 h-14 bg-neo-yellow/90 backdrop-blur-md border-2 border-black rounded-2xl flex items-center justify-center text-black mx-auto shadow-[3px_3px_0px_0px_#000] mb-3">
            <Wallet className="w-7 h-7 stroke-[2.5]" />
          </div>
          <h1 className="text-2xl font-black text-black tracking-tight">Selamat Datang</h1>
          <p className="text-sm font-semibold text-slate-700 mt-1">Masuk ke akun SakuKu Anda</p>
        </div>

        {errorMessage && (
          <div className="mb-6 p-3.5 bg-red-100 border-2 border-black text-red-950 text-xs sm:text-sm font-bold rounded-xl flex items-center gap-2 shadow-[2px_2px_0px_0px_#000]">
            <AlertCircle className="w-4 h-4 flex-shrink-0 stroke-[2.5]" />
            <span>{errorMessage}</span>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-black text-black mb-1.5">
              Username atau Email
            </label>
            <div className="relative">
              <User className="w-4 h-4 text-black absolute left-3.5 top-1/2 -translate-y-1/2 stroke-[2.5]" />
              <input
                type="text"
                required
                autoComplete="username"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                placeholder="Contoh: gusadi"
                className="w-full bg-white border-2 border-black rounded-xl pl-10 pr-4 py-2.5 text-sm font-bold text-black placeholder-slate-400 shadow-[2px_2px_0px_0px_#000] outline-none"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-black text-black mb-1.5">Kata Sandi</label>
            <div className="relative">
              <Lock className="w-4 h-4 text-black absolute left-3.5 top-1/2 -translate-y-1/2 stroke-[2.5]" />
              <input
                type="password"
                required
                autoComplete="current-password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full bg-white border-2 border-black rounded-xl pl-10 pr-4 py-2.5 text-sm font-bold text-black placeholder-slate-400 shadow-[2px_2px_0px_0px_#000] outline-none"
              />
            </div>
          </div>

          {/* Remember Username Checkbox */}
          <div className="flex items-center justify-between pt-0.5">
            <label className="flex items-center gap-2 cursor-pointer select-none">
              <input
                type="checkbox"
                checked={rememberUsername}
                onChange={(e) => setRememberUsername(e.target.checked)}
                className="w-4 h-4 rounded border-2 border-black accent-black cursor-pointer"
              />
              <span className="text-xs font-black text-black">
                Ingat username di perangkat ini
              </span>
            </label>
          </div>

          <button
            type="submit"
            disabled={isSubmitting}
            className={`w-full bg-neo-yellow hover:bg-[#FDE047] active:translate-x-[2px] active:translate-y-[2px] active:shadow-[1px_1px_0px_0px_#000] text-black font-black rounded-xl py-3.5 px-4 flex items-center justify-center gap-2 border-2 border-black shadow-[4px_4px_0px_0px_#000] transition-all ${
              isSubmitting ? "opacity-70 cursor-not-allowed" : ""
            }`}
          >
            <LogIn className="w-4 h-4 stroke-[3]" />
            <span>{isSubmitting ? "Memproses..." : "Masuk"}</span>
          </button>
        </form>

        <div className="mt-8 text-center text-xs font-bold text-slate-700">
          <span>Belum punya akun? </span>
          <Link
            href="/register"
            className="text-black font-black underline underline-offset-4 decoration-2 hover:text-neo-blue"
          >
            Daftar Sekarang
          </Link>
        </div>
      </div>
    </div>
  );
}
