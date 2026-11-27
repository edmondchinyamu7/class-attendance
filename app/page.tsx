import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { signOut } from "./login/actions";
import DashboardClient from "./dashboard-client";

export default async function HomePage() {
  const supabase = await createClient();
  const { data: claimsData, error: claimsError } = await supabase.auth.getClaims();
  const claims = claimsData?.claims;
  if (claimsError || !claims?.sub) redirect("/login");

  const { data: profile, error: profileError } = await supabase
    .from("profiles")
    .select("id, full_name, role, school_id")
    .eq("id", claims.sub)
    .single();

  const metadata = claims.app_metadata as { role?: string; school_id?: string } | undefined;
  if (profileError || !profile || profile.id !== claims.sub || profile.role !== metadata?.role || profile.school_id !== metadata?.school_id) {
    await supabase.auth.signOut();
    redirect("/login?error=profile");
  }

  if (profile.role !== "school_admin") {
    const roleName = profile.role === "teacher" ? "Teacher" : profile.role === "parent" ? "Parent" : "User";
    return <main className="flex min-h-screen items-center justify-center bg-[#f5f7f8] p-5"><section className="w-full max-w-lg rounded-2xl border border-[#e8eef0] bg-white p-8 text-center shadow-sm"><div className="mx-auto mb-4 grid h-12 w-12 place-items-center rounded-xl bg-[#e8f5ee] text-[#16845b]">CP</div><h1 className="text-xl font-extrabold text-[#102a43]">Welcome to ClassPilot</h1><p className="mt-3 text-sm leading-6 text-[#627d98]">You are signed in as a {roleName.toLowerCase()}. The {roleName.toLowerCase()} portal is not enabled in this development phase. Your account is authenticated, but no school records are exposed on this page.</p><form action={signOut} className="mt-6"><button className="btn-primary">Sign out</button></form></section></main>;
  }

  return <DashboardClient />;
}
