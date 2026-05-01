import { ReactNode } from "react";
import { useNavigate, Link, useLocation } from "react-router-dom";
import { auth, Role } from "@/lib/api";
import { Button } from "@/components/ui/button";
import { GraduationCap, Store, ShieldCheck, LogOut } from "lucide-react";

const roleMeta: Record<Role, { label: string; icon: typeof GraduationCap; gradient: string }> = {
  student: { label: "Student", icon: GraduationCap, gradient: "bg-gradient-primary" },
  vendor: { label: "Vendor", icon: Store, gradient: "bg-gradient-accent" },
  admin: { label: "Admin", icon: ShieldCheck, gradient: "bg-gradient-hero" },
};

interface NavItem {
  to: string;
  label: string;
}

export const DashboardLayout = ({
  role,
  nav,
  children,
}: {
  role: Role;
  nav: NavItem[];
  children: ReactNode;
}) => {
  const navigate = useNavigate();
  const location = useLocation();
  const session = auth.get();
  const meta = roleMeta[role];
  const Icon = meta.icon;

  const logout = () => {
    auth.clear();
    navigate("/login");
  };

  return (
    <div className="min-h-screen bg-background">
      <header className="border-b bg-card sticky top-0 z-40 shadow-soft">
        <div className="container flex h-16 items-center justify-between">
          <div className="flex items-center gap-3">
            <div className={`h-10 w-10 rounded-xl ${meta.gradient} flex items-center justify-center text-primary-foreground shadow-glow`}>
              <Icon className="h-5 w-5" />
            </div>
            <div>
              <p className="text-sm text-muted-foreground leading-none">CampusPay</p>
              <p className="font-bold leading-tight">{meta.label} #{session?.userId}</p>
            </div>
          </div>
          <nav className="hidden md:flex items-center gap-1">
            {nav.map((n) => {
              const active = location.pathname === n.to;
              return (
                <Link
                  key={n.to}
                  to={n.to}
                  className={`px-4 py-2 rounded-lg text-sm font-medium transition-smooth ${
                    active
                      ? "bg-primary text-primary-foreground shadow-soft"
                      : "text-muted-foreground hover:bg-muted hover:text-foreground"
                  }`}
                >
                  {n.label}
                </Link>
              );
            })}
          </nav>
          <Button variant="ghost" size="sm" onClick={logout}>
            <LogOut className="h-4 w-4 mr-2" /> Logout
          </Button>
        </div>
        <div className="container md:hidden flex gap-1 pb-3 overflow-x-auto">
          {nav.map((n) => {
            const active = location.pathname === n.to;
            return (
              <Link
                key={n.to}
                to={n.to}
                className={`px-3 py-1.5 rounded-lg text-sm whitespace-nowrap ${
                  active ? "bg-primary text-primary-foreground" : "bg-muted text-muted-foreground"
                }`}
              >
                {n.label}
              </Link>
            );
          })}
        </div>
      </header>
      <main className="container py-8">{children}</main>
    </div>
  );
};
