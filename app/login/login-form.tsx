"use client";

import { useActionState } from "react";
import { GraduationCap, LockKeyhole, Mail } from "lucide-react";
import { signIn, type LoginState } from "./actions";

const initialState: LoginState = {};

export default function LoginForm() {
  const [state, action, pending] = useActionState(signIn, initialState);
  return (
    <form action={action} className="mt-7 space-y-4">
      <label className="block">
        <span className="mb-1.5 block text-xs font-bold text-[#486581]">Email address</span>
        <span className="relative block"><Mail size={16} className="absolute left-3 top-3 text-[#9fb3c8]"/><input className="field pl-9" name="email" type="email" autoComplete="username" required placeholder="you@school.mw"/></span>
      </label>
      <label className="block">
        <span className="mb-1.5 block text-xs font-bold text-[#486581]">Password</span>
        <span className="relative block"><LockKeyhole size={16} className="absolute left-3 top-3 text-[#9fb3c8]"/><input className="field pl-9" name="password" type="password" autoComplete="current-password" required placeholder="Enter your password"/></span>
      </label>
      {state.error && <p role="alert" className="rounded-lg border border-[#f4d3ce] bg-[#fff5f3] px-3 py-2 text-xs leading-5 text-[#b54738]">{state.error}</p>}
      <button disabled={pending} className="btn-primary w-full py-3 disabled:cursor-not-allowed disabled:opacity-60">{pending ? "Signing in..." : "Sign in securely"}</button>
      <p className="text-center text-[11px] leading-5 text-[#829ab1]">Need an account? Contact your school administrator for an invitation.</p>
    </form>
  );
}
