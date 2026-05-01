import { useState } from "react";
import { Routes, Route, Navigate } from "react-router-dom";
import { DashboardLayout } from "@/components/DashboardLayout";
import { mockVendorSales, mockSettlements } from "@/lib/mock";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { toast } from "sonner";
import { auth } from "@/lib/api";
import { TrendingUp, Receipt, Package, Wallet, ArrowUpRight } from "lucide-react";

const nav = [
  { to: "/vendor", label: "Overview" },
  { to: "/vendor/sales", label: "Sales" },
  { to: "/vendor/inventory", label: "Inventory" },
  { to: "/vendor/settlements", label: "Settlements" },
];

const Wrap = ({ children }: { children: React.ReactNode }) => (
  <DashboardLayout role="vendor" nav={nav}>{children}</DashboardLayout>
);

const Overview = () => {
  const sales = mockVendorSales();
  const today = sales[0]?.amount ?? 0;
  const week = sales.slice(0, 7).reduce((s, r) => s + r.amount, 0);
  const pending = mockSettlements.filter((s) => s.status === "PENDING").reduce((s, r) => s + r.amount, 0);

  const stats = [
    { label: "Today's revenue", value: `₹${today}`, icon: TrendingUp, grad: "bg-gradient-primary" },
    { label: "This week", value: `₹${week}`, icon: Receipt, grad: "bg-gradient-accent" },
    { label: "Pending settlement", value: `₹${pending}`, icon: Wallet, grad: "bg-gradient-hero" },
  ];

  return (
    <Wrap>
      <div className="mb-8">
        <h1 className="text-3xl font-bold">Welcome back 👋</h1>
        <p className="text-muted-foreground">Here's how your shop is doing today</p>
      </div>
      <div className="grid sm:grid-cols-3 gap-4 mb-8">
        {stats.map((s) => (
          <div key={s.label} className="rounded-2xl border bg-card p-6 shadow-card">
            <div className={`h-11 w-11 rounded-xl ${s.grad} flex items-center justify-center text-primary-foreground mb-4`}>
              <s.icon className="h-5 w-5" />
            </div>
            <p className="text-sm text-muted-foreground">{s.label}</p>
            <p className="text-3xl font-bold mt-1">{s.value}</p>
          </div>
        ))}
      </div>

      <div className="grid md:grid-cols-2 gap-4">
        <a href="/vendor/sales" className="group rounded-2xl border bg-card p-6 shadow-card hover:shadow-glow transition-smooth hover:-translate-y-1 flex items-center justify-between">
          <div>
            <p className="text-sm text-muted-foreground mb-1">Sales history</p>
            <p className="font-bold text-lg">View every transaction</p>
          </div>
          <ArrowUpRight className="h-5 w-5 text-muted-foreground group-hover:text-primary" />
        </a>
        <a href="/vendor/settlements" className="group rounded-2xl border bg-card p-6 shadow-card hover:shadow-glow transition-smooth hover:-translate-y-1 flex items-center justify-between">
          <div>
            <p className="text-sm text-muted-foreground mb-1">Request settlement</p>
            <p className="font-bold text-lg">Cash out your earnings</p>
          </div>
          <ArrowUpRight className="h-5 w-5 text-muted-foreground group-hover:text-primary" />
        </a>
      </div>
    </Wrap>
  );
};

