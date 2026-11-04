const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://127.0.0.1:8000/api/v1";

class ApiClient {
  private getHeaders(): HeadersInit {
    const headers: Record<string, string> = {
      "Content-Type": "application/json",
    };
    if (typeof window !== "undefined") {
      const token = localStorage.getItem("token");
      if (token) {
        headers["Authorization"] = `Bearer ${token}`;
      }
    }
    return headers;
  }

  private async request<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
    const url = `${API_BASE_URL}${endpoint}`;
    const headers = { ...this.getHeaders(), ...options.headers };

    const response = await fetch(url, { ...options, headers });

    if (response.status === 401) {
      if (typeof window !== "undefined" && !window.location.pathname.startsWith("/login")) {
        localStorage.removeItem("token");
        localStorage.removeItem("user");
        window.location.href = "/login";
      }
    }

    if (!response.ok) {
      let errorDetail = "An unexpected error occurred.";
      try {
        const errorData = await response.json();
        errorDetail = errorData.detail || errorDetail;
      } catch {
        // Ignored
      }
      throw new Error(errorDetail);
    }

    return response.json();
  }

  // Auth Endpoints
  async register(data: any) {
    return this.request<any>("/auth/register", {
      method: "POST",
      body: JSON.stringify(data),
    });
  }

  async login(data: any) {
    return this.request<any>("/auth/login", {
      method: "POST",
      body: JSON.stringify(data),
    });
  }

  async logout() {
    return this.request<any>("/auth/logout", { method: "POST" });
  }

  async getMe() {
    return this.request<any>("/auth/me");
  }

  async updateMe(data: any) {
    return this.request<any>("/auth/me", {
      method: "PATCH",
      body: JSON.stringify(data),
    });
  }

  async changePassword(data: any) {
    return this.request<any>("/auth/change-password", {
      method: "POST",
      body: JSON.stringify(data),
    });
  }

  // Categories
  async getCategories(type?: string) {
    const query = type ? `?type=${type}` : "";
    return this.request<any[]>(`/categories${query}`);
  }

  async createCategory(data: any) {
    return this.request<any>("/categories", {
      method: "POST",
      body: JSON.stringify(data),
    });
  }

  async deleteCategory(id: string) {
    return this.request<any>(`/categories/${id}`, { method: "DELETE" });
  }

  // Transactions (Personal)
  async getTransactions(params?: Record<string, any>) {
    const query = params ? "?" + new URLSearchParams(params).toString() : "";
    return this.request<any>(`/transactions${query}`);
  }

  async createTransaction(data: any) {
    return this.request<any>("/transactions", {
      method: "POST",
      body: JSON.stringify(data),
    });
  }

  async deleteTransaction(id: string) {
    return this.request<any>(`/transactions/${id}`, { method: "DELETE" });
  }

  // Dashboard & Reports (Personal)
  async getPersonalDashboard() {
    return this.request<any>("/dashboard/personal");
  }

  async getPersonalReport(params?: string | { period?: string; start_date?: string; end_date?: string }) {
    if (typeof params === "string") {
      return this.request<any>(`/reports/personal?period=${params}`);
    }
    const cleanParams: Record<string, string> = {};
    if (params) {
      if (params.period) cleanParams.period = params.period;
      if (params.start_date) cleanParams.start_date = params.start_date;
      if (params.end_date) cleanParams.end_date = params.end_date;
    }
    const query = Object.keys(cleanParams).length > 0 ? "?" + new URLSearchParams(cleanParams).toString() : "";
    return this.request<any>(`/reports/personal${query}`);
  }

  // Groups
  async getGroups() {
    return this.request<any[]>("/groups");
  }

  async createGroup(data: any) {
    return this.request<any>("/groups", {
      method: "POST",
      body: JSON.stringify(data),
    });
  }

  async getGroupDetail(groupId: string) {
    return this.request<any>(`/groups/${groupId}`);
  }

  async updateGroup(groupId: string, data: { name?: string; description?: string }) {
    return this.request<any>(`/groups/${groupId}`, {
      method: "PATCH",
      body: JSON.stringify(data),
    });
  }

  async joinGroup(code: string) {
    return this.request<any>("/groups/join", {
      method: "POST",
      body: JSON.stringify({ code }),
    });
  }

  async leaveGroup(groupId: string) {
    return this.request<any>(`/groups/${groupId}/leave`, { method: "POST" });
  }

  async deleteGroup(groupId: string) {
    return this.request<any>(`/groups/${groupId}`, { method: "DELETE" });
  }

  async getGroupMembers(groupId: string) {
    return this.request<any[]>(`/groups/${groupId}/members`);
  }

  async createInvitation(groupId: string, data = { expires_in_days: 7, max_uses: 5 }) {
    return this.request<any>(`/groups/${groupId}/invitations`, {
      method: "POST",
      body: JSON.stringify(data),
    });
  }

  // Group Shared Transactions & Dashboard
  async getGroupTransactions(groupId: string, params?: Record<string, any>) {
    const query = params ? "?" + new URLSearchParams(params).toString() : "";
    return this.request<any>(`/groups/${groupId}/transactions${query}`);
  }

  async createGroupTransaction(groupId: string, data: any) {
    return this.request<any>(`/groups/${groupId}/transactions`, {
      method: "POST",
      body: JSON.stringify(data),
    });
  }

  async updateGroupTransaction(groupId: string, transactionId: string, data: any) {
    return this.request<any>(`/groups/${groupId}/transactions/${transactionId}`, {
      method: "PATCH",
      body: JSON.stringify(data),
    });
  }

  async deleteGroupTransaction(groupId: string, transactionId: string) {
    return this.request<any>(`/groups/${groupId}/transactions/${transactionId}`, {
      method: "DELETE",
    });
  }

  async getGroupDashboard(groupId: string) {
    return this.request<any>(`/groups/${groupId}/dashboard`);
  }

  async getGroupReport(groupId: string, params?: string | { period?: string; start_date?: string; end_date?: string }) {
    if (typeof params === "string") {
      return this.request<any>(`/groups/${groupId}/reports?period=${params}`);
    }
    const cleanParams: Record<string, string> = {};
    if (params) {
      if (params.period) cleanParams.period = params.period;
      if (params.start_date) cleanParams.start_date = params.start_date;
      if (params.end_date) cleanParams.end_date = params.end_date;
    }
    const query = Object.keys(cleanParams).length > 0 ? "?" + new URLSearchParams(cleanParams).toString() : "";
    return this.request<any>(`/groups/${groupId}/reports${query}`);
  }

  // Receipts & OCR Endpoints
  async uploadReceipt(file: File, groupId?: string, merchantName?: string) {
    const formData = new FormData();
    formData.append("file", file);
    if (groupId) {
      formData.append("group_id", groupId);
    }
    if (merchantName) {
      formData.append("merchant_name", merchantName);
    }
    const token = typeof window !== "undefined" ? localStorage.getItem("token") : null;
    const response = await fetch(`${API_BASE_URL}/receipts`, {
      method: "POST",
      headers: {
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
      body: formData,
    });
    if (!response.ok) {
      let errorMsg = "Gagal mengunggah struk.";
      try {
        const data = await response.json();
        errorMsg = data.detail || errorMsg;
      } catch {}
      throw new Error(errorMsg);
    }
    return response.json();
  }

  async getReceipt(id: string) {
    return this.request<any>(`/receipts/${id}`);
  }

  async getReceiptImageBlobUrl(id: string): Promise<string> {
    const url = `${API_BASE_URL}/receipts/${id}/file`;
    const response = await fetch(url, { headers: this.getHeaders() });
    if (!response.ok) {
      throw new Error("Gagal memuat file foto bukti nota.");
    }
    const blob = await response.blob();
    return URL.createObjectURL(blob);
  }

  async confirmReceipt(id: string, data: any) {
    return this.request<any>(`/receipts/${id}/confirm`, {
      method: "POST",
      body: JSON.stringify(data),
    });
  }

  async deleteReceipt(id: string) {
    return this.request<any>(`/receipts/${id}`, { method: "DELETE" });
  }

  // Voice Input Endpoints
  async parseVoice(text: string) {
    return this.request<any>("/voice/parse", {
      method: "POST",
      body: JSON.stringify({ text }),
    });
  }
}

export const api = new ApiClient();
