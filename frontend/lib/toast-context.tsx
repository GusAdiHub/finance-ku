"use client";

import React, {
  createContext,
  useContext,
  useState,
  useCallback,
  useEffect,
} from "react";
import { createPortal } from "react-dom";
import {
  Check,
  AlertCircle,
  AlertTriangle,
  Info,
  X,
  Trash2,
  HandCoins,
  Sparkles,
} from "lucide-react";

export type ToastType = "success" | "error" | "info" | "warning";

export interface ToastItem {
  id: string;
  type: ToastType;
  title: string;
  message: string;
  duration?: number;
}

export interface ConfirmOptions {
  title: string;
  message: string;
  confirmText?: string;
  cancelText?: string;
  type?: "danger" | "success" | "warning";
}

interface ToastContextType {
  showToast: (message: string, type?: ToastType, title?: string, duration?: number) => void;
  success: (message: string, title?: string, duration?: number) => void;
  error: (message: string, title?: string, duration?: number) => void;
  info: (message: string, title?: string, duration?: number) => void;
  warning: (message: string, title?: string, duration?: number) => void;
  confirm: (opts: ConfirmOptions) => Promise<boolean>;
}

const ToastContext = createContext<ToastContextType | undefined>(undefined);

// Standalone global trigger helper callable from anywhere
export function showNeoToast(
  message: string,
  type: ToastType = "success",
  title?: string,
  duration: number = 4500
) {
  if (typeof window === "undefined") return;

  // Direct DOM injection (Guaranteed 100% visibility regardless of React lifecycle or CSS purging)
  try {
    const existing = document.getElementById("sakuku-global-toast");
    if (existing) {
      existing.remove();
    }

    const toastDiv = document.createElement("div");
    toastDiv.id = "sakuku-global-toast";
    toastDiv.setAttribute("role", "status");
    toastDiv.setAttribute("aria-live", "polite");

    const bgColor =
      type === "success"
        ? "#4ADE80"
        : type === "error"
        ? "#F87171"
        : type === "warning"
        ? "#FFE600"
        : "#FFE600";

    const defaultTitle =
      title ||
      (type === "success"
        ? "BERHASIL DISIMPAN"
        : type === "error"
        ? "TERJADI KENDALA"
        : type === "warning"
        ? "PERINGATAN"
        : "INFORMASI");

    // Ensure animation keyframe is injected
    if (!document.getElementById("sakuku-toast-keyframes")) {
      const styleTag = document.createElement("style");
      styleTag.id = "sakuku-toast-keyframes";
      styleTag.textContent = `
        @keyframes sakukuToastSlide {
          from { opacity: 0; transform: translate(-50%, -24px) scale(0.95); }
          to { opacity: 1; transform: translate(-50%, 0) scale(1); }
        }
      `;
      document.head.appendChild(styleTag);
    }

    toastDiv.style.cssText = `
      position: fixed !important;
      top: 16px !important;
      left: 50% !important;
      transform: translateX(-50%) !important;
      z-index: 2147483647 !important;
      width: fit-content !important;
      min-width: 240px !important;
      max-width: min(90vw, 360px) !important;
      background-color: ${bgColor} !important;
      border: 2.5px solid #000000 !important;
      border-radius: 16px !important;
      box-shadow: 4px 4px 0px 0px #000000 !important;
      padding: 10px 14px !important;
      display: flex !important;
      visibility: visible !important;
      opacity: 1 !important;
      align-items: center !important;
      justify-content: space-between !important;
      gap: 10px !important;
      font-family: system-ui, -apple-system, sans-serif !important;
      color: #000000 !important;
      box-sizing: border-box !important;
      pointer-events: auto !important;
      transition: transform 0.25s cubic-bezier(0.16, 1, 0.3, 1), opacity 0.25s ease !important;
    `;

    const iconSvg =
      type === "success"
        ? `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#000000" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg>`
        : type === "error"
        ? `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#000000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>`
        : `<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#000000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>`;

    toastDiv.innerHTML = `
      <div style="width: 34px; height: 34px; border-radius: 10px; background: #ffffff; border: 2px solid #000000; box-shadow: 2px 2px 0 0 #000000; display: flex; align-items: center; justify-content: center; flex-shrink: 0; color: #000000;">
        ${iconSvg}
      </div>
      <div style="flex: 1; min-width: 0;">
        <div style="font-size: 10.5px; font-weight: 900; text-transform: uppercase; letter-spacing: 0.05em; color: #000000; line-height: 1.1;">
          ${defaultTitle}
        </div>
        <div style="font-size: 12.5px; font-weight: 800; color: #000000; line-height: 1.25; margin-top: 2px; word-break: break-word;">
          ${message}
        </div>
      </div>
      <button id="sakuku-toast-close-btn" style="width: 26px; height: 26px; border-radius: 8px; background: #ffffff; border: 1.5px solid #000000; box-shadow: 1.5px 1.5px 0 0 #000000; display: flex; align-items: center; justify-content: center; flex-shrink: 0; cursor: pointer; color: #000000; font-weight: 900; outline: none; padding: 0;">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="#000000" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
      </button>
    `;

    document.body.appendChild(toastDiv);

    const closeBtn = document.getElementById("sakuku-toast-close-btn");
    if (closeBtn) {
      closeBtn.onclick = (e) => {
        e.stopPropagation();
        toastDiv.remove();
        if (typeof window !== "undefined") {
          window.dispatchEvent(new CustomEvent("sakuku-toast-closed"));
        }
      };
    }

    // Auto dismiss after duration
    setTimeout(() => {
      if (document.body.contains(toastDiv)) {
        toastDiv.style.transition = "opacity 0.25s ease, transform 0.25s ease";
        toastDiv.style.opacity = "0";
        toastDiv.style.transform = "translate(-50%, -20px) scale(0.95)";
        setTimeout(() => {
          if (document.body.contains(toastDiv)) {
            toastDiv.remove();
          }
        }, 260);
      }
    }, duration);
  } catch (domErr) {
    console.error("Direct toast injection error:", domErr);
  }
}

