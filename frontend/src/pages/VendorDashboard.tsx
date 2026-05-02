import { useState, useEffect } from "react";
import { Routes, Route, Navigate } from "react-router-dom";
import { DashboardLayout } from "@/components/DashboardLayout";
import { api, auth, VendorSale, Settlement } from "@/lib/api";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { toast } from "sonner";
import { TrendingUp, Receipt, Package, Wallet, ArrowUpRight, Loader2 } from "lucide-react";

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
  const session = auth.get()!;
  const [sales, setSales] = useState<VendorSale[]>([]);
  const [pending, setPending] = useState(0);

  useEffect(() => {
    api.getVendorSales(session.userId).then(setSales).catch(console.error);
    api.getAllSettlements()
      .then((data) => setPending(data.filter(s => s.vendor_id === session.userId && s.status === "PENDING").reduce((sum, r) => sum + Number(r.amount), 0)))
      .catch(console.error);
  }, [session.userId]);

  const today = sales.length > 0 ? sales[0].amount : 0;
  const week = sales.slice(0, 7).reduce((sum, r) => sum + Number(r.amount), 0);

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
  const session = auth.get()!;
  const [sales, setSales] = useState<VendorSale[]>([]);

  useEffect(() => {
    api.getVendorSales(session.userId)
      .then(setSales)
      .catch((e) => toast.error("Failed to load sales: " + e.message));
  }, [session.userId]);

  const total = sales.reduce((s, r) => s + Number(r.amount), 0);

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
                <td className="p-4">{new Date(r.date).toLocaleDateString()}</td>
                <td className="p-4">Student #{r.student_id}</td>
                <td className="p-4">
                  <Badge className={r.status === "completed" ? "bg-success text-success-foreground" : "bg-muted text-muted-foreground"}>
                    {r.status}
                  </Badge>
                </td>
                <td className="p-4 text-right font-semibold">₹{Number(r.amount).toLocaleString()}</td>
              </tr>
            ))}
            {sales.length === 0 && (
               <tr>
                 <td colSpan={5} className="p-8 text-center text-muted-foreground">No sales recorded yet.</td>
               </tr>
            )}
          </tbody>
        </table>
      </div>
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
  const session = auth.get()!;
  const [items, setItems] = useState(initialInventory);
  const [loadingMap, setLoadingMap] = useState<Record<number, boolean>>({});

  const update = (id: number, patch: Partial<InvRow>) => {
    setItems(items.map((i) => (i.item_id === id ? { ...i, ...patch } : i)));
  };

  const save = async (item: InvRow) => {
    setLoadingMap(prev => ({ ...prev, [item.item_id]: true }));
    try {
      await api.updateInventory(session.userId, item.item_id, item.cost, item.in_stock);
      toast.success(`Updated ${item.name}`);
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Failed to update inventory");
    } finally {
      setLoadingMap(prev => ({ ...prev, [item.item_id]: false }));
    }
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
            <Button onClick={() => save(it)} disabled={loadingMap[it.item_id]} className="w-full bg-gradient-accent text-accent-foreground border-0">
              {loadingMap[it.item_id] ? <Loader2 className="h-4 w-4 animate-spin" /> : "Save changes"}
            </Button>
          </div>
        ))}
      </div>
    </Wrap>
  );
};

const Settlements = () => {
  const session = auth.get()!;
  const [list, setList] = useState<Settlement[]>([]);
  const [loading, setLoading] = useState(false);

  const fetchSettlements = () => {
    api.getAllSettlements()
       .then(data => setList(data.filter(s => s.vendor_id === session.userId)))
       .catch(e => toast.error("Failed to load settlements: " + e.message));
  };

  useEffect(() => {
    fetchSettlements();
    // eslint-disable-next-line
  }, [session.userId]);

  const pending = list.filter((s) => s.status === "PENDING").reduce((sum, r) => sum + Number(r.amount), 0);

  const request = async () => {
    setLoading(true);
    try {
      await api.requestSettlement(session.userId);
      toast.success(`Settlement requested successfully`);
      fetchSettlements();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Failed to request settlement");
    } finally {
      setLoading(false);
    }
  };

  return (
    <Wrap>
      <div className="grid md:grid-cols-[1fr_auto] gap-4 items-end mb-6">
        <div>
          <h1 className="text-3xl font-bold">Settlements</h1>
          <p className="text-muted-foreground">Request payouts for your unsettled bills</p>
        </div>
        <Button onClick={request} disabled={loading} className="h-12 bg-gradient-primary text-primary-foreground border-0 shadow-soft hover:shadow-glow transition-smooth">
          {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : "Request settlement"}
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
                <td className="p-4">{new Date(s.date).toLocaleDateString()}</td>
                <td className="p-4">
                  <Badge className={s.status === "paid" ? "bg-success text-success-foreground" : "bg-warning text-warning-foreground"}>
                    {s.status}
                  </Badge>
                </td>
                <td className="p-4 text-right font-semibold">₹{Number(s.amount).toLocaleString()}</td>
              </tr>
            ))}
            {list.length === 0 && (
               <tr>
                 <td colSpan={4} className="p-8 text-center text-muted-foreground">No settlements requested yet.</td>
               </tr>
            )}
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