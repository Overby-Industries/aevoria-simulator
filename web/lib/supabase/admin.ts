import "server-only";
import { createClient as createSupabaseClient } from "@supabase/supabase-js";

// Bypasses Row Level Security entirely — the service_role key can read/
// write ANY row regardless of policy. Only use this for code paths that
// have already independently verified the caller is authorized (e.g. the
// signature-verified Stripe webhook, or requireAdmin() checks). Never
// construct this from a value that came from the request/client.
export function createAdminClient() {
  return createSupabaseClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    {
      auth: { autoRefreshToken: false, persistSession: false },
    }
  );
}
