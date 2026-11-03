export interface User {
  id: string;
  name: string;
  email: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface AuthResponse {
  access_token: string;
  token_type: string;
  expires_in: number;
  user: User;
}

export interface Category {
  id: string;
  name: string;
  type: "income" | "expense";
  icon?: string;
  color?: string;
  is_system: boolean;
  user_id?: string;
  group_id?: string;
}

export interface Transaction {
  id: string;
  type: "income" | "expense";
  amount: number | string;
  category_id: string;
  category?: Category;
  transaction_date: string;
  description?: string;
  notes?: string;
  owner_user_id?: string;
  group_id?: string;
  created_by_user_id: string;
  input_method: "manual" | "ocr" | "voice";
  receipt_id?: string;
  created_at: string;
}

export interface TransactionItem {
  id?: string;
  item_name: string;
  quantity: number;
  price_per_unit: number;
  total_price: number;
}

export interface Receipt {
  id: string;
  user_id: string;
  group_id?: string;
  file_name: string;
  file_size: number;
  mime_type: string;
  merchant_name?: string;
  receipt_date?: string;
  total_amount?: number | string;
  status: "draft" | "confirmed" | "rejected" | "failed";
  items: TransactionItem[];
  created_at: string;
  updated_at: string;
}

export interface VoiceParseResult {
  raw_text: string;
  type: "expense" | "income";
  amount?: number | string;
  description?: string;
  suggested_category_name?: string;
  suggested_category_id?: string;
  confidence_score: number;
}

export interface PaginatedTransactions {
  items: Transaction[];
  total: number;
  page: number;
  page_size: number;
  total_pages: number;
}

export interface CategoryBreakdown {
  category_id: string;
  category_name: string;
  category_icon?: string;
  category_color?: string;
  total_amount: number | string;
  percentage: number;
  transaction_count: number;
}

export interface PersonalDashboard {
  total_income: number | string;
  total_expense: number | string;
  net_balance: number | string;
  recent_transactions: Transaction[];
  expense_by_category: CategoryBreakdown[];
  income_by_category: CategoryBreakdown[];
  start_date?: string;
  end_date?: string;
}

export interface Group {
  id: string;
  name: string;
  description?: string;
  created_by_user_id: string;
  is_active: boolean;
  user_role?: "owner" | "admin" | "member";
  members_count: number;
  created_at: string;
  updated_at: string;
}

export interface GroupMember {
  id: string;
  user_id: string;
  user_name: string;
  user_email: string;
  role: "owner" | "admin" | "member";
  joined_at: string;
  is_active: boolean;
}

export interface MemberContribution {
  user_id: string;
  user_name: string;
  total_expense: number | string;
  total_income: number | string;
  transaction_count: number;
}

export interface GroupDashboard {
  group_id: string;
  group_name: string;
  total_income: number | string;
  total_expense: number | string;
  net_balance: number | string;
  recent_transactions: Transaction[];
  expense_by_category: CategoryBreakdown[];
  income_by_category: CategoryBreakdown[];
  member_contributions: MemberContribution[];
  start_date?: string;
  end_date?: string;
}
