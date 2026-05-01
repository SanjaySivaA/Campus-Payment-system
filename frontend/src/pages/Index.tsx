import { Link } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { GraduationCap, Store, ShieldCheck, ArrowRight, Wallet, Receipt, BarChart3 } from "lucide-react";

const Index = () => {
  return (
    <div className="min-h-screen bg-background">
      {/* Hero */}
      <section className="relative overflow-hidden">
        <div className="absolute inset-0 bg-gradient-hero opacity-10" />
        <div className="absolute -top-24 -right-24 h-96 w-96 rounded-full bg-gradient-primary opacity-20 blur-3xl" />
        <div className="absolute -bottom-24 -left-24 h-96 w-96 rounded-full bg-gradient-accent opacity-20 blur-3xl" />

        <header className="container relative flex h-20 items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="h-10 w-10 rounded-xl bg-gradient-primary flex items-center justify-center text-primary-foreground shadow-glow">
              <Wallet className="h-5 w-5" />
            </div>
            <span className="font-bold text-xl">CampusPay</span>
          </div>
          <div className="flex gap-2">
            <Button variant="ghost" asChild>
              <Link to="/login">Login</Link>
            </Button>
            <Button asChild className="bg-gradient-primary text-primary-foreground border-0 shadow-soft hover:shadow-glow transition-smooth">
              <Link to="/signup/student">Get started</Link>
            </Button>
          </div>
        </header>

        <div className="container relative py-20 md:py-28 text-center max-w-4xl">
          <span className="inline-block px-4 py-1.5 rounded-full bg-secondary text-secondary-foreground text-sm font-medium mb-6">
            🎓 The campus payment system
          </span>
          <h1 className="text-5xl md:text-7xl font-bold leading-tight mb-6">
            Pay, eat, study —{" "}
            <span className="bg-gradient-hero bg-clip-text text-transparent">all on one card</span>
          </h1>
          <p className="text-lg md:text-xl text-muted-foreground mb-10 max-w-2xl mx-auto">
            One wallet for students, vendors and admins. Recharge, transact, settle and track —
            everything your campus needs in one delightful app.
          </p>
          <div className="flex flex-col sm:flex-row gap-3 justify-center">
            <Button size="lg" asChild className="bg-gradient-primary text-primary-foreground border-0 shadow-glow hover:scale-105 transition-smooth h-12 text-base">
              <Link to="/login">
                Login to your dashboard <ArrowRight className="ml-2 h-4 w-4" />
              </Link>
            </Button>
            <Button size="lg" variant="outline" asChild className="h-12 text-base">
              <Link to="/signup/student">Create student account</Link>
            </Button>
          </div>
        </div>
      </section>

      {/* Roles */}
      <section className="container py-20">
        <div className="text-center mb-12">
          <h2 className="text-4xl font-bold mb-3">Built for everyone on campus</h2>
          <p className="text-muted-foreground">Choose your role to get started</p>
        </div>
        <div className="grid md:grid-cols-3 gap-6">
          {[
            {
              icon: GraduationCap,
              title: "Students",
              desc: "Recharge your wallet, compare prices across vendors, and track every purchase.",
              cta: "Sign up as student",
              to: "/signup/student",
              gradient: "bg-gradient-primary",
            },
            {
              icon: Store,
              title: "Vendors",
              desc: "Manage your inventory, view daily sales, and request settlements with one click.",
              cta: "Sign up as vendor",
              to: "/signup/vendor",
              gradient: "bg-gradient-accent",
            },
            {
              icon: ShieldCheck,
              title: "Admins",
              desc: "Approve vendor settlements, oversee transactions and keep the campus running.",
              cta: "Admin login",
              to: "/login",
              gradient: "bg-gradient-hero",
            },
          ].map((r) => (
            <div key={r.title} className="group rounded-2xl border bg-card p-8 shadow-card hover:shadow-glow transition-smooth hover:-translate-y-1">
              <div className={`h-14 w-14 rounded-2xl ${r.gradient} flex items-center justify-center text-primary-foreground shadow-glow mb-5`}>
                <r.icon className="h-7 w-7" />
              </div>
              <h3 className="text-2xl font-bold mb-2">{r.title}</h3>
              <p className="text-muted-foreground mb-6">{r.desc}</p>
              <Button asChild variant="outline" className="w-full group-hover:bg-primary group-hover:text-primary-foreground transition-smooth">
                <Link to={r.to}>{r.cta} <ArrowRight className="ml-2 h-4 w-4" /></Link>
              </Button>
            </div>
          ))}
        </div>
      </section>

      {/* Features */}
      <section className="container pb-24">
        <div className="grid md:grid-cols-3 gap-6">
          {[
            { icon: Wallet, title: "Instant recharge", desc: "Top up your campus wallet anytime." },
            { icon: Receipt, title: "Live statements", desc: "Every transaction, neatly itemised." },
            { icon: BarChart3, title: "Smart insights", desc: "Spending limits and vendor comparisons." },
          ].map((f) => (
            <div key={f.title} className="rounded-2xl bg-gradient-warm p-6 flex gap-4 items-start">
              <div className="h-12 w-12 rounded-xl bg-card flex items-center justify-center shadow-soft text-primary">
                <f.icon className="h-6 w-6" />
              </div>
              <div>
                <h4 className="font-bold text-lg mb-1">{f.title}</h4>
                <p className="text-sm text-muted-foreground">{f.desc}</p>
              </div>
            </div>
          ))}
        </div>
      </section>

      <footer className="border-t py-8">
        <div className="container text-center text-sm text-muted-foreground">
          © 2026 CampusPay — Built with ❤️ for students
        </div>
      </footer>
    </div>
  );
};

export default Index;
