// Backend client for FastAPI server
export const API_URL = "http://localhost:8000";

export type Role = "student" | "vendor" | "admin";

export interface AuthSession {
  token: string;
  role: Role;
  userId: number;
}

export interface PriceRow {
  vendor_id: number;
  vendor_name: string;
  cost: number;
  in_stock: boolean;
  last_updated: string;
}

export interface VendorSale {
  bill_id: number;
  date: string;
  student_id: number;
  amount: number;
  status: "completed" | "refunded";
}

export interface Settlement {
  settlement_id: number;
  vendor_id: number;
  vendor_name: string;
  amount: number;
  date: string;
  status: "PENDING" | "paid";
}

const STORAGE_KEY = "campus_auth";

export const auth = {
  get(): AuthSession | null {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? JSON.parse(raw) : null;
  },
  set(s: AuthSession) {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(s));
  },
  clear() {
    localStorage.removeItem(STORAGE_KEY);
  },
};

function decodeJwt(token: string): { sub?: string; role?: string } {
  try {
    const payload = token.split(".")[1];
    return JSON.parse(atob(payload.replace(/-/g, "+").replace(/_/g, "/")));
  } catch {
    return {};
  }
}

async function request<T>(path: string, opts: RequestInit = {}): Promise<T> {
  const session = auth.get();
  const res = await fetch(`${API_URL}${path}`, {
    ...opts,
    headers: {
      "Content-Type": "application/json",
      ...(session ? { Authorization: `Bearer ${session.token}` } : {}),
      ...(opts.headers || {}),
    },
  });
  if (!res.ok) {
    let detail = `Request failed (${res.status})`;
    try {
      const j = await res.json();
      detail = j.detail || detail;
    } catch {}
    throw new Error(detail);
  }
  if (res.status === 204) return undefined as T;
  return res.json();
}

export const api = {
  login: async (user_id: number, password: string, role: Role) => {
    const data = await request<{ access_token: string; token_type: string }>(
      "/login",
      { method: "POST", body: JSON.stringify({ user_id, password, role }) }
    );
    const claims = decodeJwt(data.access_token);
    const session: AuthSession = {
      token: data.access_token,
      role: (claims.role as Role) || role,
      userId: Number(claims.sub) || user_id,
    };
    auth.set(session);
    return session;
  },

  signupStudent: (payload: {
    student_id: number;
    first_name: string;
    last_name: string;
    email: string;
    phone: string;
    password: string;
    weekly_spending_limit: number;
  }) =>
    request<{ message: string; student_id: number }>("/signup/student", {
      method: "POST",
      body: JSON.stringify(payload),
    }),

  signupVendor: (payload: {
    vendor_id: number;
    name: string;
    email: string;
    phone: string;
    password: string;
  }) =>
    request<{ message: string; vendor_id: number }>("/signup/vendor", {
      method: "POST",
      body: JSON.stringify(payload),
    }),

  getStudentProfile: (studentId: number) =>
    request<{
      student_id: number;
      first_name: string;
      last_name: string;
      email: string;
      phone: string;
      balance: number;
      spending_limit: number;
    }>(`/students/${studentId}`),

  getStatement: (studentId: number) =>
    request<
      Array<{
        bill_id: number;
        date: string;
        vendor_id: number;
        vendor_name: string;
        amount: number;
      }>
    >(`/students/${studentId}/statement`),

  recharge: (studentId: number, amount: number) =>
    request<{ message: string; recharge_id: number }>(`/students/${studentId}/recharge`, {
      method: "POST",
      body: JSON.stringify({ amount }),
    }),

  comparePrices: (itemId: number) =>
    request<PriceRow[]>(`/items/${itemId}/prices`),

  getVendorSales: (vendorId: number) =>
    request<VendorSale[]>(`/vendors/${vendorId}/sales`),

  updateInventory: (vendorId: number, itemId: number, cost: number, inStock: boolean) =>
    request<{ message: string }>(`/vendors/${vendorId}/inventory/${itemId}`, {
      method: "PUT",
      body: JSON.stringify({ cost, in_stock: inStock }),
    }),

  requestSettlement: (vendorId: number) =>
    request<{ settlement_id: number; message: string }>(`/vendors/${vendorId}/settlements`, {
      method: "POST",
    }),

  getAllSettlements: () =>
    request<Settlement[]>("/admin/settlements"),

  approveSettlement: (settlementId: number, adminId: number) =>
    request<{ message: string }>(`/admin/settlements/${settlementId}/approve?admin_id=${adminId}`, {
      method: "POST",
    }),
};