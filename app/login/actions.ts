"use server";

import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

export type LoginState = { error?: string };

export async function signIn(_prev: LoginState, formData: FormData): Promise<LoginState> {
  const email = String(formData.get("email") || "").trim().toLowerCase();
  const password = String(formData.get("password") || "");
  if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || !password) {
    return { error: "Enter a valid email address and password." };
  }

  let supabase;
  try { supabase = await createClient(); }
  catch { return { error: "Supabase is not configured. Add the project URL and publishable key to your environment." }; }

  const { data, error } = await supabase.auth.signInWithPassword({ email, password });
  if (error || !data.user) return { error: "Sign-in failed. Check your details or ask your school administrator for help." };

  const { data: profile, error: profileError } = await supabase
    .from("profiles")
    .select("role, school_id, full_name")
    .eq("id", data.user.id)
    .single();

  const appRole = data.user.app_metadata?.role;
  const appSchoolId = data.user.app_metadata?.school_id;
  const supported = ["school_admin", "teacher", "parent"].includes(String(profile?.role));
  if (profileError || !profile || !supported || !appRole || !appSchoolId || appRole !== profile.role || appSchoolId !== profile.school_id) {
    await supabase.auth.signOut();
    return { error: "Your account profile is incomplete or not yet enabled. Contact your school administrator." };
  }

  redirect("/");
}

export async function signOut() {
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect("/login");
}
