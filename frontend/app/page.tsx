"use client";

import React, { useState, useEffect, useCallback } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/lib/auth-context";
import { useModal } from "@/lib/modal-context";
import { api } from "@/lib/api";
import { PersonalDashboard, GroupDashboard, Transaction } from "@/lib/types";
import {
  formatRupiah,
  formatDate,
  parseGroupBudget,
  cleanGroupDescription,
  encodeGroupDescription,
  parseReimburseStatus,
  encodeReimburseNotes,
} from "@/lib/utils";
import {
  TrendingUp,
  TrendingDown,
  Wallet,
  ArrowRight,
  Plus,
  ScanLine,
  Mic,
  Tag,
  Receipt,
  Keyboard,
  Sparkles,
  FolderKanban,
  HandCoins,
  CheckCircle2,
  Clock,
  Target,
  Pencil,
  AlertTriangle,
  X,
  Check,
} from "lucide-react";
import Link from "next/link";

export default function DashboardPage() {
  const router = useRouter();
  const {
    user,
    isAuthenticated,
    isLoading: authLoading,
    activeScope,
    selectedGroup,
    refreshGroups,
    elderlyMode,
  } = useAuth();
  const { openTransactionModal } = useModal();

  const [dashboardData, setDashboardData] = useState<PersonalDashboard | GroupDashboard | null>(null);
  const [groupTransactions, setGroupTransactions] = useState<Transaction[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  // Budget Edit Modal State
  const [isEditingBudget, setIsEditingBudget] = useState<boolean>(false);
  const [budgetInput, setBudgetInput] = useState<string>("");
  const [isSavingBudget, setIsSavingBudget] = useState<boolean>(false);

  // Reimburse processing state
  const [processingTxId, setProcessingTxId] = useState<string | null>(null);

  const fetchDashboard = useCallback(async () => {
    if (!isAuthenticated) return;
    setIsLoading(true);
    setError(null);
    try {
      if (activeScope === "personal") {
        const data = await api.getPersonalDashboard();
        setDashboardData(data);
        setGroupTransactions([]);
      } else {
        if (!selectedGroup) {
          setDashboardData(null);
          setGroupTransactions([]);
          setIsLoading(false);
          return;
        }
        const [dashRes, txRes] = await Promise.all([
          api.getGroupDashboard(selectedGroup.id),
          api.getGroupTransactions(selectedGroup.id, { page_size: 50 }).catch(() => ({ items: [] })),
        ]);
        setDashboardData(dashRes);
        setGroupTransactions(txRes.items || []);
      }
    } catch (err: any) {
      console.error("Dashboard fetch error:", err);
      setError(err.message || "Gagal memuat data dashboard.");
    } finally {
      setIsLoading(false);
    }
  }, [isAuthenticated, activeScope, selectedGroup]);

  useEffect(() => {
    if (!authLoading) {
      if (!isAuthenticated) {
        router.push("/login");
      } else {
        fetchDashboard();
      }
    }
  }, [authLoading, isAuthenticated, router, fetchDashboard]);

  // Listen to refresh events (e.g. after transaction created)
  useEffect(() => {
    const handleRefresh = () => fetchDashboard();
    window.addEventListener("refresh-data", handleRefresh);
    return () => window.removeEventListener("refresh-data", handleRefresh);
  }, [fetchDashboard]);

  // Settle reimbursement handler
  const handleSettleReimburse = async (tx: Transaction) => {
    if (!selectedGroup) return;
    const confirmSettle = confirm(
      `Tandai nota "${tx.description || "Talangan"}" sebesar ${formatRupiah(tx.amount)} sebagai SUDAH DIREIMBURSE?`
    );
    if (!confirmSettle) return;

    setProcessingTxId(tx.id);
    try {
      const settledNote = encodeReimburseNotes("settled", tx.notes);
      await api.updateGroupTransaction(selectedGroup.id, tx.id, { notes: settledNote });
      await fetchDashboard();
    } catch (err: any) {
      alert(err.message || "Gagal mengubah status reimbursement.");
    } finally {
      setProcessingTxId(null);
    }
  };

  // Save Event Budget Handler
  const handleSaveBudget = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedGroup) return;
    setIsSavingBudget(true);
    try {
      const parsedNum = parseFloat(budgetInput.replace(/[^\d]/g, "")) || 0;
      const cleanDesc = cleanGroupDescription(selectedGroup.description);
      const encodedDesc = encodeGroupDescription(cleanDesc, parsedNum > 0 ? parsedNum : null);
      await api.updateGroup(selectedGroup.id, { description: encodedDesc });
      await refreshGroups();
      await fetchDashboard();
      setIsEditingBudget(false);
    } catch (err: any) {
      alert(err.message || "Gagal memperbarui pagu anggaran event.");
    } finally {
      setIsSavingBudget(false);
    }
  };

  if (authLoading || (isLoading && !dashboardData)) {
    return (
      <div className="space-y-6 animate-pulse">
        <div className="h-28 bg-slate-200/70 rounded-3xl" />
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="h-32 bg-slate-200/70 rounded-3xl" />
          <div className="h-32 bg-slate-200/70 rounded-3xl" />
          <div className="h-32 bg-slate-200/70 rounded-3xl" />
        </div>
        <div className="h-64 bg-slate-200/70 rounded-3xl" />
      </div>
    );
  }

  const isFamily = activeScope === "family";
  const groupDashboard = isFamily ? (dashboardData as GroupDashboard) : null;

  // Event Budget Calculations
  const eventBudget = isFamily ? parseGroupBudget(selectedGroup?.description) : null;
  const totalExpense = dashboardData ? Number(dashboardData.total_expense) || 0 : 0;
  const sisaUangKasEvent = eventBudget !== null ? eventBudget - totalExpense : null;
  const budgetPercentUsed =
    eventBudget && eventBudget > 0 ? Math.min(Math.round((totalExpense / eventBudget) * 100), 100) : 0;

  // Reimbursement Calculations
  const pendingReimbursements = groupTransactions.filter(
    (tx) => parseReimburseStatus(tx.notes).isPending
  );
  const totalPendingReimburse = pendingReimbursements.reduce(
    (acc, curr) => acc + (Number(curr.amount) || 0),
    0
  );

  const settledReimbursements = groupTransactions.filter(
    (tx) => parseReimburseStatus(tx.notes).isSettled
  );
  const totalSettledReimburse = settledReimbursements.reduce(
    (acc, curr) => acc + (Number(curr.amount) || 0),
    0
  );

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Scope Notice Banner */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white/80 backdrop-blur-xl p-5 rounded-2xl border-2 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.9),4px_4px_0px_0px_#000]">
        <div>
          <div className="flex items-center gap-2">
            <span
              className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-lg text-xs font-black uppercase border-2 border-black shadow-[2px_2px_0px_0px_#000] ${
                isFamily ? "bg-neo-yellow text-black" : "bg-neo-yellow text-black"
              }`}
            >
              {isFamily ? (
                <FolderKanban className="w-3.5 h-3.5 stroke-[2.5] text-black" />
              ) : (
                <Wallet className="w-3.5 h-3.5 stroke-[2.5] text-black" />
              )}
              <span className="text-black">
                {isFamily ? `KAS EVENT / TIM: ${selectedGroup?.name || "Event"}` : "BUKU PRIBADI"}
              </span>
            </span>
          </div>
          <h1 className={`font-black text-black mt-2 tracking-tight ${elderlyMode ? "text-2xl" : "text-xl sm:text-2xl"}`}>
            {elderlyMode
              ? isFamily
                ? `Kas Tim & Event ${selectedGroup?.name || ""}`
                : `Keuangan Pribadi Anda`
              : isFamily
              ? `Manajemen Kas & Nota: ${selectedGroup?.name || "Tim / Event"}`
              : `Ringkasan Finansial Pribadi`}
          </h1>
          <p className="text-xs sm:text-sm font-medium text-slate-700 mt-0.5">
            {isFamily
              ? `Kelola anggaran kas event, kumpulkan bukti nota, dan pantau status reimbursement talangan anggota.`
              : `Halo ${user?.name}, berikut ringkasan pemasukan dan pengeluaran pribadi bulan ini.`}
          </p>
        </div>

        {/* Quick Add CTA */}
        <div className="flex items-center gap-2">
          <button
            onClick={() => openTransactionModal({ inputMethod: "ocr" })}
            className="bg-white hover:bg-slate-100 active:translate-x-[2px] active:translate-y-[2px] active:shadow-[1px_1px_0px_0px_#000] text-black font-black text-xs sm:text-sm px-3.5 py-2.5 rounded-xl flex items-center justify-center gap-1.5 border-2 border-black shadow-[3px_3px_0px_0px_#000] transition-all"
            title="Scan struk atau nota belanja"
          >
            <ScanLine className="w-4 h-4 stroke-[2.5] text-black" />
            <span className="hidden sm:inline text-black">Setor Nota (OCR)</span>
            <span className="sm:hidden text-black">Nota</span>
          </button>
          <button
            onClick={() => openTransactionModal({ inputMethod: "manual" })}
            className="bg-neo-yellow hover:bg-[#FDE047] active:translate-x-[2px] active:translate-y-[2px] active:shadow-[1px_1px_0px_0px_#000] text-black font-black text-xs sm:text-sm px-4 py-2.5 rounded-xl flex items-center justify-center gap-1.5 border-2 border-black shadow-[3px_3px_0px_0px_#000] transition-all"
          >
            <Plus className="w-4 h-4 stroke-[3] text-black" />
            <span className="text-black">{elderlyMode ? "Catat Uang" : "Catat Transaksi"}</span>
          </button>
        </div>
      </div>

      {/* No Group Selected Warning */}
      {isFamily && !selectedGroup && (
        <div className="p-6 bg-neo-yellowLight/90 backdrop-blur-xl border-2 border-black rounded-2xl text-black text-center space-y-3 shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.7),4px_4px_0px_0px_#000]">
          <p className="font-black text-base uppercase">Belum Ada Kas Grup / Event Terpilih</p>
          <p className="text-xs sm:text-sm font-medium text-slate-800 max-w-md mx-auto">
            Buat grup kas event baru atau masukkan kode undangan tim untuk mulai mengelola anggaran & nota bersama.
          </p>
          <Link
            href="/groups"
            className="inline-flex items-center gap-2 bg-neo-yellow text-black font-black text-xs sm:text-sm px-4 py-2 rounded-xl border-2 border-black shadow-[2px_2px_0px_0px_#000] hover:bg-[#FDE047] transition-all"
          >
            <FolderKanban className="w-4 h-4 stroke-[2.5]" />
            <span>Kelola Kas Tim & Event</span>
          </Link>
        </div>
      )}

      {/* KAS EVENT & LIVE BUDGET TRACKER CARD (Neo-Glassmorphism Hero) */}
      {isFamily && selectedGroup && (
        <div className="bg-[#FFFDF9]/90 backdrop-blur-2xl p-5 sm:p-6 rounded-2xl border-2 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.95),5px_5px_0px_0px_#000] space-y-5">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b-2 border-black pb-4">
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 rounded-xl bg-neo-yellow border-2 border-black flex items-center justify-center text-black shadow-[2px_2px_0px_0px_#000]">
                <Target className="w-6 h-6 stroke-[2.5]" />
              </div>
              <div>
                <div className="flex items-center gap-2">
                  <span className="text-[10px] font-black uppercase bg-black text-white px-2 py-0.5 rounded border border-black tracking-wider">
                    LIVE BUDGET TRACKER
                  </span>
                  <span className="text-xs font-bold text-slate-600">Event: {selectedGroup.name}</span>
                </div>
                <h2 className="text-base sm:text-lg font-black text-black">
                  Pagu Anggaran & Sisa Uang Kas Event
                </h2>
              </div>
            </div>

            <button
              onClick={() => {
                setBudgetInput(eventBudget ? String(eventBudget) : "");
                setIsEditingBudget(true);
              }}
              className="self-start sm:self-auto text-xs font-black bg-white hover:bg-slate-100 text-black px-3 py-2 rounded-xl border-2 border-black shadow-[2px_2px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] flex items-center gap-1.5 transition-all"
            >
              <Pencil className="w-3.5 h-3.5 stroke-[2.5]" />
              <span>{eventBudget ? "Ubah Pagu Anggaran" : "+ Tetapkan Pagu Anggaran"}</span>
            </button>
          </div>

          {/* Sisa Kas Event Main Stat */}
          {eventBudget !== null ? (
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
              {/* Sisa Kas Display */}
              <div
                className={`p-5 rounded-2xl border-2 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.8),3px_3px_0px_0px_#000] flex flex-col justify-between ${
                  (sisaUangKasEvent || 0) >= 0 ? "bg-neo-greenLight text-black" : "bg-rose-200 text-rose-950"
                }`}
              >
                <div>
                  <span className="text-xs font-bold uppercase tracking-wider text-black flex items-center gap-1.5">
                    <Wallet className="w-4 h-4 stroke-[2.5]" />
                    <span>Sisa Uang Kas Event</span>
                  </span>
                  <p className="text-2xl sm:text-3xl font-black tracking-tight text-black mt-2">
                    {formatRupiah(sisaUangKasEvent)}
                  </p>
                </div>
                <p className="text-xs font-semibold text-slate-800 mt-2">
                  {(sisaUangKasEvent || 0) >= 0
                    ? `Aman! Masih tersisa ${(100 - budgetPercentUsed).toFixed(0)}% dari pagu anggaran.`
                    : `Perhatian! Total nota terpakai melebihi pagu anggaran.`}
                </p>
              </div>

              {/* Progress & Detail */}
              <div className="lg:col-span-2 bg-white/90 p-5 rounded-2xl border-2 border-black shadow-[inset_0_1px_1px_rgba(255,255,255,0.9),3px_3px_0px_0px_#000] flex flex-col justify-between space-y-4">
                <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                  <div className="p-2.5 bg-slate-50 border-2 border-black rounded-xl">
                    <p className="text-[11px] font-bold text-slate-600">Pagu Anggaran</p>
                    <p className="text-sm sm:text-base font-black text-black">{formatRupiah(eventBudget)}</p>
                  </div>
                  <div className="p-2.5 bg-rose-50 border-2 border-black rounded-xl">
                    <p className="text-[11px] font-bold text-rose-700">Total Nota Terpakai</p>
                    <p className="text-sm sm:text-base font-black text-rose-900">{formatRupiah(totalExpense)}</p>
                  </div>
                  <div className="p-2.5 bg-amber-50 border-2 border-black rounded-xl col-span-2 sm:col-span-1">
                    <p className="text-[11px] font-bold text-amber-800">Menunggu Reimburse</p>
                    <p className="text-sm sm:text-base font-black text-amber-950">
                      {formatRupiah(totalPendingReimburse)}
                    </p>
                  </div>
                </div>

                {/* Chunky Brutalist Progress Bar */}
                <div className="space-y-1.5">
                  <div className="flex items-center justify-between text-xs font-black">
                    <span>Penggunaan Anggaran Event</span>
                    <span>{budgetPercentUsed}% Terpakai</span>
                  </div>
                  <div className="h-4 w-full bg-slate-100 border-2 border-black rounded-full overflow-hidden p-0.5">
                    <div
                      className={`h-full rounded-full transition-all border border-black ${
                        budgetPercentUsed > 90
                          ? "bg-rose-500"
                          : budgetPercentUsed > 70
                          ? "bg-amber-400"
                          : "bg-neo-green"
                      }`}
                      style={{ width: `${Math.min(budgetPercentUsed, 100)}%` }}
                    />
                  </div>
                </div>
              </div>
            </div>
          ) : (
            <div className="p-4 bg-neo-yellowLight border-2 border-black rounded-xl flex flex-col sm:flex-row items-center justify-between gap-3 text-center sm:text-left">
              <div>
                <p className="font-black text-sm text-black">Pagu Anggaran Event Belum Ditetapkan</p>
                <p className="text-xs font-semibold text-slate-700 mt-0.5">
                  Tetapkan batas anggaran event (misal: Rp 10.000.000) agar sistem otomatis menghitung sisa uang kas dan nota belanja.
                </p>
              </div>
              <button
                onClick={() => {
                  setBudgetInput("");
                  setIsEditingBudget(true);
                }}
                className="bg-neo-yellow hover:bg-[#FDE047] text-black font-black text-xs px-4 py-2 rounded-xl border-2 border-black shadow-[2px_2px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] transition-all whitespace-nowrap"
              >
                + Tetapkan Sekarang
              </button>
            </div>
          )}
        </div>
      )}

      {/* REIMBURSEMENT MANAGER CARD (Khusus Kas Tim & Event) */}
      {isFamily && selectedGroup && (
        <div className="bg-[#FFFDF9]/90 backdrop-blur-2xl p-5 sm:p-6 rounded-2xl border-2 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.95),5px_5px_0px_0px_#000] space-y-4">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 border-b-2 border-black pb-3">
            <div className="flex items-center gap-2.5">
              <div className="w-10 h-10 rounded-xl bg-amber-300 border-2 border-black flex items-center justify-center text-black shadow-[2px_2px_0px_0px_#000]">
                <HandCoins className="w-5 h-5 stroke-[2.5]" />
              </div>
              <div>
                <h3 className="font-black text-sm sm:text-base text-black flex items-center gap-2">
                  <span>Daftar Setoran Nota & Status Reimburse</span>
                  {pendingReimbursements.length > 0 && (
                    <span className="text-[10px] bg-amber-400 text-black px-2 py-0.5 rounded-full border-2 border-black font-black">
                      {pendingReimbursements.length} Perlu Reimburse
                    </span>
                  )}
                </h3>
                <p className="text-xs font-semibold text-slate-600">
                  Pantau bukti nota yang ditalangi anggota dan selesaikan penggantian uangnya secara transparan.
                </p>
              </div>
            </div>

            <div className="flex items-center gap-2 self-start sm:self-auto">
              <span className="text-xs font-black bg-white px-3 py-1.5 rounded-xl border-2 border-black shadow-[2px_2px_0px_0px_#000]">
                Total Perlu Reimburse:{" "}
                <span className="text-amber-700">{formatRupiah(totalPendingReimburse)}</span>
              </span>
            </div>
          </div>

          {/* Pending Reimbursement List */}
          {pendingReimbursements.length > 0 ? (
            <div className="space-y-3">
              <p className="text-xs font-black text-amber-950 uppercase tracking-wider">
                Nota Menunggu Penggantian Kas:
              </p>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                {pendingReimbursements.map((tx) => {
                  const reimburse = parseReimburseStatus(tx.notes);
                  return (
                    <div
                      key={tx.id}
                      className="bg-amber-50/90 backdrop-blur-md p-4 rounded-xl border-2 border-black shadow-[inset_0_1px_1px_rgba(255,255,255,0.9),3px_3px_0px_0px_#000] flex flex-col justify-between space-y-3"
                    >
                      <div className="flex items-start justify-between gap-2">
                        <div className="space-y-1 min-w-0">
                          <div className="flex items-center gap-1.5">
                            <span className="text-[10px] bg-amber-400 text-black font-black px-1.5 py-0.5 rounded border border-black flex items-center gap-1 shadow-[1px_1px_0px_0px_#000]">
                              <Clock className="w-3 h-3 stroke-[3]" /> PERLU REIMBURSE
                            </span>
                            {tx.input_method === "ocr" && (
                              <span className="text-[10px] bg-neo-yellow text-black font-black px-1.5 py-0.5 rounded border border-black">
                                NOTA OCR
                              </span>
                            )}
                          </div>
                          <p className="font-black text-black text-sm truncate">
                            {tx.description || tx.category?.name || "Nota Belanja"}
                          </p>
                          <p className="text-[11px] font-semibold text-slate-700">
                            {formatDate(tx.transaction_date)} • {tx.category?.name}
                          </p>
                          {reimburse.cleanNotes && (
                            <p className="text-[11px] italic text-slate-600 bg-white/70 p-1.5 rounded-lg border border-black/30">
                              "{reimburse.cleanNotes}"
                            </p>
                          )}
                        </div>

                        <div className="text-right flex-shrink-0">
                          <p className="text-base font-black text-rose-700">{formatRupiah(tx.amount)}</p>
                        </div>
                      </div>

                      {/* Action Button: Settle Reimbursement */}
                      <button
                        onClick={() => handleSettleReimburse(tx)}
                        disabled={processingTxId === tx.id}
                        className="w-full bg-neo-green hover:bg-emerald-400 text-black font-black text-xs py-2 px-3 rounded-xl border-2 border-black shadow-[2px_2px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] flex items-center justify-center gap-1.5 transition-all disabled:opacity-50"
                      >
                        <CheckCircle2 className="w-4 h-4 stroke-[2.5]" />
                        <span>
                          {processingTxId === tx.id ? "Memproses..." : "Tandai Sudah Direimburse"}
                        </span>
                      </button>
                    </div>
                  );
                })}
              </div>
            </div>
          ) : (
            <div className="p-4 bg-emerald-50 border-2 border-black rounded-xl text-center space-y-1">
              <p className="text-xs font-black text-emerald-950 flex items-center justify-center gap-1.5">
                <CheckCircle2 className="w-4 h-4 text-emerald-700 stroke-[2.5]" />
                <span>Tidak ada nota yang menunggu reimburse. Semua talangan beres!</span>
              </p>
              <p className="text-[11px] text-slate-600 font-medium">
                Jika ada anggota yang belanja pakai uang pribadi, unggah nota struk dan centang "Uang Talangan Pribadi".
              </p>
            </div>
          )}

          {/* Settled reimbursement summary counter */}
          {settledReimbursements.length > 0 && (
            <div className="pt-2 flex items-center justify-between text-xs font-bold text-slate-700 border-t border-black/20">
              <span className="flex items-center gap-1.5">
                <CheckCircle2 className="w-3.5 h-3.5 text-emerald-700 stroke-[2.5]" />
                <span>{settledReimbursements.length} nota telah sukses direimburse ke anggota</span>
              </span>
              <span className="font-black text-black">Total: {formatRupiah(totalSettledReimburse)}</span>
            </div>
          )}
        </div>
      )}

      {/* Summary Stat Cards */}
      {dashboardData && (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {/* Net Balance / Saldo Kas */}
          <div className="bg-neo-yellow/90 backdrop-blur-xl text-black p-5 rounded-2xl border-2 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.8),4px_4px_0px_0px_#000] flex flex-col justify-between">
            <div className="flex items-center justify-between">
              <span className="text-xs sm:text-sm font-bold uppercase tracking-wider text-black">
                {isFamily ? "Saldo Buku Kas" : elderlyMode ? "Sisa Uang Anda" : "Sisa Saldo Bersih"}
              </span>
              <div className="w-9 h-9 rounded-xl bg-white/90 backdrop-blur-md border-2 border-black flex items-center justify-center text-black shadow-[2px_2px_0px_0px_#000]">
                <Wallet className="w-5 h-5 stroke-[2.5]" />
              </div>
            </div>
            <div className="my-3">
              <p className={`font-black tracking-tight text-black ${elderlyMode ? "text-3xl" : "text-2xl sm:text-3xl"}`}>
                {formatRupiah(dashboardData.net_balance)}
              </p>
              <p className="text-[11px] font-semibold text-slate-800 mt-1">
                {isFamily ? "Kas fisik / rekening event" : "Selisih pemasukan dan pengeluaran"}
              </p>
            </div>
          </div>

          {/* Income / Iuran Kas */}
          <div className="bg-emerald-100/80 backdrop-blur-xl text-black p-5 rounded-2xl border-2 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.9),4px_4px_0px_0px_#000] flex flex-col justify-between">
            <div className="flex items-center justify-between">
              <span className="text-xs sm:text-sm font-bold uppercase tracking-wider text-emerald-950">
                {isFamily ? "Pemasukan / Iuran Kas" : elderlyMode ? "Total Uang Masuk" : "Total Pemasukan"}
              </span>
              <div className="w-9 h-9 rounded-xl bg-white/90 backdrop-blur-md border-2 border-black flex items-center justify-center text-emerald-800 shadow-[2px_2px_0px_0px_#000]">
                <TrendingUp className="w-5 h-5 stroke-[2.5]" />
              </div>
            </div>
            <div className="my-3">
              <p className={`font-black text-emerald-950 tracking-tight ${elderlyMode ? "text-3xl" : "text-2xl sm:text-3xl"}`}>
                {formatRupiah(dashboardData.total_income)}
              </p>
              <p className="text-[11px] font-semibold text-emerald-900 mt-1">Bulan berjalan</p>
            </div>
          </div>

          {/* Expense / Pengeluaran Nota */}
          <div className="bg-rose-100/80 backdrop-blur-xl text-black p-5 rounded-2xl border-2 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.9),4px_4px_0px_0px_#000] flex flex-col justify-between">
            <div className="flex items-center justify-between">
              <span className="text-xs sm:text-sm font-bold uppercase tracking-wider text-rose-950">
                {isFamily ? "Pengeluaran / Nota Belanja" : elderlyMode ? "Total Uang Keluar" : "Total Pengeluaran"}
              </span>
              <div className="w-9 h-9 rounded-xl bg-white/90 backdrop-blur-md border-2 border-black flex items-center justify-center text-rose-800 shadow-[2px_2px_0px_0px_#000]">
                <TrendingDown className="w-5 h-5 stroke-[2.5]" />
              </div>
            </div>
            <div className="my-3">
              <p className={`font-black text-rose-950 tracking-tight ${elderlyMode ? "text-3xl" : "text-2xl sm:text-3xl"}`}>
                {formatRupiah(dashboardData.total_expense)}
              </p>
              <p className="text-[11px] font-semibold text-rose-900 mt-1">Bulan berjalan</p>
            </div>
          </div>
        </div>
      )}

      {/* Quick Input Cards */}
      <div className="space-y-2">
        <h2 className="text-xs font-black text-black uppercase tracking-wider px-1">
          Pintasan Pencatatan Transaksi
        </h2>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
          <button
            onClick={() => openTransactionModal({ inputMethod: "manual" })}
            className="flex items-center gap-3 p-4 bg-white/80 backdrop-blur-md hover:bg-neo-yellowLight/90 border-2 border-black rounded-2xl shadow-[inset_0_1px_1px_rgba(255,255,255,0.9),3px_3px_0px_0px_#000] hover:translate-x-[-1px] hover:translate-y-[-1px] hover:shadow-[4.5px_4.5px_0px_0px_#000] active:translate-x-[2px] active:translate-y-[2px] active:shadow-[1px_1px_0px_0px_#000] transition-all text-left group"
          >
            <div className="w-11 h-11 rounded-xl bg-neo-yellow border-2 border-black text-black flex items-center justify-center shadow-[2px_2px_0px_0px_#000] flex-shrink-0">
              <Keyboard className="w-5 h-5 stroke-[2.5]" />
            </div>
            <div>
              <p className="font-black text-xs sm:text-sm text-black">Catat Manual</p>
              <p className="text-[11px] font-medium text-slate-600">Ketik nominal & keterangan</p>
            </div>
          </button>

          <button
            onClick={() => openTransactionModal({ inputMethod: "ocr" })}
            className="flex items-center gap-3 p-4 bg-white/80 backdrop-blur-md hover:bg-neo-blueLight/90 border-2 border-black rounded-2xl shadow-[inset_0_1px_1px_rgba(255,255,255,0.9),3px_3px_0px_0px_#000] hover:translate-x-[-1px] hover:translate-y-[-1px] hover:shadow-[4.5px_4.5px_0px_0px_#000] active:translate-x-[2px] active:translate-y-[2px] active:shadow-[1px_1px_0px_0px_#000] transition-all text-left group"
          >
            <div className="w-11 h-11 rounded-xl bg-neo-blue border-2 border-black text-white flex items-center justify-center shadow-[2px_2px_0px_0px_#000] flex-shrink-0">
              <ScanLine className="w-5 h-5 stroke-[2.5]" />
            </div>
            <div>
              <p className="font-black text-xs sm:text-sm text-black flex items-center gap-1.5">
                <span>Scan Struk / Nota</span>
                <span className="text-[9px] bg-neo-yellow text-black border border-black px-1.5 py-0.5 rounded-md font-black">
                  OCR
                </span>
              </p>
              <p className="text-[11px] font-medium text-slate-600">Foto & baca otomatis angka belanja</p>
            </div>
          </button>

          <button
            onClick={() => openTransactionModal({ inputMethod: "voice" })}
            className="flex items-center gap-3 p-4 bg-white/80 backdrop-blur-md hover:bg-purple-100/90 border-2 border-black rounded-2xl shadow-[inset_0_1px_1px_rgba(255,255,255,0.9),3px_3px_0px_0px_#000] hover:translate-x-[-1px] hover:translate-y-[-1px] hover:shadow-[4.5px_4.5px_0px_0px_#000] active:translate-x-[2px] active:translate-y-[2px] active:shadow-[1px_1px_0px_0px_#000] transition-all text-left group"
          >
            <div className="w-11 h-11 rounded-xl bg-neo-purple border-2 border-black text-black flex items-center justify-center shadow-[2px_2px_0px_0px_#000] flex-shrink-0">
              <Mic className="w-5 h-5 stroke-[2.5]" />
            </div>
            <div>
              <p className="font-black text-xs sm:text-sm text-black flex items-center gap-1.5">
                <span>Input Suara</span>
                <span className="text-[9px] bg-neo-green text-black border border-black px-1.5 py-0.5 rounded-md font-black">
                  MIC
                </span>
              </p>
              <p className="text-[11px] font-medium text-slate-600">Bahasa Indonesia</p>
            </div>
          </button>
        </div>
      </div>

      {/* Main Content Grid: Categories & Recent Transactions */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Column: Category Breakdown & Member Contributions */}
        <div className="space-y-6">
          {/* Category Breakdown */}
          <div className="bg-white/80 backdrop-blur-xl p-5 rounded-2xl border-2 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.9),4px_4px_0px_0px_#000] space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="font-black text-black text-sm sm:text-base flex items-center gap-2">
                <Tag className="w-4 h-4 text-black stroke-[2.5]" />
                <span>Pengeluaran per Kategori</span>
              </h3>
              <Link href="/reports" className="text-xs text-black hover:underline font-bold flex items-center gap-1">
                <span>Rincian</span>
                <ArrowRight className="w-3.5 h-3.5 stroke-[2.5]" />
              </Link>
            </div>

            {dashboardData?.expense_by_category && dashboardData.expense_by_category.length > 0 ? (
              <div className="space-y-3">
                {dashboardData.expense_by_category.slice(0, 5).map((cat) => (
                  <div key={cat.category_id} className="space-y-1">
                    <div className="flex items-center justify-between text-xs">
                      <span className="font-bold text-black">{cat.category_name}</span>
                      <span className="font-black text-black">{formatRupiah(cat.total_amount)}</span>
                    </div>
                    <div className="h-3 w-full bg-slate-100/80 border border-black rounded-full overflow-hidden">
                      <div
                        className="h-full bg-neo-yellow border-r border-black transition-all"
                        style={{ width: `${Math.min(cat.percentage, 100)}%` }}
                      />
                    </div>
                    <div className="text-[10px] font-bold text-slate-600 text-right">{cat.percentage.toFixed(1)}%</div>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-xs font-medium text-slate-500 text-center py-6">
                Belum ada data pengeluaran bulan ini.
              </p>
            )}
          </div>

          {/* Member Contributions (Group / Event scope only) */}
          {isFamily && groupDashboard?.member_contributions && (
            <div className="bg-white/80 backdrop-blur-xl p-5 rounded-2xl border-2 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.9),4px_4px_0px_0px_#000] space-y-4">
              <h3 className="font-black text-black text-sm sm:text-base flex items-center gap-2">
                <FolderKanban className="w-4 h-4 text-black stroke-[2.5]" />
                <span>Kontribusi Anggota Tim</span>
              </h3>

              <div className="space-y-2.5">
                {groupDashboard.member_contributions.map((m) => (
                  <div
                    key={m.user_id}
                    className="p-3 rounded-xl bg-slate-50/80 backdrop-blur-md border-2 border-black shadow-[2px_2px_0px_0px_#000] flex items-center justify-between text-xs"
                  >
                    <div>
                      <p className="font-bold text-black">{m.user_name}</p>
                      <p className="text-[10px] text-slate-500 font-medium">{m.transaction_count} transaksi</p>
                    </div>
                    <div className="text-right">
                      <p className="font-black text-rose-700">{formatRupiah(m.total_expense)}</p>
                      {parseFloat(String(m.total_income)) > 0 && (
                        <p className="text-[10px] font-bold text-emerald-700">+{formatRupiah(m.total_income)}</p>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Right Column: Recent Transactions with Reimburse Badges */}
        <div className="lg:col-span-2 bg-white/80 backdrop-blur-xl p-5 rounded-2xl border-2 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.9),4px_4px_0px_0px_#000] space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="font-black text-black text-sm sm:text-base flex items-center gap-2">
              <Receipt className="w-4 h-4 text-black stroke-[2.5]" />
              <span>{elderlyMode ? "Catatan Terbaru" : "Transaksi & Setoran Nota Terbaru"}</span>
            </h3>
            <Link
              href="/transactions"
              className="text-xs text-black hover:underline font-bold flex items-center gap-1"
            >
              <span>Lihat Semua</span>
              <ArrowRight className="w-3.5 h-3.5 stroke-[2.5]" />
            </Link>
          </div>

          {dashboardData?.recent_transactions && dashboardData.recent_transactions.length > 0 ? (
            <div className="divide-y-2 divide-slate-100">
              {dashboardData.recent_transactions.map((tx) => {
                const isExpense = tx.type === "expense";
                const reimburse = parseReimburseStatus(tx.notes);
                return (
                  <div key={tx.id} className="py-3 flex items-center justify-between gap-3 group">
                    <div className="flex items-center gap-3 min-w-0">
                      <div
                        className={`w-10 h-10 rounded-xl border-2 border-black shadow-[2px_2px_0px_0px_#000] flex items-center justify-center flex-shrink-0 ${
                          isExpense ? "bg-rose-100 text-rose-900" : "bg-emerald-100 text-emerald-900"
                        }`}
                      >
                        {isExpense ? (
                          <TrendingDown className="w-5 h-5 stroke-[2.5]" />
                        ) : (
                          <TrendingUp className="w-5 h-5 stroke-[2.5]" />
                        )}
                      </div>
                      <div className="min-w-0">
                        <div className="flex items-center gap-1.5 flex-wrap">
                          <p className={`font-black text-black truncate ${elderlyMode ? "text-base" : "text-xs sm:text-sm"}`}>
                            {tx.category?.name || "Lain-lain"}
                          </p>
                          {reimburse.isPending && (
                            <span className="text-[9px] bg-amber-400 text-black font-black px-1.5 py-0.5 rounded border border-black shadow-[1px_1px_0px_0px_#000]">
                              PERLU REIMBURSE
                            </span>
                          )}
                          {reimburse.isSettled && (
                            <span className="text-[9px] bg-neo-green text-black font-black px-1.5 py-0.5 rounded border border-black shadow-[1px_1px_0px_0px_#000]">
                              DIREIMBURSE
                            </span>
                          )}
                        </div>
                        <p className="text-[11px] font-medium text-slate-600 truncate">
                          {tx.description || (isExpense ? "Pengeluaran" : "Pemasukan")} • {formatDate(tx.transaction_date)}
                        </p>
                      </div>
                    </div>

                    <div className="text-right flex-shrink-0">
                      <p
                        className={`font-black ${
                          isExpense ? "text-rose-700" : "text-emerald-700"
                        } ${elderlyMode ? "text-lg" : "text-xs sm:text-sm"}`}
                      >
                        {isExpense ? "-" : "+"}
                        {formatRupiah(tx.amount)}
                      </p>
                      {tx.input_method && tx.input_method !== "manual" && (
                        <span className="inline-block text-[9px] px-1.5 py-0.5 rounded border border-black bg-neo-yellow text-black font-black uppercase shadow-[1px_1px_0px_0px_#000]">
                          {tx.input_method}
                        </span>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          ) : (
            <div className="text-center py-12 space-y-3">
              <div className="w-12 h-12 rounded-xl bg-slate-100 border-2 border-black shadow-[2px_2px_0px_0px_#000] text-black flex items-center justify-center mx-auto">
                <Receipt className="w-6 h-6 stroke-[2.5]" />
              </div>
              <p className="text-xs font-medium text-slate-600">Belum ada transaksi yang tercatat.</p>
              <button
                onClick={() => openTransactionModal()}
                className="text-xs font-black text-black bg-neo-yellow hover:bg-[#FDE047] border-2 border-black rounded-lg px-3 py-1.5 shadow-[2px_2px_0px_0px_#000] transition-all"
              >
                + Mulai Catat Transaksi
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Modal Atur Pagu Anggaran Event */}
      {isEditingBudget && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/45 backdrop-blur-md animate-fade-in">
          <div className="bg-[#FFFDF9]/95 backdrop-blur-2xl w-full max-w-md rounded-2xl p-6 border-3 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.95),8px_8px_0px_0px_#000] space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="font-black text-lg text-black flex items-center gap-2">
                <Target className="w-5 h-5 text-black stroke-[2.5]" />
                <span>Pagu Anggaran Event / Tim</span>
              </h3>
              <button
                onClick={() => setIsEditingBudget(false)}
                className="p-1 hover:bg-slate-200 rounded-lg text-black"
              >
                <X className="w-5 h-5 stroke-[2.5]" />
              </button>
            </div>

            <p className="text-xs font-medium text-slate-700">
              Tetapkan batas nominal uang kas untuk event <strong>{selectedGroup?.name}</strong>. Sisa uang kas akan dihitung langsung dari total pengeluaran nota.
            </p>

            <form onSubmit={handleSaveBudget} className="space-y-4">
              <div>
                <label className="text-xs font-black text-black block mb-1">
                  Target Pagu Anggaran (Rp):
                </label>
                <div className="relative">
                  <span className="absolute left-3.5 top-1/2 -translate-y-1/2 font-black text-sm text-black">
                    Rp
                  </span>
                  <input
                    type="text"
                    inputMode="numeric"
                    required
                    value={
                      budgetInput && !isNaN(Number(budgetInput.replace(/[^\d]/g, "")))
                        ? Number(budgetInput.replace(/[^\d]/g, "")).toLocaleString("id-ID")
                        : ""
                    }
                    onChange={(e) => setBudgetInput(e.target.value.replace(/[^\d]/g, ""))}
                    placeholder="Contoh: 10.000.000"
                    className="w-full bg-white border-2 border-black rounded-xl pl-11 pr-3 py-2.5 text-base font-black text-black shadow-[2px_2px_0px_0px_#000] outline-none"
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
                  className="px-4 py-2 text-xs font-black bg-neo-yellow hover:bg-[#FDE047] text-black border-2 border-black rounded-xl shadow-[3px_3px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] transition-all flex items-center gap-1.5"
                >
                  <Check className="w-4 h-4 stroke-[3]" />
                  <span>{isSavingBudget ? "Menyimpan..." : "Simpan Anggaran"}</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
