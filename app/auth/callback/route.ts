import { NextResponse, type NextRequest } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function GET(request: NextRequest) {
  const url = request.nextUrl;
  const code = url.searchParams.get("code");
  const tokenHash = url.searchParams.get("token_hash");
  const type = url.searchParams.get("type");
  const next = url.searchParams.get("next");
  const safeNext = next && next.startsWith("/") && !next.startsWith("//") ? next : "/";

  const supabase = await createClient();
  let error: unknown = null;
  if (code) {
    const result = await supabase.auth.exchangeCodeForSession(code);
    error = result.error;
  } else if (tokenHash && ["invite", "signup", "recovery", "email"].includes(String(type))) {
    const result = await supabase.auth.verifyOtp({ token_hash: tokenHash, type: type as "invite" | "signup" | "recovery" | "email" });
    error = result.error;
  } else {
    error = new Error("Missing or invalid authentication callback parameters.");
  }

  if (!error) return NextResponse.redirect(new URL(safeNext, url.origin));
  return NextResponse.redirect(new URL("/login?error=confirmation", url.origin));
}
