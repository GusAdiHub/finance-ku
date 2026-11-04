"use client";

import React, { useState, useEffect } from "react";
import { useAuth } from "@/lib/auth-context";
import { useToast } from "@/lib/toast-context";
import { api } from "@/lib/api";
import { Group, GroupMember } from "@/lib/types";
import {
  formatDate,
  formatRupiah,
  parseGroupBudget,
  cleanGroupDescription,
  encodeGroupDescription,
} from "@/lib/utils";
import {
  FolderKanban,
  Plus,
  KeyRound,
  ShieldCheck,
  User,
  Copy,
  Check,
  LogOut,
  AlertCircle,
  Share2,
  Target,
  Pencil,
  Trash2,
  X,
  Sparkles,
} from "lucide-react";

export default function GroupsPage() {
  const { user, userGroups, selectedGroup, setSelectedGroup, refreshGroups } = useAuth();
  const toast = useToast();

  const [activeGroupId, setActiveGroupId] = useState<string>(selectedGroup?.id || "");
  const [members, setMembers] = useState<GroupMember[]>([]);
  const [isLoadingMembers, setIsLoadingMembers] = useState<boolean>(false);

  // Modals / Actions
  const [isCreatingGroup, setIsCreatingGroup] = useState<boolean>(false);
  const [newGroupName, setNewGroupName] = useState<string>("");
  const [newGroupBudget, setNewGroupBudget] = useState<string>("");
  const [newGroupDesc, setNewGroupDesc] = useState<string>("");

  const [isEditingBudget, setIsEditingBudget] = useState<boolean>(false);
  const [budgetEditInput, setBudgetEditInput] = useState<string>("");
  const [isSavingBudget, setIsSavingBudget] = useState<boolean>(false);

  // Edit Group Info Modal (Name, Budget, Description)
  const [isEditingInfo, setIsEditingInfo] = useState<boolean>(false);
  const [editNameInput, setEditNameInput] = useState<string>("");
  const [editBudgetInput, setEditBudgetInput] = useState<string>("");
  const [editDescInput, setEditDescInput] = useState<string>("");
  const [isSavingInfo, setIsSavingInfo] = useState<boolean>(false);
  const [isDeletingGroup, setIsDeletingGroup] = useState<boolean>(false);

  const [isJoiningGroup, setIsJoiningGroup] = useState<boolean>(false);
  const [isSubmittingJoin, setIsSubmittingJoin] = useState<boolean>(false);
  const [joinCode, setJoinCode] = useState<string>("");

  const [generatedInviteCode, setGeneratedInviteCode] = useState<string | null>(null);
  const [isCopied, setIsCopied] = useState<boolean>(false);
  const [actionError, setActionError] = useState<string | null>(null);
  const [actionSuccess, setActionSuccess] = useState<string | null>(null);

  useEffect(() => {
    if (selectedGroup) {
      setActiveGroupId(selectedGroup.id);
    } else if (userGroups.length > 0 && !activeGroupId) {
      setActiveGroupId(userGroups[0].id);
    }
  }, [selectedGroup, userGroups, activeGroupId]);

  useEffect(() => {
    if (activeGroupId) {
      loadMembers(activeGroupId);
      try {
        const savedCode = localStorage.getItem(`sakuku_invite_${activeGroupId}`);
        if (savedCode) {
          setGeneratedInviteCode(savedCode);
        } else {
          // Auto-generate code if user is owner/admin so a shareable code is always ready
          const grp = userGroups.find((g) => g.id === activeGroupId);
          if (grp && (grp.user_role === "owner" || grp.user_role === "admin")) {
            api
              .createInvitation(activeGroupId)
              .then((res) => {
                setGeneratedInviteCode(res.code);
                try {
                  localStorage.setItem(`sakuku_invite_${activeGroupId}`, res.code);
                } catch {}
              })
              .catch(() => {});
          } else {
            setGeneratedInviteCode(null);
          }
        }
      } catch {}
    }
  }, [activeGroupId, userGroups]);

  const loadMembers = async (grpId: string) => {
    setIsLoadingMembers(true);
    try {
      const data = await api.getGroupMembers(grpId);
      setMembers(data);
    } catch (err: any) {
      console.error("Load members error:", err);
    } finally {
      setIsLoadingMembers(false);
    }
  };

  const handleCreateGroup = async (e: React.FormEvent) => {
    e.preventDefault();
    setActionError(null);
    try {
      const parsedBudget = parseFloat(newGroupBudget.replace(/[^\d]/g, "")) || 0;
      const encodedDesc = encodeGroupDescription(
        newGroupDesc.trim(),
        parsedBudget > 0 ? parsedBudget : null
      );

      const res = await api.createGroup({
        name: newGroupName.trim(),
        description: encodedDesc || undefined,
      });
      await refreshGroups();
      setActiveGroupId(res.id);
      setSelectedGroup(res);
      setIsCreatingGroup(false);
      setNewGroupName("");
      setNewGroupBudget("");
      setNewGroupDesc("");
      toast.success("Grup Kas Event / Tim berhasil dibuat!", "GRUP DIBUAT");
      setActionSuccess("Grup Kas Event / Tim berhasil dibuat!");
    } catch (err: any) {
      const msg = err.message || "Gagal membuat grup kas event.";
      setActionError(msg);
      toast.error(msg, "GAGAL MEMBUAT");
    }
  };

  const handleSaveBudget = async (e: React.FormEvent) => {
    e.preventDefault();
    const curr = userGroups.find((g) => g.id === activeGroupId);
    if (!curr) return;
    setIsSavingBudget(true);
    try {
      const parsed = parseFloat(budgetEditInput.replace(/[^\d]/g, "")) || 0;
      const clean = cleanGroupDescription(curr.description);
      const updatedDesc = encodeGroupDescription(clean, parsed > 0 ? parsed : null);

      await api.updateGroup(curr.id, { description: updatedDesc });
      await refreshGroups();
      setIsEditingBudget(false);
      toast.success("Pagu anggaran kas event berhasil diperbarui!", "ANGGARAN DISIMPAN");
      setActionSuccess("Pagu anggaran event berhasil diperbarui!");
    } catch (err: any) {
      const msg = err.message || "Gagal memperbarui pagu anggaran.";
      setActionError(msg);
      toast.error(msg, "GAGAL MEMPERBARUI");
    } finally {
      setIsSavingBudget(false);
    }
  };

  const handleJoinGroup = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!joinCode.trim()) return;
    setIsSubmittingJoin(true);
    setActionError(null);
    try {
      const res = await api.joinGroup(joinCode.trim().toUpperCase());
      await refreshGroups();
      setActiveGroupId(res.id);
      setSelectedGroup(res);
      setIsJoiningGroup(false);
      setJoinCode("");
      toast.success("Berhasil bergabung ke grup kas event!", "BERGABUNG BERHASIL");
      setActionSuccess("Berhasil bergabung ke grup kas event!");
    } catch (err: any) {
      const msg = err.message || "Gagal bergabung dengan kode tersebut.";
      setActionError(msg);
      toast.error(msg, "KODE TIDAK VALID");
    } finally {
      setIsSubmittingJoin(false);
    }
  };

  const handleCreateInvite = async () => {
    if (!activeGroupId) return;
    setActionError(null);
    try {
      const res = await api.createInvitation(activeGroupId);
      setGeneratedInviteCode(res.code);
      try {
        localStorage.setItem(`sakuku_invite_${activeGroupId}`, res.code);
      } catch {}
      toast.success(`Kode undangan baru: ${res.code}`, "KODE BERHASIL DIBUAT");
    } catch (err: any) {
      const msg = err.message || "Gagal membuat kode undangan.";
      setActionError(msg);
      toast.error(msg, "GAGAL MEMBUAT KODE");
    }
  };

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text);
    setIsCopied(true);
    toast.success("Kode undangan berhasil disalin ke clipboard!", "KODE DISALIN");
    setTimeout(() => setIsCopied(false), 2000);
  };

  const handleLeaveGroup = async () => {
    const confirmed = await toast.confirm({
      title: "Keluar dari Kas Event?",
      message: "Apakah Anda yakin ingin keluar dari grup kas event ini? Anda tidak akan dapat melihat pembukuan kas ini lagi sampai diundang kembali.",
      confirmText: "Ya, Keluar",
      cancelText: "Batal",
      type: "danger",
    });
    if (!confirmed) return;

    try {
      await api.leaveGroup(activeGroupId);
      await refreshGroups();
      toast.info("Anda telah keluar dari grup kas event.", "KELUAR GRUP");
      setActionSuccess("Anda telah keluar dari grup.");
    } catch (err: any) {
      const msg = err.message || "Gagal keluar dari grup.";
      setActionError(msg);
      toast.error(msg, "GAGAL KELUAR");
    }
  };

  const handleOpenEditInfo = () => {
    if (!currentGroup) return;
    setEditNameInput(currentGroup.name);
    setEditBudgetInput(currentBudget ? String(currentBudget) : "");
    setEditDescInput(currentCleanDesc);
    setIsEditingInfo(true);
  };

  const handleSaveInfo = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!currentGroup) return;
    setIsSavingInfo(true);
    setActionError(null);
    try {
      const parsedBudget = parseFloat(editBudgetInput.replace(/[^\d]/g, "")) || 0;
      const encodedDesc = encodeGroupDescription(
        editDescInput.trim(),
        parsedBudget > 0 ? parsedBudget : null
      );
      const updated = await api.updateGroup(currentGroup.id, {
        name: editNameInput.trim(),
        description: encodedDesc,
      });
      await refreshGroups();
      setSelectedGroup(updated);
      setIsEditingInfo(false);
      setActionSuccess(`Kas Event berhasil diperbarui menjadi "${updated.name}"!`);
    } catch (err: any) {
      setActionError(err.message || "Gagal memperbarui info kas event.");
    } finally {
      setIsSavingInfo(false);
    }
  };

  const handleDeleteGroup = async () => {
    if (!currentGroup) return;
    const confirmed = confirm(
      `Apakah Anda yakin ingin menghapus "${currentGroup.name}"? Kas event ini beserta seluruh catatannya akan dinonaktifkan.`
    );
    if (!confirmed) return;
    setIsDeletingGroup(true);
    setActionError(null);
    try {
      await api.deleteGroup(currentGroup.id);
      await refreshGroups();
      setActionSuccess(`Kas Event "${currentGroup.name}" berhasil dihapus.`);
    } catch (err: any) {
      setActionError(err.message || "Gagal menghapus kas event.");
    } finally {
      setIsDeletingGroup(false);
    }
  };

  const currentGroup = userGroups.find((g) => g.id === activeGroupId) || userGroups[0];
  const currentBudget = currentGroup ? parseGroupBudget(currentGroup.description) : null;
  const currentCleanDesc = currentGroup ? cleanGroupDescription(currentGroup.description) : "";
  const isOwner = currentGroup?.user_role === "owner";
  const isOwnerOrAdmin = currentGroup?.user_role === "owner" || currentGroup?.user_role === "admin";

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white/80 backdrop-blur-xl p-5 rounded-2xl border-2 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.9),4px_4px_0px_0px_#000]">
        <div>
          <h1 className="font-black text-black tracking-tight text-xl sm:text-2xl">
            Kelola Kas Tim, Event & Proyek
          </h1>
          <p className="text-xs sm:text-sm font-semibold text-slate-700 mt-0.5">
            Kelola pagu anggaran, buku kas bersama (Shared Ledger), anggota tim, dan kode undangan.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={() => {
              setIsJoiningGroup(true);
              setActionError(null);
            }}
            className="bg-white hover:bg-slate-100 text-black font-black text-xs sm:text-sm px-3.5 py-2.5 rounded-xl flex items-center gap-1.5 border-2 border-black shadow-[2px_2px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] transition-all"
          >
            <KeyRound className="w-4 h-4 text-black stroke-[2.5]" />
            <span>Gabung Grup</span>
          </button>
          <button
            onClick={() => {
              setIsCreatingGroup(true);
              setActionError(null);
            }}
            className="bg-neo-yellow hover:bg-[#FDE047] text-black font-black text-xs sm:text-sm px-4 py-2.5 rounded-xl flex items-center gap-1.5 border-2 border-black shadow-[3px_3px_0px_0px_#000] active:translate-x-[2px] active:translate-y-[2px] active:shadow-[1px_1px_0px_0px_#000] transition-all"
          >
            <Plus className="w-4 h-4 stroke-[3]" />
            <span>+ Buat Kas Event Baru</span>
          </button>
        </div>
      </div>

      {actionSuccess && (
        <div className="p-3.5 bg-neo-greenLight border-2 border-black text-black text-xs sm:text-sm font-bold rounded-xl flex items-center justify-between shadow-[2px_2px_0px_0px_#000]">
          <span>{actionSuccess}</span>
          <button onClick={() => setActionSuccess(null)} className="text-black font-black text-xs hover:opacity-75">
            ✕
          </button>
        </div>
      )}

      {actionError && (
        <div className="p-3.5 bg-red-100 border-2 border-black text-red-950 text-xs sm:text-sm font-bold rounded-xl flex items-center justify-between shadow-[2px_2px_0px_0px_#000]">
          <div className="flex items-center gap-2">
            <AlertCircle className="w-4 h-4 flex-shrink-0 stroke-[2.5]" />
            <span>{actionError}</span>
          </div>
          <button onClick={() => setActionError(null)} className="text-red-950 font-black text-xs hover:opacity-75">
            ✕
          </button>
        </div>
      )}

      {/* Main Layout: Group Switcher & Group Details */}
      {userGroups.length > 0 ? (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Left: Groups List */}
          <div className="space-y-3">
            <h2 className="text-xs font-black text-black uppercase tracking-wider px-1">
              Grup Kas Event Anda ({userGroups.length})
            </h2>
            <div className="space-y-2">
              {userGroups.map((g) => {
                const isSelected = g.id === activeGroupId;
                const b = parseGroupBudget(g.description);
                return (
                  <div
                    key={g.id}
                    onClick={() => {
                      setActiveGroupId(g.id);
                      setSelectedGroup(g);
                    }}
                    className={`p-4 rounded-2xl border-2 border-black transition-all cursor-pointer flex items-center justify-between ${
                      isSelected
                        ? "bg-neo-yellowLight/90 backdrop-blur-md shadow-[4px_4px_0px_0px_#000]"
                        : "bg-white/80 backdrop-blur-md shadow-[2px_2px_0px_0px_#000] hover:translate-x-[-1px] hover:translate-y-[-1px] hover:shadow-[3.5px_3.5px_0px_0px_#000]"
                    }`}
                  >
                    <div className="flex items-center gap-3">
                      <div
                        className={`w-10 h-10 rounded-xl border-2 border-black shadow-[1.5px_1.5px_0px_0px_#000] flex items-center justify-center font-black text-sm ${
                          isSelected ? "bg-neo-yellow text-black" : "bg-slate-100 text-black"
                        }`}
                      >
                        🎪
                      </div>
                      <div>
                        <p className="font-black text-black text-sm">{g.name}</p>
                        <p className="text-xs font-semibold text-slate-700">
                          {b ? `Anggaran: ${formatRupiah(b)}` : `${g.members_count || 1} Anggota`}
                        </p>
                      </div>
                    </div>
                    {isSelected && (
                      <span className="text-[10px] bg-neo-yellow text-black px-2 py-0.5 rounded-md font-black border border-black shadow-[1px_1px_0px_0px_#000]">
                        Aktif
                      </span>
                    )}
                  </div>
                );
              })}
            </div>
          </div>

          {/* Right: Active Group Details & Members */}
          {currentGroup && (
            <div className="lg:col-span-2 space-y-6">
              {/* Group Info Card */}
              <div className="bg-white/80 backdrop-blur-xl p-5 sm:p-6 rounded-2xl border-2 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.9),4px_4px_0px_0px_#000] space-y-4">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="text-xs font-black uppercase bg-neo-yellow text-black px-2 py-0.5 rounded border border-black">
                        Kas Event / Tim
                      </span>
                      <span className="text-xs font-bold text-slate-600">Peran: {currentGroup.user_role || "member"}</span>
                    </div>
                    <h2 className="text-xl font-black text-black mt-1">{currentGroup.name}</h2>
                    <p className="text-xs font-semibold text-slate-700 mt-0.5">
                      {currentCleanDesc || "Kas operasional dan bukti nota belanja event"} • Dibuat{" "}
                      {formatDate(currentGroup.created_at)}
                    </p>
                  </div>
                  <div className="flex items-center gap-2 flex-wrap">
                    {isOwnerOrAdmin && (
                      <button
                        onClick={handleOpenEditInfo}
                        className="bg-neo-yellow hover:bg-[#FDE047] text-black border-2 border-black text-xs font-black px-3 py-2 rounded-xl flex items-center gap-1.5 shadow-[2px_2px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] transition-all"
                        title="Ubah nama, anggaran, dan deskripsi event"
                      >
                        <Pencil className="w-3.5 h-3.5 stroke-[2.5]" />
                        <span>Edit Event</span>
                      </button>
                    )}
                    <button
                      onClick={generatedInviteCode ? () => copyToClipboard(generatedInviteCode) : handleCreateInvite}
                      className="bg-purple-100 hover:bg-purple-200 text-black border-2 border-black text-xs font-black px-3 py-2 rounded-xl flex items-center gap-1.5 shadow-[2px_2px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] transition-all"
                      title="Salin atau buat kode undangan kas event"
                    >
                      <KeyRound className="w-4 h-4 stroke-[2.5]" />
                      <span>{generatedInviteCode ? `Kode: ${generatedInviteCode}` : "🔑 Kode Undangan"}</span>
                    </button>
                    {isOwner ? (
                      <button
                        onClick={handleDeleteGroup}
                        disabled={isDeletingGroup}
                        className="bg-white hover:bg-rose-100 text-rose-600 border-2 border-black text-xs font-black px-3 py-2 rounded-xl border-2 border-black shadow-[2px_2px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] flex items-center gap-1.5 transition-all disabled:opacity-50"
                        title="Hapus kas event ini"
                      >
                        <Trash2 className="w-4 h-4 stroke-[2.5]" />
                        <span>Hapus</span>
                      </button>
                    ) : (
                      <button
                        onClick={handleLeaveGroup}
                        className="text-rose-600 hover:bg-rose-100 text-xs font-black px-3 py-2 rounded-xl border-2 border-black shadow-[2px_2px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] flex items-center gap-1.5 transition-all"
                      >
                        <LogOut className="w-4 h-4 stroke-[2.5]" />
                        <span>Keluar</span>
                      </button>
                    )}
                  </div>
                </div>

                {/* Target Pagu Anggaran Bar */}
                <div className="p-3.5 bg-[#FFFDF9] border-2 border-black rounded-xl flex items-center justify-between gap-3 shadow-[2px_2px_0px_0px_#000]">
                  <div className="flex items-center gap-2.5">
                    <div className="w-8 h-8 rounded-lg bg-neo-yellow border-2 border-black flex items-center justify-center text-black">
                      <Target className="w-4 h-4 stroke-[2.5]" />
                    </div>
                    <div>
                      <p className="text-[11px] font-bold text-slate-600">Pagu Anggaran Event:</p>
                      <p className="text-sm font-black text-black">
                        {currentBudget ? formatRupiah(currentBudget) : "Belum ditentukan"}
                      </p>
                    </div>
                  </div>
                  <button
                    onClick={() => {
                      setBudgetEditInput(currentBudget ? String(currentBudget) : "");
                      setIsEditingBudget(true);
                    }}
                    className="text-xs font-black bg-white hover:bg-slate-100 text-black px-3 py-1.5 rounded-lg border-2 border-black shadow-[1.5px_1.5px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] flex items-center gap-1 transition-all"
                  >
                    <Pencil className="w-3 h-3 stroke-[2.5]" />
                    <span>{currentBudget ? "Ubah Anggaran" : "+ Pasang Anggaran"}</span>
                  </button>
                </div>

                {/* Kode Undangan Kas Event Card (Selalu Tampil) */}
                {generatedInviteCode ? (
                  <div className="p-4 bg-purple-100 border-2 border-black rounded-xl flex flex-col sm:flex-row sm:items-center justify-between gap-3.5 shadow-[3px_3px_0px_0px_#000] animate-fade-in">
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="text-[10px] sm:text-xs font-black uppercase bg-white px-2 py-0.5 rounded border border-black shadow-[1px_1px_0px_0px_#000] text-black">
                          🔑 Kode Undangan Kas Event
                        </span>
                        <span className="text-[11px] text-slate-700 font-bold">Maks. 5 Anggota • Berlaku 7 Hari</span>
                      </div>
                      <p className="text-2xl sm:text-3xl font-mono font-black tracking-widest text-black mt-2 selection:bg-neo-yellow">
                        {generatedInviteCode}
                      </p>
                      <p className="text-[11px] text-slate-700 font-semibold mt-1">
                        Bagikan kode 8 digit ini ke teman / anggota panitia agar bisa bergabung via tombol <strong>Gabung Grup Kas</strong>.
                      </p>
                    </div>
                    <div className="flex items-center gap-2 flex-wrap self-start sm:self-auto">
                      <button
                        onClick={() => copyToClipboard(generatedInviteCode)}
                        className="bg-neo-yellow hover:bg-[#FDE047] text-black text-xs font-black px-4 py-2.5 rounded-xl flex items-center justify-center gap-1.5 border-2 border-black shadow-[2px_2px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] transition-all"
                      >
                        {isCopied ? <Check className="w-4 h-4 stroke-[3]" /> : <Copy className="w-4 h-4 stroke-[2.5]" />}
                        <span>{isCopied ? "Tersalin!" : "Salin Kode"}</span>
                      </button>
                      {isOwnerOrAdmin && (
                        <button
                          onClick={handleCreateInvite}
                          className="bg-white hover:bg-slate-100 text-black text-xs font-black px-3 py-2.5 rounded-xl flex items-center justify-center gap-1.5 border-2 border-black shadow-[2px_2px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] transition-all"
                          title="Buat kode baru jika kode lama kadaluarsa"
                        >
                          <span>🔄 Buat Kode Baru</span>
                        </button>
                      )}
                    </div>
                  </div>
                ) : (
                  <div className="p-4 bg-purple-50 border-2 border-dashed border-black rounded-xl flex flex-col sm:flex-row sm:items-center justify-between gap-3 shadow-[2px_2px_0px_0px_#000]">
                    <div>
                      <p className="text-xs font-black text-black flex items-center gap-1.5">
                        <KeyRound className="w-4 h-4 stroke-[2.5] text-purple-700" />
                        <span>Kode Undangan Kas Event Belum Dibuat</span>
                      </p>
                      <p className="text-xs text-slate-700 font-medium mt-1">
                        Buat kode 8-digit sekali klik untuk mengundang anggota tim / panitia ke kas event ini.
                      </p>
                    </div>
                    {isOwnerOrAdmin ? (
                      <button
                        onClick={handleCreateInvite}
                        className="bg-neo-yellow hover:bg-[#FDE047] text-black text-xs font-black px-4 py-2.5 rounded-xl flex items-center justify-center gap-1.5 border-2 border-black shadow-[2px_2px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] transition-all self-start sm:self-auto"
                      >
                        <Share2 className="w-4 h-4 stroke-[2.5]" />
                        <span>🔑 Buat Kode Undangan</span>
                      </button>
                    ) : (
                      <span className="text-[11px] font-bold text-slate-500">
                        Hanya Admin / Pemilik yang dapat membuat kode
                      </span>
                    )}
                  </div>
                )}
              </div>

              {/* Members List Card */}
              <div className="bg-white/80 backdrop-blur-xl p-5 sm:p-6 rounded-2xl border-2 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.9),4px_4px_0px_0px_#000] space-y-4">
                <div className="flex items-center justify-between">
                  <h3 className="font-black text-black text-base flex items-center gap-2">
                    <FolderKanban className="w-4 h-4 text-black stroke-[2.5]" />
                    <span>Daftar Anggota Tim ({members.length})</span>
                  </h3>
                </div>

                {isLoadingMembers ? (
                  <div className="space-y-2 py-2">
                    {[1, 2, 3].map((i) => (
                      <div key={i} className="h-12 bg-slate-200 border-2 border-black rounded-xl animate-pulse" />
                    ))}
                  </div>
                ) : (
                  <div className="divide-y-2 divide-slate-100">
                    {members.map((m) => (
                      <div key={m.id} className="py-3 flex items-center justify-between gap-3">
                        <div className="flex items-center gap-3">
                          <div className="w-9 h-9 rounded-xl bg-neo-yellow border-2 border-black text-black flex items-center justify-center text-xs font-black shadow-[1.5px_1.5px_0px_0px_#000]">
                            {m.user_name.charAt(0).toUpperCase()}
                          </div>
                          <div>
                            <p className="font-black text-black text-xs sm:text-sm flex items-center gap-1.5">
                              <span>{m.user_name}</span>
                              {m.user_id === user?.id && (
                                <span className="text-[10px] text-black bg-neo-yellow px-1.5 py-0.2 rounded border border-black font-black">
                                  Anda
                                </span>
                              )}
                            </p>
                            <p className="text-[11px] font-semibold text-slate-600">
                              {m.user_email} • Gabung {formatDate(m.joined_at)}
                            </p>
                          </div>
                        </div>

                        <span
                          className={`text-[11px] font-black px-2.5 py-1 rounded-lg border-2 border-black shadow-[1.5px_1.5px_0px_0px_#000] ${
                            m.role === "owner"
                              ? "bg-neo-yellow text-black"
                              : m.role === "admin"
                              ? "bg-neo-blue text-white"
                              : "bg-white text-black"
                          }`}
                        >
                          {m.role === "owner" ? "Ketua / Pemilik" : m.role === "admin" ? "Bendahara / Admin" : "Anggota"}
                        </span>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>
          )}
        </div>
      ) : (
        /* Empty State */
        <div className="bg-white/90 backdrop-blur-xl p-8 sm:p-12 rounded-2xl border-2 border-black text-center max-w-lg mx-auto space-y-4 shadow-[4px_4px_0px_0px_#000]">
          <div className="w-16 h-16 rounded-2xl bg-neo-yellow border-2 border-black text-black flex items-center justify-center mx-auto shadow-[3px_3px_0px_0px_#000]">
            <FolderKanban className="w-8 h-8 stroke-[2.5]" />
          </div>
          <h2 className="text-xl font-black text-black">Belum Ada Kas Tim & Event</h2>
          <p className="text-xs sm:text-sm font-semibold text-slate-700">
            Mulai kelola uang kas event, setoran bukti nota belanja, dan penggantian reimburse secara transparan. Buat grup kas untuk kepanitiaan event Anda atau masukkan kode undangan dari tim.
          </p>
          <div className="flex flex-col sm:flex-row items-center justify-center gap-3 pt-2">
            <button
              onClick={() => setIsCreatingGroup(true)}
              className="w-full sm:w-auto bg-neo-yellow hover:bg-[#FDE047] text-black font-black text-xs sm:text-sm px-5 py-3 rounded-xl border-2 border-black shadow-[3px_3px_0px_0px_#000] active:translate-x-[2px] active:translate-y-[2px] transition-all"
            >
              + Buat Kas Event Baru
            </button>
            <button
              onClick={() => setIsJoiningGroup(true)}
              className="w-full sm:w-auto bg-white hover:bg-slate-100 text-black font-black text-xs sm:text-sm px-5 py-3 rounded-xl border-2 border-black shadow-[3px_3px_0px_0px_#000] active:translate-x-[2px] active:translate-y-[2px] transition-all"
            >
              Gabung dengan Kode
            </button>
          </div>
        </div>
      )}

      {/* Modal: Buat Kas Event Baru */}
      {isCreatingGroup && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/45 backdrop-blur-md animate-fade-in">
          <div className="bg-[#FFFDF9]/95 backdrop-blur-2xl w-full max-w-md rounded-2xl p-6 border-3 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.95),8px_8px_0px_0px_#000] space-y-4">
            <h3 className="font-black text-lg text-black flex items-center gap-2">
              <FolderKanban className="w-5 h-5 text-black stroke-[2.5]" />
              <span>Buat Kas Tim / Event Baru</span>
            </h3>
            <form onSubmit={handleCreateGroup} className="space-y-4">
              <div>
                <label className="text-xs font-black text-black block mb-1">
                  Nama Event / Tim
                </label>
                <input
                  type="text"
                  required
                  placeholder="Contoh: Panitia Wisuda 2026, Event Pameran Seni"
                  value={newGroupName}
                  onChange={(e) => setNewGroupName(e.target.value)}
                  className="w-full bg-white border-2 border-black rounded-xl px-3 py-2 text-sm font-bold text-black shadow-[2px_2px_0px_0px_#000] outline-none"
                />
              </div>

              <div>
                <label className="text-xs font-black text-black block mb-1">
                  Target Pagu Anggaran Kas (Rp) - Opsional
                </label>
                <div className="relative">
                  <span className="absolute left-3 top-1/2 -translate-y-1/2 font-black text-xs text-black">
                    Rp
                  </span>
                  <input
                    type="text"
                    inputMode="numeric"
                    placeholder="Contoh: 10.000.000"
                    value={
                      newGroupBudget && !isNaN(Number(newGroupBudget.replace(/[^\d]/g, "")))
                        ? Number(newGroupBudget.replace(/[^\d]/g, "")).toLocaleString("id-ID")
                        : ""
                    }
                    onChange={(e) => setNewGroupBudget(e.target.value.replace(/[^\d]/g, ""))}
                    className="w-full bg-white border-2 border-black rounded-xl pl-10 pr-3 py-2 text-sm font-bold text-black shadow-[2px_2px_0px_0px_#000] outline-none"
                  />
                </div>
                <p className="text-[11px] text-slate-600 font-medium mt-1">
                  Target batas anggaran belanja kas untuk event ini. Sisa kas akan terupdate otomatis.
                </p>
              </div>

              <div>
                <label className="text-xs font-black text-black block mb-1">
                  Deskripsi / Keterangan Event (Opsional)
                </label>
                <textarea
                  placeholder="Tempat setoran nota belanja konsumsi, sewa tempat, perlengkapan, dan reimburse tim."
                  value={newGroupDesc}
                  onChange={(e) => setNewGroupDesc(e.target.value)}
                  className="w-full bg-white border-2 border-black rounded-xl px-3 py-2 text-sm font-bold text-black shadow-[2px_2px_0px_0px_#000] outline-none h-20 resize-none"
                />
              </div>

              <div className="flex items-center justify-end gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setIsCreatingGroup(false)}
                  className="px-4 py-2 text-xs font-bold text-black bg-white hover:bg-slate-100 border-2 border-black rounded-xl shadow-[2px_2px_0px_0px_#000] transition-all"
                >
                  Batal
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 text-xs font-black bg-neo-yellow hover:bg-[#FDE047] text-black border-2 border-black rounded-xl shadow-[3px_3px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] transition-all"
                >
                  Simpan Kas Event
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal: Edit Budget */}
      {isEditingBudget && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/45 backdrop-blur-md animate-fade-in">
          <div className="bg-[#FFFDF9]/95 backdrop-blur-2xl w-full max-w-md rounded-2xl p-6 border-3 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.95),8px_8px_0px_0px_#000] space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="font-black text-lg text-black flex items-center gap-2">
                <Target className="w-5 h-5 text-black stroke-[2.5]" />
                <span>Ubah Pagu Anggaran Event</span>
              </h3>
              <button onClick={() => setIsEditingBudget(false)} className="p-1 hover:bg-slate-200 rounded-lg">
                <X className="w-5 h-5 stroke-[2.5]" />
              </button>
            </div>

            <form onSubmit={handleSaveBudget} className="space-y-4">
              <div>
                <label className="text-xs font-black text-black block mb-1">
                  Target Pagu Anggaran Baru (Rp):
                </label>
                <div className="relative">
                  <span className="absolute left-3 top-1/2 -translate-y-1/2 font-black text-xs text-black">
                    Rp
                  </span>
                  <input
                    type="text"
                    inputMode="numeric"
                    required
                    value={
                      budgetEditInput && !isNaN(Number(budgetEditInput.replace(/[^\d]/g, "")))
                        ? Number(budgetEditInput.replace(/[^\d]/g, "")).toLocaleString("id-ID")
                        : ""
                    }
                    onChange={(e) => setBudgetEditInput(e.target.value.replace(/[^\d]/g, ""))}
                    placeholder="Contoh: 15.000.000"
                    className="w-full bg-white border-2 border-black rounded-xl pl-10 pr-3 py-2 text-sm font-bold text-black shadow-[2px_2px_0px_0px_#000] outline-none"
                    autoFocus
                  />
                </div>
              </div>

              <div className="flex items-center justify-end gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setIsEditingBudget(false)}
                  className="px-4 py-2 text-xs font-bold text-black bg-white hover:bg-slate-100 border-2 border-black rounded-xl shadow-[2px_2px_0px_0px_#000] transition-all"
                >
                  Batal
                </button>
                <button
                  type="submit"
                  disabled={isSavingBudget}
                  className="px-4 py-2 text-xs font-black bg-neo-yellow hover:bg-[#FDE047] text-black border-2 border-black rounded-xl shadow-[3px_3px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] transition-all"
                >
                  {isSavingBudget ? "Menyimpan..." : "Simpan Anggaran"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal: Gabung Grup dengan Kode */}
      {isJoiningGroup && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/45 backdrop-blur-md animate-fade-in">
          <div className="bg-[#FFFDF9]/95 backdrop-blur-2xl w-full max-w-md rounded-2xl p-6 border-3 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.95),8px_8px_0px_0px_#000] space-y-4">
            <h3 className="font-black text-lg text-black">Gabung ke Kas Event / Tim</h3>
            <p className="text-xs font-semibold text-slate-700">
              Masukkan 8 karakter kode undangan yang dibagikan oleh ketua atau bendahara panitia.
            </p>
            <form onSubmit={handleJoinGroup} className="space-y-4">
              <div>
                <label className="text-xs font-black text-black block mb-1">Kode Undangan</label>
                <input
                  type="text"
                  required
                  maxLength={8}
                  placeholder="Contoh: A1B2C3D4"
                  value={joinCode}
                  onChange={(e) => setJoinCode(e.target.value.toUpperCase())}
                  className="w-full font-mono text-center tracking-widest text-lg font-black bg-white border-2 border-black rounded-xl px-3 py-3 text-black shadow-[2px_2px_0px_0px_#000] outline-none uppercase"
                />
              </div>

              <div className="flex items-center justify-end gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setIsJoiningGroup(false)}
                  className="px-4 py-2 text-xs font-bold text-black bg-white hover:bg-slate-100 border-2 border-black rounded-xl shadow-[2px_2px_0px_0px_#000] transition-all"
                >
                  Batal
                </button>
                <button
                  type="submit"
                  disabled={isSubmittingJoin}
                  className="px-4 py-2 text-xs font-black bg-neo-yellow hover:bg-[#FDE047] disabled:opacity-50 text-black border-2 border-black rounded-xl shadow-[3px_3px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] transition-all"
                >
                  {isSubmittingJoin ? "Memproses..." : "Gabung Sekarang"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal: Ubah Nama & Info Kas Event */}
      {isEditingInfo && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/45 backdrop-blur-md animate-fade-in">
          <div className="bg-[#FFFDF9]/95 backdrop-blur-2xl w-full max-w-md rounded-2xl p-6 border-3 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.95),8px_8px_0px_0px_#000] space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="font-black text-lg text-black flex items-center gap-2">
                <Pencil className="w-5 h-5 text-black stroke-[2.5]" />
                <span>Edit Info Kas Event / Tim</span>
              </h3>
              <button onClick={() => setIsEditingInfo(false)} className="p-1 hover:bg-slate-200 rounded-lg">
                <X className="w-5 h-5 stroke-[2.5]" />
              </button>
            </div>

            <form onSubmit={handleSaveInfo} className="space-y-4">
              <div>
                <label className="text-xs font-black text-black block mb-1">
                  Nama Event / Tim
                </label>
                <input
                  type="text"
                  required
                  placeholder="Contoh: Panitia Wisuda 2026, Kas Event Kampus"
                  value={editNameInput}
                  onChange={(e) => setEditNameInput(e.target.value)}
                  className="w-full bg-white border-2 border-black rounded-xl px-3 py-2 text-sm font-bold text-black shadow-[2px_2px_0px_0px_#000] outline-none"
                  autoFocus
                />
              </div>

              <div>
                <label className="text-xs font-black text-black block mb-1">
                  Target Pagu Anggaran Kas (Rp) - Opsional
                </label>
                <div className="relative">
                  <span className="absolute left-3 top-1/2 -translate-y-1/2 font-black text-xs text-black">
                    Rp
                  </span>
                  <input
                    type="text"
                    inputMode="numeric"
                    placeholder="Contoh: 10.000.000"
                    value={
                      editBudgetInput && !isNaN(Number(editBudgetInput.replace(/[^\d]/g, "")))
                        ? Number(editBudgetInput.replace(/[^\d]/g, "")).toLocaleString("id-ID")
                        : ""
                    }
                    onChange={(e) => setEditBudgetInput(e.target.value.replace(/[^\d]/g, ""))}
                    className="w-full bg-white border-2 border-black rounded-xl pl-10 pr-3 py-2 text-sm font-bold text-black shadow-[2px_2px_0px_0px_#000] outline-none"
                  />
                </div>
              </div>

              <div>
                <label className="text-xs font-black text-black block mb-1">
                  Deskripsi / Keterangan Event (Opsional)
                </label>
                <textarea
                  placeholder="Tempat setoran nota belanja konsumsi, perlengkapan, dan reimburse tim."
                  value={editDescInput}
                  onChange={(e) => setEditDescInput(e.target.value)}
                  className="w-full bg-white border-2 border-black rounded-xl px-3 py-2 text-sm font-bold text-black shadow-[2px_2px_0px_0px_#000] outline-none h-20 resize-none"
                />
              </div>

              <div className="flex items-center justify-end gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setIsEditingInfo(false)}
                  className="px-4 py-2 text-xs font-bold text-black bg-white hover:bg-slate-100 border-2 border-black rounded-xl shadow-[2px_2px_0px_0px_#000] transition-all"
                >
                  Batal
                </button>
                <button
                  type="submit"
                  disabled={isSavingInfo}
                  className="px-4 py-2 text-xs font-black bg-neo-yellow hover:bg-[#FDE047] text-black border-2 border-black rounded-xl shadow-[3px_3px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] transition-all"
                >
                  {isSavingInfo ? "Menyimpan..." : "Simpan Perubahan"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
