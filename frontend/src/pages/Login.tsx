import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { api, Role } from "@/lib/api";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { toast } from "sonner";
import { GraduationCap, Store, ShieldCheck, Wallet, Loader2 } from "lucide-react";

const roles: { value: Role; label: string; icon: typeof GraduationCap }[] = [
  { value: "student", label: "Student", icon: GraduationCap },
  { value: "vendor", label: "Vendor", icon: Store },
  { value: "admin", label: "Admin", icon: ShieldCheck },
];

const Login = () => {
  const navigate = useNavigate();
  const [role, setRole] = useState<Role>("student");
  const [userId, setUserId] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      const session = await api.login(Number(userId), password, role);
      toast.success(`Welcome back, ${session.role}!`);
      navigate(`/${session.role}`);
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Login failed");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex bg-background">
      {/* Left visual panel */}
      <div className="hidden lg:flex relative flex-1 bg-gradient-hero overflow-hidden items-center justify-center p-12">
        <div className="absolute inset-0 opacity-30">
          <div className="absolute top-10 left-10 h-64 w-64 rounded-full bg-primary-glow blur-3xl" />
          <div className="absolute bottom-20 right-10 h-72 w-72 rounded-full bg-accent blur-3xl" />
        </div>
        <div className="relative text-primary-foreground max-w-md">
          <Link to="/" className="inline-flex items-center gap-2 mb-12">
            <div className="h-10 w-10 rounded-xl bg-card/20 backdrop-blur flex items-center justify-center">
              <Wallet className="h-5 w-5" />
            </div>
            <span className="font-bold text-xl">CampusPay</span>
          </Link>
          <h2 className="text-5xl font-bold leading-tight mb-4">Welcome back to campus.</h2>
          <p className="text-lg opacity-90">Login to manage your wallet, sales or settlements — whatever role you're rocking today.</p>
        </div>
      </div>

      {/* Form */}
      <div className="flex-1 flex items-center justify-center p-6">
        <div className="w-full max-w-md">
          <div className="lg:hidden mb-8">
            <Link to="/" className="inline-flex items-center gap-2">
              <div className="h-10 w-10 rounded-xl bg-gradient-primary flex items-center justify-center text-primary-foreground">
                <Wallet className="h-5 w-5" />
              </div>
              <span className="font-bold text-xl">CampusPay</span>
            </Link>
          </div>

          <h1 className="text-3xl font-bold mb-2">Log in</h1>
          <p className="text-muted-foreground mb-8">Pick your role and enter your credentials.</p>

          <div className="grid grid-cols-3 gap-2 mb-6">
            {roles.map((r) => {
              const active = role === r.value;
              const Icon = r.icon;
              return (
                <button
                  key={r.value}
                  type="button"
                  onClick={() => setRole(r.value)}
                  className={`p-4 rounded-xl border-2 transition-smooth flex flex-col items-center gap-2 ${
                    active
                      ? "border-primary bg-primary/5 shadow-soft"
                      : "border-border hover:border-primary/40"
                  }`}
                >
                  <Icon className={`h-5 w-5 ${active ? "text-primary" : "text-muted-foreground"}`} />
                  <span className={`text-xs font-medium ${active ? "text-primary" : "text-muted-foreground"}`}>{r.label}</span>
                </button>
              );
            })}
          </div>

          <form onSubmit={submit} className="space-y-4">
            <div>
              <Label htmlFor="userId">{role === "student" ? "Student ID" : role === "vendor" ? "Vendor ID" : "Admin ID"}</Label>
              <Input id="userId" type="number" required value={userId} onChange={(e) => setUserId(e.target.value)} placeholder="e.g. 1" className="h-12" />
            </div>
            <div>
              <Label htmlFor="password">Password</Label>
              <Input id="password" type="password" required value={password} onChange={(e) => setPassword(e.target.value)} placeholder="••••••••" className="h-12" />
            </div>
            <Button type="submit" disabled={loading} className="w-full h-12 bg-gradient-primary text-primary-foreground border-0 shadow-soft hover:shadow-glow transition-smooth text-base">
              {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : "Log in"}
            </Button>
          </form>

          <p className="text-center text-sm text-muted-foreground mt-6">
            Don't have an account?{" "}
            <Link to="/signup/student" className="text-primary font-medium hover:underline">Sign up as student</Link>
            {" · "}
            <Link to="/signup/vendor" className="text-primary font-medium hover:underline">vendor</Link>
          </p>
        </div>
      </div>
    </div>
  );
};

export default Login;
