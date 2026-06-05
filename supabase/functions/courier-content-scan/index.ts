// courier-content-scan — Async moderation placeholder for courier-blobs uploads.
//
// Contract:
//   POST /functions/v1/courier-content-scan
//   Body: { package_id } or { storage_path, owner_id }
//   Response 200: { scan_status, ml_score, human_review_required }

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const QUARANTINE_THRESHOLD = 0.85;

type ScanPayload = {
  package_id?: string;
  storage_path?: string;
  owner_id?: string;
};

function jsonResponse(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function entropyHeuristic(path: string): number {
  // v1 placeholder: metadata-only signal on encrypted blobs (zero-knowledge preserved).
  const segments = path.split("/").filter(Boolean);
  if (segments.length < 2) return 0.1;
  const hashSegment = segments[segments.length - 1] ?? "";
  const uniqueChars = new Set(hashSegment).size;
  return Math.min(uniqueChars / 32, 1);
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

  if (!supabaseUrl || !serviceRoleKey) {
    return jsonResponse({ error: "Supabase configuration missing" }, 500);
  }

  let payload: ScanPayload;
  try {
    payload = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const admin = createClient(supabaseUrl, serviceRoleKey);

  let packageId = payload.package_id?.trim() ?? "";
  let storagePath = payload.storage_path?.trim() ?? "";

  if (!packageId && storagePath) {
    const { data: pkgRow } = await admin
      .from("courier_packages")
      .select("package_id, storage_path")
      .eq("storage_path", storagePath)
      .maybeSingle();

    if (pkgRow?.package_id) {
      packageId = pkgRow.package_id;
      storagePath = pkgRow.storage_path ?? storagePath;
    }
  }

  if (!packageId) {
    return jsonResponse({ error: "package_id or storage_path is required" }, 400);
  }

  if (!storagePath) {
    const { data: pkgRow } = await admin
      .from("courier_packages")
      .select("storage_path")
      .eq("package_id", packageId)
      .maybeSingle();
    storagePath = pkgRow?.storage_path ?? "";
  }

  const mlScore = entropyHeuristic(storagePath);
  const humanReviewRequired = mlScore >= QUARANTINE_THRESHOLD;
  const scanStatus = "completed";
  const moderationStatus = humanReviewRequired ? "quarantined" : "cleared";

  await admin.from("courier_moderation_queue").upsert(
    {
      package_id: packageId,
      scan_status: scanStatus,
      ml_score: mlScore,
      human_review_required: humanReviewRequired,
      scan_notes: "v1 metadata heuristic on encrypted blob path",
      updated_at: new Date().toISOString(),
    },
    { onConflict: "package_id" },
  );

  await admin
    .from("courier_packages")
    .update({ moderation_status: moderationStatus, updated_at: new Date().toISOString() })
    .eq("package_id", packageId);

  return jsonResponse({
    package_id: packageId,
    scan_status: scanStatus,
    ml_score: mlScore,
    human_review_required: humanReviewRequired,
    moderation_status: moderationStatus,
  });
});
