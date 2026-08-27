# Stablecoin feature comparison

Feature-by-feature comparison of the reference implementations vendored in this directory, plus **CMTAT** (`../cmtat/CMTAT`) as the baseline this repository is about.

Every statement below is taken from the source pinned in this repo — see [`README.md`](./README.md) for the exact commits and file paths. Where the upstream documentation and the code disagree, the **code** wins and the difference is called out.

Legend: ✅ present · ❌ absent · ⚠️ present but partial / indirect / non-standard.

---

## 1. At a glance

| | **CMTAT** | **Circle** USDC/EURC | **Paxos** USDP/USDG/PYUSD/PAXG | **Monerium** EURe/GBPe/USDe/ISKe | **Wyoming** FRNT/wFRNT | **CoinVertible** EURCV/USDCV | **Tether** USDT |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Directory | `../cmtat/CMTAT` | `stablecoin-evm` | `paxos-token-contracts` | `monerium-smart-contracts` | `frontier-stable-token` | `cv_eth_0xf4ccc80c…` | `usdt_eth_0xdac17f95…` |
| Solidity | 0.8.x | **0.6.12** | 0.8.28 | 0.8.x | 0.8.22 | 0.8.22 | **0.4.17** |
| Base library | OpenZeppelin 5.x | bespoke | OZ 5.x (upgradeable) | OZ 5.0.0 (upgradeable) | OZ upgradeable + Fireblocks ERC-20F | OZ 4.x (upgradeable) | none (inlined) |
| Upgrade pattern | proxy-agnostic (UUPS via factory) | transparent admin proxy | UUPS + legacy admin proxy | UUPS (ERC-1967) | UUPS | UUPS, 2-step authorization | ❌ — `deprecate()` call forwarding |
| Access control | OZ `AccessControl` + roles | 5 bespoke singleton roles | OZ `AccessControlDefaultAdminRules` | `Ownable2Step` + admin/system tiers | OZ `AccessControl`, 8 roles | 3 bespoke operators, 2-step accept | single `owner` |
| Decimals | configurable | 6 | 6 (18 for PAXG) | 18 | 6 | 18 | 6 |
| Backing model | generic (any asset / security) | fiat reserve | fiat reserve / allocated gold | EMI e-money (MiCA) | state treasury reserve | fiat reserve | fiat reserve |
| Multi-token per codebase | ✅ (framework) | ⚠️ one deploy per token | ✅ 4 tokens, shared core | ✅ 4 proxies, 1 implementation | ✅ 2 tokens (base + wrapper) | ⚠️ | ❌ |

---

## 2. ERC-20 surface & signature-based flows

| Feature | CMTAT | Circle | Paxos | Monerium | Wyoming | CoinVertible | USDT |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Standard ERC-20 return values | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ (no `return`) |
| EIP-2612 `permit` | ⚠️ `Permit` deployment version only (`6_CMTATBaseERC2612`) | ✅ (V2+) | ✅ | ✅ | ✅ | ❌ | ❌ |
| EIP-3009 `transferWithAuthorization` | ❌ | ✅ (V2+) | ✅ + batch | ❌ | ❌ | ❌ | ❌ |
| ERC-1271 (smart-account signatures) | ✅ | ✅ (`SignatureChecker`) | ✅ | ✅ | ⚠️ via OZ | ❌ | ❌ |
| Batch transfer | ✅ (`batchTransfer`) | ⚠️ `FiatTokenUtil` helper (3009 only) | ✅ `transferFromBatch` | ❌ | ⚠️ `Multicall` | ❌ | ❌ |
| `increase/decreaseAllowance` | ❌ removed in OZ 5 | ✅ (V2+) | ❌ removed in OZ 5 | ❌ removed in OZ 5 | ✅ `ERC20F` | ✅ | ❌ |
| Transfer-with-callback | ✅ ERC-1363 | ❌ | ❌ | ⚠️ ERC-677 via controller shim | ❌ | ❌ | ❌ |
| Meta-transactions | ✅ ERC-2771 | ❌ | ⚠️ covered by 3009 | ❌ | ❌ | ❌ | ❌ |

