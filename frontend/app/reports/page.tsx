"use client";

import React, { useState, useEffect, useCallback, useMemo } from "react";
import { useAuth } from "@/lib/auth-context";
import { useToast } from "@/lib/toast-context";
import { api } from "@/lib/api";
import { formatRupiah, formatDate, formatDateTime, parseReimburseStatus } from "@/lib/utils";
import {
  PieChart,
  Calendar,
  TrendingUp,
  TrendingDown,
  Wallet,
  ArrowUpRight,
  ArrowDownRight,
  AlertCircle,
  ChevronLeft,
  ChevronRight,
  Receipt,
  Layers,
  Sparkles,
  Tag,
  Clock,
  HandCoins,
  Download,
  Printer,
} from "lucide-react";

type FilterMode = "month" | "date" | "range";

const INDO_MONTHS = [
  "Januari",
  "Februari",
  "Maret",
  "April",
  "Mei",
  "Juni",
  "Juli",
  "Agustus",
  "September",
  "Oktober",
  "November",
  "Desember",
];

function getTodayString(): string {
  const now = new Date();
  const y = now.getFullYear();
  const m = String(now.getMonth() + 1).padStart(2, "0");
  const d = String(now.getDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

function getCurrentMonthString(): string {
  const now = new Date();
  const y = now.getFullYear();
  const m = String(now.getMonth() + 1).padStart(2, "0");
  return `${y}-${m}`;
}

function formatMonthLabel(monthStr: string): string {
  try {
    const [y, m] = monthStr.split("-").map(Number);
    return `${INDO_MONTHS[m - 1] || ""} ${y}`;
  } catch {
    return monthStr;
  }
}

function formatFullDateLabel(dateStr: string): string {
  try {
    const [y, m, d] = dateStr.split("-").map(Number);
    const dt = new Date(y, m - 1, d);
    return new Intl.DateTimeFormat("id-ID", {
      weekday: "long",
      day: "numeric",
      month: "long",
      year: "numeric",
    }).format(dt);
  } catch {
    return dateStr;
  }
}

function shiftMonth(monthStr: string, delta: number): string {
  const [y, m] = monthStr.split("-").map(Number);
  const dt = new Date(y, m - 1 + delta, 1);
  const nextY = dt.getFullYear();
  const nextM = String(dt.getMonth() + 1).padStart(2, "0");
  return `${nextY}-${nextM}`;
}

function shiftDay(dateStr: string, delta: number): string {
  const [y, m, d] = dateStr.split("-").map(Number);
  const dt = new Date(y, m - 1, d + delta);
  const nextY = dt.getFullYear();
  const nextM = String(dt.getMonth() + 1).padStart(2, "0");
  const nextD = String(dt.getDate()).padStart(2, "0");
  return `${nextY}-${nextM}-${nextD}`;
}

export default function ReportsPage() {
  const { activeScope, selectedGroup } = useAuth();
  const toast = useToast();

  // Filter Modes: 'month' (Bulan Tertentu), 'date' (Tanggal Tertentu), 'range' (Rentang Tanggal)
  const [filterMode, setFilterMode] = useState<FilterMode>("month");
  const [selectedMonth, setSelectedMonth] = useState<string>(getCurrentMonthString());
  const [selectedDate, setSelectedDate] = useState<string>(getTodayString());
  const [rangeStart, setRangeStart] = useState<string>(() => {
    const today = getTodayString();
    return today.slice(0, 8) + "01";
  });
  const [rangeEnd, setRangeEnd] = useState<string>(getTodayString());

  // Report & Transaction Data State
  const [reportData, setReportData] = useState<any>(null);
  const [transactions, setTransactions] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  // Filter for detailed transaction list
  const [txTypeFilter, setTxTypeFilter] = useState<"all" | "expense" | "income">("expense");

  // Determine current active date range and human-readable label
  const activePeriodInfo = useMemo(() => {
    if (filterMode === "month") {
      const [y, m] = selectedMonth.split("-").map(Number);
      const start = new Date(y, m - 1, 1, 0, 0, 0, 0);
      const end = new Date(y, m, 0, 23, 59, 59, 999);
      return {
        start_date: start.toISOString(),
        end_date: end.toISOString(),
        period: "monthly",
        label: formatMonthLabel(selectedMonth),
        badgeText: `Laporan Bulan ${formatMonthLabel(selectedMonth)}`,
      };
    } else if (filterMode === "date") {
      const [y, m, d] = selectedDate.split("-").map(Number);
      const start = new Date(y, m - 1, d, 0, 0, 0, 0);
      const end = new Date(y, m - 1, d, 23, 59, 59, 999);
      return {
        start_date: start.toISOString(),
        end_date: end.toISOString(),
        period: "daily",
        label: formatFullDateLabel(selectedDate),
        badgeText: `Laporan Tanggal ${formatFullDateLabel(selectedDate)}`,
      };
    } else {
      const [sy, sm, sd] = rangeStart.split("-").map(Number);
      const [ey, em, ed] = rangeEnd.split("-").map(Number);
      const start = new Date(sy, sm - 1, sd, 0, 0, 0, 0);
      const end = new Date(ey, em - 1, ed, 23, 59, 59, 999);
      return {
        start_date: start.toISOString(),
        end_date: end.toISOString(),
        period: "custom",
        label: `${formatDate(rangeStart)} - ${formatDate(rangeEnd)}`,
        badgeText: `Laporan Rentang: ${formatDate(rangeStart)} s/d ${formatDate(rangeEnd)}`,
      };
    }
  }, [filterMode, selectedMonth, selectedDate, rangeStart, rangeEnd]);

  // Fetch report data & transactions concurrently
  const fetchReport = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const { start_date, end_date, period } = activePeriodInfo;
      let reportRes: any;
      let txRes: any;

      if (activeScope === "personal") {
        [reportRes, txRes] = await Promise.all([
          api.getPersonalReport({ start_date, end_date, period }),
          api.getTransactions({ start_date, end_date, page_size: 100 }),
        ]);
      } else {
        if (!selectedGroup) {
          setReportData(null);
          setTransactions([]);
          setIsLoading(false);
          return;
        }
        [reportRes, txRes] = await Promise.all([
          api.getGroupReport(selectedGroup.id, { start_date, end_date, period }),
          api.getGroupTransactions(selectedGroup.id, { start_date, end_date, page_size: 100 }),
        ]);
      }

      setReportData(reportRes);
      setTransactions(txRes?.items || []);
    } catch (err: any) {
      console.error("Fetch report error:", err);
      setError(err.message || "Gagal memuat laporan finansial.");
    } finally {
      setIsLoading(false);
    }
  }, [activeScope, selectedGroup, activePeriodInfo]);

  useEffect(() => {
    fetchReport();
  }, [fetchReport]);

  const totalIncome = parseFloat(reportData?.total_income || 0);
  const totalExpense = parseFloat(reportData?.total_expense || 0);
  const pendingReimbursement = parseFloat(reportData?.pending_reimbursement || 0);
  const netBalance = parseFloat(reportData?.net_savings ?? (totalIncome - totalExpense));
  const savingsRate = totalIncome > 0 ? ((totalIncome - totalExpense) / totalIncome) * 100 : 0;

  // Filtered transactions for the detail list
  const filteredTransactions = useMemo(() => {
    if (txTypeFilter === "all") return transactions;
    return transactions.filter((tx) => tx.type === txTypeFilter);
  }, [transactions, txTypeFilter]);

  const expenseCount = transactions.filter((t) => t.type === "expense").length;
  const incomeCount = transactions.filter((t) => t.type === "income").length;

  const handleExportCSV = () => {
    if (!transactions || transactions.length === 0) {
      toast.error("Tidak ada data transaksi untuk diekspor pada periode ini.", "Data Kosong");
      return;
    }

    const headers = [
      "Tanggal",
      "Tipe",
      "Kategori",
      "Deskripsi / Toko",
      "Nominal (Rp)",
      "Status Nota",
      "Status Reimburse",
      "Catatan",
    ];

    const rows = transactions.map((tx) => {
      const reimburse = parseReimburseStatus(tx.notes);
      const isExpense = tx.type === "expense";
      const statusNota = isExpense
        ? reimburse.hasReceipt || tx.input_method === "ocr"
          ? "Ada Bukti Nota"
          : reimburse.noReceipt
          ? "Tanpa Nota"
          : "Nota Umum"
        : "-";
      const statusReimburse = reimburse.isPending
        ? "Menunggu Reimburse"
        : reimburse.isSettled
        ? "Sudah Direimburse"
        : "-";

      return [
        `"${formatDate(tx.transaction_date)}"`,
        `"${isExpense ? "Pengeluaran" : "Pemasukan"}"`,
        `"${(tx.category?.name || "Lain-lain").replace(/"/g, '""')}"`,
        `"${(tx.description || "").replace(/"/g, '""')}"`,
        tx.amount,
        `"${statusNota}"`,
        `"${statusReimburse}"`,
        `"${(reimburse.cleanNotes || "").replace(/"/g, '""')}"`,
      ].join(",");
    });

    const csvContent = "﻿" + [headers.join(","), ...rows].join("\n");
    const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    const scopeLabel =
      activeScope === "personal"
        ? "pribadi"
        : `kas-${(selectedGroup?.name || "event").toLowerCase().replace(/[^a-z0-9]/g, "-")}`;
    const periodLabel =
      filterMode === "month"
        ? selectedMonth
        : filterMode === "date"
        ? selectedDate
        : `${customStartDate}_sd_${customEndDate}`;
    link.href = url;
    link.download = `laporan-sakuku-${scopeLabel}-${periodLabel}.csv`;
    link.click();
    URL.revokeObjectURL(url);
    toast.success("File spreadsheet laporan berhasil diunduh!", "Export Berhasil");
  };

  const handlePrint = () => {
    window.print();
  };

  return (
    <div className="space-y-6 animate-fade-in pb-10">
      {/* Header & Filter Controls Card */}
      <div className="bg-white/90 backdrop-blur-xl p-5 sm:p-6 rounded-2xl border-2 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.9),4px_4px_0px_0px_#000] space-y-4">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-3">
          <div>
            <div className="flex items-center gap-2">
              <span className="p-1.5 bg-neo-yellow border-2 border-black rounded-lg shadow-[1.5px_1.5px_0px_0px_#000]">
                <Calendar className="w-5 h-5 text-black stroke-[2.5]" />
              </span>
              <h1 className="font-black text-black tracking-tight text-xl sm:text-2xl">
                Laporan & Analitik Finansial
              </h1>
            </div>
            <p className="text-xs sm:text-sm font-semibold text-slate-700 mt-1">
              {activeScope === "personal"
                ? "Laporan Catatan Keuangan Pribadi"
                : `Laporan Kas Event & Tim: ${selectedGroup?.name || "Kas Bersama"}`}
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-2 self-start md:self-auto">
            {/* Mode Selector Tabs (Bulan / Tanggal / Rentang) */}
            <div className="flex items-center bg-slate-100 p-1 rounded-xl border-2 border-black shadow-[2px_2px_0px_0px_#000]">
              <button
                onClick={() => setFilterMode("month")}
                className={`py-1.5 px-3 rounded-lg text-xs sm:text-sm font-black transition-all flex items-center gap-1.5 ${
                  filterMode === "month"
                    ? "bg-neo-yellow text-black border-2 border-black shadow-[1.5px_1.5px_0px_0px_#000]"
                    : "text-black hover:bg-slate-200 border-2 border-transparent"
                }`}
              >
                <Calendar className="w-3.5 h-3.5 stroke-[2.5]" />
                <span>Bulan</span>
              </button>
              <button
                onClick={() => setFilterMode("date")}
                className={`py-1.5 px-3 rounded-lg text-xs sm:text-sm font-black transition-all flex items-center gap-1.5 ${
                  filterMode === "date"
                    ? "bg-neo-yellow text-black border-2 border-black shadow-[1.5px_1.5px_0px_0px_#000]"
                    : "text-black hover:bg-slate-200 border-2 border-transparent"
                }`}
              >
                <Clock className="w-3.5 h-3.5 stroke-[2.5]" />
                <span>Tanggal</span>
              </button>
              <button
                onClick={() => setFilterMode("range")}
                className={`py-1.5 px-3 rounded-lg text-xs sm:text-sm font-black transition-all flex items-center gap-1.5 ${
                  filterMode === "range"
                    ? "bg-neo-yellow text-black border-2 border-black shadow-[1.5px_1.5px_0px_0px_#000]"
                    : "text-black hover:bg-slate-200 border-2 border-transparent"
                }`}
              >
                <Layers className="w-3.5 h-3.5 stroke-[2.5]" />
                <span>Rentang</span>
              </button>
            </div>

            {/* Export & Print Action Buttons */}
            <div className="flex items-center gap-1.5">
              <button
                onClick={handleExportCSV}
                className="bg-emerald-300 hover:bg-emerald-400 text-black font-black text-xs px-3 py-2 rounded-xl border-2 border-black shadow-[2px_2px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] flex items-center gap-1.5 transition-all"
                title="Unduh data transaksi periode ini ke format spreadsheet CSV"
              >
                <Download className="w-3.5 h-3.5 stroke-[2.5]" />
                <span className="hidden sm:inline">Export CSV</span>
                <span className="sm:hidden">CSV</span>
              </button>
              <button
                onClick={handlePrint}
                className="bg-white hover:bg-slate-100 text-black font-black text-xs px-3 py-2 rounded-xl border-2 border-black shadow-[2px_2px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] flex items-center gap-1.5 transition-all"
                title="Cetak atau simpan laporan sebagai file PDF"
              >
                <Printer className="w-3.5 h-3.5 stroke-[2.5]" />
                <span className="hidden sm:inline">Cetak / PDF</span>
                <span className="sm:hidden">PDF</span>
              </button>
            </div>
          </div>
        </div>

        {/* Dynamic Interactive Filter Sub-Bar */}
        <div className="pt-3 border-t-2 border-black/10 flex flex-col md:flex-row md:items-center justify-between gap-3 bg-purple-50/70 p-3.5 rounded-xl border-2 border-black shadow-[2px_2px_0px_0px_#000]">
          {/* Sub-bar for MODE: MONTH */}
          {filterMode === "month" && (
            <div className="flex flex-wrap items-center gap-2 w-full justify-between">
              <div className="flex items-center gap-1.5">
                <button
                  type="button"
                  onClick={() => setSelectedMonth((m) => shiftMonth(m, -1))}
                  className="p-1.5 bg-white hover:bg-neo-yellow border-2 border-black rounded-lg shadow-[1.5px_1.5px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] transition-all"
                  title="Bulan sebelumnya"
                >
                  <ChevronLeft className="w-4 h-4 stroke-[2.5]" />
                </button>

                <div className="relative">
                  <input
                    type="month"
                    value={selectedMonth}
                    onChange={(e) => {
                      if (e.target.value) setSelectedMonth(e.target.value);
                    }}
                    className="bg-white border-2 border-black rounded-lg px-3 py-1 text-xs sm:text-sm font-black text-black shadow-[1.5px_1.5px_0px_0px_#000] cursor-pointer"
                  />
                </div>

                <button
                  type="button"
                  onClick={() => setSelectedMonth((m) => shiftMonth(m, 1))}
                  className="p-1.5 bg-white hover:bg-neo-yellow border-2 border-black rounded-lg shadow-[1.5px_1.5px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] transition-all"
                  title="Bulan berikutnya"
                >
                  <ChevronRight className="w-4 h-4 stroke-[2.5]" />
                </button>

                <span className="text-xs sm:text-sm font-black text-black ml-2 hidden sm:inline">
                  {formatMonthLabel(selectedMonth)}
                </span>
              </div>

              {/* Quick Presets for Month */}
              <div className="flex items-center gap-1.5">
                <button
                  type="button"
                  onClick={() => setSelectedMonth(getCurrentMonthString())}
                  className={`text-[11px] sm:text-xs font-black px-2.5 py-1 rounded-lg border-2 border-black transition-all ${
                    selectedMonth === getCurrentMonthString()
                      ? "bg-neo-green text-black shadow-[1.5px_1.5px_0px_0px_#000]"
                      : "bg-white text-black hover:bg-slate-100 shadow-[1px_1px_0px_0px_#000]"
                  }`}
                >
                  Bulan Ini
                </button>
                <button
                  type="button"
                  onClick={() => setSelectedMonth(shiftMonth(getCurrentMonthString(), -1))}
                  className="text-[11px] sm:text-xs font-black px-2.5 py-1 rounded-lg border-2 border-black bg-white hover:bg-slate-100 text-black shadow-[1px_1px_0px_0px_#000] transition-all"
                >
                  Bulan Lalu
                </button>
              </div>
            </div>
          )}

          {/* Sub-bar for MODE: DATE */}
          {filterMode === "date" && (
            <div className="flex flex-wrap items-center gap-2 w-full justify-between">
              <div className="flex items-center gap-1.5">
                <button
                  type="button"
                  onClick={() => setSelectedDate((d) => shiftDay(d, -1))}
                  className="p-1.5 bg-white hover:bg-neo-yellow border-2 border-black rounded-lg shadow-[1.5px_1.5px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] transition-all"
                  title="Hari sebelumnya"
                >
                  <ChevronLeft className="w-4 h-4 stroke-[2.5]" />
                </button>

                <div className="relative">
                  <input
                    type="date"
                    value={selectedDate}
                    onChange={(e) => {
                      if (e.target.value) setSelectedDate(e.target.value);
                    }}
                    className="bg-white border-2 border-black rounded-lg px-3 py-1 text-xs sm:text-sm font-black text-black shadow-[1.5px_1.5px_0px_0px_#000] cursor-pointer"
                  />
                </div>

                <button
                  type="button"
                  onClick={() => setSelectedDate((d) => shiftDay(d, 1))}
                  className="p-1.5 bg-white hover:bg-neo-yellow border-2 border-black rounded-lg shadow-[1.5px_1.5px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] transition-all"
                  title="Hari berikutnya"
                >
                  <ChevronRight className="w-4 h-4 stroke-[2.5]" />
                </button>

                <span className="text-xs sm:text-sm font-black text-black ml-2 hidden sm:inline">
                  {formatFullDateLabel(selectedDate)}
                </span>
              </div>

              {/* Quick Presets for Date */}
              <div className="flex items-center gap-1.5">
                <button
                  type="button"
                  onClick={() => setSelectedDate(getTodayString())}
                  className={`text-[11px] sm:text-xs font-black px-2.5 py-1 rounded-lg border-2 border-black transition-all ${
                    selectedDate === getTodayString()
                      ? "bg-neo-green text-black shadow-[1.5px_1.5px_0px_0px_#000]"
                      : "bg-white text-black hover:bg-slate-100 shadow-[1px_1px_0px_0px_#000]"
                  }`}
                >
                  Hari Ini
                </button>
                <button
                  type="button"
                  onClick={() => setSelectedDate(shiftDay(getTodayString(), -1))}
                  className="text-[11px] sm:text-xs font-black px-2.5 py-1 rounded-lg border-2 border-black bg-white hover:bg-slate-100 text-black shadow-[1px_1px_0px_0px_#000] transition-all"
                >
                  Kemarin
                </button>
              </div>
            </div>
          )}

          {/* Sub-bar for MODE: RANGE */}
          {filterMode === "range" && (
            <div className="flex flex-wrap items-center gap-2.5 w-full">
              <span className="text-xs font-bold text-slate-800">Dari:</span>
              <input
                type="date"
                value={rangeStart}
                onChange={(e) => setRangeStart(e.target.value)}
                className="bg-white border-2 border-black rounded-lg px-2.5 py-1 text-xs font-black text-black shadow-[1.5px_1.5px_0px_0px_#000]"
              />
              <span className="text-xs font-bold text-slate-800">Sampai:</span>
              <input
                type="date"
                value={rangeEnd}
                onChange={(e) => setRangeEnd(e.target.value)}
                className="bg-white border-2 border-black rounded-lg px-2.5 py-1 text-xs font-black text-black shadow-[1.5px_1.5px_0px_0px_#000]"
              />
              <button
                type="button"
                onClick={fetchReport}
                className="text-xs font-black bg-neo-yellow hover:bg-[#FDE047] text-black px-3 py-1 rounded-lg border-2 border-black shadow-[1.5px_1.5px_0px_0px_#000] transition-all ml-auto"
              >
                Terapkan
              </button>
            </div>
          )}
        </div>

        {/* Current Active Period Subtitle Pill */}
        <div className="flex items-center justify-between text-xs font-bold text-slate-800 pt-1">
          <div className="flex items-center gap-1.5">
            <span className="inline-block w-2.5 h-2.5 rounded-full bg-emerald-500 animate-pulse border border-black" />
            <span>Periode Aktif:</span>
            <span className="font-black text-black bg-white px-2 py-0.5 rounded-md border border-black shadow-[1px_1px_0px_0px_#000]">
              {activePeriodInfo.badgeText}
            </span>
          </div>
          <span className="text-[11px] text-slate-600 font-medium hidden sm:inline">
            Total {transactions.length} transaksi tercatat pada periode ini
          </span>
        </div>
      </div>

      {error && (
        <div className="p-4 bg-red-100 border-2 border-black text-red-950 font-bold text-xs sm:text-sm rounded-xl flex items-center gap-2 shadow-[2px_2px_0px_0px_#000]">
          <AlertCircle className="w-4 h-4 flex-shrink-0 stroke-[2.5]" />
          <span>{error}</span>
        </div>
      )}

      {isLoading ? (
        <div className="space-y-4 animate-pulse">
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            <div className="h-28 bg-slate-200 border-2 border-black rounded-2xl" />
            <div className="h-28 bg-slate-200 border-2 border-black rounded-2xl" />
            <div className="h-28 bg-slate-200 border-2 border-black rounded-2xl" />
            <div className="h-28 bg-slate-200 border-2 border-black rounded-2xl" />
          </div>
          <div className="h-64 bg-slate-200 border-2 border-black rounded-2xl" />
        </div>
      ) : reportData ? (
        <>
          {/* Summary Metric Cards */}
          <div className="space-y-4">
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
              {/* Pengeluaran Card (Fokus Utama) */}
              <div className="bg-rose-100/90 backdrop-blur-xl text-black p-5 rounded-2xl border-2 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.9),4px_4px_0px_0px_#000]">
                <div className="flex items-center justify-between text-black mb-2">
                  <span className="text-xs font-black uppercase tracking-wider text-rose-950">
                    {activeScope === "group" ? "Kas Terpakai / Belanja" : "Total Pengeluaran"}
                  </span>
                  <div className="w-8 h-8 rounded-xl bg-white/90 backdrop-blur-md border-2 border-black text-rose-800 flex items-center justify-center shadow-[1.5px_1.5px_0px_0px_#000]">
                    <TrendingDown className="w-4 h-4 stroke-[2.5]" />
                  </div>
                </div>
                <p className="text-xl sm:text-2xl font-black text-rose-950 tracking-tight">
                  {formatRupiah(totalExpense)}
                </p>
                <p className="text-[11px] text-rose-900 font-bold mt-1 flex items-center gap-0.5">
                  <ArrowDownRight className="w-3.5 h-3.5 stroke-[2.5]" /> {expenseCount} transaksi{" "}
                  {activeScope === "group" ? "(termasuk reimburse)" : "pengeluaran"}
                </p>
              </div>

              {/* Pemasukan Card */}
              <div className="bg-emerald-100/90 backdrop-blur-xl text-black p-5 rounded-2xl border-2 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.9),4px_4px_0px_0px_#000]">
                <div className="flex items-center justify-between text-black mb-2">
                  <span className="text-xs font-black uppercase tracking-wider text-emerald-950">
                    {activeScope === "group" ? "Pemasukan / Iuran Kas" : "Total Pemasukan"}
                  </span>
                  <div className="w-8 h-8 rounded-xl bg-white/90 backdrop-blur-md border-2 border-black text-emerald-800 flex items-center justify-center shadow-[1.5px_1.5px_0px_0px_#000]">
                    <TrendingUp className="w-4 h-4 stroke-[2.5]" />
                  </div>
                </div>
                <p className="text-xl sm:text-2xl font-black text-emerald-950 tracking-tight">
                  {formatRupiah(totalIncome)}
                </p>
                <p className="text-[11px] text-emerald-900 font-bold mt-1 flex items-center gap-0.5">
                  <ArrowUpRight className="w-3.5 h-3.5 stroke-[2.5]" /> {incomeCount} transaksi masuk
                </p>
              </div>

              {/* Sisa Bersih Card */}
              <div className="bg-neo-yellow/90 backdrop-blur-xl text-black p-5 rounded-2xl border-2 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.8),4px_4px_0px_0px_#000]">
                <div className="flex items-center justify-between text-black mb-2">
                  <span className="text-xs font-black uppercase tracking-wider">
                    {activeScope === "group" ? "Saldo Buku Kas" : "Sisa Bersih"}
                  </span>
                  <div className="w-8 h-8 rounded-xl bg-white/90 backdrop-blur-md border-2 border-black text-black flex items-center justify-center shadow-[1.5px_1.5px_0px_0px_#000]">
                    <Wallet className="w-5 h-5 stroke-[2.5]" />
                  </div>
                </div>
                <p className="text-xl sm:text-2xl font-black text-black tracking-tight">
                  {formatRupiah(netBalance)}
                </p>
                <p className="text-[11px] text-slate-800 font-bold mt-1">
                  {activeScope === "group" ? "Saldo kas fisik/rekening saat ini" : "Pemasukan - Pengeluaran"}
                </p>
              </div>

              {/* Rasio Tabungan / Status */}
              <div className="bg-purple-100/90 backdrop-blur-xl text-black p-5 rounded-2xl border-2 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.9),4px_4px_0px_0px_#000]">
                <div className="flex items-center justify-between text-black mb-2">
                  <span className="text-xs font-black uppercase tracking-wider text-purple-950">
                    {activeScope === "group" ? "Efisiensi Kas" : "Rasio Tabungan"}
                  </span>
                  <div className="w-8 h-8 rounded-xl bg-white/90 backdrop-blur-md border-2 border-black text-purple-900 flex items-center justify-center shadow-[1.5px_1.5px_0px_0px_#000]">
                    <PieChart className="w-4 h-4 stroke-[2.5]" />
                  </div>
                </div>
                <p className="text-xl sm:text-2xl font-black text-purple-950 tracking-tight">
                  {savingsRate.toFixed(1)}%
                </p>
                <p className="text-[11px] text-purple-900 font-bold mt-1">
                  {savingsRate >= 20 ? "Kondisi sangat sehat (>20%)" : "Perlu ditingkatkan"}
                </p>
              </div>
            </div>

            {/* Pending Reimbursement Alert in Reports for Kas Event */}
            {activeScope === "group" && pendingReimbursement > 0 && (
              <div className="bg-amber-100/90 backdrop-blur-xl p-4 rounded-2xl border-2 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.9),3px_3px_0px_0px_#000] flex flex-col sm:flex-row sm:items-center justify-between gap-3 animate-fade-in">
                <div className="flex items-center gap-3 min-w-0">
                  <div className="w-9 h-9 rounded-xl bg-amber-400 border-2 border-black flex items-center justify-center text-black font-black shadow-[1.5px_1.5px_0px_0px_#000] flex-shrink-0">
                    <HandCoins className="w-5 h-5 stroke-[2.5]" />
                  </div>
                  <div className="min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <p className="text-xs font-black uppercase text-amber-950">
                        Talangan Menunggu Reimburse Periode Ini:
                      </p>
                      <span className="text-xs font-black bg-amber-400 text-black px-2 py-0.5 rounded border border-black shadow-[1px_1px_0px_0px_#000]">
                        {formatRupiah(pendingReimbursement)}
                      </span>
                    </div>
                    <p className="text-[11px] font-semibold text-slate-700 mt-0.5">
                      Catatan: Pengeluaran talangan belum memotong Saldo Buku Kas maupun masuk ke Kas Terpakai sampai bendahara mereimburse nota tersebut.
                    </p>
                  </div>
                </div>
              </div>
            )}
          </div>

          {/* Breakdown per Category */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Expense Breakdown */}
            <div className="bg-white/90 backdrop-blur-xl p-5 sm:p-6 rounded-2xl border-2 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.9),4px_4px_0px_0px_#000] space-y-4">
              <div className="flex items-center justify-between">
                <h3 className="font-black text-black text-base flex items-center gap-2">
                  <TrendingDown className="w-5 h-5 text-rose-600 stroke-[2.5]" />
                  <span>Rincian Pengeluaran per Kategori</span>
                </h3>
                <span className="text-xs font-black text-rose-950 bg-rose-100 px-2 py-0.5 rounded-md border border-black">
                  {formatRupiah(totalExpense)}
                </span>
              </div>

              {reportData.expense_by_category && reportData.expense_by_category.length > 0 ? (
                <div className="space-y-3.5">
                  {reportData.expense_by_category.map((cat: any) => (
                    <div key={cat.category_id} className="space-y-1.5">
                      <div className="flex items-center justify-between text-xs sm:text-sm">
                        <span className="font-black text-black flex items-center gap-1.5">
                          <span className="w-2.5 h-2.5 rounded-full bg-rose-500 border border-black inline-block" />
                          <span>{cat.category_name}</span>
                          <span className="text-[11px] text-slate-500 font-bold">
                            ({cat.transaction_count}x)
                          </span>
                        </span>
                        <div className="text-right">
                          <span className="font-black text-black">{formatRupiah(cat.total_amount)}</span>
                          <span className="text-xs font-bold text-slate-600 ml-1.5">
                            ({cat.percentage.toFixed(1)}%)
                          </span>
                        </div>
                      </div>
                      <div className="h-3 w-full bg-slate-100 border border-black rounded-full overflow-hidden">
                        <div
                          className="h-full bg-rose-500 border-r border-black transition-all duration-500"
                          style={{ width: `${Math.min(cat.percentage, 100)}%` }}
                        />
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="py-8 text-center bg-slate-50 rounded-xl border border-dashed border-black/30">
                  <p className="text-xs font-bold text-slate-600">
                    Tidak ada pengeluaran yang tercatat pada {activePeriodInfo.badgeText.toLowerCase()}.
                  </p>
                </div>
              )}
            </div>

            {/* Income Breakdown */}
            <div className="bg-white/90 backdrop-blur-xl p-5 sm:p-6 rounded-2xl border-2 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.9),4px_4px_0px_0px_#000] space-y-4">
              <div className="flex items-center justify-between">
                <h3 className="font-black text-black text-base flex items-center gap-2">
                  <TrendingUp className="w-5 h-5 text-emerald-600 stroke-[2.5]" />
                  <span>Rincian Pemasukan per Kategori</span>
                </h3>
                <span className="text-xs font-black text-emerald-950 bg-emerald-100 px-2 py-0.5 rounded-md border border-black">
                  {formatRupiah(totalIncome)}
                </span>
              </div>

              {reportData.income_by_category && reportData.income_by_category.length > 0 ? (
                <div className="space-y-3.5">
                  {reportData.income_by_category.map((cat: any) => (
                    <div key={cat.category_id} className="space-y-1.5">
                      <div className="flex items-center justify-between text-xs sm:text-sm">
                        <span className="font-black text-black flex items-center gap-1.5">
                          <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 border border-black inline-block" />
                          <span>{cat.category_name}</span>
                          <span className="text-[11px] text-slate-500 font-bold">
                            ({cat.transaction_count}x)
                          </span>
                        </span>
                        <div className="text-right">
                          <span className="font-black text-black">{formatRupiah(cat.total_amount)}</span>
                          <span className="text-xs font-bold text-slate-600 ml-1.5">
                            ({cat.percentage.toFixed(1)}%)
                          </span>
                        </div>
                      </div>
                      <div className="h-3 w-full bg-slate-100 border border-black rounded-full overflow-hidden">
                        <div
                          className="h-full bg-neo-green border-r border-black transition-all duration-500"
                          style={{ width: `${Math.min(cat.percentage, 100)}%` }}
                        />
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="py-8 text-center bg-slate-50 rounded-xl border border-dashed border-black/30">
                  <p className="text-xs font-bold text-slate-600">
                    Tidak ada pemasukan yang tercatat pada {activePeriodInfo.badgeText.toLowerCase()}.
                  </p>
                </div>
              )}
            </div>
          </div>

          {/* Rincian Transaksi Pengeluaran & Pemasukan pada Periode Terpilih */}
          <div className="bg-white/90 backdrop-blur-xl p-5 sm:p-6 rounded-2xl border-2 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.9),4px_4px_0px_0px_#000] space-y-4">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
              <div>
                <h3 className="font-black text-black text-base flex items-center gap-2">
                  <Receipt className="w-5 h-5 text-black stroke-[2.5]" />
                  <span>Daftar Transaksi: {activePeriodInfo.label}</span>
                </h3>
                <p className="text-xs text-slate-600 font-medium mt-0.5">
                  Rincian transaksi yang terjadi pada periode laporan yang Anda pilih
                </p>
              </div>

              {/* Transaction Type Filter Tabs */}
              <div className="flex items-center bg-slate-100 p-1 rounded-xl border-2 border-black shadow-[1.5px_1.5px_0px_0px_#000] self-start sm:self-auto">
                <button
                  type="button"
                  onClick={() => setTxTypeFilter("expense")}
                  className={`py-1 px-2.5 rounded-lg text-xs font-black transition-all ${
                    txTypeFilter === "expense"
                      ? "bg-rose-500 text-white border border-black shadow-[1px_1px_0px_0px_#000]"
                      : "text-black hover:bg-slate-200"
                  }`}
                >
                  Pengeluaran ({expenseCount})
                </button>
                <button
                  type="button"
                  onClick={() => setTxTypeFilter("income")}
                  className={`py-1 px-2.5 rounded-lg text-xs font-black transition-all ${
                    txTypeFilter === "income"
                      ? "bg-emerald-600 text-white border border-black shadow-[1px_1px_0px_0px_#000]"
                      : "text-black hover:bg-slate-200"
                  }`}
                >
                  Pemasukan ({incomeCount})
                </button>
                <button
                  type="button"
                  onClick={() => setTxTypeFilter("all")}
                  className={`py-1 px-2.5 rounded-lg text-xs font-black transition-all ${
                    txTypeFilter === "all"
                      ? "bg-neo-yellow text-black border border-black shadow-[1px_1px_0px_0px_#000]"
                      : "text-black hover:bg-slate-200"
                  }`}
                >
                  Semua ({transactions.length})
                </button>
              </div>
            </div>

            {/* Transaction List */}
            {filteredTransactions.length > 0 ? (
              <div className="divide-y-2 divide-black/10">
                {filteredTransactions.map((tx: any) => {
                  const isExp = tx.type === "expense";
                  const reimburse = parseReimburseStatus(tx.notes);
                  return (
                    <div
                      key={tx.id}
                      className="py-3 flex items-center justify-between gap-3 hover:bg-slate-50 px-2 rounded-xl transition-colors"
                    >
                      <div className="flex items-center gap-3 min-w-0">
                        <div
                          className={`w-9 h-9 rounded-xl border-2 border-black flex items-center justify-center flex-shrink-0 shadow-[1.5px_1.5px_0px_0px_#000] ${
                            isExp ? "bg-rose-100 text-rose-700" : "bg-emerald-100 text-emerald-700"
                          }`}
                        >
                          {isExp ? (
                            <TrendingDown className="w-4 h-4 stroke-[2.5]" />
                          ) : (
                            <TrendingUp className="w-4 h-4 stroke-[2.5]" />
                          )}
                        </div>

                        <div className="min-w-0">
                          <div className="flex items-center gap-1.5 flex-wrap">
                            <p className="text-xs sm:text-sm font-black text-black truncate">
                              {tx.description || tx.category?.name || "Transaksi"}
                            </p>
                            {/* Badges for Kas Event */}
                            {activeScope === "family" && isExp && (
                              (reimburse.hasReceipt || tx.input_method === "ocr") ? (
                                <span className="text-[9px] bg-emerald-100 text-emerald-950 font-black px-1.5 py-0.2 rounded border border-black shadow-[1px_1px_0px_0px_#000]">
                                  🧾 ADA NOTA
                                </span>
                              ) : reimburse.noReceipt ? (
                                <span className="text-[9px] bg-rose-100 text-rose-950 font-black px-1.5 py-0.2 rounded border border-black shadow-[1px_1px_0px_0px_#000]">
                                  🚫 TANPA NOTA
                                </span>
                              ) : null
                            )}
                            {reimburse.isPending && (
                              <span className="text-[9px] bg-amber-400 text-black font-black px-1.5 py-0.2 rounded border border-black shadow-[1px_1px_0px_0px_#000]">
                                PERLU REIMBURSE
                              </span>
                            )}
                            {reimburse.isSettled && (
                              <span className="text-[9px] bg-neo-green text-black font-black px-1.5 py-0.2 rounded border border-black shadow-[1px_1px_0px_0px_#000]">
                                DIREIMBURSE
                              </span>
                            )}
                          </div>
                          <div className="flex flex-wrap items-center gap-1.5 mt-0.5 text-[11px] text-slate-600 font-bold">
                            <span className="bg-slate-100 px-1.5 py-0.5 rounded border border-black/40 text-black flex items-center gap-1">
                              <Tag className="w-3 h-3 stroke-[2]" />
                              <span>{tx.category?.name || "Umum"}</span>
                            </span>
                            <span>•</span>
                            <span>{formatDateTime(tx.transaction_date)}</span>
                            {reimburse.cleanNotes && (
                              <>
                                <span>•</span>
                                <span className="text-slate-500 truncate max-w-[140px] italic">
                                  "{reimburse.cleanNotes}"
                                </span>
                              </>
                            )}
                          </div>
                        </div>
                      </div>

                      <div className="text-right flex-shrink-0">
                        <span
                          className={`text-xs sm:text-sm font-black block tracking-tight ${
                            isExp ? "text-rose-600" : "text-emerald-700"
                          }`}
                        >
                          {isExp ? "-" : "+"} {formatRupiah(tx.amount)}
                        </span>
                        <span className="text-[10px] font-bold uppercase text-slate-500">
                          {isExp ? "Keluar" : "Masuk"}
                        </span>
                      </div>
                    </div>
                  );
                })}
              </div>
            ) : (
              <div className="py-10 text-center bg-slate-50 rounded-xl border-2 border-dashed border-black/20 space-y-2">
                <Receipt className="w-8 h-8 mx-auto text-slate-400 stroke-[1.5]" />
                <p className="text-xs sm:text-sm font-black text-slate-700">
                  {txTypeFilter === "expense"
                    ? "Tidak ada pengeluaran yang tercatat pada periode ini."
                    : txTypeFilter === "income"
                    ? "Tidak ada pemasukan yang tercatat pada periode ini."
                    : "Belum ada transaksi pada periode ini."}
                </p>
                <p className="text-[11px] text-slate-500 font-medium">
                  Gunakan tombol &ldquo;+ Catat&rdquo; di atas untuk menambahkan transaksi baru.
                </p>
              </div>
            )}
          </div>
        </>
      ) : null}
    </div>
  );
}
