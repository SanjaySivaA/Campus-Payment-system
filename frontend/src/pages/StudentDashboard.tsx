import { useEffect, useState } from "react";
import { Routes, Route, Navigate } from "react-router-dom";
import { DashboardLayout } from "@/components/DashboardLayout";
import { api, auth, PriceRow } from "@/lib/api";
import { mockItems } from "@/lib/mock";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { toast } from "sonner";
import { Wallet, Receipt, BarChart3, Plus, ArrowUpRight, TrendingUp, Loader2 } from "lucide-react";

const nav = [
  { to: "/student", label: "Overview" },
  { to: "/student/statement", label: "Purchase history" },
  { to: "/student/compare", label: "Compare prices" },
  { to: "/student/recharge", label: "Recharge" },
];

const Wrap = ({ children }: { children: React.ReactNode }) => (
  <DashboardLayout role="student" nav={nav}>{children}</DashboardLayout>
);

// --- Overview ---
const Overview = () => {
  const session = auth.get()!;
  const [profile, setProfile] = useState<{ balance: number; spending_limit: number } | null>(null);

  useEffect(() => {
    api.getStudentProfile(session.userId)
      .then(setProfile)
      .catch((err) => toast.error("Failed to load profile: " + err.message));
  }, [session.userId]);

  const balance = profile?.balance ?? 0;
  const remainingLimit = profile?.spending_limit ?? 0;

  return (
    <Wrap>
      <div className="grid lg:grid-cols-3 gap-6 mb-8">
        <div className="lg:col-span-2 rounded-2xl bg-gradient-hero p-8 text-primary-foreground shadow-glow relative overflow-hidden">
          <div className="absolute -bottom-8 -right-8 h-48 w-48 rounded-full bg-card/10 blur-2xl" />
          <p className="text-sm opacity-80 mb-2">Wallet balance</p>
          <p className="text-5xl font-bold mb-1">₹{balance.toLocaleString()}</p>
          <p className="text-sm opacity-80">Student #{session.userId}</p>
          <div className="flex gap-3 mt-6">
            <Button asChild className="bg-card text-foreground hover:bg-card/90 border-0">
              <a href="/student/recharge"><Plus className="h-4 w-4 mr-1" /> Recharge</a>
            </Button>
            <Button asChild variant="outline" className="bg-transparent text-primary-foreground border-primary-foreground/40 hover:bg-card/10 hover:text-primary-foreground">
              <a href="/student/statement"><Receipt className="h-4 w-4 mr-1" /> Statement</a>
            </Button>
          </div>
        </div>
        <div className="rounded-2xl bg-card border p-6 shadow-card">
          <p className="text-sm text-muted-foreground mb-1">Weekly limit remaining</p>
          {profile === null ? (
            <Skeleton className="h-10 w-24 mb-3" />
          ) : (
            <p className="text-3xl font-bold mb-3">₹{remainingLimit.toLocaleString()}</p>
          )}
          <p className="text-xs text-muted-foreground mb-2">resets soon</p>
        </div>
      </div>

      <div className="grid sm:grid-cols-3 gap-4">
        {[
          { icon: Receipt, label: "View statement", to: "/student/statement", grad: "bg-gradient-primary" },
          { icon: BarChart3, label: "Compare prices", to: "/student/compare", grad: "bg-gradient-accent" },
          { icon: Wallet, label: "Recharge wallet", to: "/student/recharge", grad: "bg-gradient-hero" },
        ].map((c) => (
          <a key={c.to} href={c.to} className="group rounded-2xl border bg-card p-6 shadow-card hover:shadow-glow transition-smooth hover:-translate-y-1 flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className={`h-11 w-11 rounded-xl ${c.grad} flex items-center justify-center text-primary-foreground`}>
                <c.icon className="h-5 w-5" />
              </div>
              <span className="font-semibold">{c.label}</span>
            </div>
            <ArrowUpRight className="h-4 w-4 text-muted-foreground group-hover:text-primary transition-smooth" />
          </a>
        ))}
      </div>
    </Wrap>
  );
};

// --- Statement ---
interface StatementRow { bill_id: number; date: string; vendor_id: number; vendor_name: string; amount: number }

