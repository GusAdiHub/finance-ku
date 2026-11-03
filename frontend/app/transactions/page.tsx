"use client";

import React, { useState, useEffect, useCallback } from "react";
import { useAuth } from "@/lib/auth-context";
import { useModal } from "@/lib/modal-context";
import { api } from "@/lib/api";
import { Transaction, Category } from "@/lib/types";
import {
  formatRupiah,
  formatDate,
  parseReimburseStatus,
  encodeReimburseNotes,
} from "@/lib/utils";
import {
  Receipt,
  Search,
  Filter,
  TrendingUp,
  TrendingDown,
  Trash2,
  Plus,
  ChevronLeft,
  ChevronRight,
  AlertCircle,
  HandCoins,
  CheckCircle2,
  Clock,
  FolderKanban,
} from "lucide-react";

export default function TransactionsPage() {
  const { activeScope, selectedGroup, elderlyMode } = useAuth();
  const { openTransactionModal } = useModal();

  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  // Filters
  const [typeFilter, setTypeFilter] = useState<string>("");
  const [categoryFilter, setCategoryFilter] = useState<string>("");
  const [searchQuery, setSearchQuery] = useState<string>("");
  const [startDate, setStartDate] = useState<string>("");
  const [endDate, setEndDate] = useState<string>("");
  const [reimburseFilter, setReimburseFilter] = useState<"all" | "pending" | "settled">("all");
  const [page, setPage] = useState<number>(1);
  const [totalPages, setTotalPages] = useState<number>(1);
  const [totalCount, setTotalCount] = useState<number>(0);
  const [settlingTxId, setSettlingTxId] = useState<string | null>(null);

  const fetchCategories = async () => {
    try {
      const data = await api.getCategories();
      setCategories(data);
    } catch {
      // Ignored
    }
  };

  const fetchTransactions = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const params: Record<string, any> = {
        page,
        page_size: 15,
      };
      if (typeFilter) params.type = typeFilter;
      if (categoryFilter) params.category_id = categoryFilter;
      if (searchQuery) params.search = searchQuery;
      if (startDate) params.start_date = startDate;
      if (endDate) params.end_date = endDate;

      let res;
      if (activeScope === "personal") {
        res = await api.getTransactions(params);
      } else {
        if (!selectedGroup) {
          setTransactions([]);
          setIsLoading(false);
          return;
        }
        res = await api.getGroupTransactions(selectedGroup.id, params);
      }

      setTransactions(res.items || []);
      setTotalPages(res.total_pages || 1);
      setTotalCount(res.total || 0);
    } catch (err: any) {
      console.error("Fetch transactions error:", err);
      setError(err.message || "Gagal memuat daftar transaksi.");
    } finally {
      setIsLoading(false);
    }
  }, [activeScope, selectedGroup, page, typeFilter, categoryFilter, searchQuery, startDate, endDate]);

  useEffect(() => {
    fetchCategories();
  }, []);

  useEffect(() => {
    fetchTransactions();
  }, [fetchTransactions]);

  const handleSettleReimburse = async (tx: Transaction) => {
    if (!selectedGroup) return;
    const confirmSettle = confirm(
      `Tandai nota "${tx.description || "Talangan"}" sebesar ${formatRupiah(tx.amount)} sebagai SUDAH DIREIMBURSE?`
    );
    if (!confirmSettle) return;

    setSettlingTxId(tx.id);
    try {
      const settledNote = encodeReimburseNotes("settled", tx.notes);
      await api.updateGroupTransaction(selectedGroup.id, tx.id, { notes: settledNote });
      fetchTransactions();
    } catch (err: any) {
      alert(err.message || "Gagal mengubah status reimbursement.");
    } finally {
      setSettlingTxId(null);
    }
  };

  const handleDelete = async (txId: string) => {
    if (!confirm("Apakah Anda yakin ingin menghapus transaksi ini?")) return;
    try {
      if (activeScope === "personal") {
        await api.deleteTransaction(txId);
      } else if (selectedGroup) {
        // Use group transaction delete endpoint via fetch/api
        await fetch(`http://localhost:8000/api/v1/groups/${selectedGroup.id}/transactions/${txId}`, {
          method: "DELETE",
          headers: {
            Authorization: `Bearer ${localStorage.getItem("token")}`,
          },
        });
      }
      fetchTransactions();
    } catch (err: any) {
      alert(err.message || "Gagal menghapus transaksi.");
    }
  };

  const resetFilters = () => {
    setTypeFilter("");
    setCategoryFilter("");
    setSearchQuery("");
    setStartDate("");
    setEndDate("");
    setReimburseFilter("all");
    setPage(1);
  };

  const isGroupScope = activeScope === "family";
  const displayedTransactions = transactions.filter((tx) => {
    if (!isGroupScope || reimburseFilter === "all") return true;
    const r = parseReimburseStatus(tx.notes);
    if (reimburseFilter === "pending") return r.isPending;
    if (reimburseFilter === "settled") return r.isSettled;
    return true;
  });

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white/80 backdrop-blur-xl p-5 rounded-2xl border-2 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.9),4px_4px_0px_0px_#000]">
        <div>
          <h1 className={`font-black text-black tracking-tight ${elderlyMode ? "text-2xl" : "text-xl sm:text-2xl"}`}>
            {elderlyMode ? "Riwayat Uang Masuk & Keluar" : "Riwayat Transaksi & Nota"}
          </h1>
          <p className="text-xs sm:text-sm font-semibold text-slate-700 mt-0.5">
            {activeScope === "personal"
              ? "Buku Catatan Pribadi"
              : `Kas Event & Tim: ${selectedGroup?.name || "Event"}`}{" "}
            • Total {totalCount} transaksi
          </p>
        </div>

        <button
          onClick={() => openTransactionModal({ onSuccess: fetchTransactions })}
          className="bg-neo-yellow hover:bg-[#FDE047] active:translate-x-[2px] active:translate-y-[2px] active:shadow-[1px_1px_0px_0px_#000] text-black font-black text-xs sm:text-sm px-4 py-2.5 rounded-xl flex items-center justify-center gap-1.5 border-2 border-black shadow-[3px_3px_0px_0px_#000] transition-all"
        >
          <Plus className="w-4 h-4 stroke-[3]" />
          <span>{elderlyMode ? "Catat Uang Baru" : "Tambah Transaksi"}</span>
        </button>
      </div>

      {/* Filter Card */}
      <div className="bg-white/80 backdrop-blur-xl p-4 sm:p-5 rounded-2xl border-2 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.9),4px_4px_0px_0px_#000] space-y-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2 text-xs font-black text-black">
            <Filter className="w-4 h-4 text-black stroke-[2.5]" />
            <span>FILTER TRANSAKSI</span>
          </div>
          {(typeFilter || categoryFilter || searchQuery || startDate || endDate) && (
            <button
              onClick={resetFilters}
              className="text-xs text-black hover:text-rose-600 font-black underline underline-offset-4 decoration-2 transition-colors"
            >
              Reset Filter
            </button>
          )}
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
          {/* Search by description */}
          <div className="relative">
            <Search className="w-4 h-4 text-black absolute left-3 top-1/2 -translate-y-1/2 stroke-[2.5]" />
            <input
              type="text"
              placeholder="Cari deskripsi..."
              value={searchQuery}
              onChange={(e) => {
                setSearchQuery(e.target.value);
                setPage(1);
              }}
              className="w-full bg-white border-2 border-black rounded-xl pl-9 pr-3 py-2 text-xs sm:text-sm font-bold text-black placeholder-slate-500 shadow-[2px_2px_0px_0px_#000] outline-none"
            />
          </div>

          {/* Type Filter */}
          <select
            aria-label="Filter tipe transaksi"
            value={typeFilter}
            onChange={(e) => {
              setTypeFilter(e.target.value);
              setPage(1);
            }}
            className="w-full bg-white border-2 border-black rounded-xl px-3 py-2 text-xs sm:text-sm font-bold text-black shadow-[2px_2px_0px_0px_#000] outline-none"
          >
            <option value="">Semua Tipe</option>
            <option value="expense">Pengeluaran (-)</option>
            <option value="income">Pemasukan (+)</option>
          </select>

          {/* Category Filter */}
          <select
            aria-label="Filter kategori"
            value={categoryFilter}
            onChange={(e) => {
              setCategoryFilter(e.target.value);
              setPage(1);
            }}
            className="w-full bg-white border-2 border-black rounded-xl px-3 py-2 text-xs sm:text-sm font-bold text-black shadow-[2px_2px_0px_0px_#000] outline-none"
          >
            <option value="">Semua Kategori</option>
            {categories.map((cat) => (
              <option key={cat.id} value={cat.id}>
                {cat.name}
              </option>
            ))}
          </select>

          {/* Date range */}
          <div className="grid grid-cols-2 gap-1.5">
            <input
              type="date"
              aria-label="Mulai tanggal"
              value={startDate}
              onChange={(e) => {
                setStartDate(e.target.value);
                setPage(1);
              }}
              className="w-full bg-white border-2 border-black rounded-xl px-2 py-2 text-xs font-bold text-black shadow-[2px_2px_0px_0px_#000] outline-none"
            />
            <input
              type="date"
              aria-label="Sampai tanggal"
              value={endDate}
              onChange={(e) => {
                setEndDate(e.target.value);
                setPage(1);
              }}
              className="w-full bg-white border-2 border-black rounded-xl px-2 py-2 text-xs font-bold text-black shadow-[2px_2px_0px_0px_#000] outline-none"
            />
          </div>
        </div>

        {/* Reimbursement Filter Pills (Only visible in Kas Tim / Event scope) */}
        {isGroupScope && (
          <div className="flex items-center gap-2 pt-2 border-t border-black/20 flex-wrap">
            <span className="text-xs font-black text-black flex items-center gap-1">
              <HandCoins className="w-3.5 h-3.5 text-black stroke-[2.5]" />
              <span>Status Reimburse:</span>
            </span>
            <button
              onClick={() => setReimburseFilter("all")}
              className={`text-xs px-2.5 py-1 rounded-lg border-2 border-black font-black transition-all ${
                reimburseFilter === "all"
                  ? "bg-neo-yellow text-black shadow-[2px_2px_0px_0px_#000]"
                  : "bg-white text-black hover:bg-slate-100"
              }`}
            >
              Semua Transaksi
            </button>
            <button
              onClick={() => setReimburseFilter("pending")}
              className={`text-xs px-2.5 py-1 rounded-lg border-2 border-black font-bold transition-all ${
                reimburseFilter === "pending"
                  ? "bg-amber-400 text-black shadow-[2px_2px_0px_0px_#000]"
                  : "bg-white text-black hover:bg-amber-100"
              }`}
            >
              ⌛ Menunggu Reimburse
            </button>
            <button
              onClick={() => setReimburseFilter("settled")}
              className={`text-xs px-2.5 py-1 rounded-lg border-2 border-black font-bold transition-all ${
                reimburseFilter === "settled"
                  ? "bg-neo-green text-black shadow-[2px_2px_0px_0px_#000]"
                  : "bg-white text-black hover:bg-emerald-100"
              }`}
            >
              ✓ Sudah Direimburse
            </button>
          </div>
        )}
      </div>

      {/* Transaction List Card */}
      <div className="bg-white/80 backdrop-blur-xl p-5 rounded-2xl border-2 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.9),4px_4px_0px_0px_#000] space-y-4">
        {error && (
          <div className="p-3 bg-red-100 border-2 border-black text-red-950 font-bold text-xs rounded-xl flex items-center gap-2 shadow-[2px_2px_0px_0px_#000]">
            <AlertCircle className="w-4 h-4 stroke-[2.5]" />
            <span>{error}</span>
          </div>
        )}

        {isLoading ? (
          <div className="space-y-3 py-4 animate-pulse">
            {[1, 2, 3, 4, 5].map((i) => (
              <div key={i} className="h-16 bg-slate-200 border-2 border-black rounded-xl" />
            ))}
          </div>
        ) : displayedTransactions.length > 0 ? (
          <div className="divide-y-2 divide-slate-100">
            {displayedTransactions.map((tx) => {
              const isExpense = tx.type === "expense";
              const reimburse = parseReimburseStatus(tx.notes);
              return (
                <div key={tx.id} className="py-3.5 flex flex-col sm:flex-row sm:items-center justify-between gap-3 group">
                  <div className="flex items-center gap-3 min-w-0">
                    <div
                      className={`w-11 h-11 rounded-xl border-2 border-black shadow-[2px_2px_0px_0px_#000] flex items-center justify-center flex-shrink-0 ${
                        isExpense ? "bg-rose-100 text-rose-950" : "bg-emerald-100 text-emerald-950"
                      }`}
                    >
                      {isExpense ? <TrendingDown className="w-5 h-5 stroke-[2.5]" /> : <TrendingUp className="w-5 h-5 stroke-[2.5]" />}
                    </div>
                    <div className="min-w-0">
                      <div className="flex items-center gap-1.5 flex-wrap">
                        <p className={`font-black text-black truncate ${elderlyMode ? "text-base" : "text-sm"}`}>
                          {tx.category?.name || "Lain-lain"}
                        </p>
                        {reimburse.isPending && (
                          <span className="text-[10px] bg-amber-400 text-black font-black px-1.5 py-0.5 rounded border border-black shadow-[1px_1px_0px_0px_#000]">
                            PERLU REIMBURSE
                          </span>
                        )}
                        {reimburse.isSettled && (
                          <span className="text-[10px] bg-neo-green text-black font-black px-1.5 py-0.5 rounded border border-black shadow-[1px_1px_0px_0px_#000]">
                            DIREIMBURSE
                          </span>
                        )}
                        {tx.input_method === "ocr" && (
                          <span className="text-[10px] bg-neo-blue text-white font-black px-1.5 py-0.5 rounded border border-black">
                            STRUK
                          </span>
                        )}
                      </div>
                      <p className="text-xs font-semibold text-slate-600 truncate">
                        {tx.description || (isExpense ? "Pengeluaran" : "Pemasukan")} • {formatDate(tx.transaction_date)}
                      </p>
                      {reimburse.cleanNotes && (
                        <p className="text-[11px] text-slate-500 italic mt-0.5">
                          "{reimburse.cleanNotes}"
                        </p>
                      )}
                    </div>
                  </div>

                  <div className="flex items-center justify-between sm:justify-end gap-3 flex-shrink-0 pt-2 sm:pt-0 border-t sm:border-t-0 border-slate-100">
                    {/* Reimburse Settle Action Button */}
                    {isGroupScope && reimburse.isPending && (
                      <button
                        onClick={() => handleSettleReimburse(tx)}
                        disabled={settlingTxId === tx.id}
                        className="bg-neo-green hover:bg-emerald-400 text-black font-black text-xs px-2.5 py-1.5 rounded-xl border-2 border-black shadow-[2px_2px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] flex items-center gap-1 transition-all disabled:opacity-50"
                        title="Tandai nota ini sudah diganti/direimburse"
                      >
                        <CheckCircle2 className="w-3.5 h-3.5 stroke-[2.5]" />
                        <span>{settlingTxId === tx.id ? "..." : "Reimburse"}</span>
                      </button>
                    )}

                    <div className="text-right">
                      <p
                        className={`font-black ${
                          isExpense ? "text-rose-700" : "text-emerald-700"
                        } ${elderlyMode ? "text-lg" : "text-sm sm:text-base"}`}
                      >
                        {isExpense ? "-" : "+"}
                        {formatRupiah(tx.amount)}
                      </p>
                    </div>

                    <button
                      onClick={() => handleDelete(tx.id)}
                      title="Hapus transaksi"
                      className="p-2 text-black hover:text-rose-600 hover:bg-rose-100 border border-transparent hover:border-black rounded-xl transition-all"
                    >
                      <Trash2 className="w-4 h-4 stroke-[2.5]" />
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        ) : (
          <div className="text-center py-16 space-y-3">
            <div className="w-14 h-14 rounded-2xl bg-neo-yellow border-2 border-black text-black flex items-center justify-center mx-auto shadow-[3px_3px_0px_0px_#000]">
              <Receipt className="w-7 h-7 stroke-[2.5]" />
            </div>
            <p className="text-base font-black text-black">Tidak ada transaksi ditemukan</p>
            <p className="text-xs font-semibold text-slate-600">Coba ubah filter atau catat transaksi baru.</p>
          </div>
        )}

        {/* Pagination Bar */}
        {totalPages > 1 && (
          <div className="flex items-center justify-between pt-4 border-t-2 border-black text-xs font-black text-black">
            <span>
              Halaman {page} dari {totalPages}
            </span>
            <div className="flex items-center gap-1.5">
              <button
                disabled={page <= 1}
                onClick={() => setPage((p) => Math.max(p - 1, 1))}
                className="p-1.5 rounded-xl border-2 border-black text-black hover:bg-neo-yellow shadow-[2px_2px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] disabled:opacity-40 disabled:cursor-not-allowed transition-all"
              >
                <ChevronLeft className="w-4 h-4 stroke-[2.5]" />
              </button>
              <button
                disabled={page >= totalPages}
                onClick={() => setPage((p) => Math.min(p + 1, totalPages))}
                className="p-1.5 rounded-xl border-2 border-black text-black hover:bg-neo-yellow shadow-[2px_2px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] disabled:opacity-40 disabled:cursor-not-allowed transition-all"
              >
                <ChevronRight className="w-4 h-4 stroke-[2.5]" />
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
