# CMTAT ⇄ Stablecoin Feature Comparison

Feature-by-feature comparison between **CMTAT** (the CMTA Token standard, Solidity/EVM implementation) and six production stablecoins whose source is vendored in this repository.

The central question this document answers: **for each feature a real stablecoin ships, does CMTAT have it, and if not in the token itself, does one of the seven CMTA companion projects provide it?**

---

## Contents

1. [Sources and versions](#1-sources-and-versions)
   - [1.1 CMTAT and its companion projects](#11-cmtat-and-its-companion-projects)
   - [1.2 Stablecoins analysed](#12-stablecoins-analysed)
2. [How to read the tables](#2-how-to-read-the-tables)
3. [The CMTAT stack](#3-the-cmtat-stack)
4. [Comparison — token standards & signature flows](#4-token-standards--signature-flows)
5. [Comparison — supply control](#5-supply-control-issuance)
6. [Comparison — compliance & enforcement](#6-compliance--enforcement)
7. [Comparison — access control & governance](#7-access-control--governance)
8. [Comparison — upgradeability & lifecycle](#8-upgradeability--lifecycle)
9. [Comparison — yield, cross-chain and extras](#9-yield-cross-chain-and-extras)
10. [Gap analysis](#10-gap-analysis)

---

This document compares **CMTAT against the stablecoins**. For a stablecoin-to-stablecoin comparison that does not centre on CMTAT, see [`vendor/SUMMARY.md`](./vendor/SUMMARY.md).

## 1. Sources and versions

Every claim below was read from the code pinned in this repository, not from marketing material or third-party summaries. All submodule pins are the commits recorded in this repository's index, taken from `git submodule status`; run `git submodule update --init --recursive` to reproduce them.

### 1.1 CMTAT and its companion projects

Everything under [`cmtat/`](./cmtat/): the token standard, the seven companion projects that extend it, and `CMTAT-Confidential`, which is an alternative token build rather than a companion.

| Project | Role | Tag | Commit | Date | Solidity |
| --- | --- | --- | --- | --- | --- |
| CMTAT | the token standard | `v3.3.0-rc3` | `658672f` | 2026-07-31 | 0.8.36 |
| RuleEngine | transfer-restriction controller | `v3.0.0-rc6` | `ca75429` | 2026-08-21 | ^0.8.20 (compiled 0.8.36) |
| Rules | the 15 pluggable rules | `v0.6.0` | `283efe7` | 2026-08-24 | 0.8.36 |
| SnapshotEngine | on-chain balance snapshots | `v0.5.0` | `aa08935` | 2026-06-09 | 0.8.34 |
| CMTAT-Factory | CREATE2 proxy factories | `v0.5.0` | `46ca1ec` | 2026-08-26 | 0.8.36 |
| CMTAT-LayerZero | LayerZero V2 OFT adapters | `v0.2.0`+1 | `e57ca4f` | 2026-02-16 | 0.8.33 |
| CMTAT-ACE | Chainlink ACE policy-engine token builds | `v0.3.0` | `34fcb41` | 2026-06-26 | 0.8.x |
| CMTAT-CCIP | Chainlink CCIP deployment scripts | *(untagged)* | `c4f946d` | 2025-12-01 | 0.8.x |
| CMTAT-Confidential | Zama FHE confidential variant | `v1.0.0` | `285ed93` | 2026-07-10 | 0.8.x |

The CMTAT and RuleEngine pins are **release candidates**: their `version()` strings report `3.3.0` and `3.0.0`, but the tagged commits are `v3.3.0-rc3` and `v3.0.0-rc6`.

> **Chainlink's ACE policy library is not vendored here.** `CMTAT-ACE` ships its own extractors, `TransferValidationPolicy` and token builds, all read for this comparison, but the policies it attaches (`VolumeRatePolicy`, `SecureMintPolicy`, `PausePolicy`, …) come from the `@chainlink/ace` npm package, which is not installed in this tree. Claims about those policies are reproduced from [`cmtat/CMTAT-ACE/README.md`](./cmtat/CMTAT-ACE/README.md), not verified against their source. `CMTAT-ACE` also states it has had **no formal audit**, static analysis and AI review only, and `CMTAT-CCIP` is unaudited testnet tooling.

> **CMTAT in production as a stablecoin.** Zand Trust (2025) issued an AED stablecoin using CMTAT v3.0.0 via Taurus infrastructure ([Zand Trust](https://zandtrust.com/)).

CMTAT ships its own stablecoin comparison at [`cmtat/CMTAT/doc/technical/stablecoin.md`](./cmtat/CMTAT/doc/technical/stablecoin.md). It was used as a starting point, but **fourteen of its claims about USDC and USDT do not match the code in `vendor/`**, and those are catalogued, with evidence and suggested fixes, in [`stablecoin-doc-issue.md`](./stablecoin-doc-issue.md).

### 1.2 Stablecoins analysed

Everything under [`vendor/`](./vendor/): four upstream repositories pinned as submodules and two verified-source dumps taken from Etherscan.

| Issuer | Token(s) | Kind | Tag | Commit / address | Date | Solidity |
| --- | --- | --- | --- | --- | --- | --- |
| Circle | USDC, EURC | submodule | `release-2026-08-12T202509` | `fc85788` | 2026-08-12 | 0.6.12 |
| Paxos | USDP, USDG, PYUSD, PAXG | submodule | `v2.1.0`+3 | `674ac10` | 2026-07-29 | 0.8.28 |
| Monerium | EURe, GBPe, USDe, ISKe | submodule | `v2.0.0`+24 | `514bee7` | 2025-08-21 | 0.8.x |
| Wyoming | FRNT, wFRNT | submodule | *(untagged)* | `f8aa140` | 2026-04-30 | 0.8.22 |
| SG-FORGE | CoinVertible EURCV, USDCV | Etherscan dump | — | impl. `0xF4ccC80C…` | dumped 2026-08-26 | 0.8.22 |
| Tether | USDT | Etherscan dump | — | `0xdac17f95…` | dumped 2026-08-26 | 0.4.17 |

The Etherscan dumps capture a single **implementation** contract each, not a full repository: no tests, scripts or history. See [`vendor/README.md`](./vendor/README.md).

> **Wyoming — `frontier-stable-token`.** The Commission announced a migration from LayerZero to **Chainlink CCIP** in August 2026 ([press release](https://www.prnewswire.com/news-releases/wyoming-stable-token-commission-migrates-to-chainlink-ccip-for-enhanced-operational-security-302854502.html)). This snapshot still reflects the LayerZero architecture, so every FRNT / wFRNT cross-chain statement below describes the OFT design, not the one now in production.

## 2. How to read the tables

CMTAT is not one contract, so each table splits it into **three** columns. That makes it visible at a glance whether a feature is reachable from the variant CMTA actually recommends for stablecoins, from a heavier variant, or only from a companion project.

| Column | Meaning |
| --- | --- |
| **Light** | [`CMTATStandaloneLight` / `CMTATUpgradeableLight`](./cmtat/CMTAT/contracts/deployment/light/) — the variant CMTAT's own documentation recommends for stablecoins. the smallest CMTAT build: 11.3 KiB deployed, per CMTAT's own documentation (sizes were not recompiled here). |
| **CMTAT** | The token contract in any variant **other than** Light: `Standard`, `Permit`, or a dedicated one (`Allowlist`, `Snapshot`, `ERC1363`, `ERC7551`, `HolderList`, `Debt`, `UUPS`). The applicable variant is named in the cell. |
| **Companion** | A separate CMTA project that extends the token: **RuleEngine**, **Rules**, **SnapshotEngine**, **CMTAT-Factory**, **CMTAT-LayerZero**, **CMTAT-ACE** or **CMTAT-CCIP**. The specific contract or policy is named. |

> ### The Light variant cannot reach the companion contracts
>
> Light is the smallest CMTAT build, and the setters the companions plug into are only present in the heavier ones. **CMTAT-Factory is the only companion Light can definitely use.** (Evidence, for readers who want it: Light is built on [`0_CMTATBaseCore`](./cmtat/CMTAT/contracts/modules/0_CMTATBaseCore.sol), every other variant on a larger base.)
>
> | Companion | From Light? | Why |
> | --- | --- | --- |
> | RuleEngine + all 15 `Rules` | ❌ | Light has no `setRuleEngine`; binding a rule straight to the token needs that same setter |
> | SnapshotEngine | ❌ | Light has no `setSnapshotEngine`, and the engine's in-token variants are built on a heavier CMTAT base |
> | CMTAT-ACE | ❌ | it is a separate token build, and starts from a heavier CMTAT base |
> | CMTAT-CCIP | ❌ | needs the ERC-7802 cross-chain entry points, which Light does not implement |
> | CMTAT-LayerZero | ⚠️ | its recommended adapter needs ERC-7802, which Light lacks; the fallback adapter needs only `mint` / `burn`, which Light has, but that pairing is untested |
> | CMTAT-Factory | 🏭 **yes** | `CMTAT_LIGHT_TP_FACTORY`, `CMTAT_LIGHT_BEACON_FACTORY` (no Light UUPS factory) |
>
> Read the Companion column as: *"available to CMTAT, but only if you move off Light."*

Symbols: ✅ available · ⚠️ partial, indirect or non-standard · ❌ absent · 🏭 companion feature reachable from Light (CMTAT-Factory only).

Stablecoin column abbreviations: **USDC** = Circle, **PAX** = Paxos, **MON** = Monerium, **FRNT** = Wyoming, **CV** = CoinVertible, **USDT** = Tether.

## 3. The CMTAT stack

CMTAT is deliberately split across several repositories. Knowing what each one owns is the key to reading the tables.

| Project | What it owns | Bound to the token by | Light? |
| --- | --- | --- | --- |
| **CMTAT** | ERC-20, mint/burn, pause, address freeze, forced burn/transfer, RBAC, deactivation, documents, cross-chain entry points | — (it *is* the token) | — |
| **RuleEngine** | The controller: holds an ordered list of rules, is called on every transfer/mint/burn, returns the first non-zero ERC-1404 code or reverts | `token.setRuleEngine(engine)` (`DEFAULT_ADMIN_ROLE`) | ❌ no setter |
| **Rules** | The 15 pluggable rules: whitelists, blacklist, sanctions oracle, supply caps, balance caps, proof of reserve, mint allowance, conditional transfer, identity registry | `engine.setRules([...])`, or a single rule bound directly with `setRuleEngine(rule)` | ❌ needs the setter |
| **SnapshotEngine** | Scheduled on-chain balance snapshots for dividend/reward distribution; external engine **or** compiled into the token | `token.setSnapshotEngine(engine)`, or the `CMTAT*InternalSnapshot` variants | ❌ neither path exists in Light |
| **CMTAT-Factory** | Deterministic (CREATE2) deployment behind Transparent, UUPS or Beacon proxies | deployment-time | ✅ `CMTAT_LIGHT_*_FACTORY` |
| **CMTAT-LayerZero** | LayerZero V2 OFT adapters (mint/burn, not lock/unlock), each with its own owner-gated pause | grant the adapter mint/burn rights on the token | ⚠️ ERC-7802 adapter no; ERC-3643 adapter untested |
| **CMTAT-ACE** | Alternative token builds (`ComplianceTokenCMTAT*`) that route protected calls through Chainlink's ACE `PolicyEngine`; ships extractors and a `TransferValidationPolicy` that reuses CMTAT `IRule` rules | a different token deployment, not a bolt-on | ❌ starts from a heavier CMTAT base than Light |
| **CMTAT-CCIP** | Foundry scripts to deploy CMTAT behind Chainlink CCIP token pools (BurnMint or LockRelease) and wire lanes, rate limiters and allowlists | CCT admin role + pool registration | ❌ needs ERC-7802 / `CCIPModule` |

### 3.1 What Light actually contains

A single base contract, `0_CMTATBaseCore`, bundles the whole Light feature set:

| Module | Provides |
| --- | --- |
| `ERC20BaseModule` | ERC-20 core; updatable `name` / `symbol`; irrevocable `decimals` |
| `ERC20MintModule` | `mint`, `batchMint`, `batchTransfer` (`MINTER_ROLE`) |
| `ERC20BurnModule` | `burn`, `batchBurn` (`BURNER_ROLE`) |
| `PauseModule` | `pause` / `unpause` (`PAUSER_ROLE`), `deactivateContract()` (`DEFAULT_ADMIN_ROLE`) |
| `EnforcementModule` | `setAddressFrozen`, `batchSetAddressFrozen` (`ENFORCER_ROLE`) — **address-level only** |
| `ValidationModule(Core)` + `ValidationModuleAllowance` | pause + freeze checks on transfer, `transferFrom`, `approve`, mint, burn; `canTransfer` / `canSend` / `canReceive` |
| `AccessControlModule`, `VersionModule`, `TokenAttributeModule` | RBAC (5 roles), `version()`, name/symbol setters |
| defined directly in `CMTATBaseCore` | `forcedBurn` (`DEFAULT_ADMIN_ROLE`, account must be frozen first), `burnAndMint` |

**Two structural quirks that matter for the tables below:**

* `forcedBurn` exists **only** in Light. `forcedTransfer` and `freezePartialTokens` come from `ERC20EnforcementModule`, which every variant *except* Light inherits. **No variant has both**, so an issuer must decide at deployment whether seizure means *burn* (Light) or *move* (everything else).
* `Permit` and `Standard` are mutually exclusive on ERC-2612 vs ERC-2771; the contract-size limit does not allow both. Light has neither.

---

## 4. Token standards & signature flows

| Feature | Light | CMTAT | Companion | USDC | PAX | MON | FRNT | CV | USDT |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ERC-20 with standard return values | ✅ | ✅ | — | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ no `return` |
| Updatable `name` / `symbol` | ✅ | ✅ | — | ⚠️ `symbol` only, at the V2.2 upgrade | ❌ | ❌ | ❌ | ❌ | ❌ |
| `batchTransfer` / `batchMint` / `batchBurn` | ✅ | ✅ | — | ⚠️ `FiatTokenUtil` (3009 only) | ✅ `transferFromBatch` | ⚠️ `BatchMint` helper | ⚠️ `Multicall` | ❌ | ❌ |
| ERC-2612 `permit` | ❌ | ✅ `Permit` | — | ✅ (V2+) | ✅ | ✅ | ✅ | ❌ | ❌ |
| ERC-3009 `transferWithAuthorization` | ❌ | ❌ (planned, [issue #346](https://github.com/CMTA/CMTAT/issues/346)) | ❌ | ✅ | ✅ + batch | ❌ | ❌ | ❌ | ❌ |
| ERC-1271 smart-account signatures | ❌ | ✅ `Permit` (via OZ) | — | ✅ `SignatureChecker` | ✅ | ✅ | ⚠️ via OZ | ❌ | ❌ |
| ERC-1404 restriction codes | ❌ | ✅ all except `Allowlist` | ✅ **RuleEngine** returns them; each **Rules** rule owns a code range | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| ERC-2771 meta-transactions | ❌ | ✅ `Standard`, `Allowlist` | ✅ RuleEngine and rule modules are ERC-2771-aware | ❌ | ⚠️ covered by 3009 | ❌ | ❌ | ❌ | ❌ |
| ERC-6357 `multicall` | ❌ | ✅ `Permit` | — | ❌ | ❌ | ❌ | ⚠️ OZ `Multicall` | ❌ | ❌ |
| ERC-1363 `transferAndCall` | ❌ | ✅ `ERC1363` | — | ❌ | ❌ | ⚠️ ERC-677 via controller shim | ❌ | ❌ | ❌ |
| ERC-7802 cross-chain mint/burn | ❌ | ✅ all except `Allowlist` | — | ❌ (CCTP) | ❌ | ❌ | ❌ (LayerZero OFT) | ❌ | ❌ |
| ERC-3643 / ERC-7551 / ERC-7943 | ⚠️ ERC-7943 errors only | ✅ | ✅ **Rules** `IdentityRegistryWhitelist`, `RuleIdentityRegistry` fill the ERC-3643 slots | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| ERC-7201 namespaced storage | ✅ | ✅ | ✅ RuleEngine, Rules, SnapshotEngine | ❌ | ⚠️ explicit `BaseStorageV3` | ✅ | ⚠️ OZ | ❌ `*DataLayout` | ❌ |

**Reading.** CMTAT is the only project here implementing ERC-1404, ERC-3643, ERC-7551, ERC-7943 or ERC-7802. All of them sit above Light, which implements plain ERC-20 plus batch helpers. Every stablecoin except CoinVertible and USDT ships `permit`; Light does not.

**ERC-3009 is absent from the entire stack**, Light and companion projects alike, and it is the one signature standard both Circle and Paxos ship. CMTA has it on the roadmap as a dedicated deployment version ([CMTAT issue #346](https://github.com/CMTA/CMTAT/issues/346)); the status below reflects the code pinned here, not the roadmap.

## 5. Supply control (issuance)

| Feature | Light | CMTAT | Companion | USDC | PAX | MON | FRNT | CV | USDT |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Role-gated mint | ✅ `MINTER_ROLE` | ✅ | — | ✅ minters | ✅ `SUPPLY_CONTROLLER_ROLE` | ✅ `system` | ✅ `MINTER_ROLE` | ✅ registrar only | ⚠️ `owner` only |
| Role-gated burn | ✅ `BURNER_ROLE` | ✅ (+ `BURNER_FROM`, `BURNER_SELF`) | — | ⚠️ minter, own balance only | ✅ | ✅ `system` | ✅ `BURNER_ROLE` | ✅ registrar only | ⚠️ `owner` |
| Mint to an arbitrary address | ✅ | ✅ | — | ✅ (within allowance) | ✅ | ✅ | ✅ | ✅ | ❌ `issue()` credits `owner` only |
| **Per-minter mint allowance** | ❌ | ❌ in-token | ✅ **Rules** `RuleMintAllowance` — `setMintAllowance`, `increase`/`decreaseMintAllowance`, decremented per mint | ✅ `minterAllowance` | ✅ | ✅ + global cap | ❌ | ❌ | ❌ |
| Rate-limited minting (time window) | ❌ | ❌ | ✅ **CMTAT-ACE** `VolumeRatePolicy` — per-account cumulative cap in a rolling window; `RuleMintAllowance` is a quota with no time dimension | ❌ | ✅ `RateLimit.sol` | ❌ | ❌ | ❌ | ❌ |
| Max total supply cap | ❌ | ❌ in-token | ✅ **Rules** `RuleMaxTotalSupply` (+ `…ERC3643`) | ❌ | ❌ | ⚠️ via allowance cap | ❌ | ❌ | ❌ |
| Per-call amount cap / ticket size | ❌ | ❌ in-token | ✅ **CMTAT-ACE** `MaxPolicy`, `VolumePolicy` | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Proof-of-reserve-backed minting** | ❌ | ❌ in-token | ✅ **Rules** `RuleChainlinkPoR`, or **CMTAT-ACE** `SecureMintPolicy` — both cap minting at a Chainlink PoR feed | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Minter management in a separate contract | ❌ RBAC only | ❌ RBAC only | ✅ **RuleEngine** + `RuleMintAllowance` | ✅ `MasterMinter` | ✅ `SupplyControl` | ❌ | ❌ | ❌ | ❌ |
| Atomic burn-then-mint | ✅ `burnAndMint` | ✅ | — | ❌ | ❌ | ⚠️ `recover` | ❌ | ❌ | ❌ |
| Mint/burn allowed while paused | ❌ | ❌ | — | ❌ | ✅ by design | n/a (no pause) | ❌ | ❌ | ❌ |

**Reading.** Light gates minting on `MINTER_ROLE` and nothing else: no allowance, no cap, no rate limit. Circle, Paxos and Monerium each bound how much a single compromised minter key can issue; Light does not, and neither does any other CMTAT variant on its own.

The companion projects answer this comprehensively: `RuleMintAllowance` matches USDC's `minterAllowance`, and `RuleChainlinkPoR` goes further than anything in `vendor/` by tying issuance to an on-chain reserve attestation, which **none** of the six stablecoins does. But every one of those rules requires the RuleEngine, so **none of it is reachable from Light**. An issuer who wants USDC-grade minter controls has to move to Standard or Permit and pay roughly 11 KiB of extra bytecode plus two external contracts.

Paxos's time-windowed rate limit does have an equivalent, but only through a third architecture: **CMTAT-ACE**'s `VolumeRatePolicy` caps how much an account can move within a rolling window, and attaching it to the `mint` selector reproduces `SupplyControl` + `RateLimit.sol`. That means a different token build (`ComplianceTokenCMTAT*`), not a contract bolted onto an existing deployment.

## 6. Compliance & enforcement

| Feature | Light | CMTAT | Companion | USDC | PAX | MON | FRNT | CV | USDT |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| In-token address freeze | ✅ `setAddressFrozen` + batch (`ENFORCER_ROLE`) | ✅ | — | ✅ | ✅ | ❌ external | ❌ external | ✅ batch | ✅ |
| Global pause | ✅ `PauseModule` | ✅ | — | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ |
| Permanent deactivation | ✅ `deactivateContract()` | ✅ | — | ❌ | ❌ | ❌ | ❌ | ❌ | ⚠️ `deprecate()` |
| Pre-trade check functions | ✅ `canTransfer` / `canSend` / `canReceive` | ✅ + `detectTransferRestriction` | ✅ every **Rules** rule exposes both | ❌ | ❌ | ❌ | ⚠️ `hasAccess` | ✅ `findNotFrozen` | ❌ |
| Forced burn / seizure | ✅ `forcedBurn` (frozen accounts) | ❌ | — | ❌ | ✅ `wipeFrozenAddress` | ⚠️ `recover` only | ❌ | ✅ `wipeFrozenAddress` | ✅ `destroyBlackFunds` |
| Forced transfer to a third party | ❌ | ✅ `forcedTransfer` | — | ❌ | ⚠️ wipe + re-mint | ✅ `recover` (signature-gated) | ❌ | ❌ | ❌ |
| Partial balance freeze | ❌ | ✅ `freezePartialTokens` | ⚠️ **Rules** `RuleERC2980` (whitelist + frozenlist) | ❌ | ⚠️ whole address | ❌ | ❌ | ⚠️ whole address | ⚠️ whole address |
| **External / shared blacklist** | ❌ | ✅ via engine | ✅ **RuleEngine** + **Rules** `RuleBlacklist` — one engine, several tokens | ❌ | ❌ | ✅ shared validator | ✅ shared registry | ❌ | ⚠️ getters for successors |
| Allowlist / whitelist | ❌ | ✅ `Allowlist` variant (`ALLOWLIST_ROLE`) | ✅ **Rules** `RuleWhitelist`, `RuleReceiverWhitelist`, `RuleSpenderWhitelist`, `RuleWhitelistWrapper` | ❌ | ❌ | ⚠️ custom validator | ⚠️ pluggable registry | ❌ | ❌ |
| **Sanctions-oracle screening** | ❌ | ❌ in-token | ✅ **Rules** `RuleSanctionsList` (Chainalysis), reusable as an ACE policy via `TransferValidationPolicy` | ❌ | ❌ | ❌ | ✅ via registry | ❌ | ❌ |
| Pluggable transfer-rule engine | ❌ **no `setRuleEngine`** | ✅ all except `Allowlist` | ✅ **RuleEngine** is that engine | ❌ | ❌ | ✅ `IValidator` | ✅ `IAccessRegistry` | ❌ | ❌ |
| Per-holder balance cap | ❌ | ❌ in-token | ✅ **Rules** `RuleMaxBalance` | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Per-holder rolling volume cap | ❌ | ❌ in-token | ✅ **CMTAT-ACE** `VolumeRatePolicy` | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Trading-hours / settlement window | ❌ | ❌ | ✅ **CMTAT-ACE** `IntervalPolicy` | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Externalised pause and RBAC | ❌ | ❌ in-token | ✅ **CMTAT-ACE** `PausePolicy`, `RoleBasedAccessControlPolicy` (Standard variant) | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Compliance change without redeploy | ❌ | ⚠️ swap the RuleEngine | ✅ **CMTAT-ACE** — attach / detach / reorder policies by governance | ❌ | ❌ | ⚠️ swap the validator | ⚠️ swap the registry | ❌ | ❌ |
| **Per-transfer operator approval** | ❌ | ❌ in-token | ✅ **Rules** `RuleConditionalTransferLight` | ❌ | ❌ | ❌ | ❌ | ⚠️ redemption routing | ❌ |
| Identity registry / KYC binding | ❌ | ✅ ERC-3643 slot | ✅ **Rules** `IdentityRegistryWhitelist`, `RuleIdentityRegistry` | ❌ | ❌ | ❌ | ⚠️ off-chain | ❌ | ❌ |
| Standardised enforcement events | ⚠️ `ForcedTransfer` event only | ✅ ERC-7551 / ERC-7943 | — | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

**Reading.** Light's compliance model is exactly USDT's: an in-token address blacklist, a global pause, and a way to destroy a blacklisted balance. It is a faithful, modern, role-separated reimplementation of the 2017 design, plus permanent deactivation and pre-trade views, which USDT lacks. That is enough for a plain fiat stablecoin, and it is the case CMTA's documentation makes.

Everything beyond that lives in `Rules`: shared blacklists, sanctions screening, whitelists, balance caps, per-transfer approval, identity binding. **All of it requires leaving Light.** Once you do, the model differs from every stablecoin here: Monerium and Wyoming each have *one* pluggable hook, while the RuleEngine runs an ordered, composable stack of them.

**CMTAT now has three compliance architectures, not two.** Beyond in-token enforcement and the RuleEngine, `CMTAT-ACE` routes protected calls through Chainlink's ACE `PolicyEngine`, where compliance is a list of policies attached per function selector and changed by governance rather than by upgrade. It ships in two shapes: **Lite**, which swaps the RuleEngine for the PolicyEngine on transfer validation and keeps CMTAT's roles; and **Standard**, which is policy-authoritative: ACE gates mint, burn, transfer, enforcement and admin, and the token drops `AccessControlUpgradeable` for `OwnableUpgradeable`. That last point is a real trade-off: the Standard variant gives up the granular RBAC that is otherwise one of CMTAT's advantages over USDC and USDT, moving authorisation into policies.

**Light gets `forcedBurn` but not `forcedTransfer`; every other variant gets the reverse.** Paxos and CoinVertible can freeze then wipe; USDT can destroy. No single CMTAT deployment can both burn from a frozen address and move its tokens elsewhere.

## 7. Access control & governance

| Feature | Light | CMTAT | Companion | USDC | PAX | MON | FRNT | CV | USDT |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Model | OZ `AccessControl`, **5 roles** | OZ `AccessControl`, ~15 roles | RBAC, `Ownable` or `Ownable2Step` flavours (RuleEngine, Rules, SnapshotEngine, CMTAT-Factory); `Ownable` only for LayerZero and ACE | 5 bespoke singletons | OZ `AccessControlDefaultAdminRules` | `Ownable2Step` + admin/system | OZ `AccessControl`, 8 roles | 3 bespoke operators | single `owner` |
| Roles | `DEFAULT_ADMIN`, `MINTER`, `BURNER`, `PAUSER`, `ENFORCER` | + `ERC20ENFORCER`, `ALLOWLIST`, `CROSS_CHAIN`, `SNAPSHOOTER`, `DOCUMENT`, `EXTRA_INFORMATION`, `DEBT`, `PROXY_UPGRADE`, … | separate managers per concern (`onlyRulesManager`, `onlyComplianceManager`, `onlySanctionListManager`) | owner, masterMinter, pauser, blacklister, rescuer | ✅ granular | 3 tiers | ✅ granular | registrar, operations, technical | — |
| Each role grantable to several addresses | ✅ | ✅ | ✅ | ❌ one address each | ✅ | ⚠️ system/admin are sets | ✅ | ❌ immutable | ❌ |
| Two-step role handover | ❌ OZ immediate | ❌ OZ immediate | ✅ `Ownable2Step` flavours of RuleEngine, every rule, SnapshotEngine and the factories; ❌ LayerZero and ACE | ❌ | ✅ delayed admin transfer | ✅ | ⚠️ OZ | ✅ `accept*Role` | ❌ |
| Timelock shipped in-repo | ❌ | ❌ | ❌ | ❌ | ✅ `timelock-controller/` | ❌ | ❌ | ❌ | ❌ |
| Roles annotated with fund-redirection risk | ⚠️ `access-control.md` | ⚠️ `access-control.md` | — | ❌ | ✅ `Roles.sol` | ⚠️ `tokendesign.md` | ⚠️ README | ❌ | ❌ |

**Reading.** Light already separates five independently grantable roles, against USDC's five one-address-each singletons and USDT's single `owner`. The gap is governance *tooling*: **Paxos is the only project that ships a `TimelockController` with the token** and annotates which roles can redirect funds. CMTAT's `Ownable2Step` safety exists only on four of the companion contracts (RuleEngine, Rules, SnapshotEngine, CMTAT-Factory), never on the token itself, so it is unavailable to any deployment: `DEFAULT_ADMIN_ROLE` transfers take effect immediately. CMTAT-LayerZero's adapters use plain `Ownable`, and CMTAT-ACE's Standard build uses `OwnableUpgradeable`.

## 8. Upgradeability & lifecycle

| Feature | Light | CMTAT | Companion | USDC | PAX | MON | FRNT | CV | USDT |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Immutable (standalone) | ✅ `CMTATStandaloneLight` | ✅ | 🏭 Factory deploys these too | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Transparent proxy | ✅ `CMTATUpgradeableLight` | ✅ | 🏭 `CMTAT_LIGHT_TP_FACTORY`, `CMTAT_TP_FACTORY` | ✅ | ⚠️ legacy admin proxy | ❌ | ❌ | ❌ | ❌ |
| Beacon proxy (fleet-wide upgrade) | ✅ | ✅ | 🏭 `CMTAT_LIGHT_BEACON_FACTORY`, `CMTAT_BEACON_FACTORY` | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| UUPS proxy | ❌ no Light UUPS contract | ✅ `CMTATUpgradeableUUPS` (Standard branch only) | ⚠️ `CMTAT_UUPS_FACTORY` — no Light or Permit implementation to point at | ❌ | ✅ | ✅ | ✅ | ✅ | ❌ |
| **Deterministic addresses (CREATE2)** | ✅ | ✅ | 🏭 **CMTAT-Factory** — same address across chains | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Dedicated upgrade role | ✅ `PROXY_UPGRADE_ROLE` | ✅ | 🏭 factories have their own access-control flavours | ⚠️ proxy admin | ✅ | ⚠️ `owner` | ✅ `UPGRADER_ROLE` | ✅ `technical` | n/a |
| Two-step upgrade authorization | ❌ | ❌ | ❌ | ❌ | ⚠️ via timelock | ❌ | ❌ | ✅ `authorizeImplementation` → `upgradeTo` | n/a |
| Storage-collision strategy | ✅ ERC-7201 | ✅ ERC-7201 | ✅ same | ⚠️ inheritance order | ✅ explicit storage contracts | ✅ ERC-7201 | ⚠️ OZ | ✅ `*DataLayout` | n/a |
| **Rescue foreign ERC-20 / native coin** | ❌ | ❌ | ❌ **no companion provides it** | ✅ `rescueERC20` | ✅ `reclaimToken` | ❌ | ✅ `salvageERC20` + `salvageGas` | ❌ | ❌ |
| Version exposed on-chain | ✅ `version()` | ✅ | ✅ `VersionModule` everywhere | ❌ | ❌ | ⚠️ `CONTRACT_ID()` | ❌ | ✅ `version()` | ❌ |
| Irreversible shutdown | ✅ `deactivateContract()` | ✅ | — | ❌ | ❌ | ❌ | ❌ | ❌ | ⚠️ `deprecate()` |

**Reading.** Light keeps almost every row here, and CMTAT-Factory is the one companion it can use. The factory gives even a Light deployment two things no stablecoin in `vendor/` has: **beacon-proxy fleet upgrades** (the natural fit for a multi-currency issuer — Monerium runs four tokens, Paxos four) and **CREATE2 deterministic addresses** (the same token address on every chain, which every cross-chain stablecoin here solves out-of-band).

Two concrete misses, both variant-independent:

* **No UUPS Light variant** exists, and `CMTATUpgradeableUUPS` is built on the Standard branch, so a Light issuer wanting UUPS must write their own.
* **Nothing in the entire stack can recover a foreign ERC-20 sent to the token contract.** Circle, Paxos and Wyoming all ship it; CMTAT and all seven companion projects lack it.

## 9. Yield, cross-chain and extras

| Feature | Light | CMTAT | Companion | USDC | PAX | MON | FRNT | CV | USDT |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| On-chain balance snapshots | ❌ no `setSnapshotEngine` | ✅ `Snapshot` variant / `setSnapshotEngine` | ✅ **SnapshotEngine** — external or in-token, with a scheduler | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Dividend / coupon distribution | ❌ | ✅ `Debt` / `DebtEngine` variants | ✅ SnapshotEngine + `IncomeVault` (external) | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Native yield (rebasing balances) | ❌ | ❌ | ❌ | ❌ | ✅ USDG multipliers | ❌ | ❌ | ❌ | ❌ |
| ERC-4626 yield wrapper | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ `FrontierVault` | ❌ | ❌ |
| Cross-chain mint/burn interface | ❌ | ✅ ERC-7802 (`CROSS_CHAIN_ROLE`) | — | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Chainlink CCIP compatibility | ❌ | ✅ `CCIPModule` (`getCCIPAdmin()`) | ✅ **CMTAT-CCIP** — scripts for BurnMint and LockRelease token pools, lane wiring, admin-role claim | ❌ | ⚠️ audited, not in repo | ❌ | ⚠️ announced migration | ❌ | ❌ |
| LayerZero OFT adapter | ❌ | ✅ ERC-7802 variants | ✅ **CMTAT-LayerZero** `LayerZeroAdapterERC7802` (recommended) / `LayerZeroAdapter` (ERC-3643) | ❌ | ❌ | ❌ | ✅ `FrontierOFTAdapter*` | ❌ | ❌ |
| Bridge mechanism | — | — | mint/burn via LayerZero; **either** mint/burn or lock/release via CCIP pools | CCTP mint/burn | — | — | **both**: lock/unlock on the hub, mint/burn on spokes | — | — |
| Bridge-level pause | — | — | ✅ owner-gated `pause()` on each LayerZero adapter | ⚠️ token-level only | — | — | ⚠️ token-level only | — | — |
| Bridge-level rate limit / allowlist | — | — | ✅ **CMTAT-CCIP** — per-lane CCIP pool rate limiters and allowlists | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Non-EVM implementation | ⚠️ external repos | ⚠️ external repos | — | ❌ | ❌ | ❌ | ✅ Solana program in-repo | ❌ | ⚠️ separate codebases |
| Confidential balances | ❌ | ✅ **CMTAT-Confidential** (Zama FHE) | — | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| On-chain legal documents | ❌ | ✅ ERC-1643 `DocumentERC1643Module` | — | ❌ | ❌ | ❌ | ⚠️ `contractUri` | ❌ | ❌ |
| On-chain token metadata (ISIN, terms) | ❌ | ✅ `ExtraInformationModule` | — | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| On-chain holder registry | ❌ | ✅ `HolderList` variant | ⚠️ Rules whitelists approximate it | ❌ | ⚠️ payout groups | ❌ | ❌ | ❌ | ❌ |
| Transfer fee | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ (set to 0) |
| Redemption modelled on-chain | ⚠️ burn | ⚠️ burn | ⚠️ `RuleConditionalTransferLight` can gate it | ⚠️ burn | ⚠️ burn | ⚠️ signature-gated burn | ⚠️ burn | ✅ redemption addresses | ⚠️ `redeem` |

**Reading.** Light is deliberately stripped of all of this, and for a plain fiat stablecoin that is the right call: none of the six stablecoins has documents, snapshots or holder lists either. What Light also gives up, less obviously, is **cross-chain**: ERC-7802 and the CCIP module are absent from it, so a Light token has no standard bridge entry points. Given that five of the six stablecoins here are multi-chain (CoinVertible is the exception), that is the most likely reason a stablecoin issuer would have to leave Light for reasons unrelated to compliance.

**No part of the CMTAT stack pays holders a yield**: neither the rebasing model (Paxos USDG) nor the ERC-4626 wrapper (Wyoming wFRNT) has a counterpart. SnapshotEngine + IncomeVault addresses periodic *distribution*, which is a different mechanism from continuously accruing balances.

## 10. Gap analysis

### 10.1 Stablecoin features the CMTA stack covers outside the token

These are all available to a CMTAT issuer, but none of them live in the token contract: each needs a companion project deployed and wired alongside it. The last column is the one that matters in practice, because CMTA's own guidance points stablecoin issuers at Light.

| Feature | Who has it | CMTAT answer | From Light? |
| --- | --- | --- | --- |
| Per-minter mint allowance | USDC, Paxos, Monerium | ✅ **Rules** `RuleMintAllowance` | ❌ needs RuleEngine |
| Shared blacklist across several tokens | Monerium, Wyoming | ✅ **RuleEngine** + **Rules** `RuleBlacklist` (heed the stateful-rule warning) | ❌ needs RuleEngine |
| Sanctions-oracle screening | Wyoming | ✅ **Rules** `RuleSanctionsList` | ❌ needs RuleEngine |
| Minter management in a separate contract | USDC (`MasterMinter`), Paxos (`SupplyControl`) | ✅ **RuleEngine** + `RuleMintAllowance` is the architectural equivalent | ❌ needs RuleEngine |
| Per-transfer operator approval | CoinVertible (registrar validation) | ✅ **Rules** `RuleConditionalTransferLight` | ❌ needs RuleEngine |
| Max supply / per-holder balance caps | none | ✅ **Rules** `RuleMaxTotalSupply`, `RuleMaxBalance` | ❌ needs RuleEngine |
| Proof-of-reserve-gated minting | none | ✅ **Rules** `RuleChainlinkPoR`, or **CMTAT-ACE** `SecureMintPolicy` | ❌ needs RuleEngine or an ACE build |
| Deterministic cross-chain addresses | none — all solve it out-of-band | ✅ **CMTAT-Factory** (CREATE2) | 🏭 **yes** |
| Fleet-wide upgrade of many tokens | none — all upgrade per token | ✅ **CMTAT-Factory** beacon factories | 🏭 **yes** |
| LayerZero OFT bridging | Wyoming | ✅ **CMTAT-LayerZero** adapters | ⚠️ recommended adapter needs ERC-7802; the fallback is untested on Light |
| Time-windowed rate limiting | Paxos `RateLimit.sol` | ✅ **CMTAT-ACE** `VolumeRatePolicy` | ❌ separate token build |
| Compliance changed by configuration, not upgrade | Monerium, Wyoming (one hook each) | ✅ **CMTAT-ACE** policy attach/detach/reorder | ❌ separate token build |

**`CMTAT-Factory` is the only companion project a Light deployment can definitely use.** RuleEngine and every rule need `setRuleEngine`, which Light does not have; SnapshotEngine needs either `setSnapshotEngine`, also absent, or its in-token variants, which start from a heavier CMTAT base. CMTAT-LayerZero's ERC-3643 adapter may work with Light, but nothing in that repository tests it.

### 10.2 Stablecoin features the CMTA ecosystem does not provide

The genuine gaps: absent from every CMTAT variant **and** from all seven companion projects, so an issuer who needs one has to build it.

| Feature | Who has it | Notes |
| --- | --- | --- |
| **ERC-3009 `transferWithAuthorization`** | USDC, Paxos | The main payments-integration gap. Not in any CMTAT variant, nor in any of the seven companion projects. **Planned**: CMTA tracks it as a dedicated deployment version in [issue #346](https://github.com/CMTA/CMTAT/issues/346). |
| **Rescue / salvage of foreign tokens** | USDC, Paxos, Wyoming | Absent from CMTAT *and* all seven companion projects. |
| **Native yield / rebasing balances** | Paxos USDG | No CMTAT equivalent; snapshots address distribution, not accrual. |
| **ERC-4626 yield wrapper** | Wyoming wFRNT | Would have to be built on top of CMTAT. |
| **Signature-gated burn / wallet recovery** | Monerium | `forcedTransfer` is unilateral; Monerium requires the holder's signature. |
| **Transfer fee** | USDT | Deliberately absent; noted for completeness. |
| **`forcedBurn` and `forcedTransfer` together** | Paxos, CoinVertible (freeze → wipe) | Both exist in the stack, but never in one deployment: `forcedBurn` is Light-only, `forcedTransfer` is every-variant-but-Light. The gap is the combination, not either function. |
| **Timelock shipped with the token** | Paxos | No CMTA project ships one. OpenZeppelin's `TimelockController` drops in, so this is the cheapest of the gaps to close. |

### 10.3 CMTAT features no stablecoin in `vendor/` has

* **ERC-1404 restriction codes** and pre-trade `canTransfer` / `detectTransferRestriction` views — every stablecoin here simply reverts.
* **Composable rule stacking** — Monerium and Wyoming each have *one* pluggable hook; RuleEngine runs an ordered list of them.
* **Proof-of-reserve-gated minting** (`RuleChainlinkPoR`) — no stablecoin here ties issuance to an on-chain reserve attestation.
* **Per-holder balance caps** and **max total supply caps** as policy rather than code.
* **Permanent deactivation** (`deactivateContract()`, ERC-8343 draft) — only USDT's `deprecate()` is comparable, and it forwards rather than terminates.
* **On-chain snapshots** for dividend distribution (SnapshotEngine).
* **On-chain legal documents** (ERC-1643) and token metadata (ISIN, terms).
* **Standardised enforcement events** (ERC-7551 / ERC-7943).
* **Confidential balances** (CMTAT-Confidential, Zama FHE).
* **Beacon + CREATE2 factory deployment** (CMTAT-Factory).
* **A bridge that can be paused independently of the token** — CMTAT-LayerZero's adapters each carry their own owner-gated `pause()`. Wyoming's OFT adapters have no such switch; halting a bridge there means pausing the token.
* **Bridge-agnostic cross-chain entry points** — ERC-7802 is a standard interface any bridge can drive; every stablecoin here is wired to one specific bridge (CCTP for Circle, LayerZero for Wyoming). CMTAT has working tooling for both LayerZero and CCIP.
* **Compliance as runtime configuration** (CMTAT-ACE) — policies are attached, detached and reordered by governance per function selector. Monerium and Wyoming can swap their single hook; no stablecoin here can reorder a policy chain without an upgrade.
* **Trading-hours windows** (`IntervalPolicy`) and **per-holder rolling volume caps** (`VolumeRatePolicy`) — neither has any counterpart in `vendor/`.
* **Mutable `name` / `symbol`** post-deployment.

### 10.4 Practical conclusion for a stablecoin issuer

CMTAT's own documentation recommends the **Light** variant for stablecoins. That recommendation holds only for a specific shape of stablecoin.

**Where Light is sufficient.** For a single-chain, non-yield-bearing fiat token whose compliance need is "freeze an address and, if ordered, destroy its balance", Light matches USDT's model exactly and improves on it: five independently grantable roles instead of one `owner`, batch operations, pre-trade `canTransfer` views, permanent deactivation, mutable `name`/`symbol`, and, through CMTAT-Factory, beacon upgrades and CREATE2 addresses that no stablecoin in `vendor/` has. At 11.3 KiB it is also the smallest deployment in the set.

**Where Light falls short.** Four things the stablecoins here provide and Light does not:

| What Light lacks | Who has it | Cost of fixing it |
| --- | --- | --- |
| Any bound on minter authority | USDC, Paxos, Monerium | move to Standard/Permit + RuleEngine + `RuleMintAllowance` |
| `permit` (ERC-2612) | USDC, Paxos, Monerium, Wyoming | move to Permit — which forfeits ERC-2771 |
| Cross-chain entry points | Circle (CCTP), Wyoming (OFT), Paxos | move to a variant that implements ERC-7802 / CCIP, then add a `CMTAT-LayerZero` adapter |
| Forced *transfer* (it has forced *burn*) | Paxos, CoinVertible | move to any non-Light variant — and lose `forcedBurn` |

**The competitive configuration is Standard or Permit + RuleEngine + Rules**, which matches USDC and Monerium feature for feature and adds composable rule stacking neither has, at a reported 22–23 KiB plus two external contracts, roughly double Light's footprint.

**Three gaps survive every configuration** and must be built by the issuer: **ERC-3009**, **foreign-token rescue**, and **yield accrual**. Only ERC-3009 has a published plan, as a dedicated deployment version in [CMTAT issue #346](https://github.com/CMTA/CMTAT/issues/346). Time-windowed rate limiting is no longer one of them, since `CMTAT-ACE`'s `VolumeRatePolicy` covers it, but only by deploying a different token build.

---

## See also

* [`vendor/README.md`](./vendor/README.md) — per-directory guide to each stablecoin codebase and its main files.
* [`vendor/SUMMARY.md`](./vendor/SUMMARY.md) — stablecoin-to-stablecoin comparison.
* [`stablecoin-doc-issue.md`](./stablecoin-doc-issue.md) — 14 documented errors in CMTAT's own stablecoin comparison, with suggested fixes.
* [`cmtat/CMTAT/doc/technical/stablecoin.md`](./cmtat/CMTAT/doc/technical/stablecoin.md) — CMTAT's Light-variant deployment guide.
* [`cmtat/Rules/README.md`](./cmtat/Rules/README.md) — the rule catalogue and restriction codes.
* [`cmtat/RuleEngine/README.md`](./cmtat/RuleEngine/README.md) — engine architecture and token-binding model.
* [`cmtat/CMTAT-LayerZero/README.md`](./cmtat/CMTAT-LayerZero/README.md) — OFT adapter selection and deployment guide.

---

## AI assistance

Parts of this project were written with the help of AI coding assistant Claude Code (Anthropic).
