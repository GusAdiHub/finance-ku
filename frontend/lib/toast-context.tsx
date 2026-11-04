"use client";

import React, { createContext, useContext, useState, useCallback, useEffect } from "react";
import { Check, AlertCircle, Info, X, Sparkles } from "lucide-react";

export type ToastType = "success" | "error" | "info";

export interface ToastItem {
  id: string;
  type: ToastType;
  title?: string;
  message: string;
  duration?: number;
}

interface ToastContextType {
  showToast: (message: string, type?: ToastType, title?: string, duration?: number) => void;
  success: (message: string, title?: string, duration?: number) => void;
  error: (message: string, title?: string, duration?: number) => void;
  info: (message: string, title?: string, duration?: number) => void;
}

const ToastContext = createContext<ToastContextType | undefined>(undefined);

export function ToastProvider({ children }: { children: React.ReactNode }) {
  const [toast, setToast] = useState<ToastItem | null>(null);

  const showToast = useCallback(
    (message: string, type: ToastType = "success", title?: string, duration: number = 3200) => {
      const id = String(Date.now());
      setToast({ id, type, title, message, duration });
    },
    []
  );

  const success = useCallback(
    (message: string, title: string = "Berhasil Disimpan", duration: number = 3200) => {
      showToast(message, "success", title, duration);
    },
    [showToast]
  );

  const error = useCallback(
    (message: string, title: string = "Terjadi Kesalahan", duration: number = 4000) => {
      showToast(message, "error", title, duration);
    },
    [showToast]
  );

  const info = useCallback(
    (message: string, title: string = "Informasi", duration: number = 3200) => {
      showToast(message, "info", title, duration);
    },
    [showToast]
  );

  // Auto-dismiss timer
  useEffect(() => {
    if (!toast) return;
    const timer = setTimeout(() => {
      setToast(null);
    }, toast.duration || 3200);

    return () => clearTimeout(timer);
  }, [toast]);

  // Global window event listener
  useEffect(() => {
    const handleGlobalToast = (e: Event) => {
      const customEvent = e as CustomEvent<{
        message: string;
        type?: ToastType;
        title?: string;
        duration?: number;
      }>;
      if (customEvent.detail?.message) {
        showToast(
          customEvent.detail.message,
          customEvent.detail.type || "success",
          customEvent.detail.title,
          customEvent.detail.duration
        );
      }
    };

    window.addEventListener("app-toast", handleGlobalToast);
    return () => window.removeEventListener("app-toast", handleGlobalToast);
  }, [showToast]);

  return (
    <ToastContext.Provider value={{ showToast, success, error, info }}>
      {children}

      {/* Floating Neobrutalist Notification Toast */}
      {toast && (
        <aside
          aria-live="polite"
          className="fixed top-4 left-1/2 -translate-x-1/2 z-[9999] w-[92%] sm:w-auto min-w-[300px] max-w-md animate-toast-slide pointer-events-auto"
        >
          <div
            className={`p-3 sm:p-3.5 rounded-2xl border-2 border-black shadow-[4px_4px_0px_0px_#000] flex items-center justify-between gap-3 ${
              toast.type === "success"
                ? "bg-emerald-300 text-black"
                : toast.type === "error"
                ? "bg-rose-200 text-black"
                : "bg-neo-yellow text-black"
            }`}
          >
            {/* Icon & Message */}
            <div className="flex items-center gap-2.5 min-w-0">
              <div className="w-8 h-8 rounded-xl bg-white border-2 border-black shadow-[1.5px_1.5px_0px_0px_#000] flex items-center justify-center flex-shrink-0 text-black">
                {toast.type === "success" && <Check className="w-4 h-4 stroke-[3] text-emerald-700" />}
                {toast.type === "error" && <AlertCircle className="w-4 h-4 stroke-[2.5] text-rose-700" />}
                {toast.type === "info" && <Sparkles className="w-4 h-4 stroke-[2.5] text-amber-700" />}
              </div>

              <div className="min-w-0">
                {toast.title && (
                  <p className="text-xs font-black uppercase tracking-tight text-black leading-tight">
                    {toast.title}
                  </p>
                )}
                <p className="text-xs font-bold text-slate-900 truncate">
                  {toast.message}
                </p>
              </div>
            </div>

            {/* Close Button */}
            <button
              onClick={() => setToast(null)}
              className="p-1 rounded-lg bg-white/80 hover:bg-white text-black border border-black shadow-[1px_1px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] flex-shrink-0 transition-all"
              aria-label="Tutup notifikasi"
            >
              <X className="w-3.5 h-3.5 stroke-[3]" />
            </button>
          </div>
        </aside>
      )}
    </ToastContext.Provider>
  );
}

export function useToast() {
  const context = useContext(ToastContext);
  if (!context) {
    throw new Error("useToast must be used within a ToastProvider");
  }
  return context;
}
