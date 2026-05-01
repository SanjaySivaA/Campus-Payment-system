import { ReactNode } from "react";
import { Navigate, useLocation } from "react-router-dom";
import { auth, Role } from "@/lib/api";

export const ProtectedRoute = ({
  children,
  allow,
}: {
  children: ReactNode;
  allow: Role[];
}) => {
  const location = useLocation();
  const session = auth.get();
  if (!session) return <Navigate to="/login" state={{ from: location }} replace />;
  if (!allow.includes(session.role)) return <Navigate to="/login" replace />;
  return <>{children}</>;
};
