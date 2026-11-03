import { type ClassValue, clsx } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatRupiah(amount: number | string | undefined | null): string {
  if (amount === undefined || amount === null) return "Rp 0";
  const num = typeof amount === "string" ? parseFloat(amount) : amount;
  if (isNaN(num)) return "Rp 0";
  return new Intl.NumberFormat("id-ID", {
    style: "currency",
    currency: "IDR",
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(num);
}

export function formatDate(dateString: string): string {
  try {
    const d = new Date(dateString);
    return new Intl.DateTimeFormat("id-ID", {
      day: "numeric",
      month: "short",
      year: "numeric",
    }).format(d);
  } catch {
    return dateString;
  }
}

export function formatDateTime(dateString: string): string {
  try {
    const d = new Date(dateString);
    return new Intl.DateTimeFormat("id-ID", {
      day: "numeric",
      month: "short",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    }).format(d);
  } catch {
    return dateString;
  }
}

// Event Budget & Kas Group Helpers
export function parseGroupBudget(description?: string | null): number | null {
  if (!description) return null;
  const match = description.match(/\[(?:ANGGARAN|BUDGET):(\d+)\]/i);
  if (match && match[1]) {
    const val = parseInt(match[1], 10);
    return isNaN(val) ? null : val;
  }
  return null;
}

export function cleanGroupDescription(description?: string | null): string {
  if (!description) return "";
  return description.replace(/\[(?:ANGGARAN|BUDGET):\d+\]/gi, "").trim();
}

export function encodeGroupDescription(cleanDescription: string, budget?: number | null): string {
  const desc = (cleanDescription || "").trim();
  if (budget && budget > 0) {
    return `[ANGGARAN:${Math.round(budget)}] ${desc}`.trim();
  }
  return desc;
}

// Reimbursement Status Helpers for Event & Team Cash
export type ReimburseStatus = "none" | "pending" | "settled";

export function parseReimburseStatus(notes?: string | null): {
  status: ReimburseStatus;
  isPending: boolean;
  isSettled: boolean;
  isReimburse: boolean;
  cleanNotes: string;
} {
  if (!notes) {
    return { status: "none", isPending: false, isSettled: false, isReimburse: false, cleanNotes: "" };
  }
  const isPending = notes.includes("[REIMBURSE_PENDING]");
  const isSettled = notes.includes("[REIMBURSED]");
  const status: ReimburseStatus = isPending ? "pending" : isSettled ? "settled" : "none";
  const cleanNotes = notes
    .replace("[REIMBURSE_PENDING]", "")
    .replace("[REIMBURSED]", "")
    .trim();

  return {
    status,
    isPending,
    isSettled,
    isReimburse: isPending || isSettled,
    cleanNotes,
  };
}

export function encodeReimburseNotes(status: ReimburseStatus, userNotes?: string | null): string {
  const clean = (userNotes || "")
    .replace("[REIMBURSE_PENDING]", "")
    .replace("[REIMBURSED]", "")
    .trim();

  if (status === "pending") {
    return clean ? `[REIMBURSE_PENDING] ${clean}` : "[REIMBURSE_PENDING]";
  }
  if (status === "settled") {
    return clean ? `[REIMBURSED] ${clean}` : "[REIMBURSED]";
  }
  return clean;
}
