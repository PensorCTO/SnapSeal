### **Architectural Manifest: ProofLock Viability & System Architecture**

**Viability Assessment:** YES, highly viable, but contingent on solving the "Biometric Injection" vulnerability. The market analysis dictates that software-only hashing is insufficient against sophisticated AI spoofing. To compete with Truepic and ZCAM, ProofLock must utilize hardware-level security (Apple Secure Enclave / Android TEE). The zero-knowledge architecture (local hashing, no cloud media upload)  combined with Polygon anchoring provides a massive privacy and cost advantage over centralized competitors.

#### **Trade-Off Matrix: Hardware vs. Software Provenance**

| Architecture | Pros | Cons | Decision for App Store Success |
| :---- | :---- | :---- | :---- |
| **Pure Flutter (Software Hashing)** | Rapid cross-platform development; easy to maintain. | Vulnerable to virtual camera injection; fails enterprise/legal standards.  | **REJECTED.** Will not survive enterprise scrutiny. |
| **Flutter \+ Native Platform Channels (Hardware Enclave)** | Cryptographic proof of physical device origin; highly defensible in court (FRE 901).  | High complexity; requires writing Swift (CryptoKit) and Kotlin (Keystore) bindings. | **APPROVED.** Mandatory for establishing a zero-trust provenance pipeline. |
| **Flutter \+ C2PA FFI Integration** | Industry standard compatibility; portable metadata. | Large binary size; complex Rust-to-Dart FFI bridging. | **APPROVED.** Dual-layer (Blockchain \+ C2PA) is the market equilibrium. |

#### **Core System Flow (C4 Context)**

Code snippet

graph TD  
    subgraph Mobile Device \["iOS / Android Device (Flutter)"\]  
        UI\["Presentation Layer (Riverpod)"\]  
        ISO\["Isolate: SHA-256 Hashing"\]  
        TEE\["Native Enclave (CryptoKit/Keystore)"\]  
        UI \--\>|Raw Pixels| ISO  
        ISO \--\>|Hash| TEE  
        TEE \--\>|Signed Hash| UI  
    end

    subgraph Backend \["Supabase (PostgreSQL)"\]  
        RPC\["Edge Functions (RPC)"\]  
        DB\[("proof\_ledger\\ncourier\_packages")\]  
    end

    subgraph Blockchain \["Polygon Network"\]  
        SC\["Smart Contract (EVM)"\]  
    end

    UI \--\>|1. Pre-flight Check| RPC  
    RPC \--\>|2. Query| DB  
    UI \--\>|3. Anchor Payload| SC  
    UI \--\>|4. Record Tx| RPC  
    RPC \--\>|5. Insert| DB

### ---

**Cursor Strategy Rules (.mdc)**

Create the following files in the .cursor/rules/ directory to enforce architectural constraints during AI code generation.

#### **01-flutter-state-performance.mdc**

Markdown

