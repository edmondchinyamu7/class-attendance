import { NextResponse } from "next/server";
import { checkDatabase } from "@/lib/db";
export async function GET() {
  try { const db = await checkDatabase(); return NextResponse.json({ ok:true, database:"connected", serverTime:db.server_time }); }
  catch { return NextResponse.json({ ok:false, database:"not_configured" }, { status:503 }); }
}
