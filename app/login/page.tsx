import { GraduationCap, ShieldCheck } from "lucide-react";
import LoginForm from "./login-form";

export default function LoginPage() {
  return <main className="flex min-h-screen items-center justify-center bg-[#f5f7f8] px-4 py-10">
    <section className="w-full max-w-md rounded-2xl border border-[#e8eef0] bg-white p-7 shadow-[0_16px_50px_rgba(16,42,67,.08)] sm:p-9">
      <div className="mb-8 flex items-center gap-3"><div className="grid h-11 w-11 place-items-center rounded-xl bg-[#e8f5ee] text-[#16845b]"><GraduationCap size={25}/></div><div><div className="text-xl font-extrabold tracking-tight text-[#102a43]">ClassPilot</div><div className="text-[10px] font-bold uppercase tracking-[.18em] text-[#829ab1]">Malawi school management</div></div></div>
      <div className="text-2xl font-extrabold tracking-tight text-[#102a43]">Welcome back</div><p className="mt-2 text-sm text-[#829ab1]">Sign in with the email address from your school invitation.</p>
      <LoginForm/>
      <div className="mt-7 flex items-start gap-2 rounded-xl bg-[#f3f8f5] p-3 text-[11px] leading-5 text-[#627d68]"><ShieldCheck size={16} className="mt-0.5 shrink-0 text-[#16845b]"/> Your school records are protected by Supabase authentication and database access policies.</div>
    </section>
  </main>;
}
