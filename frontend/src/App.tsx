import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Route, Routes } from "react-router-dom";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { Toaster } from "@/components/ui/toaster";
import { TooltipProvider } from "@/components/ui/tooltip";
import Index from "./pages/Index.tsx";
import NotFound from "./pages/NotFound.tsx";
import Login from "./pages/Login.tsx";
import SignupStudent from "./pages/SignupStudent.tsx";
import SignupVendor from "./pages/SignupVendor.tsx";
import StudentDashboard from "./pages/StudentDashboard.tsx";
import VendorDashboard from "./pages/VendorDashboard.tsx";
import AdminDashboard from "./pages/AdminDashboard.tsx";
import { ProtectedRoute } from "./components/ProtectedRoute.tsx";

const queryClient = new QueryClient();

const App = () => (
  <QueryClientProvider client={queryClient}>
    <TooltipProvider>
      <Toaster />
      <Sonner />
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<Index />} />
          <Route path="/login" element={<Login />} />
          <Route path="/signup/student" element={<SignupStudent />} />
          <Route path="/signup/vendor" element={<SignupVendor />} />
          <Route path="/student/*" element={<ProtectedRoute allow={["student"]}><StudentDashboard /></ProtectedRoute>} />
          <Route path="/vendor/*" element={<ProtectedRoute allow={["vendor"]}><VendorDashboard /></ProtectedRoute>} />
          <Route path="/admin/*" element={<ProtectedRoute allow={["admin"]}><AdminDashboard /></ProtectedRoute>} />
          <Route path="*" element={<NotFound />} />
        </Routes>
      </BrowserRouter>
    </TooltipProvider>
  </QueryClientProvider>
);

export default App;
