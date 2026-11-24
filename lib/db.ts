import { sql } from "@vercel/postgres";
export { sql };
export async function checkDatabase() { const result = await sql\`select now() as server_time\`; return result.rows[0]; }
