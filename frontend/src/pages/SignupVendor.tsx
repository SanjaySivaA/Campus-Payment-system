import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { api } from "@/lib/api";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { toast } from "sonner";
import { Store, Loader2, Wallet } from "lucide-react";

const SignupVendor = () => {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [form, setForm] = useState({
    vendor_id: "",
    name: "",
    email: "",
    phone: "",
    password: "",
  });

  const update = (k: keyof typeof form) => (e: React.ChangeEvent<HTMLInputElement>) =>
    setForm({ ...form, [k]: e.target.value });

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      await api.signupVendor({
        vendor_id: Number(form.vendor_id),
        name: form.name,
        email: form.email,
        phone: form.phone,
        password: form.password,
      });
      toast.success("Vendor account created — please log in");
      navigate("/login");
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Signup failed");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-background flex items-center justify-center p-6">
      <div className="w-full max-w-xl">
        <Link to="/" className="inline-flex items-center gap-2 mb-8">
          <div className="h-10 w-10 rounded-xl bg-gradient-primary flex items-center justify-center text-primary-foreground">
            <Wallet className="h-5 w-5" />
          </div>
          <span className="font-bold text-xl">CampusPay</span>
        </Link>

        <div className="bg-card rounded-2xl shadow-card border p-8">
          <div className="flex items-center gap-3 mb-6">
            <div className="h-12 w-12 rounded-xl bg-gradient-accent flex items-center justify-center text-primary-foreground shadow-glow">
              <Store className="h-6 w-6" />
            </div>
            <div>
              <h1 className="text-2xl font-bold">Become a vendor</h1>
              <p className="text-sm text-muted-foreground">Start selling on campus today</p>
            </div>
          </div>
          <form onSubmit={submit} className="space-y-4">
            <div>
              <Label>Vendor ID</Label>
              <Input type="number" required value={form.vendor_id} onChange={update("vendor_id")} className="h-11" />
            </div>
            <div>
              <Label>Shop name</Label>
              <Input required maxLength={100} value={form.name} onChange={update("name")} className="h-11" />
            </div>
            <div>
              <Label>Email</Label>
              <Input type="email" required value={form.email} onChange={update("email")} className="h-11" />
            </div>
            <div>
              <Label>Phone</Label>
              <Input required maxLength={15} value={form.phone} onChange={update("phone")} className="h-11" />
            </div>
            <div>
              <Label>Password</Label>
              <Input type="password" required minLength={4} value={form.password} onChange={update("password")} className="h-11" />
            </div>
            <Button type="submit" disabled={loading} className="w-full h-12 bg-gradient-accent text-accent-foreground border-0 shadow-soft hover:shadow-glow transition-smooth">
              {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : "Create vendor account"}
            </Button>
          </form>
          <p className="text-center text-sm text-muted-foreground mt-6">
            Already have an account?{" "}
            <Link to="/login" className="text-primary font-medium hover:underline">Log in</Link>
          </p>
        </div>
      </div>
    </div>
  );
};

export default SignupVendor;
