"use client";

import React, { useEffect } from "react";
import { usePathname, useRouter } from "next/navigation";
import { useAuth } from "@/lib/auth-context";
import { DesktopSidebar } from "@/components/layout/DesktopSidebar";
import { MobileHeader } from "@/components/layout/MobileHeader";
import { BottomNav } from "@/components/layout/BottomNav";
import { TransactionModal } from "@/components/transactions/TransactionModal";
import { Wallet, Loader2 } from "lucide-react";

export function AppShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const { isAuthenticated, isLoading } = useAuth();

  const isAuthPage = pathname === "/login" || pathname === "/register";

  useEffect(() => {
    if (!isLoading) {
      if (!isAuthenticated && !isAuthPage) {
        router.replace("/login");
      }
    }
  }, [isLoading, isAuthenticated, isAuthPage, router]);

  // If on Login or Register page, display clean standalone card without sidebar/navbars
  if (isAuthPage) {
    return (
      <main className="min-h-screen bg-[#FFFDF9] flex items-center justify-center relative overflow-hidden">
        {/* Ambient Gradient Mesh for Frosted Glass Refraction */}
        <div className="fixed inset-0 overflow-hidden pointer-events-none -z-10">
          <div className="absolute -top-20 -left-20 w-96 h-96 bg-amber-300/35 rounded-full blur-3xl" />
          <div className="absolute top-1/3 -right-20 w-[30rem] h-[30rem] bg-sky-300/30 rounded-full blur-3xl" />
          <div className="absolute -bottom-20 left-1/4 w-[28rem] h-[28rem] bg-emerald-300/25 rounded-full blur-3xl" />
        </div>
        {children}
      </main>
    );
  }

  // If loading authentication state, show clean splash screen
  if (isLoading) {
    return (
      <div className="min-h-screen bg-[#FFFDF9] flex flex-col items-center justify-center p-4 relative overflow-hidden">
        <div className="fixed inset-0 overflow-hidden pointer-events-none -z-10">
          <div className="absolute top-1/4 left-1/3 w-96 h-96 bg-amber-300/30 rounded-full blur-3xl" />
        </div>
        <div className="w-14 h-14 bg-neo-yellow border-2 border-black rounded-2xl flex items-center justify-center text-black shadow-[4px_4px_0px_0px_#000] mb-4 animate-bounce">
          <Wallet className="w-7 h-7 stroke-[2.5]" />
        </div>
        <h2 className="text-xl font-black text-black tracking-tight">SakuKeluarga</h2>
        <div className="flex items-center gap-2 mt-3 text-slate-700 font-bold text-sm">
          <Loader2 className="w-4 h-4 animate-spin text-black stroke-[2.5]" />
          <span>Memeriksa status login...</span>
        </div>
      </div>
    );
  }

  // If not authenticated and on protected route, show redirect screen
  if (!isAuthenticated) {
    return (
      <div className="min-h-screen bg-[#FFFDF9] flex flex-col items-center justify-center p-4">
        <Loader2 className="w-6 h-6 animate-spin text-black stroke-[2.5] mb-2" />
        <p className="text-sm font-bold text-slate-700">Mengarahkan ke halaman masuk...</p>
      </div>
    );
  }

  // Authenticated User Layout with Sidebar, Header, and Bottom Navigation
  return (
    <div className="flex min-h-screen relative bg-[#FFFDF9]">
      {/* Ambient Gradient Mesh for Frosted Brutalist Glass Refraction */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none -z-10">
        <div className="absolute -top-24 -left-24 w-[32rem] h-[32rem] bg-amber-300/35 rounded-full blur-3xl opacity-75" />
        <div className="absolute top-1/4 right-0 w-[30rem] h-[30rem] bg-sky-300/30 rounded-full blur-3xl opacity-75" />
        <div className="absolute -bottom-24 left-1/3 w-[32rem] h-[32rem] bg-emerald-300/25 rounded-full blur-3xl opacity-60" />
        <div className="absolute bottom-1/3 right-1/4 w-80 h-80 bg-pink-300/20 rounded-full blur-3xl opacity-50" />
      </div>

      {/* Desktop Sidebar */}
      <DesktopSidebar />

      {/* Main App Content Area */}
      <div className="flex-1 flex flex-col min-w-0">
        <MobileHeader />

        <main className="flex-1 pb-24 lg:pb-12 max-w-7xl w-full mx-auto p-4 sm:p-6 lg:p-8">
          {children}
        </main>

        <BottomNav />
      </div>

      {/* Global Transaction Bottom Sheet / Modal */}
      <TransactionModal />
    </div>
  );
}