\---  
description: Enforces Riverpod state management and UI performance optimizations  
globs: lib/presentation/**\*\*/*\*.dart***  
***\---***  
***\# UI Performance & State Constraints***  
***\- \*\*State Management\*\*: Strictly use \`flutter\_riverpod\` (v2.x). Use \`@riverpod\` code generation for \`Notifier\` and \`AsyncNotifier\`. Do not use \`ChangeNotifier\` or \`BLoC\`.***  
***\- \*\*Rendering Isolation\*\*: Complex UI components with high-frequency updates (e.g., the SHA-256 hashing progress ring in Screen 2\) MUST be wrapped in a \`RepaintBoundary\` to isolate the compositing layer and prevent full-tree repaints.***  
***\- \*\*Heavy Computation\*\*: All cryptographic hashing (\`crypto\` package) and file I/O operations MUST be offloaded to Dart Isolates using \`Isolate.run()\` to prevent UI thread frame drops.***

#### **02-postgres-schema-rls.mdc**

Markdown

\---  
description: Enforces Supabase PostgreSQL schema optimization and RLS rules  
globs: supabase/migrations/*\*.sql*  
*\---*  
*\# PostgreSQL Schema & Security Constraints*  
*\- **\*\*Indexing\*\***: The \`proof\_ledger\` table MUST maintain a \`UNIQUE INDEX\` on \`asset\_hash\`. Use B-tree indexes for \`transaction\_hash\` and \`owner\_id\` to optimize lookup speed.*  
*\- **\*\*RLS (Row Level Security)\*\***: All media and ledger tables must enforce RLS. \`SELECT\` operations should be restricted to authenticated users matching \`owner\_id\`.*   
*\- **\*\*Black-Box Architecture\*\***: \`courier\_packages\` MUST NOT allow direct \`SELECT\` queries. All reads must go through explicit RPC functions (e.g., \`attempt\_courier\_unlock\`) using \`SECURITY DEFINER\` to prevent unauthorized scraping.*

#### **03-hardware-cryptography.mdc**

Markdown

\---  
description: Constraints for Sovereign-Key / Ghost-Key cryptography pipeline  
globs: lib/core/ghost*\_key/**\*\*/\*.dart, ios/Runner/\*\*/\*.swift, android/app/src/main/\*\*/\*.kt***  
***\---***  
***\# Cryptography & Platform Channels***  
***\- \*\*Hardware Enclave\*\*: Do not use purely software-based key generation for signing proofs. Keys MUST be generated and stored in the iOS Secure Enclave (via CryptoKit) or Android hardware-backed Keystore.***  
***\- \*\*Platform Channels\*\*: Use Flutter \`MethodChannel\` to request the native layer to sign the \`asset\_hash\` with the device-bound key.***  
***\- \*\*Local Archive\*\*: File encryption MUST use XOR \+ SHA256 derivation via \`VaultEncryptionHandler\`. Media must be deleted from temporary unencrypted storage immediately after successful vault insertion.***

### ---

**The Blueprint: ProofLock Implementation Spec**

#### **1\. Database Schema Optimization (PostgreSQL)**

Ensure the following indexes and functions are present in the next Supabase migration to support fast verification and scale.

SQL

\-- High-performance lookup indexes  
CREATE UNIQUE INDEX idx\_proof\_ledger\_hash ON proof\_ledger(asset\_hash);  
CREATE INDEX idx\_proof\_ledger\_owner ON proof\_ledger(owner\_id);  
CREATE INDEX idx\_media\_transaction ON picture(transaction\_hash);

\-- Enforce zero-knowledge courier architecture  
ALTER TABLE courier\_packages ENABLE ROW LEVEL SECURITY;  
CREATE POLICY "Insert own courier packages" ON courier\_packages FOR INSERT WITH CHECK (auth.uid() \= owner\_id);  
\-- No SELECT policy for courier\_packages to enforce RPC-only access

\-- Optimized pre-flight check (Context Anchor: check\_proof\_status)  
CREATE OR REPLACE FUNCTION check\_proof\_status(p\_file\_hash text)   
RETURNS text   
LANGUAGE plpgsql  
SECURITY DEFINER  
AS $$  
DECLARE  
    v\_owner uuid;  
BEGIN  
    SELECT owner\_id INTO v\_owner FROM proof\_ledger WHERE asset\_hash \= p\_file\_hash;  
    IF NOT FOUND THEN RETURN 'new'; END IF;  
    IF v\_owner IS NULL THEN RETURN 'anonymous'; END IF;  
    IF v\_owner \= auth.uid() THEN RETURN 'owned\_by\_me'; END IF;  
    RETURN 'owned\_by\_other';  
END;  
$$;

#### **2\. Flutter File Structure Changes**

Map the UI Blueprint to the existing Layer 3 Presentation architecture.

Plaintext

lib/  
├── core/  
│   ├── ghost\_key/  
│   │   ├── native\_enclave\_channel.dart    \<-- ADDED: MethodChannel for Secure Enclave  
│   │   └── crypto/  
├── presentation/  
│   ├── capture/  
│   │   ├── capture\_screen.dart            \<-- Screen 1: Native Camera integration  
│   │   └── providers/capture\_provider.dart  
│   ├── fingerprint/  
│   │   ├── fingerprint\_screen.dart        \<-- Screen 2: RepaintBoundary for Progress Ring  
│   │   ├── widgets/hashing\_progress\_ring.dart   
│   │   └── isolate/hash\_worker.dart       \<-- ADDED: Off-thread SHA-256 calculation  
│   ├── notarization/  
│   │   ├── submit\_chain\_screen.dart       \<-- Screen 3: Chain selection  
│   │   └── providers/blockchain\_provider.dart  
│   ├── verification/  
│   │   ├── certificate\_screen.dart        \<-- Screen 4: QR Generation  
│   │   └── verify\_public\_screen.dart      \<-- Screen 5: Public API / No Auth required

#### **3\. Core Logic Integration (Context Anchor: VaultService.proofLockFile)**

Refactor the existing pipeline to inject hardware signing before blockchain notarization.

Dart

// lib/core/services/vault\_service.dart

Future\<ProofResult\> proofLockFile(File sourceFile, String userId) async {  
  // 1\. Offload hashing to Isolate to maintain 60fps UI  
  final String fileHash \= await Isolate.run(() \=\> \_calculateSHA256(sourceFile));  
    
  // 2\. Pre-flight RPC  
  final status \= await \_supabase.rpc('check\_proof\_status', params: {'p\_file\_hash': fileHash});  
  if (status \!= 'new') throw ProofExistsException(status);

  // 3\. HARDWARE SIGNING (Required for App Store Viability & Market Parity)  
  // Invokes iOS Secure Enclave or Android TEE via MethodChannel  
  final String deviceSignature \= await \_nativeEnclave.signHash(fileHash);

  // 4\. Polygon Notarization  
  final String txHash \= await \_blockchainHandler.notarizeFileHash(  
    fileHash: fileHash,   
    deviceSignature: deviceSignature,  
  );

  // 5\. Local Archive Encryption & DB Sync  
  await \_encryptionHandler.encryptToFile(sourceFile, userId, fileHash);  
  await \_supabase.from('proof\_ledger').insert({  
    'asset\_hash': fileHash,  
    'owner\_id': userId,  
    'tx\_hash': txHash,  
    'media\_type': \_determineMediaType(sourceFile),  
  });

  // 6\. Burn original  
  await sourceFile.delete();  
    
  return ProofResult.success(txHash);  
}  
