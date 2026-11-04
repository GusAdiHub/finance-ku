"use client";

import React from "react";
import { useAuth } from "@/lib/auth-context";
import { Wallet, User, FolderKanban } from "lucide-react";
import Link from "next/link";

export function MobileHeader() {
  const { user, activeScope, setActiveScope } = useAuth();

  return (
    <header className="lg:hidden sticky top-0 z-30 bg-[#FFFDF9]/85 backdrop-blur-xl border-b-2 border-black px-4 py-3 flex items-center justify-between">
      {/* Brand */}
      <div className="flex items-center gap-2">
        <div className="w-9 h-9 rounded-xl bg-neo-yellow border-2 border-black shadow-[2px_2px_0px_0px_#000] flex items-center justify-center text-black">
          <Wallet className="w-5 h-5 stroke-[2.5]" />
        </div>
        <span className="font-black text-black tracking-tight text-lg">SakuKu</span>
      </div>

      {/* Scope Pill */}
      <div className="flex items-center bg-white/80 backdrop-blur-md p-0.5 rounded-xl border-2 border-black shadow-[2px_2px_0px_0px_#000]">
        <button
          onClick={() => setActiveScope("personal")}
          className={`flex items-center gap-1 py-1 px-2.5 rounded-lg text-xs font-black transition-all ${
            activeScope === "personal"
              ? "bg-neo-yellow text-black border border-black shadow-[1px_1px_0px_0px_#000]"
              : "text-black hover:bg-slate-100"
          }`}
        >
          <User className="w-3.5 h-3.5 stroke-[2.5] text-black" />
          <span className="text-black">Pribadi</span>
        </button>
        <button
          onClick={() => setActiveScope("family")}
          className={`flex items-center gap-1 py-1 px-2.5 rounded-lg text-xs font-black transition-all ${
            activeScope === "family"
              ? "bg-neo-yellow text-black border border-black shadow-[1px_1px_0px_0px_#000]"
              : "text-black hover:bg-slate-100"
          }`}
        >
          <FolderKanban className="w-3.5 h-3.5 stroke-[2.5] text-black" />
          <span className="text-black">Kas Event</span>
        </button>
      </div>

      {/* Action: Profile */}
      <div className="flex items-center gap-2">
        <Link
          href="/profile"
          className="w-8 h-8 rounded-xl bg-neo-yellow border-2 border-black text-black font-black flex items-center justify-center text-xs shadow-[2px_2px_0px_0px_#000]"
        >
          {user ? user.name.charAt(0).toUpperCase() : "U"}
        </Link>
      </div>
    </header>
  );
}
