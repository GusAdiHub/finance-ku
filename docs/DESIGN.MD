# DESIGN SYSTEM & UI SPECIFICATION
## Personal & Family Finance Tracker (PWA)

### 1. Core Visual Identity
- **Theme:** Soft & Modern Blue (Clean, high readability for youth & elderly users).
- **Font Family:** `Poppins` (Google Fonts) — Weights: 400 (Regular), 500 (Medium), 600 (SemiBold), 700 (Bold).
- **Icons:** `lucide-react` (stroke-width: 2px, consistent sizing: 20px standard, 24px primary actions).
- **Corner Radius (Strict Rounded UI):**
  - Main Cards & Modals: `rounded-2xl` (16px) to `rounded-3xl` (24px).
  - Buttons, Inputs & Dropdowns: `rounded-xl` (12px).
  - Badges & Pills: `rounded-full`.
  - Avoid sharp edges across all tables, cards, and action controls.

### 2. Color Palette (Tailwind CSS Mapping)
- **App Background:** `#F8FAFC` (`bg-slate-50`)
- **Card / Surface:** `#FFFFFF` (`bg-white`) with soft border `#E2E8F0` (`border-slate-200/80`) and subtle shadow (`shadow-sm`).
- **Primary Brand (Soft Royal Blue):**
  - Main Action / Active State: `#2563EB` (`bg-blue-600`, hover `bg-blue-700`)
  - Soft Surface / Highlight: `#EFF6FF` (`bg-blue-50`)
  - Muted Border / Accent: `#DBEAFE` (`border-blue-100`, `text-blue-700`)
- **Semantic Finance Colors:**
  - Income (Pemasukan): `#059669` (`text-emerald-600`), Surface `#ECFDF5` (`bg-emerald-50`)
  - Expense (Pengeluaran): `#E11D48` (`text-rose-600`), Surface `#FFF1F2` (`bg-rose-50`)
  - OCR / Voice Draft Warning: `#D97706` (`text-amber-600`), Surface `#FFFBEB` (`bg-amber-50`)
- **Typography Colors:**
  - Primary Text: `#0F172A` (`text-slate-900`)
  - Secondary Text: `#475569` (`text-slate-600`)
  - Muted / Caption: `#94A3B8` (`text-slate-400`)

### 3. Ergonomics & Dual-Target Accessibility (Youth & Parents)
- **Touch Targets:** Minimum height `48px` (`min-h-[48px]`) for all interactive buttons, inputs, and navigation items.
- **Elderly-Friendly Mode (Mode Ramah Orang Tua):** Support a global toggle that scales base font size up (`text-base` to `text-lg`) and increases button padding.
- **Currency Formatting:** Strictly Indonesian Rupiah (`Rp 1.500.000`) with clear `+` / `-` prefixes and semantic colors.

### 4. Layout & Navigation Architecture (Mobile-First PWA)
- **Desktop (`lg:` and up):** Left fixed Sidebar (`w-64`) with rounded navigation pills + Main content container (`max-w-5xl mx-auto`).
- **Mobile (`< lg`):**
  - Top Sticky Header containing Scope Switcher (`Pribadi` vs `Grup Keluarga`) and Group Selector dropdown.
  - Bottom Navigation Bar (`h-16`) with 5 thumb-friendly slots: `Beranda`, `Riwayat`, prominent floating `+ Catat` button, `Keluarga`, `Profil`.
  - Modals behave as **Bottom Sheets** (`rounded-t-3xl`) on mobile and centered modals (`rounded-2xl`) on desktop.

### 5. Key Component Patterns
- **Scope Switcher:** Segmented pill toggle at the top to strictly separate Personal Finance (`owner_user_id`) and Family Group Finance (`group_id`).
- **Quick Input Banner:** 3 prominent action cards with large Lucide icons for `Ketik Manual`, `Foto Struk (OCR)`, and `Pesan Suara (Voice)`.
- **Draft Confirmation Card (OCR & Voice):** Before saving OCR/Voice inputs, display a review state with a "Draft Konfirmasi" badge allowing users to edit store name, date, category, and amount.
- **Transaction List:** Use responsive stacked rounded cards instead of cramped horizontal-scrolling tables on mobile. Each card displays category icon, title, creator badge (for family scope), input method badge (`Manual`/`OCR`/`Suara`), date, and nominal.