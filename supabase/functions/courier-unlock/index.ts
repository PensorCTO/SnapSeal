// courier-unlock — Password gate + short-lived signed blob URL for web recipients.
//
// Contract:
//   POST /functions/v1/courier-unlock
//   Body: { package_id, verifier_guess, requestor_email? }
//   Response 200: {
//     key, file_extension, asset_hash, signed_url, expires_in_seconds
//   }

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const SIGNED_URL_TTL_SECONDS = 60;

type UnlockPayload = {
  package_id?: string;
  verifier_guess?: string;
  requestor_email?: string;
};

function jsonResponse(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Only POST is accepted" }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");

  if (!supabaseUrl || !serviceRoleKey || !anonKey) {
    return jsonResponse({ error: "Supabase configuration missing" }, 500);
  }

  let payload: UnlockPayload;
  try {
    payload = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const packageId = payload.package_id?.trim() ?? "";
  const verifierGuess = payload.verifier_guess ?? "";
  const requestorEmail = payload.requestor_email?.trim() ?? "";

  if (!packageId) {
    return jsonResponse({ error: "package_id is required" }, 400);
  }

  const admin = createClient(supabaseUrl, serviceRoleKey);
  const { data: unlockRows, error: unlockError } = await admin.rpc(
    "attempt_courier_unlock",
    {
      p_package_id: packageId,
      p_verifier_guess: verifierGuess,
      p_requestor_email: requestorEmail,
    },
  );

  if (unlockError) {
    const message = unlockError.message ?? "Unlock failed";
    const status = message.includes("Invalid verifier") ? 403 : 423;
    return jsonResponse({ error: message }, status);
  }

  const row = Array.isArray(unlockRows) ? unlockRows[0] : unlockRows;
  if (!row) {
    return jsonResponse({ error: "Unlock returned no package data" }, 500);
  }

  const storagePath = row.storage_path as string;
  const storageBucket = (row.storage_bucket as string) || "courier-blobs";

  const { data: signed, error: signError } = await admin.storage
    .from(storageBucket)
    .createSignedUrl(storagePath, SIGNED_URL_TTL_SECONDS);

  if (signError || !signed?.signedUrl) {
    return jsonResponse(
      { error: signError?.message ?? "Failed to create signed download URL" },
      500,
    );
  }

  return jsonResponse({
    key: row.key,
    file_extension: row.file_extension,
    asset_hash: row.asset_hash,
    signed_url: signed.signedUrl,
    expires_in_seconds: SIGNED_URL_TTL_SECONDS,
  });
});
