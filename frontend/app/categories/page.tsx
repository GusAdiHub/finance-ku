"use client";

import React, { useState, useEffect } from "react";
import { api } from "@/lib/api";
import { Category } from "@/lib/types";
import { Tag, Plus, Trash2, Lock, AlertCircle, Check } from "lucide-react";

export default function CategoriesPage() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [typeFilter, setTypeFilter] = useState<"expense" | "income">("expense");
  const [isLoading, setIsLoading] = useState<boolean>(true);

  // Add Category Modal
  const [isAdding, setIsAdding] = useState<boolean>(false);
  const [newName, setNewName] = useState<string>("");
  const [newType, setNewType] = useState<"expense" | "income">("expense");
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const [message, setMessage] = useState<{ text: string; isError: boolean } | null>(null);

  const fetchCategories = async () => {
    setIsLoading(true);
    try {
      const data = await api.getCategories();
      setCategories(data);
    } catch (err: any) {
      console.error("Fetch categories error:", err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchCategories();
  }, []);

  const handleAddCategory = async (e: React.FormEvent) => {
    e.preventDefault();
    setMessage(null);
    setIsSubmitting(true);
    try {
      await api.createCategory({
        name: newName.trim(),
        type: newType,
      });
      setIsAdding(false);
      setNewName("");
      setMessage({ text: "Kategori baru berhasil ditambahkan!", isError: false });
      fetchCategories();
    } catch (err: any) {
      setMessage({ text: err.message || "Gagal membuat kategori.", isError: true });
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDeleteCategory = async (cat: Category) => {
    if (cat.is_system) {
      alert("Kategori bawaan sistem tidak dapat dihapus.");
      return;
    }
    if (!confirm(`Hapus kategori "${cat.name}"?`)) return;

    try {
      await api.deleteCategory(cat.id);
      setMessage({ text: "Kategori berhasil dihapus.", isError: false });
      fetchCategories();
    } catch (err: any) {
      setMessage({ text: err.message || "Gagal menghapus kategori.", isError: true });
    }
  };

  const filteredCategories = categories.filter((c) => c.type === typeFilter);

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white/80 backdrop-blur-xl p-5 rounded-2xl border-2 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.9),4px_4px_0px_0px_#000]">
        <div>
          <h1 className="font-black text-black tracking-tight text-xl sm:text-2xl">
            Kelola Kategori Transaksi
          </h1>
          <p className="text-xs sm:text-sm font-semibold text-slate-700 mt-0.5">
            Daftar kategori standar dan kustom untuk pengelompokan pemasukan & pengeluaran.
          </p>
        </div>

        <button
          onClick={() => {
            setIsAdding(true);
            setMessage(null);
          }}
          className="bg-neo-yellow hover:bg-[#FDE047] active:translate-x-[2px] active:translate-y-[2px] active:shadow-[1px_1px_0px_0px_#000] text-black font-black text-xs sm:text-sm px-4 py-2.5 rounded-xl flex items-center justify-center gap-1.5 border-2 border-black shadow-[3px_3px_0px_0px_#000] transition-all"
        >
          <Plus className="w-4 h-4 stroke-[3]" />
          <span>Tambah Kategori</span>
        </button>
      </div>

      {message && (
        <div
          className={`p-3.5 rounded-xl flex items-center justify-between text-xs sm:text-sm font-bold border-2 border-black shadow-[2px_2px_0px_0px_#000] ${
            message.isError
              ? "bg-red-100 text-red-950"
              : "bg-neo-greenLight text-black"
          }`}
        >
          <span>{message.text}</span>
          <button onClick={() => setMessage(null)} className="font-black hover:opacity-75">✕</button>
        </div>
      )}

      {/* Tabs */}
      <div className="flex items-center gap-2">
        <button
          onClick={() => setTypeFilter("expense")}
          className={`py-2 px-4 rounded-xl text-xs sm:text-sm font-black transition-all border-2 border-black shadow-[2px_2px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] ${
            typeFilter === "expense"
              ? "bg-rose-400 text-black font-black"
              : "bg-white text-black hover:bg-slate-100"
          }`}
        >
          Kategori Pengeluaran (-)
        </button>
        <button
          onClick={() => setTypeFilter("income")}
          className={`py-2 px-4 rounded-xl text-xs sm:text-sm font-black transition-all border-2 border-black shadow-[2px_2px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] ${
            typeFilter === "income"
              ? "bg-neo-green text-black"
              : "bg-white text-black hover:bg-slate-100"
          }`}
        >
          Kategori Pemasukan (+)
        </button>
      </div>

      {/* Categories Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
        {isLoading ? (
          [1, 2, 3, 4, 5, 6].map((i) => (
            <div key={i} className="h-16 bg-slate-200 border-2 border-black rounded-xl animate-pulse" />
          ))
        ) : filteredCategories.length > 0 ? (
          filteredCategories.map((cat) => (
            <div
              key={cat.id}
              className="bg-white/80 backdrop-blur-xl p-4 rounded-2xl border-2 border-black shadow-[inset_0_1px_1px_rgba(255,255,255,0.9),3px_3px_0px_0px_#000] flex items-center justify-between hover:translate-x-[-1px] hover:translate-y-[-1px] hover:shadow-[4.5px_4.5px_0px_0px_#000] transition-all"
            >
              <div className="flex items-center gap-3">
                <div
                  className={`w-10 h-10 rounded-xl border-2 border-black shadow-[1.5px_1.5px_0px_0px_#000] flex items-center justify-center font-bold text-sm ${
                    cat.type === "expense" ? "bg-rose-100 text-rose-950" : "bg-emerald-100 text-emerald-950"
                  }`}
                >
                  <Tag className="w-4 h-4 stroke-[2.5]" />
                </div>
                <div>
                  <p className="font-black text-black text-sm">{cat.name}</p>
                  <p className="text-[11px] font-semibold text-slate-600">
                    {cat.is_system ? "Bawaan Sistem" : "Kategori Khusus Anda"}
                  </p>
                </div>
              </div>

              {cat.is_system ? (
                <span title="Kategori sistem tidak bisa dihapus" className="text-slate-400 p-1.5">
                  <Lock className="w-4 h-4 stroke-[2.5]" />
                </span>
              ) : (
                <button
                  onClick={() => handleDeleteCategory(cat)}
                  title="Hapus kategori"
                  className="p-1.5 text-black hover:text-rose-600 hover:bg-rose-100 border border-transparent hover:border-black rounded-lg transition-colors"
                >
                  <Trash2 className="w-4 h-4 stroke-[2.5]" />
                </button>
              )}
            </div>
          ))
        ) : (
          <p className="text-xs font-semibold text-slate-600 col-span-3 text-center py-12">Tidak ada kategori ditemukan.</p>
        )}
      </div>

      {/* Modal Add Category */}
      {isAdding && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/45 backdrop-blur-md animate-fade-in">
          <div className="bg-[#FFFDF9]/95 backdrop-blur-2xl w-full max-w-md rounded-2xl p-6 border-3 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.95),8px_8px_0px_0px_#000] space-y-4">
            <h3 className="font-black text-lg text-black">Tambah Kategori Baru</h3>
            <form onSubmit={handleAddCategory} className="space-y-4">
              <div>
                <label className="text-xs font-black text-black block mb-1">Tipe</label>
                <div className="grid grid-cols-2 gap-2">
                  <button
                    type="button"
                    onClick={() => setNewType("expense")}
                    className={`py-2 rounded-xl text-xs font-black border-2 border-black shadow-[2px_2px_0px_0px_#000] transition-all ${
                      newType === "expense"
                        ? "bg-rose-500 text-white"
                        : "bg-white text-black hover:bg-slate-100"
                    }`}
                  >
                    Pengeluaran
                  </button>
                  <button
                    type="button"
                    onClick={() => setNewType("income")}
                    className={`py-2 rounded-xl text-xs font-black border-2 border-black shadow-[2px_2px_0px_0px_#000] transition-all ${
                      newType === "income"
                        ? "bg-neo-green text-black"
                        : "bg-white text-black hover:bg-slate-100"
                    }`}
                  >
                    Pemasukan
                  </button>
                </div>
              </div>

              <div>
                <label className="text-xs font-black text-black block mb-1">Nama Kategori</label>
                <input
                  type="text"
                  required
                  placeholder="Contoh: Langganan Hiburan, Kopi"
                  value={newName}
                  onChange={(e) => setNewName(e.target.value)}
                  className="w-full bg-white border-2 border-black rounded-xl px-3 py-2 text-sm font-bold text-black shadow-[2px_2px_0px_0px_#000] outline-none"
                />
              </div>

              <div className="flex items-center justify-end gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setIsAdding(false)}
                  className="px-4 py-2 text-xs font-bold text-black bg-white hover:bg-slate-100 border-2 border-black rounded-xl shadow-[2px_2px_0px_0px_#000] transition-all"
                >
                  Batal
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="px-4 py-2 text-xs font-black bg-neo-yellow hover:bg-[#FDE047] text-black border-2 border-black rounded-xl shadow-[3px_3px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] transition-all"
                >
                  {isSubmitting ? "Menyimpan..." : "Simpan Kategori"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
