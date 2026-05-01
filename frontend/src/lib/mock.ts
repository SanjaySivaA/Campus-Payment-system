// TODO: Replace with real API endpoints once backend exposes them.
// Mock data for screens whose endpoints don't exist yet.

export interface PriceRow {
  vendor_id: number;
  vendor_name: string;
  cost: number;
  in_stock: boolean;
  last_updated: string;
}

export const mockItems = [
  { item_id: 1, name: "Cheese Sandwich" },
  { item_id: 2, name: "Cold Coffee" },
  { item_id: 3, name: "Maggi" },
  { item_id: 4, name: "Notebook (200pg)" },
  { item_id: 5, name: "Printout (B/W)" },
  { item_id: 6, name: "Samosa" },
];

export function mockPrices(itemId: number): PriceRow[] {
  const base = 30 + (itemId % 7) * 12;
  return [
    { vendor_id: 1, vendor_name: "Campus Canteen", cost: base, in_stock: true, last_updated: new Date().toISOString() },
    { vendor_id: 2, vendor_name: "Hostel Mess Cafe", cost: base + 8, in_stock: true, last_updated: new Date().toISOString() },
    { vendor_id: 3, vendor_name: "Quick Bites", cost: base - 4, in_stock: false, last_updated: new Date().toISOString() },
    { vendor_id: 4, vendor_name: "North Block Stall", cost: base + 2, in_stock: true, last_updated: new Date().toISOString() },
  ];
}

export interface VendorSale {
  bill_id: number;
  date: string;
  student_id: number;
  amount: number;
  status: "completed" | "refunded";
}

export function mockVendorSales(): VendorSale[] {
  const days = 12;
  return Array.from({ length: days }).map((_, i) => ({
    bill_id: 1000 + i,
    date: new Date(Date.now() - i * 86400000).toISOString().slice(0, 10),
    student_id: 100 + ((i * 7) % 30),
    amount: Math.round(40 + Math.random() * 260),
    status: i === 3 ? "refunded" : "completed",
  }));
}

export interface Settlement {
  settlement_id: number;
  vendor_id: number;
  vendor_name: string;
  amount: number;
  date: string;
  status: "PENDING" | "paid";
}

export const mockSettlements: Settlement[] = [
  { settlement_id: 1, vendor_id: 1, vendor_name: "Campus Canteen", amount: 12480, date: "2026-04-28", status: "PENDING" },
  { settlement_id: 2, vendor_id: 2, vendor_name: "Hostel Mess Cafe", amount: 8920, date: "2026-04-27", status: "PENDING" },
  { settlement_id: 3, vendor_id: 4, vendor_name: "North Block Stall", amount: 5340, date: "2026-04-25", status: "paid" },
  { settlement_id: 4, vendor_id: 3, vendor_name: "Quick Bites", amount: 3210, date: "2026-04-30", status: "PENDING" },
];