const Statement = () => {
  const session = auth.get()!;
  const [rows, setRows] = useState<StatementRow[] | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    api.getStatement(session.userId)
      .then((d) => setRows(d as StatementRow[]))
      .catch((e) => {
        setError(e.message);
        setRows([]);
      });
  }, [session.userId]);

  const total = rows?.reduce((s, r) => s + Number(r.amount), 0) ?? 0;

  return (
    <Wrap>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-3xl font-bold">Purchase history</h1>
          <p className="text-muted-foreground">Every transaction you've made on campus</p>
        </div>
        <div className="text-right">
          <p className="text-sm text-muted-foreground">Total spent</p>
          <p className="text-2xl font-bold text-primary">₹{total.toLocaleString()}</p>
        </div>
      </div>

      {error && (
        <div className="rounded-xl border border-warning/40 bg-warning/10 p-4 mb-4 text-sm">
          <p className="font-medium text-warning-foreground">{error}</p>
          <p className="text-muted-foreground mt-1">Make sure your FastAPI server is running.</p>
        </div>
      )}

      <div className="rounded-2xl border bg-card shadow-card overflow-hidden">
        {rows === null ? (
          <div className="p-6 space-y-3">{Array.from({length: 5}).map((_, i) => <Skeleton key={i} className="h-14 w-full" />)}</div>
        ) : rows.length === 0 ? (
          <div className="p-12 text-center text-muted-foreground">No purchases yet — go grab a samosa! 🥟</div>
        ) : (
          <table className="w-full text-sm">
            <thead className="bg-muted/50 text-left">
              <tr>
                <th className="p-4 font-medium">Bill #</th>
                <th className="p-4 font-medium">Date</th>
                <th className="p-4 font-medium">Vendor</th>
                <th className="p-4 font-medium text-right">Amount</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((r) => (
                <tr key={r.bill_id} className="border-t hover:bg-muted/30 transition-smooth">
                  <td className="p-4 font-mono text-xs">#{r.bill_id}</td>
                  <td className="p-4">{new Date(r.date).toLocaleDateString()}</td>
                  <td className="p-4 font-medium">{r.vendor_name}</td>
                  <td className="p-4 text-right font-semibold">₹{Number(r.amount).toLocaleString()}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </Wrap>
  );
};

// --- Compare prices ---
const Compare = () => {
  const [itemId, setItemId] = useState("1");
  const [rows, setRows] = useState<PriceRow[]>([]);
  const [loading, setLoading] = useState(false);

  const search = async () => {
    setLoading(true);
    try {
      const data = await api.comparePrices(Number(itemId));
      setRows(data.sort((a, b) => a.cost - b.cost));
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Failed to compare prices");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { search(); /* initial */ // eslint-disable-next-line
  }, []);

  const cheapest = rows.find((r) => r.in_stock);

  return (
    <Wrap>
      <div className="mb-6">
        <h1 className="text-3xl font-bold">Compare prices</h1>
        <p className="text-muted-foreground">Find the best deal across campus vendors</p>
      </div>

      <div className="rounded-2xl bg-card border shadow-card p-6 mb-6">
        <div className="grid sm:grid-cols-[1fr_auto] gap-3 items-end">
          <div>
            <Label>Pick an item</Label>
            <Select value={itemId} onValueChange={setItemId}>
              <SelectTrigger className="h-12"><SelectValue /></SelectTrigger>
              <SelectContent>
                {mockItems.map((i) => (
                  <SelectItem key={i.item_id} value={String(i.item_id)}>{i.name}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <Button onClick={search} disabled={loading} className="h-12 bg-gradient-primary text-primary-foreground border-0 shadow-soft">
            {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : "Compare"}
          </Button>
        </div>
      </div>

      {cheapest && (
        <div className="rounded-2xl bg-gradient-warm p-6 mb-6 flex items-center gap-4">
          <div className="h-12 w-12 rounded-xl bg-card flex items-center justify-center shadow-soft text-success">
            <TrendingUp className="h-6 w-6" />
          </div>
          <div>
            <p className="text-sm text-muted-foreground">Best deal in stock</p>
            <p className="font-bold text-lg">{cheapest.vendor_name} — ₹{cheapest.cost}</p>
          </div>
        </div>
      )}

      <div className="grid md:grid-cols-2 gap-4">
        {rows.map((r) => (
          <div key={r.vendor_id} className="rounded-2xl border bg-card p-5 shadow-card hover:shadow-glow transition-smooth">
            <div className="flex items-start justify-between mb-3">
              <div>
                <p className="font-bold text-lg">{r.vendor_name}</p>
                <p className="text-xs text-muted-foreground">Updated {new Date(r.last_updated).toLocaleDateString()}</p>
              </div>
              <Badge variant={r.in_stock ? "default" : "secondary"} className={r.in_stock ? "bg-success text-success-foreground" : "bg-muted text-muted-foreground"}>
                {r.in_stock ? "In stock" : "Out of stock"}
              </Badge>
            </div>
            <p className="text-3xl font-bold text-primary">₹{r.cost}</p>
          </div>
        ))}
      </div>
    </Wrap>
  );
};

// --- Recharge ---
const Recharge = () => {
  const session = auth.get()!;
  const [amount, setAmount] = useState("500");
  const [loading, setLoading] = useState(false);
  const presets = [200, 500, 1000, 2000];

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      await api.recharge(session.userId, Number(amount));
      toast.success(`₹${amount} added to your wallet!`);
      setAmount("0");
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Recharge failed");
    } finally {
      setLoading(false);
    }
  };

  return (
    <Wrap>
      <div className="mb-6">
        <h1 className="text-3xl font-bold">Recharge wallet</h1>
        <p className="text-muted-foreground">Top up instantly — pay anywhere on campus</p>
      </div>
      <div className="max-w-xl rounded-2xl border bg-card p-8 shadow-card">
        <form onSubmit={submit} className="space-y-5">
          <div>
            <Label>Amount (₹)</Label>
            <Input type="number" min={1} required value={amount} onChange={(e) => setAmount(e.target.value)} className="h-14 text-2xl font-bold" />
          </div>
          <div className="grid grid-cols-4 gap-2">
            {presets.map((p) => (
              <button type="button" key={p} onClick={() => setAmount(String(p))} className="py-3 rounded-xl border hover:border-primary hover:bg-primary/5 transition-smooth font-semibold">
                ₹{p}
              </button>
            ))}
          </div>
          <Button type="submit" disabled={loading} className="w-full h-12 bg-gradient-primary text-primary-foreground border-0 shadow-soft hover:shadow-glow transition-smooth">
            {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : `Recharge ₹${amount || 0}`}
          </Button>
        </form>
      </div>
    </Wrap>
  );
};

const StudentDashboard = () => (
  <Routes>
    <Route index element={<Overview />} />
    <Route path="statement" element={<Statement />} />
    <Route path="compare" element={<Compare />} />
    <Route path="recharge" element={<Recharge />} />
    <Route path="*" element={<Navigate to="/student" replace />} />
  </Routes>
);

export default StudentDashboard;