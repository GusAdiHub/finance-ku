import "./globals.css";
import React from "react";
import type { Metadata, Viewport } from "next";
import { AuthProvider } from "@/lib/auth-context";
import { ToastProvider } from "@/lib/toast-context";
import { ModalProvider } from "@/lib/modal-context";
import { AppShell } from "@/components/layout/AppShell";

export const metadata: Metadata = {
  title: "SakuKu — Personal & Event Finance Tracker",
  description: "Aplikasi pencatat keuangan pribadi dan event berbasis Shared Ledger dengan input suara & scan struk.",
  manifest: "/manifest.json",
  icons: {
    icon: "/favicon.ico",
  },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
  themeColor: "#FFE600",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="id">
      <body className="bg-[#FFFDF9] text-black min-h-screen selection:bg-neo-yellow selection:text-black font-sans">
        <AuthProvider>
          <ToastProvider>
            <ModalProvider>
              <AppShell>{children}</AppShell>
            </ModalProvider>
          </ToastProvider>
        </AuthProvider>
      </body>
    </html>
  );
}
