import { neon } from "@neondatabase/serverless";

export function getDb() {
  const url = process.env.DATABASE_URL;
  if (!url) throw new Error("DATABASE_URL is not configured.");
  return neon(url);
}

export async function checkDatabase() {
  const sql = getDb();
  const rows = await sql`select now() as server_time`;
  return rows[0] as { server_time: string };
}
