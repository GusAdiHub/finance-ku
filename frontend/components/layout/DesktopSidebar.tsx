"use client";

import React from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useAuth } from "@/lib/auth-context";
import { useModal } from "@/lib/modal-context";
import { ScopeSwitcher } from "./ScopeSwitcher";
import {
  LayoutDashboard,
  ReceiptText,
  FolderKanban,
  PieChart,
  Tags,
  UserCheck,
  Plus,
  Eye,
  LogOut,
  Wallet,
} from "lucide-react";

export function DesktopSidebar() {
  const pathname = usePathname();
  const { user, logout, elderlyMode, toggleElderlyMode } = useAuth();
  const { openTransactionModal } = useModal();

  const navItems = [
    { label: "Beranda", href: "/", icon: LayoutDashboard },
    { label: "Riwayat Transaksi", href: "/transactions", icon: ReceiptText },
    { label: "Kas Tim & Event", href: "/groups", icon: FolderKanban },
    { label: "Laporan Finansial", href: "/reports", icon: PieChart },
    { label: "Kategori", href: "/categories", icon: Tags },
    { label: "Profil & Akun", href: "/profile", icon: UserCheck },
  ];

  return (
    <aside className="hidden lg:flex flex-col w-72 bg-[#FFFDF9]/80 backdrop-blur-xl border-r-2 border-black min-h-screen sticky top-0 h-screen p-5 justify-between select-none z-20">
      <div className="flex flex-col gap-6 overflow-y-auto pr-1">
        {/* Brand Header */}
        <div className="flex items-center gap-3 px-1">
          <div className="w-11 h-11 rounded-xl bg-neo-yellow/90 backdrop-blur-md border-2 border-black shadow-[3px_3px_0px_0px_#000] flex items-center justify-center text-black">
            <Wallet className="w-6 h-6 stroke-[2.5]" />
          </div>
          <div>
            <h1 className="font-black text-xl text-black leading-tight tracking-tight">SakuKeluarga</h1>
            <p className="text-[11px] font-bold text-slate-700 uppercase tracking-wider">Shared Finance</p>
          </div>
        </div>

        {/* Scope Switcher */}
        <div className="pt-1">
          <ScopeSwitcher />
        </div>

        {/* Quick Add Button */}
        <button
          onClick={() => openTransactionModal()}
          className={`w-full bg-neo-yellow hover:bg-[#FDE047] active:translate-x-[2px] active:translate-y-[2px] active:shadow-[1px_1px_0px_0px_#000] text-black font-black rounded-xl py-3 px-4 flex items-center justify-center gap-2 border-2 border-black shadow-[4px_4px_0px_0px_#000] transition-all ${
            elderlyMode ? "py-4 text-base" : "text-sm"
          }`}
        >
          <Plus className="w-5 h-5 stroke-[3]" />
          <span>{elderlyMode ? "CATAT UANG BARU" : "CATAT TRANSAKSI"}</span>
        </button>

        {/* Navigation Links */}
        <nav className="flex flex-col gap-2">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = pathname === item.href;
            return (
              <Link
                key={item.href}
                href={item.href}
                className={`flex items-center gap-3 px-3.5 py-2.5 rounded-xl transition-all ${
                  isActive
                    ? "bg-neo-yellow text-black font-black border-2 border-black shadow-[3px_3px_0px_0px_#000]"
                    : "text-black font-bold hover:bg-neo-yellowLight/80 hover:backdrop-blur-sm hover:border-2 hover:border-black hover:shadow-[2px_2px_0px_0px_#000] border-2 border-transparent"
                } ${elderlyMode ? "text-base py-3.5" : "text-sm"}`}
              >
                <Icon className="w-5 h-5 stroke-[2.5] text-black" />
                <span className="text-black">{item.label}</span>
              </Link>
            );
          })}
        </nav>
      </div>

      {/* Bottom Area: Elderly Toggle & User Info */}
      <div className="pt-4 border-t-2 border-black flex flex-col gap-3">
        {/* Mode Ramah Orang Tua Toggle */}
        <div className="bg-white/80 backdrop-blur-md border-2 border-black rounded-xl p-3 shadow-[3px_3px_0px_0px_#000] flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-lg bg-neo-yellowLight border border-black text-black flex items-center justify-center">
              <Eye className="w-4 h-4 stroke-[2.5]" />
            </div>
            <div>
              <p className="text-xs font-bold text-black">Mode Orang Tua</p>
              <p className="text-[10px] text-slate-600 font-medium">Teks lebih besar</p>
            </div>
          </div>
          <button
            onClick={toggleElderlyMode}
            className={`w-11 h-6 rounded-full border-2 border-black transition-colors relative focus:outline-none ${
              elderlyMode ? "bg-neo-green" : "bg-slate-200"
            }`}
            aria-label="Toggle Mode Orang Tua"
          >
            <span
              className={`block w-4 h-4 rounded-full bg-black transition-transform absolute top-0.5 ${
                elderlyMode ? "translate-x-5" : "translate-x-0.5"
              }`}
            />
          </button>
        </div>

        {/* User Card */}
        {user && (
          <div className="flex items-center justify-between p-2.5 rounded-xl bg-white/80 backdrop-blur-md border-2 border-black shadow-[3px_3px_0px_0px_#000]">
            <div className="flex items-center gap-2.5 overflow-hidden">
              <div className="w-8 h-8 rounded-lg bg-neo-yellow border-2 border-black text-black font-black flex items-center justify-center text-xs flex-shrink-0 shadow-[1px_1px_0px_0px_#000]">
                {user.name.charAt(0).toUpperCase()}
              </div>
              <div className="truncate">
                <p className="text-xs font-bold text-black truncate">{user.name}</p>
                <p className="text-[10px] font-medium text-slate-600 truncate">{user.email}</p>
              </div>
            </div>
            <button
              onClick={logout}
              title="Keluar"
              className="p-1.5 text-black hover:bg-rose-100 hover:text-rose-600 border border-transparent hover:border-black rounded-lg transition-colors flex-shrink-0"
            >
              <LogOut className="w-4 h-4" />
            </button>
          </div>
        )}
      </div>
    </aside>
  );
}
