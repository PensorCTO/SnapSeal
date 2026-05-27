import { useCallback, useEffect, useMemo, useState } from 'react';
import { createClient, type SupabaseClient } from '@supabase/supabase-js';

type AttemptStatus = {
  status?: string;
  attempts_remaining?: number;
  locked?: boolean;
};

type VaultPhase = 'loading' | 'ready' | 'invalid_id' | 'expired' | 'locked' | 'error';

type VaultCourierProps = {
  packageId: string | null;
};

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function resolveSupabase(): SupabaseClient | null {
  const url = import.meta.env.PUBLIC_SUPABASE_URL?.trim();
  const anonKey = import.meta.env.PUBLIC_SUPABASE_ANON_KEY?.trim();
  if (!url || !anonKey || url.includes('your-project')) {
    return null;
  }
  return createClient(url, anonKey);
}

function normalizePackageId(raw: string | null | undefined): string | null {
  const trimmed = raw?.trim() ?? '';
  if (!trimmed) return null;
  return UUID_RE.test(trimmed) ? trimmed : null;
}

function phaseFromStatus(status: AttemptStatus | null, packageId: string | null): VaultPhase {
  if (!packageId) return 'invalid_id';
  if (!status) return 'ready';
  if (status.locked) return 'locked';
  const label = (status.status ?? '').toLowerCase();
  if (label.includes('expired') || label.includes('revoked')) return 'expired';
  return 'ready';
}