**Notes**

* USDT predates the finalised ERC-20 semantics: `transfer`/`approve` return nothing and carry an `onlyPayloadSize` guard against the short-address attack. Integrators must use a "safe transfer" wrapper.
* Circle's EIP-712 domain separator is recomputed from the live `chainid()` since **V2.2**, which makes the permits fork-safe; earlier versions cached it at initialization.
* Paxos exposes the largest gasless surface: `permit` (typed **and** raw-bytes signature), `transferWithAuthorization`, `receiveWithAuthorization`, their batch variants, and a `cancelPermits(count)` nonce-bumping escape hatch.
* CoinVertible has neither permit nor 3009 — every movement is an on-chain call from the holder.
* `increaseAllowance` / `decreaseAllowance` are **not** an ERC-20 requirement and were dropped from OpenZeppelin in v5. CMTAT, Paxos and Monerium are all on OZ 5 and define no replacement, so they no longer expose them; Circle (bespoke), Wyoming (Fireblocks `ERC20F`) and CoinVertible (OZ 4) still do.

---

## 3. Supply control (mint / burn)

| | CMTAT | Circle | Paxos | Monerium | Wyoming | CoinVertible | USDT |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Who may mint | `MINTER_ROLE` | any configured *minter* | `SUPPLY_CONTROLLER_ROLE` (external contract) | `system` accounts | `MINTER_ROLE` (+ `ADAPTER_ROLE`) | `registrar` only | `owner` only |
| Per-minter allowance | ❌ (role only) | ✅ `minterAllowance` | ✅ optional + **rate limit** | ✅ + global cap | ❌ | ❌ | ❌ |
| Minter management delegated off-token | ❌ | ✅ `MasterMinter` / `MintController` | ✅ `SupplyControl` contract | ❌ (in-token) | ❌ | ❌ | ❌ |
| Burn from arbitrary holder | ⚠️ `forcedBurn` (Light only, address must be frozen) or `forcedTransfer(from, address(0), …)` (every other variant) | ❌ | ✅ `wipeFrozenAddress` | ⚠️ `burn(from,…)` **with holder signature** | ❌ `burn(uint256)` is self-burn only | ✅ `wipeFrozenAddress` | ✅ `destroyBlackFunds` |
| Batch mint | ✅ `batchMint` / `batchBurn` | ❌ | ⚠️ facet-level | ⚠️ `BatchMint` migration helper | ⚠️ `Multicall` | ❌ | ❌ |
| Mint/burn while paused | configurable | ❌ | ✅ (documented, by design) | n/a (no pause) | ❌ | ❌ | ❌ |

**Notes**

* **Circle** is the only one where a minter can *only* burn its own balance — there is no seizure primitive anywhere in `contracts/v1` or `contracts/v2`. Blacklisting freezes funds permanently but never destroys or reassigns them.
* **Paxos** pushes supply authority into a separate deployed contract (`SupplyControl`) with a sliding-window `RateLimit`, so a compromised supply controller is bounded per time window. No other issuer here bounds a compromised supply controller per time window.
* **Monerium** requires an EIP-712/ERC-1271 signature *from the holder* for `burn` and for `recover`, so redemption and wallet recovery are user-authorised rather than unilateral.
* **CoinVertible** collapses issuance into one address: `onlyAllowedMinter` resolves to `msg.sender == registrar`, i.e. the registrar is the sole minter and the sole burner (`burn` always burns from `registrar`, never from a third party).

---

## 4. Compliance & enforcement

