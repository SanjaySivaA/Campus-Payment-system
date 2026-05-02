import { useState, useEffect } from "react";
import { Routes, Route, Navigate } from "react-router-dom";
import { DashboardLayout } from "@/components/DashboardLayout";
import { api, auth, Settlement } from "@/lib/api";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { toast } from "sonner";
import { Wallet, CheckCircle2, Clock, TrendingUp, Loader2 } from "lucide-react";

const nav = [
  { to: "/admin", label: "Overview" },
  { to: "/admin/settlements", label: "Settlements" },
];

const Wrap = ({ children }: { children: React.ReactNode }) => (
  <DashboardLayout role="admin" nav={nav}>{children}</DashboardLayout>
);

const Overview = () => {
  const [settlements, setSettlements] = useState<Settlement[]>([]);

  useEffect(() => {
    api.getAllSettlements()
       .then(setSettlements)
       .catch((e) => toast.error("Failed to load overview data: " + e.message));
  }, []);

  const pending = settlements.filter((s) => s.status === "PENDING");
  const paid = settlements.filter((s) => s.status === "paid");
  const totalPending = pending.reduce((sum, r) => sum + Number(r.amount), 0);
  const totalPaid = paid.reduce((sum, r) => sum + Number(r.amount), 0);

  return (
    <Wrap>
      <div className="mb-8">
        <h1 className="text-3xl font-bold">Admin overview</h1>
        <p className="text-muted-foreground">Keep the campus economy running</p>
      </div>
      <div className="grid md:grid-cols-3 gap-4 mb-8">
        <div className="rounded-2xl bg-gradient-hero p-6 text-primary-foreground shadow-glow">
          <Wallet className="h-6 w-6 mb-3 opacity-90" />
          <p className="text-sm opacity-80">Pending payouts</p>
          <p className="text-4xl font-bold">₹{totalPending.toLocaleString()}</p>
          <p className="text-xs opacity-80 mt-1">{pending.length} requests</p>
        </div>
        <div className="rounded-2xl border bg-card p-6 shadow-card">
          <CheckCircle2 className="h-6 w-6 mb-3 text-success" />
          <p className="text-sm text-muted-foreground">Paid historically</p>
          <p className="text-4xl font-bold">₹{totalPaid.toLocaleString()}</p>
          <p className="text-xs text-muted-foreground mt-1">{paid.length} settlements</p>
        </div>
        <div className="rounded-2xl border bg-card p-6 shadow-card">
          <TrendingUp className="h-6 w-6 mb-3 text-accent" />
          <p className="text-sm text-muted-foreground">Active vendors</p>
          <p className="text-4xl font-bold">{new Set(settlements.map((s) => s.vendor_id)).size}</p>
          <p className="text-xs text-muted-foreground mt-1">across campus</p>
        </div>
      </div>
      <a href="/admin/settlements" className="block rounded-2xl border bg-card p-6 shadow-card hover:shadow-glow transition-smooth hover:-translate-y-1">
        <p className="text-sm text-muted-foreground mb-1">Action needed</p>
        <p className="text-xl font-bold">Review {pending.length} pending settlement requests →</p>
      </a>
    </Wrap>
  );
};

const Settlements = () => {
  const session = auth.get()!;
  const [list, setList] = useState<Settlement[]>([]);
  const [busy, setBusy] = useState<number | null>(null);

  useEffect(() => {
    api.getAllSettlements()
       .then(setList)
       .catch((e) => toast.error("Failed to load settlements: " + e.message));
  }, []);

  const approve = async (s: Settlement) => {
    setBusy(s.settlement_id);
    try {
      await api.approveSettlement(s.settlement_id, session.userId);
      setList((prev) => prev.map((x) => (x.settlement_id === s.settlement_id ? { ...x, status: "paid" } : x)));
      toast.success(`Settlement #${s.settlement_id} approved & paid to ${s.vendor_name}`);
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Approval failed");
    } finally {
      setBusy(null);
    }
  };

  const pending = list.filter((s) => s.status === "PENDING");
  const paid = list.filter((s) => s.status === "paid");

  return (
    <Wrap>
      <div className="mb-6">
        <h1 className="text-3xl font-bold">Settlement requests</h1>
        <p className="text-muted-foreground">Review and approve vendor payouts</p>
      </div>

      <h2 className="text-lg font-bold mb-3 flex items-center gap-2">
        <Clock className="h-5 w-5 text-warning" /> Pending ({pending.length})
      </h2>
      <div className="grid md:grid-cols-2 gap-4 mb-10">
        {pending.length === 0 ? (
          <div className="md:col-span-2 rounded-2xl border bg-card p-8 text-center text-muted-foreground">
            🎉 All caught up — no pending settlements
          </div>
        ) : pending.map((s) => (
          <div key={s.settlement_id} className="rounded-2xl border bg-card p-6 shadow-card">
            <div className="flex items-start justify-between mb-4">
              <div>
                <p className="font-bold text-lg">{s.vendor_name}</p>
                <p className="text-xs text-muted-foreground">Settlement #{s.settlement_id} · {new Date(s.date).toLocaleDateString()}</p>
              </div>
              <Badge className="bg-warning text-warning-foreground">Pending</Badge>
            </div>
            <p className="text-3xl font-bold text-primary mb-4">₹{Number(s.amount).toLocaleString()}</p>
            <Button
              onClick={() => approve(s)}
              disabled={busy === s.settlement_id}
              className="w-full bg-gradient-primary text-primary-foreground border-0 shadow-soft hover:shadow-glow transition-smooth"
            >
              {busy === s.settlement_id ? (
                <><Loader2 className="h-4 w-4 mr-2 animate-spin" /> Processing bank transfer…</>
              ) : (
                <><CheckCircle2 className="h-4 w-4 mr-2" /> Approve & pay</>
              )}
            </Button>
          </div>
        ))}
      </div>

      <h2 className="text-lg font-bold mb-3 flex items-center gap-2">
        <CheckCircle2 className="h-5 w-5 text-success" /> Paid ({paid.length})
      </h2>
      <div className="rounded-2xl border bg-card shadow-card overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-muted/50 text-left">
            <tr>
              <th className="p-4 font-medium">#</th>
              <th className="p-4 font-medium">Vendor</th>
              <th className="p-4 font-medium">Date</th>
              <th className="p-4 font-medium text-right">Amount</th>
            </tr>
          </thead>
          <tbody>
            {paid.map((s) => (
              <tr key={s.settlement_id} className="border-t hover:bg-muted/30">
                <td className="p-4 font-mono text-xs">#{s.settlement_id}</td>
                <td className="p-4 font-medium">{s.vendor_name}</td>
                <td className="p-4">{new Date(s.date).toLocaleDateString()}</td>
                <td className="p-4 text-right font-semibold">₹{Number(s.amount).toLocaleString()}</td>
              </tr>
            ))}
            {paid.length === 0 && (
              <tr>
                <td colSpan={4} className="p-8 text-center text-muted-foreground">No historical payments.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </Wrap>
  );
};

const AdminDashboard = () => (
  <Routes>
    <Route index element={<Overview />} />
    <Route path="settlements" element={<Settlements />} />
    <Route path="*" element={<Navigate to="/admin" replace />} />
  </Routes>
);

export default AdminDashboard;