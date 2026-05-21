# Blueprint — Phase 2: FactLockCam to ProofLock (10 MAY 2026)

## 1. Architectural Manifest

This phase transitions the application from a "Camera-First" utility to a "Vault-First" evidence ledger, prioritizing tamper-evident integrity signals (risk reduction), zero-latency rendering, and strict hardware provenance for media capture.

```mermaid
graph TD
    A[Supabase Auth Session] -->|Route: /vault-dashboard| B(Vault Dashboard)
    
    subgraph Presentation Layer: Vault-First
    B -->|Fetch via Riverpod| C[(Local SQLite Metadata)]
    B -.->|Background Sync| D[(Supabase media tables)]
    end
    
    subgraph Action Layer: Lightweight Modals
    B -->|Tap Thumbnail| E[Hero Animation Bottom Sheet]
    E -->|Select 'Certificate'| F[Generate PDF via pdf/printing]
    E -->|Select 'Courier'| G[Isolate: Encrypt & Package .plock]
    F --> H[OS Share Sheet share_plus]
    G --> H
    end

    subgraph Capture Layer: Strict Provenance
    B -->|Tap FAB| I[Sandboxed Camera UI]
    I -->|AcquisitionMode: Photo| J[In-Memory Hash & AES-GCM]
    I -->|AcquisitionMode: Video| J
    J --> C
    end