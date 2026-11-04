"use client";

import React, { useState, useEffect, useCallback } from "react";
import { useAuth } from "@/lib/auth-context";
import { useModal } from "@/lib/modal-context";
import { useToast } from "@/lib/toast-context";
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
  Eye,
  X,
  Loader2,
} from "lucide-react";

export default function TransactionsPage() {
  const { activeScope, selectedGroup } = useAuth();
  const { openTransactionModal } = useModal();
  const toast = useToast();

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
  const [reimburseFilter, setReimburseFilter] = useState<
    "all" | "pending" | "settled" | "has_receipt" | "no_receipt"
  >("all");
  const [page, setPage] = useState<number>(1);
  const [totalPages, setTotalPages] = useState<number>(1);
  const [totalCount, setTotalCount] = useState<number>(0);
  const [settlingTxId, setSettlingTxId] = useState<string | null>(null);

  // Receipt Preview Modal States
  const [viewingReceiptId, setViewingReceiptId] = useState<string | null>(null);
  const [receiptDetail, setReceiptDetail] = useState<any | null>(null);
  const [receiptImageUrl, setReceiptImageUrl] = useState<string | null>(null);
  const [receiptLoading, setReceiptLoading] = useState<boolean>(false);
  const [receiptError, setReceiptError] = useState<string | null>(null);

  const handleOpenReceipt = async (receiptId: string) => {
    setViewingReceiptId(receiptId);
    setReceiptLoading(true);
    setReceiptError(null);
    setReceiptDetail(null);
    if (receiptImageUrl) {
      URL.revokeObjectURL(receiptImageUrl);
      setReceiptImageUrl(null);
    }

    try {
      const [detail, imgUrl] = await Promise.allSettled([
        api.getReceipt(receiptId),
        api.getReceiptImageBlobUrl(receiptId),
      ]);

      if (detail.status === "fulfilled") {
        setReceiptDetail(detail.value);
      }
      if (imgUrl.status === "fulfilled") {
        setReceiptImageUrl(imgUrl.value);
      }
    } catch (err: any) {
      setReceiptError(err.message || "Gagal memuat data struk.");
    } finally {
      setReceiptLoading(false);
    }
  };

  const handleCloseReceipt = () => {
    setViewingReceiptId(null);
    setReceiptDetail(null);
    if (receiptImageUrl) {
      URL.revokeObjectURL(receiptImageUrl);
      setReceiptImageUrl(null);
    }
    setReceiptError(null);
  };

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
    const r = parseReimburseStatus(tx.notes);
    if (!r.canReimburse) {
      toast.error("Transaksi ini dicatat tanpa nota sehingga tidak bisa direimburse.", "Syarat Tidak Terpenuhi");
      return;
    }
    const confirmSettle = confirm(
      `Tandai nota "${tx.description || "Talangan"}" sebesar ${formatRupiah(tx.amount)} sebagai SUDAH DIREIMBURSE?`
    );
    if (!confirmSettle) return;

    setSettlingTxId(tx.id);
    try {
      const settledNote = encodeReimburseNotes("settled", tx.notes);
      await api.updateGroupTransaction(selectedGroup.id, tx.id, { notes: settledNote });
      toast.success(
        `Nota ${tx.description || "Talangan"} (${formatRupiah(tx.amount)}) berhasil direimburse!`,
        "Reimburse Selesai"
      );
      fetchTransactions();
      window.dispatchEvent(new CustomEvent("refresh-data"));
    } catch (err: any) {
      toast.error(err.message || "Gagal mengubah status reimbursement.", "Gagal");
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
        await api.deleteGroupTransaction(selectedGroup.id, txId);
      }
      toast.info("Transaksi berhasil dihapus.", "Terhapus");
      fetchTransactions();
      window.dispatchEvent(new CustomEvent("refresh-data"));
    } catch (err: any) {
      toast.error(err.message || "Gagal menghapus transaksi.", "Gagal");
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
    if (reimburseFilter === "has_receipt") return r.hasReceipt || tx.input_method === "ocr";
    if (reimburseFilter === "no_receipt") return r.noReceipt;
    return true;
  });

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white/80 backdrop-blur-xl p-5 rounded-2xl border-2 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.9),4px_4px_0px_0px_#000]">
        <div>
          <h1 className="font-black text-black tracking-tight text-xl sm:text-2xl">
            Riwayat Transaksi & Nota
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
          <span>Tambah Transaksi</span>
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

        {/* Reimbursement & Receipt Filter Pills (Only visible in Kas Tim / Event scope) */}
        {isGroupScope && (
          <div className="flex items-center gap-2 pt-2 border-t border-black/20 flex-wrap">
            <span className="text-xs font-black text-black flex items-center gap-1">
              <HandCoins className="w-3.5 h-3.5 text-black stroke-[2.5]" />
              <span>Status Nota & Reimburse:</span>
            </span>
            <button
              onClick={() => setReimburseFilter("all")}
              className={`text-xs px-2.5 py-1 rounded-lg border-2 border-black font-black transition-all ${
                reimburseFilter === "all"
                  ? "bg-neo-yellow text-black shadow-[2px_2px_0px_0px_#000]"
                  : "bg-white text-black hover:bg-slate-100"
              }`}
            >
              Semua
            </button>
            <button
              onClick={() => setReimburseFilter("has_receipt")}
              className={`text-xs px-2.5 py-1 rounded-lg border-2 border-black font-bold transition-all ${
                reimburseFilter === "has_receipt"
                  ? "bg-emerald-400 text-black shadow-[2px_2px_0px_0px_#000] font-black"
                  : "bg-white text-black hover:bg-emerald-50"
              }`}
            >
              🧾 Ada Nota
            </button>
            <button
              onClick={() => setReimburseFilter("no_receipt")}
              className={`text-xs px-2.5 py-1 rounded-lg border-2 border-black font-bold transition-all ${
                reimburseFilter === "no_receipt"
                  ? "bg-rose-400 text-black shadow-[2px_2px_0px_0px_#000] font-black"
                  : "bg-white text-black hover:bg-rose-50"
              }`}
            >
              🚫 Tanpa Nota
            </button>
            <button
              onClick={() => setReimburseFilter("pending")}
              className={`text-xs px-2.5 py-1 rounded-lg border-2 border-black font-bold transition-all ${
                reimburseFilter === "pending"
                  ? "bg-amber-400 text-black shadow-[2px_2px_0px_0px_#000] font-black"
                  : "bg-white text-black hover:bg-amber-100"
              }`}
            >
              ⌛ Menunggu Reimburse
            </button>
            <button
              onClick={() => setReimburseFilter("settled")}
              className={`text-xs px-2.5 py-1 rounded-lg border-2 border-black font-bold transition-all ${
                reimburseFilter === "settled"
                  ? "bg-neo-green text-black shadow-[2px_2px_0px_0px_#000] font-black"
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
                        <p className="font-black text-black truncate text-sm">
                          {tx.category?.name || "Lain-lain"}
                        </p>
                        {/* Status Nota Bukti Kas Event */}
                        {isGroupScope && isExpense && (
                          (reimburse.hasReceipt || tx.input_method === "ocr") ? (
                            <span className="text-[10px] bg-emerald-100 text-emerald-950 font-black px-1.5 py-0.5 rounded border border-black shadow-[1px_1px_0px_0px_#000]">
                              🧾 ADA NOTA
                            </span>
                          ) : reimburse.noReceipt ? (
                            <span className="text-[10px] bg-rose-100 text-rose-950 font-black px-1.5 py-0.5 rounded border border-black shadow-[1px_1px_0px_0px_#000]">
                              🚫 TANPA NOTA
                            </span>
                          ) : null
                        )}
                        {reimburse.isPending && (
                          <span className="text-[10px] bg-amber-400 text-black font-black px-1.5 py-0.5 rounded border border-black shadow-[1px_1px_0px_0px_#000]">
                            ⏳ PERLU REIMBURSE
                          </span>
                        )}
                        {reimburse.isSettled && (
                          <span className="text-[10px] bg-neo-green text-black font-black px-1.5 py-0.5 rounded border border-black shadow-[1px_1px_0px_0px_#000]">
                            ✓ DIREIMBURSE
                          </span>
                        )}
                        {isGroupScope && isExpense && reimburse.noReceipt && (
                          <span className="text-[10px] bg-slate-200 text-slate-800 font-bold px-1.5 py-0.5 rounded border border-slate-400">
                            TIDAK BISA REIMBURSE
                          </span>
                        )}
                        {tx.receipt_id ? (
                          <button
                            type="button"
                            onClick={() => handleOpenReceipt(tx.receipt_id!)}
                            className="text-[10px] bg-neo-blue hover:bg-blue-600 text-white font-black px-2 py-0.5 rounded-lg border border-black shadow-[1px_1px_0px_0px_#000] flex items-center gap-1 active:translate-x-[1px] active:translate-y-[1px] transition-all cursor-pointer"
                            title="Klik untuk melihat foto bukti struk / nota"
                          >
                            <Eye className="w-3 h-3 stroke-[2.5]" />
                            <span>Lihat Nota</span>
                          </button>
                        ) : tx.input_method === "ocr" ? (
                          <span className="text-[10px] bg-neo-blue text-white font-black px-1.5 py-0.5 rounded border border-black">
                            STRUK
                          </span>
                        ) : null}
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
                        className={`font-black text-sm sm:text-base ${
                          isExpense ? "text-rose-700" : "text-emerald-700"
                        }`}
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

      {/* Modal Preview Foto Struk / Nota */}
      {viewingReceiptId && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-fade-in">
          <div className="bg-white rounded-2xl border-3 border-black shadow-[6px_6px_0px_0px_#000] max-w-lg w-full max-h-[90vh] flex flex-col overflow-hidden">
            {/* Modal Header */}
            <div className="p-4 bg-neo-yellow border-b-2 border-black flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Receipt className="w-5 h-5 text-black stroke-[2.5]" />
                <h3 className="font-black text-black text-base">Foto Bukti Struk & Nota</h3>
              </div>
              <button
                onClick={handleCloseReceipt}
                className="p-1 rounded-lg border-2 border-black bg-white hover:bg-rose-100 text-black transition-all"
              >
                <X className="w-4 h-4 stroke-[3]" />
              </button>
            </div>

            {/* Modal Body */}
            <div className="p-4 overflow-y-auto space-y-4 flex-1">
              {receiptLoading ? (
                <div className="py-12 flex flex-col items-center justify-center gap-2 text-slate-600">
                  <Loader2 className="w-7 h-7 animate-spin text-black" />
                  <p className="text-xs font-bold">Memuat file struk...</p>
                </div>
              ) : receiptError ? (
                <div className="p-4 bg-rose-100 border-2 border-black text-rose-950 rounded-xl text-xs font-bold flex items-center gap-2">
                  <AlertCircle className="w-4 h-4 stroke-[2.5]" />
                  <span>{receiptError}</span>
                </div>
              ) : (
                <>
                  {/* Image Preview */}
                  {receiptImageUrl ? (
                    <div className="border-2 border-black rounded-xl overflow-hidden bg-slate-900 flex items-center justify-center max-h-[350px]">
                      <img
                        src={receiptImageUrl}
                        alt="Bukti Nota"
                        className="max-h-[350px] w-auto object-contain"
                      />
                    </div>
                  ) : (
                    <div className="p-6 bg-slate-100 border-2 border-black rounded-xl text-center text-xs font-bold text-slate-600">
                      File gambar struk tidak ditemukan pada server media.
                    </div>
                  )}

                  {/* Extracted Details */}
                  {receiptDetail && (
                    <div className="bg-slate-50 border-2 border-black rounded-xl p-3.5 space-y-2">
                      <div className="flex items-center justify-between text-xs">
                        <span className="font-bold text-slate-600">Merchant / Toko:</span>
                        <span className="font-black text-black">{receiptDetail.merchant_name || "-"}</span>
                      </div>
                      {receiptDetail.total_amount && (
                        <div className="flex items-center justify-between text-xs">
                          <span className="font-bold text-slate-600">Total Nominal:</span>
                          <span className="font-black text-emerald-800 bg-emerald-100 px-2 py-0.5 rounded border border-black">
                            {formatRupiah(receiptDetail.total_amount)}
                          </span>
                        </div>
                      )}
                      {receiptDetail.receipt_date && (
                        <div className="flex items-center justify-between text-xs">
                          <span className="font-bold text-slate-600">Tanggal Nota:</span>
                          <span className="font-bold text-black">{formatDate(receiptDetail.receipt_date)}</span>
                        </div>
                      )}

                      {/* Extracted items breakdown */}
                      {receiptDetail.items && receiptDetail.items.length > 0 && (
                        <div className="pt-2 border-t border-black/10">
                          <p className="text-[11px] font-black text-slate-700 mb-1.5">Item Belanja Terdeteksi:</p>
                          <div className="space-y-1 max-h-32 overflow-y-auto">
                            {receiptDetail.items.map((it: any, idx: number) => (
                              <div key={idx} className="flex items-center justify-between text-[11px] bg-white p-1.5 rounded border border-slate-200">
                                <span className="font-bold text-black truncate mr-2">{it.item_name}</span>
                                <span className="font-mono font-bold text-slate-700 flex-shrink-0">
                                  {it.quantity > 1 ? `${it.quantity}x ` : ""}{formatRupiah(it.total_price || it.price_per_unit)}
                                </span>
                              </div>
                            ))}
                          </div>
                        </div>
                      )}
                    </div>
                  )}
                </>
              )}
            </div>

            {/* Modal Footer */}
            <div className="p-3 bg-slate-50 border-t-2 border-black flex items-center justify-end">
              <button
                onClick={handleCloseReceipt}
                className="bg-white hover:bg-slate-100 text-black font-black text-xs px-4 py-2 rounded-xl border-2 border-black shadow-[2px_2px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px]"
              >
                Tutup
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
