// anchor-relay — ProofLock Polygon saga relay (live mainnet)
//
// Contract:
//   POST /functions/v1/anchor-relay
//   Authorization: Bearer <user JWT>
//   Body: { asset_hash, owner_signature, device_signature }
//   Response 200: { transactionHash: string, status: "pending" | "already_notarized" }
//
// Environment (supabase secrets):
//   ALCHEMY_API_URL — Polygon RPC URL (used by ethers JsonRpcProvider)
//   RELAYER_PRIVATE_KEY — Funded hot wallet for notarize() gas
//   SUPABASE_URL — Supabase project URL
//   SUPABASE_SERVICE_ROLE_KEY — Service role key for admin DB writes

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import {
  hashMessage,
  hexToBytes,
  recoverAddress,
} from "https://esm.sh/viem@2.23.2";
import { ethers } from "https://esm.sh/ethers@5.7.2";

const CONTRACT_ADDRESS = "0x83508c78104b8b58ff844EE5654FaaC06cFFc155";
const CONTRACT_ABI = ["function notarize(bytes32 fileHash) external"];

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type RelayPayload = {
  asset_hash?: string;
  owner_signature?: string;
  device_signature?: string;
};

function jsonResponse(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function normalizeHash(raw: string): `0x${string}` {
  const trimmed = raw.trim().toLowerCase();
  if (trimmed.startsWith("0x")) {
    return trimmed as `0x${string}`;
  }
  return `0x${trimmed}` as `0x${string}`;
}

function normalizeSignature(raw: string): `0x${string}` {
  const trimmed = raw.trim();
  if (trimmed.startsWith("0x")) {
    return trimmed as `0x${string}`;
  }
  return `0x${trimmed}` as `0x${string}`;
}

async function recoverSignerAddress(
  assetHash: string,
  ownerSignature: string,
): Promise<`0x${string}`> {
  const hashBytes = hexToBytes(normalizeHash(assetHash));
  const messageHash = hashMessage({ raw: hashBytes });
  return recoverAddress({
    hash: messageHash,
    signature: normalizeSignature(ownerSignature),
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Only POST is accepted" }, 405);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return jsonResponse({ error: "Missing Authorization bearer token" }, 401);
  }

  let payload: RelayPayload;
  try {
    payload = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const assetHash = payload.asset_hash?.trim();
  const ownerSignature = payload.owner_signature?.trim();
  const deviceSignature = payload.device_signature?.trim();

  if (!assetHash) {
    return jsonResponse({ error: "asset_hash is required" }, 400);
  }
  if (!ownerSignature) {
    return jsonResponse({ error: "owner_signature is required" }, 400);
  }
  if (!deviceSignature) {
    return jsonResponse({ error: "device_signature is required" }, 400);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    return jsonResponse({ error: "Relay misconfigured" }, 500);
  }

  const userClient = createClient(supabaseUrl, Deno.env.get("SUPABASE_ANON_KEY") ?? serviceRoleKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const adminClient = createClient(supabaseUrl, serviceRoleKey);

  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user) {
    return jsonResponse({ error: "Invalid auth token" }, 401);
  }

  const userId = userData.user.id;

  const { data: profile, error: profileError } = await userClient
    .from("profiles")
    .select("wallet_id, evm_address")
    .eq("id", userId)
    .maybeSingle();

  if (profileError || !profile?.wallet_id) {
    return jsonResponse({ error: "Profile wallet not found" }, 403);
  }

  let recoveredAddress: `0x${string}`;
  try {
    recoveredAddress = await recoverSignerAddress(assetHash, ownerSignature);
  } catch {
    return jsonResponse({ error: "Invalid owner_signature" }, 400);
  }

  const profileAddress = (profile.evm_address as string | null)?.toLowerCase();
  if (!profileAddress || profileAddress !== recoveredAddress.toLowerCase()) {
    return jsonResponse({ error: "Signature address mismatch" }, 403);
  }

  const { data: pendingRow, error: pendingError } = await adminClient
    .from("proof_ledger")
    .select("asset_hash, notarization_status")
    .eq("asset_hash", assetHash)
    .eq("wallet_id", profile.wallet_id)
    .maybeSingle();

  if (pendingError || !pendingRow) {
    return jsonResponse({ error: "Pending proof_ledger row not found" }, 404);
  }

  if (pendingRow.notarization_status === "notarized") {
    const { data: finalized } = await adminClient
      .from("proof_ledger")
      .select("chain_tx_hash")
      .eq("asset_hash", assetHash)
      .maybeSingle();
    return jsonResponse({
      transactionHash: finalized?.chain_tx_hash,
      status: "already_notorized",
    });
  }

  // --- POLYGON BROADCAST (live mainnet only; no simulated tx hashes) ---
  // Deploy marker: live-only relay (2026-05-22).
  const rpcUrl = Deno.env.get("ALCHEMY_API_URL");
  const relayerKey = Deno.env.get("RELAYER_PRIVATE_KEY");

  if (!rpcUrl || !relayerKey) {
    const missing = [
      !rpcUrl ? "ALCHEMY_API_URL" : null,
      !relayerKey ? "RELAYER_PRIVATE_KEY" : null,
    ].filter(Boolean);

    console.error(
      `anchor-relay: live Polygon secrets missing: ${missing.join(", ")}`,
    );

    return jsonResponse(
      {
        error: "Relayer environment not configured",
        missing,
        message:
          "Set ALCHEMY_API_URL and RELAYER_PRIVATE_KEY via supabase secrets set before notarizing on Polygon mainnet.",
      },
      500,
    );
  }

  let txHash: string;
  try {
    const provider = new ethers.providers.JsonRpcProvider(rpcUrl);
    const wallet = new ethers.Wallet(relayerKey, provider);
    const contract = new ethers.Contract(
      CONTRACT_ADDRESS,
      CONTRACT_ABI,
      wallet,
    );

    const hexValue = assetHash.startsWith("0x")
      ? assetHash.slice(2)
      : assetHash;
    const fileHashBytes32 = ("0x" + hexValue.slice(0, 64).padStart(64, "0")) as `0x${string}`;

    const feeData = await provider.getFeeData();
    const maxPriorityFeePerGas = ethers.utils.parseUnits("40", "gwei");

    const tx = await contract.notarize(fileHashBytes32, {
      maxPriorityFeePerGas,
      maxFeePerGas: feeData.lastBaseFeePerGas
        .mul(2)
        .add(maxPriorityFeePerGas),
    });

    txHash = tx.hash;
  } catch (error) {
    console.error("Polygon broadcast failed:", error);

    await adminClient.rpc("fail_polygon_notarization", {
      p_asset_hash: assetHash,
      p_wallet_id: profile.wallet_id,
    });

    return jsonResponse(
      {
        error: "Blockchain transaction failed",
        message: error instanceof Error ? error.message : String(error),
      },
      500,
    );
  }

  // Record successful broadcast in proof_ledger
  const { error: finalizeError } = await adminClient.rpc(
    "finalize_polygon_notarization",
    {
      p_asset_hash: assetHash,
      p_chain_tx_hash: txHash,
      p_wallet_id: profile.wallet_id,
    },
  );

  if (finalizeError) {
    // Transaction already broadcast but DB update failed — log and return hash anyway
    // The NotarizationMonitorService will pick up pending transactions
    console.error(
      `finalize_polygon_notarization RPC failed for ${assetHash}: ${finalizeError.message}`,
    );
  }

  return jsonResponse({
    transactionHash: txHash,
    status: "pending",
  });
});
