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

// Reimbursement Status & Receipt Proof Helpers for Event & Team Cash
export type ReimburseStatus = "none" | "pending" | "settled";

export function parseReimburseStatus(notes?: string | null): {
  status: ReimburseStatus;
  isPending: boolean;
  isSettled: boolean;
  isReimburse: boolean;
  hasReceipt: boolean;
  noReceipt: boolean;
  canReimburse: boolean;
  cleanNotes: string;
} {
  if (!notes) {
    return {
      status: "none",
      isPending: false,
      isSettled: false,
      isReimburse: false,
      hasReceipt: false,
      noReceipt: false,
      canReimburse: true,
      cleanNotes: "",
    };
  }
  const isPending = notes.includes("[REIMBURSE_PENDING]");
  const isSettled = notes.includes("[REIMBURSED]");
  const hasNotaTag = notes.includes("[ADA_NOTA]");
  const noNotaTag = notes.includes("[TANPA_NOTA]");

  // A purchase without a receipt explicitly CANNOT be reimbursed
  const canReimburse = !noNotaTag;
  const status: ReimburseStatus = canReimburse
    ? isPending
      ? "pending"
      : isSettled
      ? "settled"
      : "none"
    : "none";

  const hasReceipt = hasNotaTag || isPending || isSettled;
  const noReceipt = noNotaTag;

  const cleanNotes = notes
    .replace("[ADA_NOTA]", "")
    .replace("[TANPA_NOTA]", "")
    .replace("[REIMBURSE_PENDING]", "")
    .replace("[REIMBURSED]", "")
    .trim();

  return {
    status,
    isPending: status === "pending",
    isSettled: status === "settled",
    isReimburse: status === "pending" || status === "settled",
    hasReceipt,
    noReceipt,
    canReimburse,
    cleanNotes,
  };
}

export function encodeReceiptAndReimburseNotes(
  hasReceipt: boolean,
  reimbursePending: boolean,
  userNotes?: string | null
): string {
  const clean = (userNotes || "")
    .replace("[ADA_NOTA]", "")
    .replace("[TANPA_NOTA]", "")
    .replace("[REIMBURSE_PENDING]", "")
    .replace("[REIMBURSED]", "")
    .trim();

  const tags: string[] = [];
  if (hasReceipt) {
    tags.push("[ADA_NOTA]");
    if (reimbursePending) {
      tags.push("[REIMBURSE_PENDING]");
    }
  } else {
    // Tanpa nota -> explicitly marked, cannot be reimbursed!
    tags.push("[TANPA_NOTA]");
  }

  const prefix = tags.join(" ");
  return clean ? `${prefix} ${clean}` : prefix;
}

export function encodeReimburseNotes(status: ReimburseStatus, userNotes?: string | null): string {
  const hadNoNota = userNotes?.includes("[TANPA_NOTA]") ?? false;
  const hadNota = userNotes?.includes("[ADA_NOTA]") ?? false;
  const clean = (userNotes || "")
    .replace("[ADA_NOTA]", "")
    .replace("[TANPA_NOTA]", "")
    .replace("[REIMBURSE_PENDING]", "")
    .replace("[REIMBURSED]", "")
    .trim();

  if (hadNoNota) {
    return clean ? `[TANPA_NOTA] ${clean}` : "[TANPA_NOTA]";
  }

  const notaTag = hadNota || status !== "none" ? "[ADA_NOTA] " : "";
  if (status === "pending") {
    return `${notaTag}[REIMBURSE_PENDING] ${clean}`.trim();
  }
  if (status === "settled") {
    return `${notaTag}[REIMBURSED] ${clean}`.trim();
  }
  return clean;
}