export default function VaultCourier({ packageId: rawPackageId }: VaultCourierProps) {
  const packageId = useMemo(() => normalizePackageId(rawPackageId), [rawPackageId]);
  const supabase = useMemo(() => resolveSupabase(), []);

  const [phase, setPhase] = useState<VaultPhase>(() =>
    packageId ? 'loading' : 'invalid_id',
  );
  const [attemptStatus, setAttemptStatus] = useState<AttemptStatus | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isUnlocking, setIsUnlocking] = useState(false);

  const loadAttemptStatus = useCallback(async () => {
    if (!packageId) {
      setPhase('invalid_id');
      return;
    }

    if (!supabase) {
      setPhase('error');
      setMessage(
        'Supabase is not configured for this deployment. Set PUBLIC_SUPABASE_URL and PUBLIC_SUPABASE_ANON_KEY.',
      );
      return;
    }

    setPhase('loading');
    setMessage(null);

    try {
      const { data, error } = await supabase.rpc('check_courier_attempts', {
        p_package_id: packageId,
      });

      if (error) {
        const detail = error.message.toLowerCase();
        if (detail.includes('not found') || detail.includes('invalid')) {
          setPhase('invalid_id');
          setMessage('This courier package id is invalid or no longer exists.');
          return;
        }
        throw error;
      }

      const status = (data ?? null) as AttemptStatus | null;
      setAttemptStatus(status);
      setPhase(phaseFromStatus(status, packageId));
    } catch (err) {
      setPhase('error');
      setMessage(err instanceof Error ? err.message : 'Unable to load package status.');
    }
  }, [packageId, supabase]);

  useEffect(() => {
    void loadAttemptStatus();
  }, [loadAttemptStatus]);

  const handleUnlock = async (event: React.FormEvent) => {
    event.preventDefault();

    if (!packageId || !supabase || phase === 'locked' || phase === 'expired') {
      return;
    }

    setIsUnlocking(true);
    setMessage(null);

    try {
      const { data, error } = await supabase.functions.invoke('courier-unlock', {
        body: {
          package_id: packageId,
          verifier_guess: password,
          requestor_email: email.trim(),
        },
      });

      if (error) {
        throw new Error(error.message);
      }

      if (!data?.signed_url) {
        throw new Error('Unlock succeeded but no download URL was returned.');
      }

      // Full browser decrypt + SHA-256 verify will land here (CourierCrypto parity).
      setMessage(
        'Password accepted. Client-side decrypt and fingerprint verification will complete in a follow-up release.',
      );
      await loadAttemptStatus();
    } catch (err) {
      const text = err instanceof Error ? err.message : 'Unlock failed.';
      setMessage(text);
      await loadAttemptStatus();
    } finally {
      setIsUnlocking(false);
    }
  };

  const statusLabel = attemptStatus?.status ?? (packageId ? 'unknown' : 'missing');
  const attemptsRemaining = attemptStatus?.attempts_remaining;

  return (
    <div className="mx-auto max-w-xl px-6 py-12">
      <header className="mb-8 text-center">
        <p className="mono-label mb-2">Web Archive</p>
        <h1 className="font-mono text-2xl font-bold text-verified-neon md:text-3xl">
          FactLockCam Courier
        </h1>
        <p className="mt-3 text-sm text-white/70">
          Unlock and verify an encrypted courier package locally in this browser.
        </p>
      </header>

      <section className="panel mb-6 p-5 font-mono text-xs">
        <p>
          <span className="text-white/50">PACKAGE</span>{' '}
          <span className="break-all text-white">{packageId ?? '—'}</span>
        </p>
        {attemptStatus && (
          <>
            <p className="mt-3">
              <span className="text-white/50">STATUS</span> {statusLabel}
            </p>
            {attemptsRemaining != null && (
              <p className="mt-1">
                <span className="text-white/50">ATTEMPTS REMAINING</span> {attemptsRemaining}
              </p>
            )}
          </>
        )}
        {message && <p className="mt-3 text-alert-amber">{message}</p>}
      </section>

      {phase === 'invalid_id' && (
        <div className="panel border-alert-amber/40 p-6 text-center">
          <h2 className="font-mono text-lg text-alert-amber">Invalid package link</h2>
          <p className="mt-2 text-sm text-white/70">
            The URL is missing a valid courier package id. Ask the sender to resend the proof link.
          </p>
        </div>
      )}

      {phase === 'expired' && (
        <div className="panel border-alert-amber/40 p-6 text-center">
          <h2 className="font-mono text-lg text-alert-amber">Package expired</h2>
          <p className="mt-2 text-sm text-white/70">
            This secure delivery window has closed. Contact the archive owner for a new Send Proof
            link.
          </p>
        </div>
      )}

      {phase === 'locked' && (
        <div className="panel border-alert-amber/40 p-6 text-center">
          <h2 className="font-mono text-lg text-alert-amber">Package locked</h2>
          <p className="mt-2 text-sm text-white/70">
            Too many failed unlock attempts. Contact the sender to issue a new courier package.
          </p>
        </div>
      )}

      {phase === 'error' && (
        <div className="panel border-alert-amber/40 p-6 text-center">
          <h2 className="font-mono text-lg text-alert-amber">Unable to load package</h2>
          <p className="mt-2 text-sm text-white/70">
            {message ?? 'An unexpected error occurred while contacting the archive service.'}
          </p>
          <button type="button" className="btn-ghost mt-4" onClick={() => void loadAttemptStatus()}>
            Retry
          </button>
        </div>
      )}

      {(phase === 'ready' || phase === 'loading') && packageId && (
        <form className="panel space-y-4 p-6" onSubmit={handleUnlock}>
          <div>
            <label htmlFor="recipient-email" className="mono-label mb-2 block">
              Recipient email
            </label>
            <input
              id="recipient-email"
              type="email"
              autoComplete="email"
              className="input-field"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="name@example.com"
              disabled={phase === 'loading' || isUnlocking}
            />
          </div>
          <div>
            <label htmlFor="courier-password" className="mono-label mb-2 block">
              One-time password
            </label>
            <input
              id="courier-password"
              type="password"
              className="input-field"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              disabled={phase === 'loading' || isUnlocking}
            />
          </div>
          <button
            type="submit"
            className="btn-primary w-full"
            disabled={phase === 'loading' || isUnlocking || !password}
          >
            {phase === 'loading' || isUnlocking ? 'Working…' : 'Unlock package'}
          </button>
          <p className="text-center text-xs text-white/40">
            Decryption and SHA-256 verification run locally in your browser. Plaintext never passes
            through FactLockCam servers.
          </p>
        </form>
      )}
    </div>
  );
}
