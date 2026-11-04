"use client";

import React, { useState, useEffect } from "react";
import { useAuth } from "@/lib/auth-context";
import { api } from "@/lib/api";
import { formatDate } from "@/lib/utils";
import {
  User,
  Mail,
  Lock,
  LogOut,
  Calendar,
  Check,
  AlertCircle,
  KeyRound,
} from "lucide-react";

export default function ProfilePage() {
  const { user, refreshUser, logout } = useAuth();

  // Profile update
  const [name, setName] = useState(user?.name || "");
  const [isUpdatingProfile, setIsUpdatingProfile] = useState(false);
  const [profileMsg, setProfileMsg] = useState<{ text: string; isError: boolean } | null>(null);

  useEffect(() => {
    if (user?.name) {
      setName(user.name);
    }
  }, [user]);

  // Password change
  const [oldPassword, setOldPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [isChangingPassword, setIsChangingPassword] = useState(false);
  const [passwordMsg, setPasswordMsg] = useState<{ text: string; isError: boolean } | null>(null);

  const handleUpdateProfile = async (e: React.FormEvent) => {
    e.preventDefault();
    setProfileMsg(null);
    setIsUpdatingProfile(true);
    try {
      await api.updateMe({ name: name.trim() });
      await refreshUser();
      setProfileMsg({ text: "Profil berhasil diperbarui!", isError: false });
    } catch (err: any) {
      setProfileMsg({ text: err.message || "Gagal memperbarui profil.", isError: true });
    } finally {
      setIsUpdatingProfile(false);
    }
  };

  const handleChangePassword = async (e: React.FormEvent) => {
    e.preventDefault();
    setPasswordMsg(null);

    if (newPassword !== confirmPassword) {
      setPasswordMsg({ text: "Konfirmasi kata sandi baru tidak cocok.", isError: true });
      return;
    }

    if (newPassword.length < 8) {
      setPasswordMsg({ text: "Kata sandi baru minimal 8 karakter.", isError: true });
      return;
    }

    setIsChangingPassword(true);
    try {
      await api.changePassword({
        current_password: oldPassword,
        new_password: newPassword,
      });
      setOldPassword("");
      setNewPassword("");
      setConfirmPassword("");
      setPasswordMsg({ text: "Kata sandi berhasil diubah!", isError: false });
    } catch (err: any) {
      setPasswordMsg({ text: err.message || "Gagal mengubah kata sandi.", isError: true });
    } finally {
      setIsChangingPassword(false);
    }
  };

  return (
    <div className="max-w-3xl mx-auto space-y-6 animate-fade-in">
      {/* Header */}
      <div className="bg-white/80 backdrop-blur-xl p-5 rounded-2xl border-2 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.9),4px_4px_0px_0px_#000] flex items-center justify-between">
        <div>
          <h1 className="font-black text-black tracking-tight text-xl sm:text-2xl">
            Pengaturan Akun & Profil
          </h1>
          <p className="text-xs sm:text-sm font-semibold text-slate-700 mt-0.5">
            Kelola preferensi akun, profil pengguna, dan kata sandi.
          </p>
        </div>

        <button
          onClick={logout}
          className="bg-rose-100/90 hover:bg-rose-200 text-rose-950 text-xs sm:text-sm font-black px-4 py-2.5 rounded-xl border-2 border-black shadow-[2px_2px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] flex items-center gap-1.5 transition-all"
        >
          <LogOut className="w-4 h-4 stroke-[2.5]" />
          <span>Keluar</span>
        </button>
      </div>

      {/* Edit Profile Form */}
      <div className="bg-white/80 backdrop-blur-xl p-5 sm:p-6 rounded-2xl border-2 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.9),4px_4px_0px_0px_#000] space-y-4">
        <h3 className="font-black text-black text-base flex items-center gap-2">
          <User className="w-4 h-4 text-black stroke-[2.5]" />
          <span>Informasi Pengguna</span>
        </h3>

        {profileMsg && (
          <div
            className={`p-3 rounded-xl text-xs sm:text-sm font-bold border-2 border-black shadow-[2px_2px_0px_0px_#000] flex items-center gap-2 ${
              profileMsg.isError
                ? "bg-red-100 text-red-950"
                : "bg-neo-greenLight text-black"
            }`}
          >
            {profileMsg.isError ? <AlertCircle className="w-4 h-4 stroke-[2.5]" /> : <Check className="w-4 h-4 stroke-[3]" />}
            <span>{profileMsg.text}</span>
          </div>
        )}

        <form onSubmit={handleUpdateProfile} className="space-y-4">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="text-xs font-black text-black block mb-1">Nama Lengkap</label>
              <input
                type="text"
                required
                value={name}
                onChange={(e) => setName(e.target.value)}
                className="w-full bg-white border-2 border-black rounded-xl px-3.5 py-2.5 text-sm font-bold text-black shadow-[2px_2px_0px_0px_#000] outline-none"
              />
            </div>

            <div>
              <label className="text-xs font-black text-black block mb-1">Alamat Email</label>
              <input
                type="text"
                disabled
                value={
                  user?.email?.endsWith("@sakuku.local")
                    ? "Belum ditautkan (Login via Username)"
                    : user?.email || ""
                }
                className="w-full bg-slate-100 border-2 border-black rounded-xl px-3.5 py-2.5 text-sm font-bold text-slate-500 cursor-not-allowed shadow-[2px_2px_0px_0px_#000]"
              />
            </div>
          </div>

          <div className="flex items-center justify-between pt-2">
            <span className="text-[11px] font-semibold text-slate-600">
              Terdaftar sejak {user ? formatDate(user.created_at) : "-"}
            </span>
            <button
              type="submit"
              disabled={isUpdatingProfile}
              className="bg-neo-yellow hover:bg-[#FDE047] text-black font-black text-xs sm:text-sm px-5 py-2.5 rounded-xl border-2 border-black shadow-[3px_3px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] transition-all disabled:opacity-50"
            >
              {isUpdatingProfile ? "Menyimpan..." : "Simpan Perubahan"}
            </button>
          </div>
        </form>
      </div>

      {/* Change Password Form */}
      <div className="bg-white/80 backdrop-blur-xl p-5 sm:p-6 rounded-2xl border-2 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.9),4px_4px_0px_0px_#000] space-y-4">
        <h3 className="font-black text-black text-base flex items-center gap-2">
          <KeyRound className="w-4 h-4 text-black stroke-[2.5]" />
          <span>Ganti Kata Sandi</span>
        </h3>

        {passwordMsg && (
          <div
            className={`p-3 rounded-xl text-xs sm:text-sm font-bold border-2 border-black shadow-[2px_2px_0px_0px_#000] flex items-center gap-2 ${
              passwordMsg.isError
                ? "bg-red-100 text-red-950"
                : "bg-neo-greenLight text-black"
            }`}
          >
            {passwordMsg.isError ? <AlertCircle className="w-4 h-4 stroke-[2.5]" /> : <Check className="w-4 h-4 stroke-[3]" />}
            <span>{passwordMsg.text}</span>
          </div>
        )}

        <form onSubmit={handleChangePassword} className="space-y-4">
          <div>
            <label className="text-xs font-black text-black block mb-1">Kata Sandi Saat Ini</label>
            <input
              type="password"
              required
              value={oldPassword}
              onChange={(e) => setOldPassword(e.target.value)}
              placeholder="••••••••"
              className="w-full bg-white border-2 border-black rounded-xl px-3.5 py-2.5 text-sm font-bold text-black shadow-[2px_2px_0px_0px_#000] outline-none"
            />
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="text-xs font-black text-black block mb-1">Kata Sandi Baru</label>
              <input
                type="password"
                required
                minLength={8}
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                placeholder="Minimal 8 karakter"
                className="w-full bg-white border-2 border-black rounded-xl px-3.5 py-2.5 text-sm font-bold text-black shadow-[2px_2px_0px_0px_#000] outline-none"
              />
            </div>

            <div>
              <label className="text-xs font-black text-black block mb-1">Ulangi Kata Sandi Baru</label>
              <input
                type="password"
                required
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                placeholder="Ulangi kata sandi"
                className="w-full bg-white border-2 border-black rounded-xl px-3.5 py-2.5 text-sm font-bold text-black shadow-[2px_2px_0px_0px_#000] outline-none"
              />
            </div>
          </div>

          <div className="flex justify-end pt-2">
            <button
              type="submit"
              disabled={isChangingPassword}
              className="bg-neo-blue hover:bg-blue-600 text-white font-black text-xs sm:text-sm px-5 py-2.5 rounded-xl border-2 border-black shadow-[3px_3px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] transition-all disabled:opacity-50"
            >
              {isChangingPassword ? "Mengubah..." : "Perbarui Kata Sandi"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
