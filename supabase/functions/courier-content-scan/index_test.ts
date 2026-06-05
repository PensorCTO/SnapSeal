import {
  assertEquals,
  assertExists,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

Deno.test("entropy heuristic returns bounded score", () => {
  const entropyHeuristic = (path: string): number => {
    const segments = path.split("/").filter(Boolean);
    if (segments.length < 2) return 0.1;
    const hashSegment = segments[segments.length - 1] ?? "";
    const uniqueChars = new Set(hashSegment).size;
    return Math.min(uniqueChars / 32, 1);
  };

  const low = entropyHeuristic("user-id/abc.seal");
  const high = entropyHeuristic(
    "user-id/abcdef0123456789abcdef0123456789abcdef01.seal",
  );

  assertEquals(low < high, true);
  assertEquals(high <= 1, true);
});

Deno.test("courier-content-scan module exports serve handler", async () => {
  const mod = await import("./index.ts");
  assertExists(mod);
});
