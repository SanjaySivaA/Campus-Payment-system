import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { api } from "@/lib/api";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { toast } from "sonner";
import { GraduationCap, Loader2, Wallet } from "lucide-react";

const SignupStudent = () => {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [form, setForm] = useState({
    student_id: "",
    first_name: "",
    last_name: "",
    email: "",
    phone: "",
    password: "",
    weekly_spending_limit: "1000",
  });

  const update = (k: keyof typeof form) => (e: React.ChangeEvent<HTMLInputElement>) =>
    setForm({ ...form, [k]: e.target.value });

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      await api.signupStudent({
        student_id: Number(form.student_id),
        first_name: form.first_name,
        last_name: form.last_name,
        email: form.email,
        phone: form.phone,
        password: form.password,
        weekly_spending_limit: Number(form.weekly_spending_limit),
      });
      toast.success("Account created — please log in");
      navigate("/login");
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Signup failed");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-background flex items-center justify-center p-6">
      <div className="w-full max-w-2xl">
        <Link to="/" className="inline-flex items-center gap-2 mb-8">
          <div className="h-10 w-10 rounded-xl bg-gradient-primary flex items-center justify-center text-primary-foreground">
            <Wallet className="h-5 w-5" />
          </div>
          <span className="font-bold text-xl">CampusPay</span>
        </Link>

        <div className="bg-card rounded-2xl shadow-card border p-8">
          <div className="flex items-center gap-3 mb-6">
            <div className="h-12 w-12 rounded-xl bg-gradient-primary flex items-center justify-center text-primary-foreground shadow-glow">
              <GraduationCap className="h-6 w-6" />
            </div>
            <div>
              <h1 className="text-2xl font-bold">Create student account</h1>
              <p className="text-sm text-muted-foreground">Get your campus wallet in seconds</p>
            </div>
          </div>

          <form onSubmit={submit} className="grid sm:grid-cols-2 gap-4">
            <div className="sm:col-span-2">
              <Label>Student ID</Label>
              <Input type="number" required value={form.student_id} onChange={update("student_id")} className="h-11" />
            </div>
            <div>
              <Label>First name</Label>
              <Input required maxLength={20} value={form.first_name} onChange={update("first_name")} className="h-11" />
            </div>
            <div>
              <Label>Last name</Label>
              <Input required maxLength={20} value={form.last_name} onChange={update("last_name")} className="h-11" />
            </div>
            <div className="sm:col-span-2">
              <Label>Email</Label>
              <Input type="email" required value={form.email} onChange={update("email")} className="h-11" />
            </div>
            <div>
              <Label>Phone</Label>
              <Input required maxLength={15} value={form.phone} onChange={update("phone")} className="h-11" />
            </div>
            <div>
              <Label>Weekly spending limit (₹)</Label>
              <Input type="number" required value={form.weekly_spending_limit} onChange={update("weekly_spending_limit")} className="h-11" />
            </div>
            <div className="sm:col-span-2">
              <Label>Password</Label>
              <Input type="password" required minLength={4} value={form.password} onChange={update("password")} className="h-11" />
            </div>
            <Button type="submit" disabled={loading} className="sm:col-span-2 h-12 bg-gradient-primary text-primary-foreground border-0 shadow-soft hover:shadow-glow transition-smooth">
              {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : "Create account"}
            </Button>
          </form>
          <p className="text-center text-sm text-muted-foreground mt-6">
            Already have an account?{" "}
            <Link to="/login" className="text-primary font-medium hover:underline">Log in</Link>
            {" · "}
            <Link to="/signup/vendor" className="text-primary font-medium hover:underline">Vendor signup</Link>
          </p>
        </div>
      </div>
    </div>
  );
};

export default SignupStudent;
