"use client";

import React, { useState, useEffect, useCallback } from "react";
import { useAuth } from "@/lib/auth-context";
import { api } from "@/lib/api";
import { formatRupiah } from "@/lib/utils";
import {
  PieChart,
  Calendar,
  TrendingUp,
  TrendingDown,
  Wallet,
  ArrowUpRight,
  ArrowDownRight,
  AlertCircle,
} from "lucide-react";

export default function ReportsPage() {
  const { activeScope, selectedGroup, elderlyMode } = useAuth();
  const [period, setPeriod] = useState<string>("monthly");
  const [reportData, setReportData] = useState<any>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  const fetchReport = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      let data;
      if (activeScope === "personal") {
        data = await api.getPersonalReport(period);
      } else {
        if (!selectedGroup) {
          setReportData(null);
          setIsLoading(false);
          return;
        }
        data = await api.getGroupReport(selectedGroup.id, period);
      }
      setReportData(data);
    } catch (err: any) {
      console.error("Fetch report error:", err);
      setError(err.message || "Gagal memuat laporan finansial.");
    } finally {
      setIsLoading(false);
    }
  }, [activeScope, selectedGroup, period]);

  useEffect(() => {
    fetchReport();
  }, [fetchReport]);

  const totalIncome = parseFloat(reportData?.total_income || 0);
  const totalExpense = parseFloat(reportData?.total_expense || 0);
  const netBalance = parseFloat(reportData?.net_balance || 0);
  const savingsRate = totalIncome > 0 ? ((totalIncome - totalExpense) / totalIncome) * 100 : 0;

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white/80 backdrop-blur-xl p-5 rounded-2xl border-2 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.9),4px_4px_0px_0px_#000]">
        <div>
          <h1 className={`font-black text-black tracking-tight ${elderlyMode ? "text-2xl" : "text-xl sm:text-2xl"}`}>
            {elderlyMode ? "Laporan Uang Masuk & Keluar" : "Laporan & Analitik Finansial"}
          </h1>
          <p className="text-xs sm:text-sm font-semibold text-slate-700 mt-0.5">
            {activeScope === "personal" ? "Laporan Catatan Pribadi" : `Laporan Kas Event & Tim: ${selectedGroup?.name || "Event"}`}
          </p>
        </div>

        {/* Period Selector Tabs */}
        <div className="flex items-center bg-white/80 backdrop-blur-md p-1 rounded-xl border-2 border-black shadow-[2px_2px_0px_0px_#000]">
          <button
            onClick={() => setPeriod("weekly")}
            className={`py-1.5 px-3 rounded-lg text-xs sm:text-sm font-black transition-all ${
              period === "weekly"
                ? "bg-neo-yellow text-black border-2 border-black shadow-[1.5px_1.5px_0px_0px_#000]"
                : "text-black hover:bg-slate-100 border-2 border-transparent"
            }`}
          >
            Mingguan
          </button>
          <button
            onClick={() => setPeriod("monthly")}
            className={`py-1.5 px-3 rounded-lg text-xs sm:text-sm font-black transition-all ${
              period === "monthly"
                ? "bg-neo-yellow text-black border-2 border-black shadow-[1.5px_1.5px_0px_0px_#000]"
                : "text-black hover:bg-slate-100 border-2 border-transparent"
            }`}
          >
            Bulanan
          </button>
          <button
            onClick={() => setPeriod("yearly")}
            className={`py-1.5 px-3 rounded-lg text-xs sm:text-sm font-black transition-all ${
              period === "yearly"
                ? "bg-neo-yellow text-black border-2 border-black shadow-[1.5px_1.5px_0px_0px_#000]"
                : "text-black hover:bg-slate-100 border-2 border-transparent"
            }`}
          >
            Tahunan
          </button>
        </div>
      </div>

      {error && (
        <div className="p-4 bg-red-100 border-2 border-black text-red-950 font-bold text-xs sm:text-sm rounded-xl flex items-center gap-2 shadow-[2px_2px_0px_0px_#000]">
          <AlertCircle className="w-4 h-4 flex-shrink-0 stroke-[2.5]" />
          <span>{error}</span>
        </div>
      )}

      {isLoading ? (
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 animate-pulse">
          <div className="h-32 bg-slate-200 border-2 border-black rounded-2xl" />
          <div className="h-32 bg-slate-200 border-2 border-black rounded-2xl" />
          <div className="h-32 bg-slate-200 border-2 border-black rounded-2xl" />
          <div className="h-32 bg-slate-200 border-2 border-black rounded-2xl" />
        </div>
      ) : reportData ? (
        <>
          {/* Summary Metric Cards */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            <div className="bg-emerald-100/80 backdrop-blur-xl text-black p-5 rounded-2xl border-2 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.9),4px_4px_0px_0px_#000]">
              <div className="flex items-center justify-between text-black mb-2">
                <span className="text-xs font-black uppercase tracking-wider">Pemasukan</span>
                <div className="w-8 h-8 rounded-xl bg-white/90 backdrop-blur-md border-2 border-black text-emerald-800 flex items-center justify-center shadow-[1.5px_1.5px_0px_0px_#000]">
                  <TrendingUp className="w-4 h-4 stroke-[2.5]" />
                </div>
              </div>
              <p className="text-xl sm:text-2xl font-black text-emerald-950 tracking-tight">{formatRupiah(totalIncome)}</p>
              <p className="text-[11px] text-emerald-900 font-bold mt-1 flex items-center gap-0.5">
                <ArrowUpRight className="w-3.5 h-3.5 stroke-[2.5]" /> Total dana masuk
              </p>
            </div>

            <div className="bg-rose-100/80 backdrop-blur-xl text-black p-5 rounded-2xl border-2 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.9),4px_4px_0px_0px_#000]">
              <div className="flex items-center justify-between text-black mb-2">
                <span className="text-xs font-black uppercase tracking-wider">Pengeluaran</span>
                <div className="w-8 h-8 rounded-xl bg-white/90 backdrop-blur-md border-2 border-black text-rose-800 flex items-center justify-center shadow-[1.5px_1.5px_0px_0px_#000]">
                  <TrendingDown className="w-4 h-4 stroke-[2.5]" />
                </div>
              </div>
              <p className="text-xl sm:text-2xl font-black text-rose-950 tracking-tight">{formatRupiah(totalExpense)}</p>
              <p className="text-[11px] text-rose-900 font-bold mt-1 flex items-center gap-0.5">
                <ArrowDownRight className="w-3.5 h-3.5 stroke-[2.5]" /> Total dana keluar
              </p>
            </div>

            <div className="bg-neo-yellow/90 backdrop-blur-xl text-black p-5 rounded-2xl border-2 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.8),4px_4px_0px_0px_#000]">
              <div className="flex items-center justify-between text-black mb-2">
                <span className="text-xs font-black uppercase tracking-wider">Sisa Bersih</span>
                <div className="w-8 h-8 rounded-xl bg-white/90 backdrop-blur-md border-2 border-black text-black flex items-center justify-center shadow-[1.5px_1.5px_0px_0px_#000]">
                  <Wallet className="w-4 h-4 stroke-[2.5]" />
                </div>
              </div>
              <p className="text-xl sm:text-2xl font-black text-black tracking-tight">
                {formatRupiah(netBalance)}
              </p>
              <p className="text-[11px] text-slate-800 font-bold mt-1">Pemasukan - Pengeluaran</p>
            </div>

            <div className="bg-purple-100/80 backdrop-blur-xl text-black p-5 rounded-2xl border-2 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.9),4px_4px_0px_0px_#000]">
              <div className="flex items-center justify-between text-black mb-2">
                <span className="text-xs font-black uppercase tracking-wider">Rasio Tabungan</span>
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

          {/* Breakdown per Category */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Expense Breakdown */}
            <div className="bg-white/80 backdrop-blur-xl p-5 sm:p-6 rounded-2xl border-2 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.9),4px_4px_0px_0px_#000] space-y-4">
              <h3 className="font-black text-black text-base flex items-center gap-2">
                <TrendingDown className="w-5 h-5 text-rose-600 stroke-[2.5]" />
                <span>Rincian Pengeluaran per Kategori</span>
              </h3>

              {reportData.expense_by_category && reportData.expense_by_category.length > 0 ? (
                <div className="space-y-4">
                  {reportData.expense_by_category.map((cat: any) => (
                    <div key={cat.category_id} className="space-y-1.5">
                      <div className="flex items-center justify-between text-xs sm:text-sm">
                        <span className="font-bold text-black">{cat.category_name}</span>
                        <div className="text-right">
                          <span className="font-black text-black">{formatRupiah(cat.total_amount)}</span>
                          <span className="text-xs font-bold text-slate-600 ml-2">({cat.percentage.toFixed(1)}%)</span>
                        </div>
                      </div>
                      <div className="h-3 w-full bg-slate-100 border border-black rounded-full overflow-hidden">
                        <div
                          className="h-full bg-rose-500 border-r border-black"
                          style={{ width: `${Math.min(cat.percentage, 100)}%` }}
                        />
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-xs font-semibold text-slate-600 py-6 text-center">Belum ada pengeluaran pada periode ini.</p>
              )}
            </div>

            {/* Income Breakdown */}
            <div className="bg-white/80 backdrop-blur-xl p-5 sm:p-6 rounded-2xl border-2 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.9),4px_4px_0px_0px_#000] space-y-4">
              <h3 className="font-black text-black text-base flex items-center gap-2">
                <TrendingUp className="w-5 h-5 text-emerald-600 stroke-[2.5]" />
                <span>Rincian Pemasukan per Kategori</span>
              </h3>

              {reportData.income_by_category && reportData.income_by_category.length > 0 ? (
                <div className="space-y-4">
                  {reportData.income_by_category.map((cat: any) => (
                    <div key={cat.category_id} className="space-y-1.5">
                      <div className="flex items-center justify-between text-xs sm:text-sm">
                        <span className="font-bold text-black">{cat.category_name}</span>
                        <div className="text-right">
                          <span className="font-black text-black">{formatRupiah(cat.total_amount)}</span>
                          <span className="text-xs font-bold text-slate-600 ml-2">({cat.percentage.toFixed(1)}%)</span>
                        </div>
                      </div>
                      <div className="h-3 w-full bg-slate-100 border border-black rounded-full overflow-hidden">
                        <div
                          className="h-full bg-neo-green border-r border-black"
                          style={{ width: `${Math.min(cat.percentage, 100)}%` }}
                        />
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-xs font-semibold text-slate-600 py-6 text-center">Belum ada pemasukan pada periode ini.</p>
              )}
            </div>
          </div>
        </>
      ) : null}
    </div>
  );
}
