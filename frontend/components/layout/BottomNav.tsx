"use client";

import React from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useModal } from "@/lib/modal-context";
import { useAuth } from "@/lib/auth-context";
import { LayoutDashboard, ReceiptText, Plus, FolderKanban, PieChart } from "lucide-react";

export function BottomNav() {
  const pathname = usePathname();
  const { openTransactionModal } = useModal();

  return (
    <nav className="lg:hidden fixed bottom-0 left-0 right-0 z-40 bg-[#FFFDF9]/85 backdrop-blur-xl border-t-2 border-black pb-safe pt-1 px-3 shadow-[0_-3px_0px_0px_#000]">
      <div className="flex items-center justify-around h-16 max-w-md mx-auto relative">
        {/* Beranda */}
        <Link
          href="/"
          className={`flex flex-col items-center justify-center flex-1 py-1 transition-all ${
            pathname === "/" ? "text-black font-black" : "text-slate-600 hover:text-black font-semibold"
          }`}
        >
          <LayoutDashboard className="w-5 h-5 stroke-[2.5]" />
          <span className="text-[10px] mt-1">Beranda</span>
        </Link>

        {/* Riwayat */}
        <Link
          href="/transactions"
          className={`flex flex-col items-center justify-center flex-1 py-1 transition-all ${
            pathname === "/transactions" ? "text-black font-black" : "text-slate-600 hover:text-black font-semibold"
          }`}
        >
          <ReceiptText className="w-5 h-5 stroke-[2.5]" />
          <span className="text-[10px] mt-1">Riwayat</span>
        </Link>

        {/* Center Floating Action Button (+ Catat) */}
        <div className="flex-1 flex justify-center -translate-y-4">
          <button
            onClick={() => openTransactionModal()}
            className="w-14 h-14 rounded-2xl bg-neo-yellow hover:bg-[#FDE047] text-black shadow-[4px_4px_0px_0px_#000] border-2 border-black flex items-center justify-center active:translate-x-[2px] active:translate-y-[2px] active:shadow-[1px_1px_0px_0px_#000] transition-all"
            aria-label="Catat Transaksi"
          >
            <Plus className="w-7 h-7 stroke-[3]" />
          </button>
        </div>

        {/* Kas Tim / Event */}
        <Link
          href="/groups"
          className={`flex flex-col items-center justify-center flex-1 py-1 transition-all ${
            pathname === "/groups" ? "text-black font-black" : "text-slate-600 hover:text-black font-semibold"
          }`}
        >
          <FolderKanban className="w-5 h-5 stroke-[2.5]" />
          <span className="text-[10px] mt-1">Kas Event</span>
        </Link>

        {/* Laporan */}
        <Link
          href="/reports"
          className={`flex flex-col items-center justify-center flex-1 py-1 transition-all ${
            pathname === "/reports" ? "text-black font-black" : "text-slate-600 hover:text-black font-semibold"
          }`}
        >
          <PieChart className="w-5 h-5 stroke-[2.5]" />
          <span className="text-[10px] mt-1">Laporan</span>
        </Link>
      </div>
    </nav>
  );
}