| | CMTAT | Circle | Paxos | Monerium | Wyoming | CoinVertible | USDT |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Deny-list / blacklist | ✅ (enforcement + RuleEngine) | ✅ in-token | ✅ freeze in-token | ✅ **external shared validator** | ✅ **external registry** | ✅ freeze in-token | ✅ in-token |
| Allow-list | ✅ `AllowlistModule` | ❌ | ❌ | ⚠️ possible via custom validator | ⚠️ registry is pluggable | ❌ | ❌ |
| List shared across tokens | ✅ (RuleEngine) | ❌ | ❌ | ✅ (one validator, 4 tokens) | ✅ (`DenyList` per mesh) | ❌ | ⚠️ getters exposed for successors |
| Pluggable transfer rules | ✅ **RuleEngine / ERC-1404** | ❌ | ❌ | ✅ `IValidator` hook | ✅ `IAccessRegistry` hook | ❌ | ❌ |
| Sanctions-oracle integration | via a Rule | ❌ | ❌ | ❌ | ⚠️ not verified — registry not vendored | ❌ | ❌ |
| Freeze part of a balance | ✅ `freezePartialTokens` (partial freeze) | ❌ | ⚠️ whole address | ❌ | ❌ | ⚠️ whole address | ⚠️ whole address |
| Forced transfer | ✅ `forcedTransfer` (every variant except Light) | ❌ | ⚠️ wipe + re-mint | ✅ `recover` (signature-gated) | ❌ | ❌ | ❌ |
| Seize / destroy funds | ✅ `forcedBurn` (Light) or `forcedTransfer` to `address(0)` (other variants) | ❌ | ✅ `wipeFrozenAddress` | ⚠️ `recover` only | ❌ | ✅ `wipeFrozenAddress` | ✅ `destroyBlackFunds` |
| Pause | ✅ `PauseModule` | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ |
| Permanent deactivation | ✅ `deactivateContract()` | ❌ | ❌ | ❌ | ❌ | ❌ | ⚠️ `deprecate()` |
| Standardised enforcement events | ✅ ERC-7551 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

**Notes**

* The compliance list sits in one of two places. **In-token lists** (Circle, Paxos, CoinVertible, USDT) keep the check in the token's own storage — cheap and simple, but each token carries its own list and any policy change needs an implementation upgrade. **Externalised hooks** (CMTAT's RuleEngine, Monerium's `IValidator`, Wyoming's `IAccessRegistry`) call out to a swappable contract on every transfer — one policy can serve many tokens and can be replaced without touching the token. CMTAT is the most general of the three: a RuleEngine can chain arbitrary rules and returns ERC-1404 restriction codes.
* **Wyoming's sanctions screening could not be verified here.** Only `IAccessRegistry` and a test mock are vendored; the `FrontierAccessRegistry` implementation is not. The Chainalysis delegation appears solely in Wyoming's own `README.md`, which hedges it ("**may** delegate additional checks"), so it is recorded as unverified rather than asserted.
* **Monerium has no pause function at all.** Emergency response relies on the shared `BlacklistValidatorUpgradeable`, or on a UUPS upgrade.
* **CoinVertible's pause is total** in the deployed code: `mint`, `burn`, `transfer`, `transferFrom` and `approve` all carry `onlyWhenNotPaused`. The `IAccessControl` NatSpec claims registrar `mint`/`burn` remain available while paused — the implementation does not match that comment.
* **Wyoming** deliberately lets a *cross-chain* delivery land in a frozen wallet (`mintToFrozenWallet` / `transferToFrozenWallet`) so the destination transaction cannot revert; the tokens remain immovable afterwards. It is the only design here that treats "don't strand a LayerZero message" as more important than "never credit a denied wallet".
* **USDT's `destroyBlackFunds`** burns the balance *and* decreases `totalSupply` — the assets are destroyed on-chain rather than reassigned to the issuer, unlike Paxos/CoinVertible where the wipe is followed by an off-chain seizure of the backing.

---

## 5. Upgradeability & operational safety