const Sales = () => {
  const sales = mockVendorSales();
  const total = sales.reduce((s, r) => s + r.amount, 0);
  return (
    <Wrap>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-3xl font-bold">Sales history</h1>
          <p className="text-muted-foreground">Bills issued to students</p>
        </div>
        <div className="text-right">
          <p className="text-sm text-muted-foreground">Total</p>
          <p className="text-2xl font-bold text-primary">₹{total.toLocaleString()}</p>
        </div>
      </div>
      <div className="rounded-2xl border bg-card shadow-card overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-muted/50 text-left">
            <tr>
              <th className="p-4 font-medium">Bill #</th>
              <th className="p-4 font-medium">Date</th>
              <th className="p-4 font-medium">Student</th>
              <th className="p-4 font-medium">Status</th>
              <th className="p-4 font-medium text-right">Amount</th>
            </tr>
          </thead>
          <tbody>
            {sales.map((r) => (
              <tr key={r.bill_id} className="border-t hover:bg-muted/30 transition-smooth">
                <td className="p-4 font-mono text-xs">#{r.bill_id}</td>
                <td className="p-4">{r.date}</td>
                <td className="p-4">Student #{r.student_id}</td>
                <td className="p-4">
                  <Badge className={r.status === "completed" ? "bg-success text-success-foreground" : "bg-muted text-muted-foreground"}>
                    {r.status}
                  </Badge>
                </td>
                <td className="p-4 text-right font-semibold">₹{r.amount}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      {/* TODO: wire to /vendors/{id}/sales endpoint */}
    </Wrap>
  );
};

interface InvRow { item_id: number; name: string; cost: number; in_stock: boolean }
const initialInventory: InvRow[] = [
  { item_id: 1, name: "Cheese Sandwich", cost: 60, in_stock: true },
  { item_id: 2, name: "Cold Coffee", cost: 50, in_stock: true },
  { item_id: 6, name: "Samosa", cost: 20, in_stock: false },
];

const Inventory = () => {
  const [items, setItems] = useState(initialInventory);
  const update = (id: number, patch: Partial<InvRow>) => {
    setItems(items.map((i) => (i.item_id === id ? { ...i, ...patch } : i)));
  };
  const save = (item: InvRow) => {
    // TODO: call update_vendor_inventory via /vendors/{vid}/inventory/{iid}
    toast.success(`Updated ${item.name}`);
  };
  return (
    <Wrap>
      <div className="mb-6">
        <h1 className="text-3xl font-bold">Inventory</h1>
        <p className="text-muted-foreground">Manage prices and stock for your items</p>
      </div>
      <div className="grid md:grid-cols-2 gap-4">
        {items.map((it) => (
          <div key={it.item_id} className="rounded-2xl border bg-card p-6 shadow-card">
            <div className="flex items-center gap-3 mb-4">
              <div className="h-10 w-10 rounded-xl bg-gradient-warm flex items-center justify-center text-primary">
                <Package className="h-5 w-5" />
              </div>
              <div>
                <p className="font-bold">{it.name}</p>
                <p className="text-xs text-muted-foreground">Item #{it.item_id}</p>
              </div>
            </div>
            <div className="grid grid-cols-2 gap-3 mb-4">
              <div>
                <Label>Price (₹)</Label>
                <Input type="number" value={it.cost} onChange={(e) => update(it.item_id, { cost: Number(e.target.value) })} />
              </div>
              <div>
                <Label>Status</Label>
                <button
                  type="button"
                  onClick={() => update(it.item_id, { in_stock: !it.in_stock })}
                  className={`w-full h-10 rounded-md border font-medium text-sm ${
                    it.in_stock ? "bg-success/10 text-success border-success/40" : "bg-muted text-muted-foreground"
                  }`}
                >
                  {it.in_stock ? "In stock" : "Out of stock"}
                </button>
              </div>
            </div>
            <Button onClick={() => save(it)} className="w-full bg-gradient-accent text-accent-foreground border-0">
              Save changes
            </Button>
          </div>
        ))}
      </div>
    </Wrap>
  );
};

const Settlements = () => {
  const session = auth.get()!;
  const [list, setList] = useState(mockSettlements.filter((s) => s.vendor_id === session.userId).length
    ? mockSettlements.filter((s) => s.vendor_id === session.userId)
    : mockSettlements.slice(0, 3));
  const pending = list.filter((s) => s.status === "PENDING").reduce((s, r) => s + r.amount, 0);

  const request = () => {
    // TODO: call request_settlement(vendor_id) via /vendors/{id}/settlements
    const newOne = {
      settlement_id: Math.max(...list.map((l) => l.settlement_id)) + 1,
      vendor_id: session.userId,
      vendor_name: "Your shop",
      amount: Math.round(1000 + Math.random() * 4000),
      date: new Date().toISOString().slice(0, 10),
      status: "PENDING" as const,
    };
    setList([newOne, ...list]);
    toast.success(`Settlement #${newOne.settlement_id} requested`);
  };

  return (
    <Wrap>
      <div className="grid md:grid-cols-[1fr_auto] gap-4 items-end mb-6">
        <div>
          <h1 className="text-3xl font-bold">Settlements</h1>
          <p className="text-muted-foreground">Request payouts for your unsettled bills</p>
        </div>
        <Button onClick={request} className="h-12 bg-gradient-primary text-primary-foreground border-0 shadow-soft hover:shadow-glow transition-smooth">
          Request settlement
        </Button>
      </div>

      <div className="rounded-2xl bg-gradient-warm p-6 mb-6">
        <p className="text-sm text-muted-foreground">Pending payout</p>
        <p className="text-4xl font-bold text-primary">₹{pending.toLocaleString()}</p>
      </div>

      <div className="rounded-2xl border bg-card shadow-card overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-muted/50 text-left">
            <tr>
              <th className="p-4 font-medium">Settlement #</th>
              <th className="p-4 font-medium">Date</th>
              <th className="p-4 font-medium">Status</th>
              <th className="p-4 font-medium text-right">Amount</th>
            </tr>
          </thead>
          <tbody>
            {list.map((s) => (
              <tr key={s.settlement_id} className="border-t hover:bg-muted/30">
                <td className="p-4 font-mono text-xs">#{s.settlement_id}</td>
                <td className="p-4">{s.date}</td>
                <td className="p-4">
                  <Badge className={s.status === "paid" ? "bg-success text-success-foreground" : "bg-warning text-warning-foreground"}>
                    {s.status}
                  </Badge>
                </td>
                <td className="p-4 text-right font-semibold">₹{s.amount.toLocaleString()}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </Wrap>
  );
};

const VendorDashboard = () => (
  <Routes>
    <Route index element={<Overview />} />
    <Route path="sales" element={<Sales />} />
    <Route path="inventory" element={<Inventory />} />
    <Route path="settlements" element={<Settlements />} />
    <Route path="*" element={<Navigate to="/vendor" replace />} />
  </Routes>
);

export default VendorDashboard;
