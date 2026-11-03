"use client";

import React, { createContext, useContext, useState } from "react";

interface ModalOptions {
  type?: "income" | "expense";
  inputMethod?: "manual" | "ocr" | "voice";
  onSuccess?: () => void;
}

interface ModalContextType {
  isOpen: boolean;
  options: ModalOptions;
  openTransactionModal: (opts?: ModalOptions) => void;
  closeTransactionModal: () => void;
}

const ModalContext = createContext<ModalContextType | undefined>(undefined);

export function ModalProvider({ children }: { children: React.ReactNode }) {
  const [isOpen, setIsOpen] = useState(false);
  const [options, setOptions] = useState<ModalOptions>({});

  const openTransactionModal = (opts?: ModalOptions) => {
    setOptions(opts || {});
    setIsOpen(true);
  };

  const closeTransactionModal = () => {
    setIsOpen(false);
    setOptions({});
  };

  return (
    <ModalContext.Provider
      value={{
        isOpen,
        options,
        openTransactionModal,
        closeTransactionModal,
      }}
    >
      {children}
    </ModalContext.Provider>
  );
}

export function useModal() {
  const context = useContext(ModalContext);
  if (!context) {
    throw new Error("useModal must be used within a ModalProvider");
  }
  return context;
}
