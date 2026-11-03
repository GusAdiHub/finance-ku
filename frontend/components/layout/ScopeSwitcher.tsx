"use client";

import React from "react";
import { useAuth } from "@/lib/auth-context";
import { User, FolderKanban, ChevronDown, Plus } from "lucide-react";
import Link from "next/link";

interface ScopeSwitcherProps {
  compact?: boolean;
}

export function ScopeSwitcher({ compact = false }: ScopeSwitcherProps) {
  const { activeScope, setActiveScope, selectedGroup, setSelectedGroup, userGroups, elderlyMode } = useAuth();

  return (
    <div className="flex flex-col gap-2">
      {/* Scope Pill Toggle */}
      <div className="bg-white/80 backdrop-blur-md p-1 rounded-xl flex items-center border-2 border-black shadow-[3px_3px_0px_0px_#000]">
        <button
          onClick={() => setActiveScope("personal")}
          className={`flex-1 flex items-center justify-center gap-1.5 py-1.5 px-3 rounded-lg text-xs md:text-sm font-black transition-all ${
            activeScope === "personal"
              ? "bg-neo-yellow text-black border-2 border-black shadow-[2px_2px_0px_0px_#000]"
              : "text-black hover:bg-slate-100 border-2 border-transparent"
          } ${elderlyMode ? "text-base py-2.5" : ""}`}
        >
          <User className={`w-4 h-4 stroke-[2.5] text-black ${elderlyMode ? "w-5 h-5" : ""}`} />
          <span className="text-black">{elderlyMode ? "Kas Pribadi" : "Pribadi"}</span>
        </button>

        <button
          onClick={() => setActiveScope("family")}
          className={`flex-1 flex items-center justify-center gap-1.5 py-1.5 px-3 rounded-lg text-xs md:text-sm font-black transition-all ${
            activeScope === "family"
              ? "bg-neo-yellow text-black border-2 border-black shadow-[2px_2px_0px_0px_#000]"
              : "text-black hover:bg-slate-100 border-2 border-transparent"
          } ${elderlyMode ? "text-base py-2.5" : ""}`}
        >
          <FolderKanban className={`w-4 h-4 stroke-[2.5] text-black ${elderlyMode ? "w-5 h-5" : ""}`} />
          <span className="text-black">{elderlyMode ? "Kas Tim / Event" : "Kas Event & Tim"}</span>
        </button>
      </div>

      {/* Group Selector Dropdown when in Group / Event Scope */}
      {activeScope === "family" && (
        <div className="animate-fade-in flex flex-col gap-1">
          {userGroups.length > 0 ? (
            <div className="relative">
              <select
                aria-label="Pilih grup kas event"
                value={selectedGroup?.id || ""}
                onChange={(e) => {
                  const grp = userGroups.find((g) => g.id === e.target.value);
                  if (grp) setSelectedGroup(grp);
                }}
                className={`w-full bg-white border-2 border-black rounded-xl px-3 py-2 text-xs md:text-sm font-bold text-black focus:outline-none shadow-[2px_2px_0px_0px_#000] appearance-none pr-8 cursor-pointer ${
                  elderlyMode ? "text-base py-3" : ""
                }`}
              >
                {userGroups.map((g) => (
                  <option key={g.id} value={g.id}>
                    🎪 {g.name.replace(/Keluarga\s*Cemara/gi, "Panitia Event & Proyek")} ({g.members_count || 1} anggota)
                  </option>
                ))}
              </select>
              <ChevronDown className="w-4 h-4 text-black absolute right-2.5 top-1/2 -translate-y-1/2 pointer-events-none stroke-[2.5]" />
            </div>
          ) : (
            <Link
              href="/groups"
              className="text-xs text-black bg-neo-yellow hover:bg-[#FDE047] border-2 border-black rounded-xl p-2.5 flex items-center justify-center gap-1 font-bold shadow-[2px_2px_0px_0px_#000] transition-all"
            >
              <Plus className="w-3.5 h-3.5 stroke-[3]" />
              <span>Belum ada Kas Grup / Event. Buat sekarang</span>
            </Link>
          )}
        </div>
      )}
    </div>
  );
}