| | CMTAT | Circle | Paxos | Monerium | Wyoming | CoinVertible | USDT |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Pattern | UUPS (via `CMTAT-Factory`) or immutable | transparent proxy | UUPS / admin proxy | UUPS | UUPS | UUPS | none |
| Who may upgrade | `DEFAULT_ADMIN_ROLE` | proxy `admin` | `DEFAULT_ADMIN_ROLE` (+ timelock) | `owner` (2-step) | `UPGRADER_ROLE` | `technical`, after registrar/operations **authorization** | n/a |
| Two-step upgrade | ❌ | ❌ | ⚠️ via `TimelockController` | ❌ | ❌ | ✅ `authorizeImplementation` then `upgradeTo` | n/a |
| Two-step role handover | ❌ OZ `AccessControl`, immediate | ❌ | ✅ `DefaultAdminRules` (delayed) | ✅ `Ownable2Step` | ⚠️ OZ | ✅ `accept*Role` per operator | ❌ |
| Timelock in-repo | ❌ | ❌ | ✅ `timelock-controller/` | ❌ | ❌ | ❌ | ❌ |
| Rescue foreign tokens | ❌ | ✅ `rescueERC20` (`rescuer` role) | ✅ `reclaimToken` | ❌ | ✅ `salvageERC20` + `salvageGas` | ❌ | ❌ |
| Explicit storage-layout contract | ⚠️ ERC-7201 namespaces | ❌ (inheritance order) | ✅ `BaseStorageV3` | ⚠️ OZ 5 base only; `validator` is a plain slot | ⚠️ OZ namespaces | ✅ `*DataLayout.sol` | n/a |
| Public audits in repo | ✅ (upstream) | ⚠️ external | ✅ 7 PDFs (Halborn, Zellic, ToB) | ✅ 3 PDFs (Ackee) | ❌ | ❌ | ❌ |

**Notes**

* **CoinVertible has the strictest upgrade ceremony** of the set: the registrar (or operations) first calls `authorizeImplementation(addr)`, then and only then can the `technical` operator call `upgradeTo(addr)`, and the authorization is consumed. Its operator addresses are `immutable`, so rotating an operator means shipping a new implementation whose three operators have all accepted their roles — role changes and code changes are the same event.
* **USDT cannot be upgraded.** `deprecate(newAddress)` flips a flag after which every ERC-20 entry point forwards to a successor contract implementing `*ByLegacy` functions. Storage stays behind in the old contract; the successor must read through it.
* **Paxos** is alone in shipping a `TimelockController` next to the token and in documenting which roles can redirect funds (`Roles.sol` marks `PAYOUT_GROUP_ADMIN_ROLE` and `CLAIM_ADMIN_ROLE` as ⚠️ privileged, "cold wallet only").

---

## 6. Yield, cross-chain and extras

| | CMTAT | Circle | Paxos | Monerium | Wyoming | CoinVertible | USDT |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Native yield to holders | ❌ (see `DebtModule` for coupons) | ❌ | ✅ **USDG**: auto-compounding multipliers + payout groups | ❌ | ✅ **wFRNT**: ERC-4626 vault | ❌ | ❌ |
| Rebasing / non-1:1 balances | ❌ | ❌ | ✅ (shares × multiplier) | ❌ | ⚠️ wrapper token, not rebasing | ❌ | ❌ |
| Cross-chain in-repo | ✅ ERC-7802 + CCIP module | ❌ (bridged-USDC *standard* doc only) | ⚠️ ToB cross-chain audit, no adapter here | ❌ | ✅ **LayerZero OFT** (EVM + Solana) | ❌ | ❌ |
| Non-EVM target | ❌ | ❌ | ❌ | ❌ | ✅ Solana (Anchor program) | ❌ | ⚠️ other chains, other codebases |
| Transfer fee | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ `basisPointsRate` / `maximumFee` (set to 0) |
| Snapshots / balance history | ✅ `SnapshotEngine` | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Holder registry on-chain | ✅ `HolderListModule` | ❌ | ⚠️ payout-group registration | ❌ | ❌ | ❌ | ❌ |
| Legal documents on-chain | ✅ ERC-1643 `DocumentEngine` | ❌ | ❌ | ❌ | ⚠️ `contractUri` | ❌ | ❌ |
| Confidential balances | ✅ `CMTAT-Confidential` (FHE) | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Redemption modelled on-chain | ⚠️ burn | ⚠️ burn | ⚠️ burn | ⚠️ signature-gated burn | ⚠️ burn | ✅ **redemption addresses** + `RedemptionStarted` | ⚠️ `redeem` |

**Notes**