if (typeof window !== "undefined") {
  (window as any).showNeoToast = showNeoToast;
}

export function ToastProvider({ children }: { children: React.ReactNode }) {
  const [toast, setToast] = useState<ToastItem | null>(null);
  const [mounted, setMounted] = useState<boolean>(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  // Confirm Modal State
  const [confirmState, setConfirmState] = useState<{
    isOpen: boolean;
    title: string;
    message: string;
    confirmText: string;
    cancelText: string;
    type: "danger" | "success" | "warning";
    resolve: (value: boolean) => void;
  } | null>(null);

  const showToast = useCallback(
    (message: string, type: ToastType = "success", title?: string, duration: number = 4500) => {
      const defaultTitle =
        title ||
        (type === "success"
          ? "BERHASIL DISIMPAN"
          : type === "error"
          ? "TERJADI KENDALA"
          : type === "warning"
          ? "PERHATIAN"
          : "INFORMASI");

      setToast({
        id: String(Date.now()),
        type,
        title: defaultTitle,
        message,
        duration,
      });

      // Directly render rock-solid DOM overlay banner
      showNeoToast(message, type, defaultTitle, duration);
    },
    []
  );

  const success = useCallback(
    (message: string, title?: string, duration?: number) => {
      showToast(message, "success", title || "BERHASIL DISIMPAN", duration || 4500);
    },
    [showToast]
  );

  const error = useCallback(
    (message: string, title?: string, duration?: number) => {
      showToast(message, "error", title || "GAGAL MEMPROSES", duration || 5000);
    },
    [showToast]
  );

  const info = useCallback(
    (message: string, title?: string, duration?: number) => {
      showToast(message, "info", title || "INFORMASI", duration || 4500);
    },
    [showToast]
  );

  const warning = useCallback(
    (message: string, title?: string, duration?: number) => {
      showToast(message, "warning", title || "PERINGATAN", duration || 4500);
    },
    [showToast]
  );

  // Neo-Brutalist confirmation modal promise
  const confirm = useCallback((opts: ConfirmOptions): Promise<boolean> => {
    return new Promise((resolve) => {
      setConfirmState({
        isOpen: true,
        title: opts.title,
        message: opts.message,
        confirmText: opts.confirmText || "Konfirmasi",
        cancelText: opts.cancelText || "Batal",
        type: opts.type || "danger",
        resolve,
      });
    });
  }, []);

  const handleConfirmAction = (result: boolean) => {
    if (confirmState) {
      confirmState.resolve(result);
      setConfirmState(null);
    }
  };

  // Auto-dismiss timer for toast
  useEffect(() => {
    if (!toast) return;
    const timer = setTimeout(() => {
      setToast(null);
    }, toast.duration || 4500);

    return () => clearTimeout(timer);
  }, [toast]);

  // Global window event listener
  useEffect(() => {
    const handleGlobalEvent = (e: Event) => {
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

    window.addEventListener("app-neo-toast", handleGlobalEvent);
    window.addEventListener("app-toast", handleGlobalEvent);
    const handleClose = () => setToast(null);
    window.addEventListener("sakuku-toast-closed", handleClose);
    return () => {
      window.removeEventListener("app-neo-toast", handleGlobalEvent);
      window.removeEventListener("app-toast", handleGlobalEvent);
      window.removeEventListener("sakuku-toast-closed", handleClose);
    };
  }, [showToast]);

  const toastContent = toast && (
    <aside
      role="status"
      aria-live="polite"
      className="fixed top-3 sm:top-5 inset-x-0 mx-auto z-[99999] w-fit min-w-[240px] max-w-[min(90vw,360px)] pointer-events-auto transition-all animate-neo-toast"
      style={{ zIndex: 99999 }}
    >
      <div
        className={`py-2 px-3 sm:py-2.5 sm:px-3.5 rounded-2xl border-2 sm:border-[2.5px] border-black shadow-[4px_4px_0px_0px_#000] flex items-center justify-between gap-2.5 ${
          toast.type === "success"
            ? "bg-[#4ADE80] text-black"
            : toast.type === "error"
            ? "bg-[#F87171] text-black"
            : toast.type === "warning"
            ? "bg-neo-yellow text-black"
            : "bg-neo-yellow text-black"
        }`}
      >
        {/* Left Chunky Icon Box */}
        <div className="w-8 h-8 rounded-xl bg-white border-2 border-black shadow-[1.5px_1.5px_0px_0px_#000] flex items-center justify-center flex-shrink-0 text-black">
          {toast.type === "success" && <Check className="w-4 h-4 stroke-[3.5] text-black" />}
          {toast.type === "error" && <AlertCircle className="w-4 h-4 stroke-[3] text-black" />}
          {toast.type === "warning" && <AlertTriangle className="w-4 h-4 stroke-[3] text-black" />}
          {toast.type === "info" && <Sparkles className="w-4 h-4 stroke-[3] text-black" />}
        </div>

        {/* Middle Message Details */}
        <div className="min-w-0 flex-1">
          <p className="text-[10.5px] font-black uppercase tracking-wider text-black leading-tight flex items-center gap-1.5">
            <span>{toast.title}</span>
          </p>
          <p className="text-xs font-black text-black leading-snug mt-0.5 break-words">
            {toast.message}
          </p>
        </div>

        {/* Right Neo-Brutalist Close Button */}
        <button
          onClick={() => setToast(null)}
          className="w-6 h-6 rounded-lg bg-white hover:bg-black hover:text-white text-black border-2 border-black shadow-[1.5px_1.5px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] active:shadow-[1px_1px_0px_0px_#000] flex items-center justify-center flex-shrink-0 transition-all cursor-pointer"
          aria-label="Tutup notifikasi"
        >
          <X className="w-3.5 h-3.5 stroke-[3]" />
        </button>
      </div>
    </aside>
  );

  const confirmModalContent = confirmState && (
    <div
      role="dialog"
      aria-modal="true"
      className="fixed inset-0 z-[100000] flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-fade-in"
      style={{ zIndex: 100000 }}
    >
      <div className="bg-[#FFFDF9] border-3 border-black rounded-3xl shadow-[6px_6px_0px_0px_#000] max-w-[340px] w-[90%] p-4 sm:p-5 space-y-4 animate-fade-in">
        {/* Header Icon + Title */}
        <div className="flex items-start gap-3">
          <div
            className={`w-10 h-10 rounded-xl border-2 border-black shadow-[2px_2px_0px_0px_#000] flex items-center justify-center flex-shrink-0 ${
              confirmState.type === "danger"
                ? "bg-rose-300 text-rose-950"
                : confirmState.type === "success"
                ? "bg-[#4ADE80] text-black"
                : "bg-neo-yellow text-black"
            }`}
          >
            {confirmState.type === "danger" && <Trash2 className="w-5 h-5 stroke-[2.5]" />}
            {confirmState.type === "success" && <HandCoins className="w-5 h-5 stroke-[2.5]" />}
            {confirmState.type === "warning" && <AlertTriangle className="w-5 h-5 stroke-[2.5]" />}
          </div>

          <div className="min-w-0 flex-1">
            <h3 className="text-base font-black text-black tracking-tight leading-tight">
              {confirmState.title}
            </h3>
            <p className="text-xs font-semibold text-slate-700 mt-1 leading-snug">
              {confirmState.message}
            </p>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex items-center justify-end gap-2 pt-1 border-t-2 border-black/10">
          <button
            type="button"
            onClick={() => handleConfirmAction(false)}
            className="flex-1 sm:flex-none bg-white hover:bg-slate-100 text-black font-black text-xs py-2 px-3 rounded-xl border-2 border-black shadow-[2px_2px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] active:shadow-[1px_1px_0px_0px_#000] transition-all"
          >
            {confirmState.cancelText}
          </button>
          <button
            type="button"
            onClick={() => handleConfirmAction(true)}
            className={`flex-1 sm:flex-none font-black text-xs py-2 px-4 rounded-xl border-2 border-black shadow-[2px_2px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] active:shadow-[1px_1px_0px_0px_#000] transition-all ${
              confirmState.type === "danger"
                ? "bg-rose-400 hover:bg-rose-500 text-black"
                : confirmState.type === "success"
                ? "bg-[#4ADE80] hover:bg-emerald-400 text-black"
                : "bg-neo-yellow hover:bg-[#FDE047] text-black"
            }`}
          >
            {confirmState.confirmText}
          </button>
        </div>
      </div>
    </div>
  );

  return (
    <ToastContext.Provider value={{ showToast, success, error, info, warning, confirm }}>
      {children}
      {mounted && typeof document !== "undefined" ? (
        createPortal(
          <>
            {toastContent}
            {confirmModalContent}
          </>,
          document.body
        )
      ) : (
        <>
          {toastContent}
          {confirmModalContent}
        </>
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
