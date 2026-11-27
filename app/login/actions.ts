"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
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


export async function registerStudent(formData: FormData) {
  const fullName = String(formData.get("full_name") || "").trim();
  const studentCode = String(formData.get("student_code") || "").trim().toUpperCase();
  const className = String(formData.get("class_name") || "").trim();
  const phone = String(formData.get("phone") || "").trim();
  const parentName = String(formData.get("parent_name") || "").trim();
  const parentPhone = String(formData.get("parent_phone") || "").trim();
  const parentEmail = String(formData.get("parent_email") || "").trim().toLowerCase();

  if (fullName.length < 2 || fullName.length > 120 || studentCode.length < 2 || studentCode.length > 40 ||
      !/^Form [1-4][A-C]$/.test(className) || phone.length > 30 || parentName.length > 120 ||
      parentPhone.length > 30 || parentEmail.length > 254 ||
      (parentEmail && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(parentEmail))) {
    redirect("/?error=student-input");
  }

  const supabase = await createClient();
  const { data: claimsData, error: claimsError } = await supabase.auth.getClaims();
  const claims = claimsData?.claims;
  if (claimsError || !claims?.sub) redirect("/login");

  const { data: profile, error: profileError } = await supabase
    .from("profiles")
    .select("id, role, school_id")
    .eq("id", claims.sub)
    .single();
  const metadata = claims.app_metadata as { role?: string; school_id?: string } | undefined;

  if (profileError || !profile || profile.id !== claims.sub || profile.role !== "school_admin" ||
      metadata?.role !== profile.role || metadata?.school_id !== profile.school_id) {
    redirect("/login?error=profile");
  }

  const { error } = await supabase.from("students").insert({
    school_id: profile.school_id,
    student_code: studentCode,
    full_name: fullName,
    class_name: className,
    phone: phone || null,
    parent_name: parentName || null,
    parent_phone: parentPhone || null,
    parent_email: parentEmail || null,
  });

  if (error) redirect(error.code === "23505" ? "/?error=student-duplicate" : "/?error=student-save");
  revalidatePath("/");
  redirect("/?success=student-created");
}