* **Paxos USDG** and **Wyoming wFRNT** solve yield in opposite ways. USDG rebases: balances are shares multiplied by a growing multiplier, computed inside the token via a diamond-facet architecture (`ClaimableRewardsFacet`, `MultiplierMgmtFacet`, `PayoutGroupFacet`) so the proxy stays under the code-size limit. Wyoming keeps FRNT strictly 1:1 and wraps it in an ERC-4626 vault (`FrontierVault`) whose share price appreciates — which is why its hub-chain OFT adapter must **lock/unlock** rather than mint/burn: burning would corrupt the `totalSupply`-based yield computation.
* **CoinVertible** is the only one where redemption is a first-class on-chain concept: the registrar declares redemption addresses, and any `transfer`/`transferFrom` targeting one is silently rerouted to the registrar with a `RedemptionStarted` event. The user experience is "send to a burn address", the accounting is "issuer receives the tokens".

---

## 7. Where CMTAT sits

CMTAT is a **framework**, not a single token, and that shows in the comparison:

* **Broader compliance toolkit than any of the fiat stablecoins.** ERC-1404 restriction codes, partial-balance freezing, standardised ERC-7551 enforcement events, on-chain legal documents (ERC-1643), snapshots and an on-chain holder list are CMTAT's alone. An allow-list is the one item others could match: Monerium's `IValidator` and Wyoming's `IAccessRegistry` are pluggable enough to hold one, but neither ships an allow-list implementation. Those come from its securities/tokenisation heritage — Circle, Paxos and Tether only ever need "is this address denied?".
* **Comparable or stronger enforcement primitives.** `forcedTransfer` — which burns when the destination is `address(0)` — plus `deactivateContract()` cover everything Paxos, CoinVertible and USDT can do, with explicit events; Circle and Wyoming have no seizure at all. Light is the exception inside CMTAT: it gets `forcedBurn` instead, cannot move a position elsewhere, and can only act on an address already frozen.
* **Weaker on issuance controls.** CMTAT gates minting on a role, full stop. Circle's per-minter allowances, Paxos's rate-limited external `SupplyControl` and Monerium's capped mint allowances all bound the blast radius of a compromised minter key in a way a plain role does not. This is the clearest gap if CMTAT is used as a fiat-backed stablecoin.
* **No EIP-3009.** Circle and Paxos both ship it; several payment integrations expect `transferWithAuthorization` on a USD stablecoin. CMTAT covers gasless approvals with EIP-2612 and gasless calls with ERC-2771 instead.
* **Modularity where the others hardcode.** The RuleEngine/SnapshotEngine/DebtEngine split is the same instinct as Monerium's `IValidator` and Wyoming's `IAccessRegistry`, taken further — CMTAT can swap policy without an upgrade, which the in-token-blacklist designs cannot.
* **Unique capabilities.** `CMTAT-Confidential` (FHE balances), the debt/coupon modules and the `CMTAT-Factory` deterministic deployment have no counterpart in any of the vendored stablecoins.

## 8. Cross-cutting observations

1. **Half of these tokens keep the compliance list in their own storage; half externalise it behind a hook.** The externalised designs (CMTAT, Monerium, Wyoming) let one policy serve several tokens and change without an upgrade; the in-token designs (Circle, Paxos, CoinVertible, USDT) are cheaper per transfer and simpler to audit.
2. **Seizure capability splits the set.** Circle and Wyoming ship *no* way to destroy or move a user's balance; Paxos, CoinVertible, USDT and CMTAT all do. Monerium sits between the two with a signature-gated `recover`.
3. **The newest codebases converge on UUPS + OZ `AccessControl` + `permit`.** Paxos 2.x, Wyoming, CoinVertible and CMTAT all look alike at that layer; the differentiation has moved up into supply control, yield and cross-chain.
4. **Pausing is near-universal — Monerium is the exception.** Every other token, including the 2017-vintage USDT, can be frozen globally.
5. **Two of the six stablecoins pay holders a yield, and both restructured the token around it.** USDG (rebasing multipliers) and wFRNT (ERC-4626 wrapper) use incompatible mechanics, and each forced a change elsewhere — diamond facets for one, lock/unlock bridging for the other.
