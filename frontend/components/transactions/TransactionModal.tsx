"use client";

import React, { useState, useEffect, useRef } from "react";
import { useModal } from "@/lib/modal-context";
import { useAuth } from "@/lib/auth-context";
import { api } from "@/lib/api";
import { Category, TransactionItem } from "@/lib/types";
import { formatRupiah, encodeReimburseNotes } from "@/lib/utils";
import {
  X,
  Keyboard,
  ScanLine,
  Mic,
  MicOff,
  Calendar,
  Tag,
  FileText,
  Check,
  AlertCircle,
  Upload,
  Image as ImageIcon,
  Loader2,
  Trash2,
  Sparkles,
  Volume2,
  Store,
  Plus,
  FolderKanban,
  HandCoins,
} from "lucide-react";

export function TransactionModal() {
  const { isOpen, options, closeTransactionModal } = useModal();
  const { activeScope, selectedGroup, userGroups, elderlyMode } = useAuth();
  const fileInputRef = useRef<HTMLInputElement>(null);

  const [method, setMethod] = useState<"manual" | "ocr" | "voice">("manual");
  const [type, setType] = useState<"income" | "expense">("expense");
  const [amount, setAmount] = useState<string>("");
  const [categoryId, setCategoryId] = useState<string>("");
  const [date, setDate] = useState<string>(new Date().toISOString().split("T")[0]);
  const [description, setDescription] = useState<string>("");
  const [targetScope, setTargetScope] = useState<"personal" | "family">(activeScope);
  const [targetGroupId, setTargetGroupId] = useState<string>(selectedGroup?.id || "");
  const [isReimbursePending, setIsReimbursePending] = useState<boolean>(false);

  // OCR specific states
  const [receiptFile, setReceiptFile] = useState<File | null>(null);
  const [receiptPreviewUrl, setReceiptPreviewUrl] = useState<string | null>(null);
  const [isScanningOCR, setIsScanningOCR] = useState<boolean>(false);
  const [receiptId, setReceiptId] = useState<string | null>(null);
  const [extractedItems, setExtractedItems] = useState<TransactionItem[]>([]);
  const [ocrFeedback, setOcrFeedback] = useState<{
    type: "success" | "warning";
    message: string;
  } | null>(null);
  const [rawOcrText, setRawOcrText] = useState<string | null>(null);
  const [showRawOcr, setShowRawOcr] = useState<boolean>(false);
  const [merchantName, setMerchantName] = useState<string>("");
  const [suggestedMerchant, setSuggestedMerchant] = useState<string | null>(null);
  const [customCategoryName, setCustomCategoryName] = useState<string>("");

  // Voice specific states
  const [isListening, setIsListening] = useState<boolean>(false);
  const [voiceTranscript, setVoiceTranscript] = useState<string>("" );
  const [isParsingVoice, setIsParsingVoice] = useState<boolean>(false);
  const [voiceParsedSummary, setVoiceParsedSummary] = useState<string | null>(null);
  const recognitionRef = useRef<any>(null);
  const latestTranscriptRef = useRef<string>("");

  const [categories, setCategories] = useState<Category[]>([]);
  const [isLoadingCategories, setIsLoadingCategories] = useState<boolean>(false);
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  // Sync state when modal opens
  useEffect(() => {
    if (isOpen) {
      setType(options.type || "expense");
      setMethod(options.inputMethod || "manual");
      setTargetScope(activeScope);
      setTargetGroupId(selectedGroup?.id || (userGroups[0]?.id ?? ""));
      setAmount("");
      setDescription("");
      setMerchantName("");
      setSuggestedMerchant(null);
      setCustomCategoryName("");
      setErrorMessage(null);
      setDate(new Date().toISOString().split("T")[0]);
      setReceiptFile(null);
      setReceiptPreviewUrl(null);
      setReceiptId(null);
      setExtractedItems([]);
      setIsScanningOCR(false);
      setOcrFeedback(null);
      setRawOcrText(null);
      setShowRawOcr(false);
      setVoiceTranscript("");
      setVoiceParsedSummary(null);
      setIsListening(false);
      setIsReimbursePending(false);
    }
  }, [isOpen, options, activeScope, selectedGroup, userGroups]);

  // Load categories when type changes
  useEffect(() => {
    if (isOpen) {
      loadCategories(type);
    }
  }, [isOpen, type]);

  const loadCategories = async (catType: "income" | "expense") => {
    setIsLoadingCategories(true);
    try {
      const data = await api.getCategories(catType);
      setCategories(data);
      if (data.length > 0) {
        setCategoryId((prev) => {
          if (prev === "__custom__") return "__custom__";
          return data.some((c) => c.id === prev) ? prev : data[0].id;
        });
      }
    } catch (err: any) {
      console.error("Failed to load categories:", err);
    } finally {
      setIsLoadingCategories(false);
    }
  };

  const addQuickAmount = (val: number) => {
    const current = parseFloat(amount.replace(/[^\d]/g, "")) || 0;
    setAmount(String(Math.round(current + val)));
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (!file.type.startsWith("image/")) {
      setErrorMessage("Format file harus berupa gambar struk (JPEG, PNG, WebP).");
      return;
    }

    setReceiptFile(file);
    setReceiptPreviewUrl(URL.createObjectURL(file));
    setReceiptId(null);
    setExtractedItems([]);
    setOcrFeedback(null);
    setErrorMessage(null);
  };

  const handleRunOCR = async () => {
    if (!receiptFile) return;

    setIsScanningOCR(true);
    setErrorMessage(null);
    setOcrFeedback(null);
    setSuggestedMerchant(null);
    try {
      const targetGroup = targetScope === "family" ? targetGroupId : undefined;
      const receiptData = await api.uploadReceipt(
        receiptFile,
        targetGroup,
        merchantName.trim() || undefined
      );

      setReceiptId(receiptData.id);
      setRawOcrText(receiptData.raw_ocr_data?.raw_text || null);

      // Auto-populate parsed values: focus on amount and date
      let amountFound = false;
      if (receiptData.total_amount) {
        const cleanAmt = Math.round(Number(receiptData.total_amount));
        setAmount(String(cleanAmt));
        amountFound = true;
      }

      // Keep merchant input manual: only provide suggestion if user hasn't filled it
      if (receiptData.merchant_name && !merchantName.trim()) {
        setSuggestedMerchant(receiptData.merchant_name);
      }

      if (receiptData.receipt_date) {
        setDate(receiptData.receipt_date.split("T")[0]);
      }
      if (receiptData.items && receiptData.items.length > 0) {
        setExtractedItems(receiptData.items);
      }

      // Read OCR status from response
      const ocrStatus = receiptData.ocr_status || receiptData.raw_ocr_data?.ocr_status;
      const ocrMsg = receiptData.ocr_message || receiptData.raw_ocr_data?.ocr_message;

      if (amountFound) {
        setOcrFeedback({
          type: "success",
          message: `Nominal berhasil terbaca: ${formatRupiah(receiptData.total_amount)}. Silakan tinjau kembali sebelum menyimpan.`,
        });
      } else if (ocrStatus === "unavailable") {
        setOcrFeedback({
          type: "warning",
          message:
            ocrMsg ||
            "Struk tersimpan sebagai draft, namun mesin OCR (Tesseract) belum terpasang di server. Silakan ketik nominal manual di kolom bawah.",
        });
      } else {
        setOcrFeedback({
          type: "warning",
          message:
            ocrMsg ||
            "Struk berhasil dipindai, namun angka total belanja belum terdeteksi otomatis. Silakan masukkan nominal secara manual di kolom bawah.",
        });
      }
    } catch (err: any) {
      setErrorMessage(err.message || "Gagal memindai struk dengan OCR.");
    } finally {
      setIsScanningOCR(false);
    }
  };

  const updateExtractedItem = (index: number, field: string, value: any) => {
    setExtractedItems((prev) => {
      const copy = [...prev];
      const item = { ...copy[index], [field]: value };
      if (field === "quantity" || field === "price_per_unit") {
        item.total_price = Number(item.quantity) * Number(item.price_per_unit);
      }
      copy[index] = item;
      return copy;
    });
  };

  const removeExtractedItem = (index: number) => {
    setExtractedItems((prev) => prev.filter((_, i) => i !== index));
  };

  // Voice Recognition Controls
  const toggleListening = () => {
    if (isListening) {
      stopListening();
    } else {
      startListening();
    }
  };

  const startListening = () => {
    const SpeechRecognition =
      (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition;

    if (!SpeechRecognition) {
      setErrorMessage(
        "Browser Anda belum mendukung Web Speech API bawaan. Anda dapat mengetik kalimat transaksi langsung pada kolom di bawah atau klik contoh cepat."
      );
      return;
    }

    try {
      const recognition = new SpeechRecognition();
      recognition.lang = "id-ID";
      recognition.interimResults = true;
      recognition.continuous = false;

      recognition.onstart = () => {
        setIsListening(true);
        setErrorMessage(null);
        latestTranscriptRef.current = "";
      };

      recognition.onresult = (event: any) => {
        let currentText = "";
        for (let i = 0; i < event.results.length; i++) {
          currentText += event.results[i][0].transcript + " ";
        }
        currentText = currentText.trim();
        latestTranscriptRef.current = currentText;
        setVoiceTranscript(currentText);
      };

      recognition.onerror = (event: any) => {
        console.error("Speech recognition error:", event.error);
        setIsListening(false);
        if (event.error === "not-allowed" || event.error === "service-not-allowed") {
          setErrorMessage(
            "Izin mikrofon belum diberikan. Silakan izinkan akses mikrofon di browser Anda (klik ikon gembok di address bar), atau gunakan tombol contoh / ketik di bawah."
          );
        } else if (event.error === "network") {
          setErrorMessage(
            "Layanan pengenalan suara browser memerlukan koneksi internet aktif. Anda tetap dapat menggunakan tombol contoh atau mengetik kalimat di bawah."
          );
        } else if (event.error === "audio-capture") {
          setErrorMessage(
            "Mikrofon tidak terdeteksi pada komputer / perangkat Anda. Pastikan mikrofon terpasang."
          );
        } else if (event.error === "no-speech") {
          setErrorMessage(
            "Suara tidak terdengar. Silakan coba lagi dan berbicara lebih dekat ke mikrofon."
          );
        } else if (event.error !== "aborted") {
          setErrorMessage(
            `Pengenalan suara mengalami kendala (${event.error}). Anda dapat menggunakan tombol contoh atau ketik kalimat di bawah.`
          );
        }
      };

      recognition.onend = () => {
        setIsListening(false);
        const recorded = latestTranscriptRef.current.trim();
        if (recorded) {
          handleParseVoice(recorded);
        }
      };

      recognitionRef.current = recognition;
      recognition.start();
    } catch (err: any) {
      console.error("Speech start error:", err);
      setIsListening(false);
      setErrorMessage("Tidak dapat memulai mikrofon. Pastikan izin mikrofon telah diberikan.");
    }
  };

  const stopListening = () => {
    if (recognitionRef.current) {
      recognitionRef.current.stop();
    }
    setIsListening(false);
  };

  const handleParseVoice = async (textToParse?: string) => {
    const query = (textToParse || voiceTranscript).trim();
    if (!query) {
      setErrorMessage("Silakan ucapkan atau ketik kalimat transaksi terlebih dahulu.");
      return;
    }

    setIsParsingVoice(true);
    setErrorMessage(null);
    try {
      const parsed = await api.parseVoice(query);
      if (parsed.type) {
        setType(parsed.type);
      }
      if (parsed.amount) {
        setAmount(String(parsed.amount));
      }
      if (parsed.description) {
        setDescription(parsed.description);
      }
      if (parsed.suggested_category_id) {
        setCategoryId(parsed.suggested_category_id);
      }
      setVoiceParsedSummary(
        `Berhasil dianalisis: ${parsed.type === "expense" ? "Pengeluaran" : "Pemasukan"} ${
          parsed.amount ? formatRupiah(parsed.amount) : ""
        } (${parsed.suggested_category_name || "Kategori Umum"})`
      );
    } catch (err: any) {
      setErrorMessage(err.message || "Gagal memproses teks suara dengan AI.");
    } finally {
      setIsParsingVoice(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage(null);

    const parsedAmount = parseFloat(amount.replace(/[^\d]/g, ""));
    if (!parsedAmount || parsedAmount <= 0) {
      setErrorMessage("Nominal transaksi harus lebih dari 0.");
      return;
    }

    if (!categoryId) {
      setErrorMessage("Silakan pilih kategori.");
      return;
    }

    if (targetScope === "family" && !targetGroupId) {
      setErrorMessage("Silakan pilih grup keluarga.");
      return;
    }

    setIsSubmitting(true);
    try {
      let finalCategoryId = categoryId;
      if (categoryId === "__custom__") {
        const trimmed = customCategoryName.trim();
        if (!trimmed) {
          setErrorMessage("Silakan ketik nama kategori baru.");
          setIsSubmitting(false);
          return;
        }

        // Check if user already has a category with this name (case-insensitive)
        const existingCat = categories.find(
          (c) => c.name.toLowerCase() === trimmed.toLowerCase()
        );
        if (existingCat) {
          finalCategoryId = existingCat.id;
        } else {
          try {
            const newCat = await api.createCategory({
              name: trimmed,
              type: method === "ocr" ? "expense" : type,
            });
            finalCategoryId = newCat.id;
            setCategories((prev) => [...prev, newCat]);
          } catch (catErr: any) {
            setErrorMessage(catErr.message || "Gagal membuat kategori baru.");
            setIsSubmitting(false);
            return;
          }
        }
      }

      if (method === "ocr" && receiptId) {
        // Construct clear description with manual merchant name
        const finalDescription = description.trim()
          ? merchantName.trim()
            ? `Belanja di ${merchantName.trim()} (${description.trim()})`
            : description.trim()
          : merchantName.trim()
          ? `Belanja di ${merchantName.trim()}`
          : "Pembayaran struk belanja";

        // Reimbursement note encoding if saving to group ledger
        const reimburseNote =
          targetScope === "family" && isReimbursePending
            ? encodeReimburseNotes("pending", description)
            : undefined;

        // Confirm receipt draft
        await api.confirmReceipt(receiptId, {
          category_id: finalCategoryId,
          merchant_name: merchantName.trim() || undefined,
          total_amount: parsedAmount,
          transaction_date: date ? new Date(date).toISOString() : undefined,
          description: finalDescription,
          notes: reimburseNote,
          target_scope: targetScope,
          group_id: targetScope === "family" ? targetGroupId : undefined,
          items: extractedItems.length > 0 ? extractedItems : undefined,
        });
      } else {
        // Standard personal or group transaction creation
        const finalDescription = description.trim()
          ? merchantName.trim()
            ? `Belanja di ${merchantName.trim()} (${description.trim()})`
            : description.trim()
          : merchantName.trim()
          ? `Belanja di ${merchantName.trim()}`
          : undefined;

        const reimburseNote =
          targetScope === "family" && isReimbursePending
            ? encodeReimburseNotes("pending", description)
            : undefined;

        const payload = {
          amount: parsedAmount,
          type,
          category_id: finalCategoryId,
          transaction_date: date,
          description: finalDescription,
          notes: reimburseNote,
          input_method: method,
        };

        if (targetScope === "personal") {
          await api.createTransaction(payload);
        } else {
          await api.createGroupTransaction(targetGroupId, payload);
        }
      }

      if (options.onSuccess) {
        options.onSuccess();
      }
      closeTransactionModal();
      window.dispatchEvent(new CustomEvent("refresh-data"));
    } catch (err: any) {
      setErrorMessage(err.message || "Gagal menyimpan transaksi.");
    } finally {
      setIsSubmitting(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-end lg:items-center justify-center p-0 lg:p-4 bg-black/45 backdrop-blur-md animate-fade-in">
      <div className="bg-[#FFFDF9]/95 backdrop-blur-2xl w-full max-w-lg rounded-t-3xl lg:rounded-3xl border-3 border-black shadow-[inset_0_1.5px_1px_rgba(255,255,255,0.95),8px_8px_0px_0px_#000] flex flex-col max-h-[92vh] overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between p-4 border-b-2 border-black bg-white/80 backdrop-blur-md">
          <div>
            <h2 className={`font-black text-black tracking-tight ${elderlyMode ? "text-xl" : "text-lg"}`}>
              {elderlyMode ? "CATAT UANG MASUK / KELUAR" : "TAMBAH TRANSAKSI"}
            </h2>
            <p className="text-xs font-semibold text-slate-600">Pilih metode dan isi rincian transaksi</p>
          </div>
          <button
            onClick={closeTransactionModal}
            className="p-1.5 text-black hover:bg-rose-100 border border-transparent hover:border-black rounded-xl transition-colors"
          >
            <X className="w-5 h-5 stroke-[2.5]" />
          </button>
        </div>

        {/* Input Method Selector */}
        <div className="grid grid-cols-3 gap-1.5 p-2 bg-[#FFFDF9] border-b-2 border-black text-xs font-black text-black">
          <button
            type="button"
            onClick={() => setMethod("manual")}
            className={`flex items-center justify-center gap-1.5 py-2 rounded-xl transition-all ${
              method === "manual" ? "bg-neo-yellow text-black border-2 border-black shadow-[2px_2px_0px_0px_#000]" : "hover:bg-slate-100 border-2 border-transparent"
            }`}
          >
            <Keyboard className="w-4 h-4 stroke-[2.5]" />
            <span>Manual</span>
          </button>
          <button
            type="button"
            onClick={() => {
              setMethod("ocr");
              setType("expense");
            }}
            className={`flex items-center justify-center gap-1.5 py-2 rounded-xl transition-all ${
              method === "ocr" ? "bg-neo-yellow text-black border-2 border-black shadow-[2px_2px_0px_0px_#000]" : "hover:bg-slate-100 border-2 border-transparent"
            }`}
          >
            <ScanLine className="w-4 h-4 stroke-[2.5]" />
            <span>Scan Struk</span>
          </button>
          <button
            type="button"
            onClick={() => setMethod("voice")}
            className={`flex items-center justify-center gap-1.5 py-2 rounded-xl transition-all ${
              method === "voice" ? "bg-neo-yellow text-black border-2 border-black shadow-[2px_2px_0px_0px_#000]" : "hover:bg-slate-100 border-2 border-transparent"
            }`}
          >
            <Mic className="w-4 h-4 stroke-[2.5]" />
            <span>Suara</span>
          </button>
        </div>

        {/* Modal Body / Form */}
        <form onSubmit={handleSubmit} className="p-4 sm:p-5 overflow-y-auto space-y-4">
          {errorMessage && (
            <div className="p-3 bg-red-100 border-2 border-black text-red-950 text-xs sm:text-sm font-bold rounded-xl flex items-center gap-2 shadow-[2px_2px_0px_0px_#000]">
              <AlertCircle className="w-4 h-4 flex-shrink-0 stroke-[2.5]" />
              <span>{errorMessage}</span>
            </div>
          )}

          {/* Voice Input Section (If method is Voice) */}
          {method === "voice" && (
            <div className="p-4 bg-purple-100 border-2 border-black rounded-2xl space-y-3 shadow-[3px_3px_0px_0px_#000]">
              <div className="flex items-center justify-between">
                <span className="text-xs font-black text-black flex items-center gap-1.5">
                  <Volume2 className="w-4 h-4 text-purple-700 stroke-[2.5]" />
                  <span>Input Transaksi Melalui Suara:</span>
                </span>
                {voiceParsedSummary && (
                  <span className="text-[10px] bg-neo-green text-black font-black px-2 py-0.5 rounded-md border-2 border-black flex items-center gap-1 shadow-[1.5px_1.5px_0px_0px_#000]">
                    <Check className="w-3 h-3 stroke-[3]" /> Terbaca
                  </span>
                )}
              </div>

              {/* Microphone Action Button */}
              <div className="flex flex-col items-center justify-center py-2 space-y-2">
                <button
                  type="button"
                  onClick={toggleListening}
                  className={`w-16 h-16 rounded-2xl border-2 border-black flex items-center justify-center transition-all shadow-[4px_4px_0px_0px_#000] active:translate-x-[2px] active:translate-y-[2px] active:shadow-[1px_1px_0px_0px_#000] ${
                    isListening
                      ? "bg-rose-500 text-white animate-pulse"
                      : "bg-neo-yellow text-black hover:bg-[#FDE047]"
                  }`}
                  title={isListening ? "Klik untuk berhenti merekam" : "Klik untuk mulai berbicara"}
                >
                  {isListening ? <MicOff className="w-7 h-7 stroke-[2.5]" /> : <Mic className="w-7 h-7 stroke-[2.5]" />}
                </button>
                <p className="text-xs font-black text-black text-center">
                  {isListening
                    ? "Sedang mendengarkan... Katakan transaksi Anda sekarang."
                    : "Tekan tombol mikrofon lalu katakan transaksi Anda."}
                </p>
                <p className="text-[11px] text-slate-700 text-center font-medium italic">
                  Contoh: &ldquo;Catat pengeluaran makan siang dua puluh lima ribu rupiah&rdquo; atau &ldquo;Beli bensin 50 ribu&rdquo;
                </p>
              </div>

              {/* Transcript Textbox & Trigger */}
              <div className="space-y-2">
                <input
                  type="text"
                  value={voiceTranscript}
                  onChange={(e) => setVoiceTranscript(e.target.value)}
                  placeholder="Atau ketik kalimat percakapan transaksi di sini..."
                  className="w-full bg-white border-2 border-black rounded-xl px-3 py-2 text-xs sm:text-sm text-black font-bold shadow-[2px_2px_0px_0px_#000] outline-none"
                />

                <button
                  type="button"
                  onClick={() => handleParseVoice()}
                  disabled={isParsingVoice || !voiceTranscript.trim()}
                  className="w-full bg-neo-purple hover:bg-purple-300 text-black font-black text-xs sm:text-sm py-2.5 px-4 rounded-xl flex items-center justify-center gap-2 border-2 border-black shadow-[3px_3px_0px_0px_#000] active:translate-x-[2px] active:translate-y-[2px] active:shadow-[1px_1px_0px_0px_#000] transition-all disabled:opacity-50"
                >
                  {isParsingVoice ? (
                    <>
                      <Loader2 className="w-4 h-4 animate-spin stroke-[2.5]" />
                      <span>Menganalisis kalimat transaksi...</span>
                    </>
                  ) : (
                    <>
                      <Sparkles className="w-4 h-4 stroke-[2.5]" />
                      <span>Analisis & Ekstraksi Suara ke Form</span>
                    </>
                  )}
                </button>
              </div>

              {/* Quick Sample Voice Presets */}
              <div className="pt-1">
                <span className="text-[11px] font-black text-black block mb-1.5">
                  Atau coba klik contoh kalimat di bawah:
                </span>
                <div className="flex flex-wrap gap-1.5">
                  {[
                    "Makan siang di warteg 25 ribu",
                    "Beli bensin pertalite 50 ribu",
                    "Gaji bulanan 10 juta rupiah",
                    "Bayar tagihan listrik 350.000",
                    "Jajan kopi kenangan 28rb",
                  ].map((sample) => (
                    <button
                      key={sample}
                      type="button"
                      onClick={() => {
                        setVoiceTranscript(sample);
                        latestTranscriptRef.current = sample;
                        handleParseVoice(sample);
                      }}
                      className="text-[11px] bg-white hover:bg-neo-yellow text-black font-bold px-2.5 py-1 rounded-lg border-2 border-black transition-all shadow-[1.5px_1.5px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px]"
                    >
                      &ldquo;{sample}&rdquo;
                    </button>
                  ))}
                </div>
              </div>

              {voiceParsedSummary && (
                <div className="p-2.5 bg-neo-greenLight border-2 border-black rounded-xl text-xs text-black font-bold flex items-start gap-1.5 shadow-[2px_2px_0px_0px_#000]">
                  <Check className="w-4 h-4 flex-shrink-0 text-black stroke-[3] mt-0.5" />
                  <span>{voiceParsedSummary}</span>
                </div>
              )}
            </div>
          )}

          {/* OCR Input Section - Simpel & Cepat */}
          {method === "ocr" && (
            <div className="space-y-3.5">
              {/* 1. Upload Struk & Tombol Pindai */}
              <div className="bg-white border-2 border-black rounded-2xl p-3.5 space-y-2.5 shadow-[3px_3px_0px_0px_#000]">
                <input
                  ref={fileInputRef}
                  type="file"
                  accept="image/jpeg,image/png,image/webp"
                  onChange={handleFileChange}
                  className="hidden"
                />

                {!receiptPreviewUrl ? (
                  <div
                    onClick={() => fileInputRef.current?.click()}
                    className="border-2 border-dashed border-black hover:bg-neo-yellowLight rounded-xl py-4 px-3 text-center cursor-pointer transition-colors bg-white flex flex-col items-center justify-center gap-1.5"
                  >
                    <Upload className="w-6 h-6 text-black stroke-[2.5]" />
                    <span className="text-xs sm:text-sm font-black text-black">
                      Pilih atau Foto Struk Belanja
                    </span>
                    <span className="text-[11px] text-slate-700 font-medium">Format JPG, PNG, atau WebP (Maks. 10 MB)</span>
                  </div>
                ) : (
                  <div className="space-y-2.5">
                    <div className="relative rounded-xl overflow-hidden border-2 border-black bg-white h-32 flex items-center justify-center p-1.5 shadow-[2px_2px_0px_0px_#000]">
                      <img
                        src={receiptPreviewUrl}
                        alt="Receipt Preview"
                        className="h-full object-contain rounded-lg"
                      />
                      <button
                        type="button"
                        onClick={() => {
                          setReceiptFile(null);
                          setReceiptPreviewUrl(null);
                          setReceiptId(null);
                          setExtractedItems([]);
                          setOcrFeedback(null);
                          setSuggestedMerchant(null);
                        }}
                        className="absolute top-2 right-2 p-1.5 bg-rose-500 text-white rounded-lg border-2 border-black shadow-[2px_2px_0px_0px_#000] hover:bg-rose-600 transition-colors"
                        title="Ganti gambar"
                      >
                        <Trash2 className="w-3.5 h-3.5 stroke-[2.5]" />
                      </button>
                    </div>

                    {!receiptId && (
                      <button
                        type="button"
                        onClick={handleRunOCR}
                        disabled={isScanningOCR}
                        className="w-full bg-neo-blue hover:bg-blue-600 text-white font-black text-xs sm:text-sm py-2.5 px-4 rounded-xl flex items-center justify-center gap-2 border-2 border-black shadow-[3px_3px_0px_0px_#000] active:translate-x-[2px] active:translate-y-[2px] active:shadow-[1px_1px_0px_0px_#000] transition-all disabled:opacity-50"
                      >
                        {isScanningOCR ? (
                          <>
                            <Loader2 className="w-4 h-4 animate-spin stroke-[2.5]" />
                            <span>Membaca angka struk...</span>
                          </>
                        ) : (
                          <>
                            <Sparkles className="w-4 h-4 stroke-[2.5]" />
                            <span>Pindai Struk & Deteksi Angka</span>
                          </>
                        )}
                      </button>
                    )}

                    {ocrFeedback && (
                      <div
                        className={`p-2.5 rounded-xl text-xs font-bold flex items-center gap-2 border-2 border-black shadow-[2px_2px_0px_0px_#000] ${
                          ocrFeedback.type === "success"
                            ? "bg-neo-greenLight text-black"
                            : "bg-amber-100 text-black"
                        }`}
                      >
                        {ocrFeedback.type === "success" ? (
                          <Check className="w-4 h-4 flex-shrink-0 text-black stroke-[3]" />
                        ) : (
                          <AlertCircle className="w-4 h-4 flex-shrink-0 text-black stroke-[2.5]" />
                        )}
                        <span>{ocrFeedback.message}</span>
                      </div>
                    )}
                  </div>
                )}
              </div>

              {/* 2. Jumlah Nominal (Otomatis dari Struk) */}
              <div className="space-y-1.5">
                <div className="flex items-center justify-between">
                  <label className="text-xs font-black text-black">Nominal Belanja:</label>
                  {amount && Number(amount.replace(/[^\d]/g, "")) > 0 && (
                    <span className="text-xs font-black text-black bg-neo-yellow px-2 py-0.5 rounded-md border-2 border-black shadow-[1.5px_1.5px_0px_0px_#000]">
                      {formatRupiah(Number(amount.replace(/[^\d]/g, "")))}
                    </span>
                  )}
                </div>
                <div className="relative">
                  <span className="absolute left-4 top-1/2 -translate-y-1/2 text-black font-black text-lg sm:text-xl">
                    Rp
                  </span>
                  <input
                    type="text"
                    inputMode="numeric"
                    required
                    value={
                      amount && !isNaN(Number(amount.replace(/[^\d]/g, "")))
                        ? Number(amount.replace(/[^\d]/g, "")).toLocaleString("id-ID")
                        : ""
                    }
                    onChange={(e) => {
                      const digits = e.target.value.replace(/[^\d]/g, "");
                      setAmount(digits);
                    }}
                    placeholder="0"
                    className="w-full bg-white border-2 border-black rounded-xl pl-12 pr-4 py-3 text-xl sm:text-2xl font-black text-black shadow-[3px_3px_0px_0px_#000] outline-none"
                  />
                </div>
                {amount && (
                  <p className="text-[11px] text-emerald-800 font-bold flex items-center gap-1">
                    <Check className="w-3.5 h-3.5 stroke-[3]" /> Angka terdeteksi dari struk. Anda dapat mengubah jika perlu.
                  </p>
                )}
              </div>

              {/* 3. Tempat Belanja / Toko (Input Manual + 4 Pilihan Cepat) */}
              <div className="space-y-1.5">
                <label className="text-xs font-black text-black flex items-center gap-1">
                  <Store className="w-3.5 h-3.5 text-black stroke-[2.5]" />
                  <span>Tempat Belanja / Toko:</span>
                </label>
                <input
                  type="text"
                  value={merchantName}
                  onChange={(e) => setMerchantName(e.target.value)}
                  placeholder="Ketik nama toko (misal: Indomaret, Warung, Apotek)..."
                  className="w-full bg-white border-2 border-black rounded-xl px-3 py-2.5 text-xs sm:text-sm text-black font-bold shadow-[2px_2px_0px_0px_#000] outline-none"
                />
                <div className="flex items-center gap-1.5 flex-wrap pt-0.5">
                  {["Indomaret", "Alfamart", "Warung / Pasar", "Apotek"].map((name) => (
                    <button
                      key={name}
                      type="button"
                      onClick={() => setMerchantName(name)}
                      className={`text-xs px-2.5 py-1 rounded-lg border-2 border-black transition-all font-bold shadow-[1.5px_1.5px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] ${
                        merchantName === name
                          ? "bg-neo-yellow text-black font-black"
                          : "bg-white text-black hover:bg-neo-yellowLight"
                      }`}
                    >
                      {name}
                    </button>
                  ))}
                  {merchantName && (
                    <button
                      type="button"
                      onClick={() => setMerchantName("")}
                      className="text-[11px] text-rose-600 font-bold hover:underline ml-auto"
                    >
                      Hapus
                    </button>
                  )}
                </div>
              </div>

              {/* 4. Kategori Pengeluaran (Dropdown + Opsi Buat Kategori Baru / Lainnya) */}
              <div className="space-y-1.5">
                <div className="flex items-center justify-between">
                  <label className="text-xs font-black text-black flex items-center gap-1">
                    <Tag className="w-3.5 h-3.5 text-black stroke-[2.5]" />
                    <span>Kategori Pengeluaran:</span>
                  </label>
                  {categoryId !== "__custom__" ? (
                    <button
                      type="button"
                      onClick={() => {
                        setCategoryId("__custom__");
                        setCustomCategoryName("");
                      }}
                      className="text-[11px] text-black bg-neo-yellow hover:bg-[#FDE047] font-black px-2 py-0.5 rounded-lg border-2 border-black flex items-center gap-0.5 shadow-[1.5px_1.5px_0px_0px_#000] transition-all"
                    >
                      <Plus className="w-3 h-3 stroke-[3]" />
                      <span>+ Kategori Baru</span>
                    </button>
                  ) : (
                    <button
                      type="button"
                      onClick={() => {
                        setCategoryId(categories[0]?.id || "");
                        setCustomCategoryName("");
                      }}
                      className="text-[11px] text-black bg-white hover:bg-slate-100 font-bold px-2 py-0.5 rounded-lg border-2 border-black shadow-[1.5px_1.5px_0px_0px_#000] transition-all"
                    >
                      Batal (Pilih Daftar)
                    </button>
                  )}
                </div>

                {isLoadingCategories ? (
                  <div className="h-10 bg-slate-200 border-2 border-black rounded-xl animate-pulse" />
                ) : (
                  <div className="space-y-2">
                    <select
                      aria-label="Pilih kategori pengeluaran"
                      value={categoryId}
                      onChange={(e) => setCategoryId(e.target.value)}
                      required
                      className="w-full bg-white border-2 border-black rounded-xl px-3 py-2.5 text-xs sm:text-sm font-bold text-black shadow-[2px_2px_0px_0px_#000] outline-none"
                    >
                      {categories.map((cat) => (
                        <option key={cat.id} value={cat.id}>
                          {cat.name}
                        </option>
                      ))}
                      <option value="__custom__">✨ + Ketik Kategori Baru Sendiri...</option>
                    </select>

                    {/* Input manual kategori baru jika dipilih */}
                    {categoryId === "__custom__" && (
                      <div className="p-3 bg-neo-yellowLight border-2 border-black rounded-xl space-y-1.5 shadow-[2px_2px_0px_0px_#000]">
                        <label className="text-[11px] font-black text-black flex items-center gap-1">
                          <Sparkles className="w-3.5 h-3.5 text-black stroke-[2.5]" />
                          <span>Ketik Nama Kategori Baru:</span>
                        </label>
                        <input
                          type="text"
                          required
                          value={customCategoryName}
                          onChange={(e) => setCustomCategoryName(e.target.value)}
                          placeholder="Contoh: Laundry, Servis Kendaraan, Skincare, dll..."
                          className="w-full bg-white border-2 border-black rounded-lg px-3 py-2 text-xs sm:text-sm text-black font-bold shadow-[1.5px_1.5px_0px_0px_#000] outline-none"
                          autoFocus
                        />
                        <p className="text-[10px] text-slate-700 font-semibold">
                          Kategori ini akan otomatis tersimpan di akun Anda dan dapat dipakai lagi nanti.
                        </p>
                      </div>
                    )}
                  </div>
                )}
              </div>

              {/* 5. Tanggal & Catatan Tambahan (Opsional) */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div className="space-y-1.5">
                  <label className="text-xs font-black text-black flex items-center gap-1">
                    <Calendar className="w-3.5 h-3.5 text-black stroke-[2.5]" />
                    <span>Tanggal:</span>
                  </label>
                  <input
                    type="date"
                    required
                    value={date}
                    onChange={(e) => setDate(e.target.value)}
                    className="w-full bg-white border-2 border-black rounded-xl px-3 py-2 text-sm font-bold text-black shadow-[2px_2px_0px_0px_#000] outline-none"
                  />
                </div>

                <div className="space-y-1.5">
                  <label className="text-xs font-black text-black flex items-center gap-1">
                    <FileText className="w-3.5 h-3.5 text-black stroke-[2.5]" />
                    <span>Catatan (Opsional):</span>
                  </label>
                  <input
                    type="text"
                    placeholder="Contoh: Belanja sabun & cemilan"
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                    className="w-full bg-white border-2 border-black rounded-xl px-3 py-2 text-sm font-bold text-black shadow-[2px_2px_0px_0px_#000] outline-none"
                  />
                </div>
              </div>

              {/* 6. Simpan ke Buku Catatan (Pribadi vs Kas Tim / Event) */}
              <div className="space-y-2">
                <label className="text-xs font-black text-black">Simpan ke:</label>
                <div className="grid grid-cols-2 gap-2">
                  <button
                    type="button"
                    onClick={() => {
                      setTargetScope("personal");
                      setIsReimbursePending(false);
                    }}
                    className={`py-2 px-3 rounded-xl border-2 border-black text-xs sm:text-sm font-black transition-all shadow-[2px_2px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] ${
                      targetScope === "personal"
                        ? "bg-neo-yellow text-black"
                        : "bg-white text-black hover:bg-slate-100"
                    }`}
                  >
                    👤 Catatan Pribadi
                  </button>
                  <button
                    type="button"
                    onClick={() => setTargetScope("family")}
                    className={`py-2 px-3 rounded-xl border-2 border-black text-xs sm:text-sm font-black transition-all shadow-[2px_2px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] ${
                      targetScope === "family"
                        ? "bg-neo-yellow text-black"
                        : "bg-white text-black hover:bg-slate-100"
                    }`}
                  >
                    🎪 Kas Tim / Event
                  </button>
                </div>

                {targetScope === "family" && (
                  <div className="space-y-2 pt-1 animate-fade-in">
                    {userGroups.length > 0 ? (
                      <select
                        aria-label="Pilih grup kas event tujuan"
                        value={targetGroupId}
                        onChange={(e) => setTargetGroupId(e.target.value)}
                        className="w-full bg-white border-2 border-black rounded-xl px-3 py-2 text-xs sm:text-sm font-bold text-black shadow-[2px_2px_0px_0px_#000] outline-none"
                      >
                        {userGroups.map((g) => (
                          <option key={g.id} value={g.id}>
                            🎪 {g.name.replace(/Keluarga\s*Cemara/gi, "Panitia Event & Proyek")}
                          </option>
                        ))}
                      </select>
                    ) : (
                      <p className="text-xs text-rose-600 font-bold">
                        Anda belum memiliki grup kas event manapun.
                      </p>
                    )}

                    {/* Reimbursement Toggle */}
                    <div className="p-3 bg-amber-50/90 border-2 border-black rounded-xl shadow-[2px_2px_0px_0px_#000]">
                      <label className="flex items-start gap-2.5 cursor-pointer">
                        <input
                          type="checkbox"
                          checked={isReimbursePending}
                          onChange={(e) => setIsReimbursePending(e.target.checked)}
                          className="mt-0.5 w-4 h-4 rounded border-2 border-black accent-black cursor-pointer"
                        />
                        <div className="flex-1">
                          <span className="text-xs font-black text-black flex items-center gap-1.5">
                            <HandCoins className="w-3.5 h-3.5 text-black stroke-[2.5]" />
                            <span>Uang Talangan Pribadi (Perlu Reimburse)</span>
                          </span>
                          <p className="text-[11px] text-slate-700 font-semibold leading-tight mt-0.5">
                            Centang jika nota ini Anda talangi pakai uang pribadi dan perlu diganti oleh kas event/tim.
                          </p>
                        </div>
                      </label>
                    </div>
                  </div>
                )}
              </div>

              {/* 7. Rincian Barang dari Struk (Jika Terdeteksi) */}
              {extractedItems.length > 0 && (
                <div className="space-y-2 pt-2 border-t-2 border-black">
                  <label className="text-xs font-black text-black flex items-center justify-between">
                    <span>Rincian Barang ({extractedItems.length} item):</span>
                    <span className="text-[10px] text-slate-700 font-semibold">Dapat diedit</span>
                  </label>
                  <div className="space-y-2 max-h-36 overflow-y-auto pr-1">
                    {extractedItems.map((item, idx) => (
                      <div
                        key={idx}
                        className="flex items-center gap-2 p-2 bg-white rounded-xl border-2 border-black text-xs shadow-[2px_2px_0px_0px_#000]"
                      >
                        <input
                          type="text"
                          value={item.item_name}
                          onChange={(e) => updateExtractedItem(idx, "item_name", e.target.value)}
                          className="flex-1 bg-white border border-black rounded-lg px-2 py-1 text-black font-bold"
                        />
                        <input
                          type="number"
                          min="1"
                          value={item.quantity}
                          onChange={(e) => updateExtractedItem(idx, "quantity", e.target.value)}
                          className="w-12 bg-white border border-black rounded-lg px-2 py-1 text-black font-bold text-center"
                        />
                        <span className="font-black text-black w-20 text-right">
                          {formatRupiah(item.total_price)}
                        </span>
                        <button
                          type="button"
                          onClick={() => removeExtractedItem(idx)}
                          className="text-black hover:text-rose-600 p-1"
                        >
                          <X className="w-3.5 h-3.5 stroke-[3]" />
                        </button>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
          )}

          {/* Manual & Voice Input Sections */}
          {method !== "ocr" && (
            <>
              {/* Scope selection for the transaction */}
              <div className="space-y-2">
                <label className="text-xs font-black text-black">Simpan ke Buku Catatan:</label>
                <div className="grid grid-cols-2 gap-2">
                  <button
                    type="button"
                    onClick={() => {
                      setTargetScope("personal");
                      setIsReimbursePending(false);
                    }}
                    className={`py-2 px-3 rounded-xl border-2 border-black text-xs sm:text-sm font-black transition-all shadow-[2px_2px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] ${
                      targetScope === "personal"
                        ? "bg-neo-yellow text-black"
                        : "bg-white text-black hover:bg-slate-100"
                    }`}
                  >
                    👤 Catatan Pribadi
                  </button>
                  <button
                    type="button"
                    onClick={() => setTargetScope("family")}
                    className={`py-2 px-3 rounded-xl border-2 border-black text-xs sm:text-sm font-black transition-all shadow-[2px_2px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] ${
                      targetScope === "family"
                        ? "bg-neo-yellow text-black"
                        : "bg-white text-black hover:bg-slate-100"
                    }`}
                  >
                    🎪 Kas Tim / Event
                  </button>
                </div>

                {targetScope === "family" && (
                  <div className="space-y-2 pt-1 animate-fade-in">
                    {userGroups.length > 0 ? (
                      <select
                        aria-label="Pilih grup kas event tujuan"
                        value={targetGroupId}
                        onChange={(e) => setTargetGroupId(e.target.value)}
                        className="w-full bg-white border-2 border-black rounded-xl px-3 py-2 text-xs sm:text-sm font-bold text-black shadow-[2px_2px_0px_0px_#000] outline-none"
                      >
                        {userGroups.map((g) => (
                          <option key={g.id} value={g.id}>
                            🎪 {g.name.replace(/Keluarga\s*Cemara/gi, "Panitia Event & Proyek")}
                          </option>
                        ))}
                      </select>
                    ) : (
                      <p className="text-xs text-rose-600 font-bold">
                        Anda belum memiliki grup kas event manapun.
                      </p>
                    )}

                    {/* Reimbursement Toggle if Expense */}
                    {type === "expense" && (
                      <div className="p-3 bg-amber-50/90 border-2 border-black rounded-xl shadow-[2px_2px_0px_0px_#000]">
                        <label className="flex items-start gap-2.5 cursor-pointer">
                          <input
                            type="checkbox"
                            checked={isReimbursePending}
                            onChange={(e) => setIsReimbursePending(e.target.checked)}
                            className="mt-0.5 w-4 h-4 rounded border-2 border-black accent-black cursor-pointer"
                          />
                          <div className="flex-1">
                            <span className="text-xs font-black text-black flex items-center gap-1.5">
                              <HandCoins className="w-3.5 h-3.5 text-black stroke-[2.5]" />
                              <span>Uang Talangan Pribadi (Perlu Reimburse)</span>
                            </span>
                            <p className="text-[11px] text-slate-700 font-semibold leading-tight mt-0.5">
                              Centang jika biaya ini Anda talangi pakai uang pribadi dan perlu diganti oleh kas event/tim.
                            </p>
                          </div>
                        </label>
                      </div>
                    )}
                  </div>
                )}
              </div>

              {/* Type Toggle: Pengeluaran vs Pemasukan */}
              <div className="grid grid-cols-2 gap-2 p-1.5 bg-white border-2 border-black rounded-2xl shadow-[3px_3px_0px_0px_#000]">
                <button
                  type="button"
                  onClick={() => setType("expense")}
                  className={`py-2.5 rounded-xl text-xs sm:text-sm font-black transition-all ${
                    type === "expense"
                      ? "bg-rose-400 text-black font-black border-2 border-black shadow-[2px_2px_0px_0px_#000]"
                      : "text-black hover:bg-slate-100 border-2 border-transparent"
                  } ${elderlyMode ? "py-3 text-base" : ""}`}
                >
                  {elderlyMode ? "Uang Keluar" : "Pengeluaran (-)"}
                </button>
                <button
                  type="button"
                  onClick={() => setType("income")}
                  className={`py-2.5 rounded-xl text-xs sm:text-sm font-black transition-all ${
                    type === "income"
                      ? "bg-neo-green text-black border-2 border-black shadow-[2px_2px_0px_0px_#000]"
                      : "text-black hover:bg-slate-100 border-2 border-transparent"
                  } ${elderlyMode ? "py-3 text-base" : ""}`}
                >
                  {elderlyMode ? "Uang Masuk" : "Pemasukan (+)"}
                </button>
              </div>

              {/* Nominal Input */}
              <div className="space-y-1.5">
                <div className="flex items-center justify-between">
                  <label className="text-xs font-black text-black">Jumlah Nominal:</label>
                  {amount && Number(amount.replace(/[^\d]/g, "")) > 0 && (
                    <span className="text-xs font-black text-black bg-neo-yellow px-2.5 py-0.5 rounded-lg border-2 border-black shadow-[1.5px_1.5px_0px_0px_#000]">
                      {formatRupiah(Number(amount.replace(/[^\d]/g, "")))}
                    </span>
                  )}
                </div>
                <div className="relative">
                  <span className="absolute left-4 top-1/2 -translate-y-1/2 text-black font-black text-lg sm:text-xl">
                    Rp
                  </span>
                  <input
                    type="text"
                    inputMode="numeric"
                    required
                    value={
                      amount && !isNaN(Number(amount.replace(/[^\d]/g, "")))
                        ? Number(amount.replace(/[^\d]/g, "")).toLocaleString("id-ID")
                        : ""
                    }
                    onChange={(e) => {
                      const digits = e.target.value.replace(/[^\d]/g, "");
                      setAmount(digits);
                    }}
                    placeholder="0"
                    className={`w-full bg-white border-2 border-black rounded-2xl pl-12 pr-4 py-3.5 text-xl sm:text-2xl font-black text-black shadow-[3px_3px_0px_0px_#000] outline-none transition-all ${
                      elderlyMode ? "py-4 text-2xl" : ""
                    }`}
                  />
                </div>

                {/* Quick Amount Chips */}
                <div className="flex items-center gap-1.5 flex-wrap pt-1">
                  {[10000, 20000, 50000, 100000, 500000].map((val) => (
                    <button
                      key={val}
                      type="button"
                      onClick={() => addQuickAmount(val)}
                      className="px-2.5 py-1 bg-white hover:bg-neo-yellow text-black text-xs font-bold rounded-lg border-2 border-black shadow-[1.5px_1.5px_0px_0px_#000] active:translate-x-[1px] active:translate-y-[1px] transition-all"
                    >
                      +{formatRupiah(val).replace("Rp", "").trim()}
                    </button>
                  ))}
                </div>
              </div>

              {/* Kategori */}
              <div className="space-y-1.5">
                <div className="flex items-center justify-between">
                  <label className="text-xs font-black text-black flex items-center gap-1">
                    <Tag className="w-3.5 h-3.5 text-black stroke-[2.5]" />
                    <span>Kategori {type === "expense" ? "Pengeluaran" : "Pemasukan"}:</span>
                  </label>
                  {categoryId !== "__custom__" ? (
                    <button
                      type="button"
                      onClick={() => {
                        setCategoryId("__custom__");
                        setCustomCategoryName("");
                      }}
                      className="text-[11px] text-black bg-neo-yellow hover:bg-[#FDE047] font-black px-2 py-0.5 rounded-lg border-2 border-black flex items-center gap-0.5 shadow-[1.5px_1.5px_0px_0px_#000] transition-all"
                    >
                      <Plus className="w-3 h-3 stroke-[3]" />
                      <span>+ Kategori Baru</span>
                    </button>
                  ) : (
                    <button
                      type="button"
                      onClick={() => {
                        setCategoryId(categories[0]?.id || "");
                        setCustomCategoryName("");
                      }}
                      className="text-[11px] text-black bg-white hover:bg-slate-100 font-bold px-2 py-0.5 rounded-lg border-2 border-black shadow-[1.5px_1.5px_0px_0px_#000] transition-all"
                    >
                      Batal (Pilih Daftar)
                    </button>
                  )}
                </div>

                {isLoadingCategories ? (
                  <div className="h-10 bg-slate-200 border-2 border-black rounded-xl animate-pulse" />
                ) : (
                  <div className="space-y-2">
                    <select
                      aria-label="Pilih kategori transaksi"
                      value={categoryId}
                      onChange={(e) => setCategoryId(e.target.value)}
                      required
                      className="w-full bg-white border-2 border-black rounded-xl px-3 py-2.5 text-sm font-bold text-black shadow-[2px_2px_0px_0px_#000] outline-none"
                    >
                      {categories.map((cat) => (
                        <option key={cat.id} value={cat.id}>
                          {cat.name}
                        </option>
                      ))}
                      <option value="__custom__">✨ + Ketik Kategori Baru Sendiri...</option>
                    </select>

                    {/* Input manual kategori baru jika dipilih */}
                    {categoryId === "__custom__" && (
                      <div className="p-3 bg-neo-yellowLight border-2 border-black rounded-xl space-y-1.5 shadow-[2px_2px_0px_0px_#000]">
                        <label className="text-[11px] font-black text-black flex items-center gap-1">
                          <Sparkles className="w-3.5 h-3.5 text-black stroke-[2.5]" />
                          <span>
                            Nama Kategori {type === "expense" ? "Pengeluaran" : "Pemasukan"} Baru:
                          </span>
                        </label>
                        <input
                          type="text"
                          required
                          value={customCategoryName}
                          onChange={(e) => setCustomCategoryName(e.target.value)}
                          placeholder={`Ketik nama kategori ${
                            type === "expense" ? "pengeluaran" : "pemasukan"
                          } baru...`}
                          className="w-full bg-white border-2 border-black rounded-lg px-3 py-2 text-xs sm:text-sm text-black font-bold shadow-[1.5px_1.5px_0px_0px_#000] outline-none"
                          autoFocus
                        />
                        <p className="text-[10px] text-slate-700 font-semibold">
                          Kategori ini akan otomatis tersimpan di akun Anda dan dapat dipakai lagi nanti.
                        </p>
                      </div>
                    )}
                  </div>
                )}
              </div>

              {/* Tanggal & Deskripsi */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div className="space-y-1.5">
                  <label className="text-xs font-black text-black flex items-center gap-1">
                    <Calendar className="w-3.5 h-3.5 text-black stroke-[2.5]" />
                    <span>Tanggal:</span>
                  </label>
                  <input
                    type="date"
                    required
                    value={date}
                    onChange={(e) => setDate(e.target.value)}
                    className="w-full bg-white border-2 border-black rounded-xl px-3 py-2 text-sm font-bold text-black shadow-[2px_2px_0px_0px_#000] outline-none"
                  />
                </div>

                <div className="space-y-1.5">
                  <label className="text-xs font-black text-black flex items-center gap-1">
                    <FileText className="w-3.5 h-3.5 text-black stroke-[2.5]" />
                    <span>Keterangan:</span>
                  </label>
                  <input
                    type="text"
                    placeholder={
                      method === "voice"
                        ? "Keterangan dari suara"
                        : "Contoh: Belanja mingguan"
                    }
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                    className="w-full bg-white border-2 border-black rounded-xl px-3 py-2 text-sm font-bold text-black shadow-[2px_2px_0px_0px_#000] outline-none"
                  />
                </div>
              </div>
            </>
          )}

          {/* Submit Button */}
          <div className="pt-2">
            <button
              type="submit"
              disabled={isSubmitting || isScanningOCR || isParsingVoice}
              className={`w-full bg-neo-yellow hover:bg-[#FDE047] active:translate-x-[2px] active:translate-y-[2px] active:shadow-[1px_1px_0px_0px_#000] text-black font-black rounded-xl py-3.5 px-4 flex items-center justify-center gap-2 border-2 border-black shadow-[4px_4px_0px_0px_#000] transition-all ${
                isSubmitting || isScanningOCR || isParsingVoice ? "opacity-70 cursor-not-allowed" : ""
              } ${elderlyMode ? "py-4 text-lg" : "text-sm"}`}
            >
              <Check className="w-5 h-5 stroke-[3]" />
              <span>
                {isSubmitting
                  ? "Menyimpan Transaksi..."
                  : method === "ocr" && receiptId
                  ? "Konfirmasi & Simpan Transaksi Struk"
                  : method === "voice"
                  ? "Konfirmasi & Simpan Transaksi Suara"
                  : "Simpan Transaksi"}
              </span>
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
