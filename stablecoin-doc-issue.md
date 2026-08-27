# Documentation issues — `CMTAT/doc/technical/stablecoin.md`

Errors and inaccuracies found in the "Comparison with USDC and USDT" section of [`cmtat/CMTAT/doc/technical/stablecoin.md`](./cmtat/CMTAT/doc/technical/stablecoin.md) (CMTAT `v3.3.0-rc3`).

**Method.** Every claim about USDC and USDT was checked against the verified source vendored in this repository, not against third-party summaries:

| Token | Source checked | Version |
| --- | --- | --- |
| USDC | [`vendor-stablecoins/stablecoin-evm/`](./vendor-stablecoins/stablecoin-evm/) (`circlefin/stablecoin-evm`) | `fc85788`, 2026-08-12 |
| USDT | [`vendor-stablecoins/usdt_eth_0xdac17f95…/TetherToken.sol`](./vendor-stablecoins/) (Etherscan, `0xdac17f95…`) | deployed bytecode source |
| CMTAT | [`cmtat/CMTAT/`](./cmtat/CMTAT/) | `v3.3.0-rc3`, `658672f` |
| Rules / RuleEngine | [`cmtat/Rules/`](./cmtat/Rules/), [`cmtat/RuleEngine/`](./cmtat/RuleEngine/) | `v0.6.0` / `v3.0.0-rc6` |

Line numbers refer to `doc/technical/stablecoin.md` as pinned here.

---

## Summary

| # | Line | Issue | Severity |
| --- | --- | --- | --- |
| [1](#1-usdc-does-not-have-instanttransfer) | 345, 383 | USDC credited with `instantTransfer` — belongs to Benji | **High** |
| [2](#2-usdt-does-not-have-size) | 345, 403 | USDT credited with `size` — belongs to BUIDL | **High** |
| [3](#3-usdc-does-not-have-disableerc20thirdpartytransfer) | 354 (fn ³) | USDC credited with `disableERC20ThirdPartyTransfer` — belongs to Benji | **High** |
| [4](#4-usdt-has-no-migrate-function) | 375 (fn ⁴) | USDT credited with `migrate` — the function is `deprecate` | **Medium** |
| [5](#5-usdt-cannot-mint-to-any-address) | 329 | "Mint to any address ✓" for USDT — `issue()` credits the owner only | **Medium** |
| [6](#6-usdc-has-no-mintfrom-function) | 330 | Row labelled `mintFrom`, which does not exist in USDC | **Low** |
| [7](#7-there-is-no-uups-permit-variant) | 372 | CMTAT Permit marked ✓ for UUPS — no such deployment contract | **Medium** |
| [8](#8-rulemintallowance-already-exists) | 382 | Says a per-minter cap "could be implemented" — it already ships in `Rules` | **Medium** |
| [9](#9-usdt-is-not-erc-20-compliant) | 319 | USDT marked ✓ for ERC-20 without qualification | **Low** |
| [10](#10-usdts-deprecate-is-a-permanent-shutdown) | 349 | USDT marked — for deactivation; `deprecate()` is one-way | **Low** |
| [11](#11-usdcs-role-model-is-understated) | 360–361 | USDC has 5 privileged singletons, not "Minter + Blacklister" | **Low** |
| [12](#12-usdcs-symbol-is-not-fixed-at-deployment) | 335, 388 | `FiatTokenV2_2.initializeV2_2` sets `symbol` | **Low** |
| [13](#13-usdcs-rescueerc20-is-not-mentioned) | 380–384 | A real USDC feature absent from the whole CMTAT stack goes unlisted | **Medium** |
| [14](#14-scope-only-two-stablecoins) | §"Comparison with USDC and USDT" | Four other major stablecoins raise the bar on issuance and compliance | Informational |

Issues **1–3 share a single root cause**, described next.

---

## Root cause of issues 1–3: rows copied from the tokenized-fund table

These are **not invented function names.** They are real functions belonging to other tokens, carried into the wrong columns.

CMTAT's *other* comparison table — "CMTAT for tokenized market funds", at [`doc/README.md:267`](./cmtat/CMTAT/doc/README.md) — attributes them correctly:

| Row in the funds table | Franklin Templeton (FOBXX / Benji) | Blackrock (BUIDL) |
| --- | --- | --- |
| Forced Transfer | ✔ "called `instantTransfer`" | ✔ "called *size*" |
| Restriction on `transferFrom` | ✔ "through `disableERC20ThirdPartyTransfer` & `enableERC20ThirdPartyTransfer`" | ✘ |

`stablecoin.md` carries the same two rows over a table whose columns are **USDC | USDT | Light | Standard | Permit**. The result places `instantTransfer` under USDC and `size` under USDT — consistent with the columns having been shifted one token family across (Benji → USDC, BUIDL → USDT).

> The Benji and BUIDL attributions themselves are **not verified in this repository** — neither token is vendored here — and are reproduced as CMTAT states them. (`size` is most likely a typo for `seize`.) What is verified is that none of these functions belong to USDC or USDT.

---

## 1. USDC does not have `instantTransfer`

**Location** — line 345 (Compliance and Regulatory table), restated at line 383.

```
| Forced transfer to a third party | ✓ (`instantTransfer`) | ✓ (`size`) | — | ✓ | ✓ |
```
```
- **Forced transfer** (`instantTransfer`) — available in CMTAT Standard and Permit via `forcedTransfer`.
```

**Finding** — No such function exists anywhere in `vendor-stablecoins/stablecoin-evm`. **USDC has no forced-transfer and no seizure capability of any kind.** Blacklisting via `Blacklistable.blacklist()` freezes an address permanently, but nothing in `contracts/v1`, `contracts/v1.1` or `contracts/v2` can move or destroy a holder's balance. The only value-recovery function is `Rescuable.rescueERC20`, which pulls *foreign* ERC-20 tokens off the token contract and cannot touch USDC balances.

**Suggested fix** — set the USDC cell to `—`, and move the line at 383 out of "Features USDC has that CMTAT Light lacks" into "Features CMTAT has that USDC lacks".

## 2. USDT does not have `size`

**Location** — line 345, restated at line 403.

**Finding** — `TetherToken.sol` contains no function named `size` (nor `seize`). USDT's only enforcement primitive is `destroyBlackFunds(address)`, which burns a blacklisted balance and decrements `_totalSupply` — the document already credits it correctly on line 346. As written, line 345 double-counts a capability USDT does not have.

**Suggested fix** — set the USDT cell to `—`.

## 3. USDC does not have `disableERC20ThirdPartyTransfer`

**Location** — line 354, footnote ³.

> ³ USDC allows the contract owner to disable third-party (`transferFrom`) transfers entirely via `disableERC20ThirdPartyTransfer` / `enableERC20ThirdPartyTransfer`.

**Finding** — Neither function exists in the repository, and there is no global third-party-transfer switch in any form (`grep -rn "ThirdParty|delegatedTransfer|transferFromEnabled" contracts/` returns nothing).

**This one is different from issues 1 and 2: the row's ✓ survives, the justification does not.** USDC *does* restrict a spender — `FiatTokenV1.transferFrom` carries `notBlacklisted(msg.sender)` alongside `notBlacklisted(from)` and `notBlacklisted(to)` — which is mechanically the same check CMTAT applies to a frozen spender. So USDC and CMTAT are **equivalent** on the row "Restriction on `transferFrom` spender", rather than USDC being ahead.

**Suggested fix** — rewrite footnote ³ as:

> ³ USDC blocks `transferFrom` when the spender is blacklisted (`notBlacklisted(msg.sender)`), equivalent to CMTAT's frozen-spender check. Neither token can disable delegated transfers globally; CMTAT Standard and Permit can, by deploying a RuleEngine rule that rejects calls where `spender != from && spender != address(0) && from != address(0) && to != address(0)`.

The second sentence of the existing footnote is correct and should be kept — but it is a **CMTAT-only** capability, not an "additionally" that matches something USDC has.

## 4. USDT has no `migrate` function

**Location** — line 375, footnote ⁴.

> ⁴ USDT includes a `migrate` function because it predates the proxy upgrade pattern and needed a manual balance migration path.

**Finding** — `TetherToken.sol` has no `migrate`. The actual mechanism is `deprecate(address _upgradedAddress)`, which sets `deprecated = true` and stores `upgradedAddress`; every ERC-20 entry point then forwards to the successor contract via `transferByLegacy` / `transferFromByLegacy` / `approveByLegacy` (the `UpgradedStandardToken` interface). **No balances are migrated** — storage stays in the old contract and the successor reads through it.

Unlike issues 1–3, this claim has no counterpart in the tokenized-fund table, so its origin is unclear.

**Suggested fix** — rename the row "Migrate function (balance carry-over)" to "Successor-contract forwarding" and rewrite footnote ⁴ around `deprecate`. The conclusion drawn (ERC-7201 makes CMTAT migrations transparent) still stands.

## 5. USDT cannot mint to any address

**Location** — line 329.

```
| Mint to any address | Partial² | ✓ | ✓ | ✓ | ✓ |
```

**Finding** — USDT's issuance function takes **no recipient**:

```solidity
function issue(uint amount) public onlyOwner {
    require(_totalSupply + amount > _totalSupply);
    require(balances[owner] + amount > balances[owner]);
    balances[owner] += amount;
    _totalSupply += amount;
    Issue(amount);
}
```

New supply is always credited to `owner`; distribution is a subsequent ordinary transfer. `redeem(uint amount)` is symmetric — it burns from `balances[owner]` only. USDT is in fact **more** restricted than USDC here, not less, yet the table shows it as unrestricted while USDC is marked "Partial".

**Suggested fix** — set the USDT cell to `—` (or "owner balance only") and add a footnote. Consider extending the same note to the "Burn / redeem" row at line 333.

## 6. USDC has no `mintFrom` function

**Location** — line 330.

```
| Mint with dedicated allowance (`mintFrom`) | ✓ | — | — | — | — |
```

**Finding** — There is no `mintFrom` in `vendor-stablecoins/stablecoin-evm`. USDC's mechanism is `configureMinter(minter, minterAllowedAmount)` called by the `masterMinter`, followed by `mint(to, amount)` from the minter, with `minterAllowed[msg.sender]` decremented on each call. The ✓ is correct in substance; only the function name is wrong.

**Suggested fix** — relabel the row "Mint with dedicated allowance (`minterAllowance`)". See also issue 8 — the CMTAT cells on this row should not all be `—`.

## 7. There is no UUPS Permit variant

**Location** — line 372.

```
| Upgradeable — UUPS | — | — | — | ✓ (dedicated variant) | ✓ (dedicated variant) |
```

**Finding** — `cmtat/CMTAT/contracts/deployment/` contains exactly one UUPS contract:

```solidity
contract CMTATUpgradeableUUPS is CMTATBaseERC2771, UUPSUpgradeable
```

It is built on `CMTATBaseERC2771` — the **Standard** branch. The Permit deployment contracts (`CMTATStandalonePermit`, `CMTATUpgradeablePermit`) derive from `CMTATBaseERC2612` and do **not** inherit `UUPSUpgradeable`, so they cannot sit behind a UUPS proxy. `CMTAT_UUPS_FACTORY` in CMTAT-Factory accepts an arbitrary `logic_` address, but no Permit implementation satisfying the UUPS contract exists to point it at.

**Suggested fix** — set the Permit cell to `—`, or to "requires a custom variant".

## 8. `RuleMintAllowance` already exists

**Location** — line 382 (and the CMTAT cells of line 330).

> - **Mint allowance per minter** (`minterAllowance`) — CMTAT uses an uncapped `MINTER_ROLE` instead. A per-minter cap could be implemented via a custom RuleEngine or a minter proxy.

**Finding** — It does not need to be implemented. `cmtat/Rules` ships `RuleMintAllowance` (`src/rules/operation/RuleMintAllowance.sol`, plus an `Ownable2Step` flavour) with `mintAllowance(address)`, `setMintAllowance`, `increaseMintAllowance`, `decreaseMintAllowance` and a batch reset, decremented on each mint — functionally equivalent to USDC's `minterAllowance`.

**This contradicts CMTAT's own funds table**, which already credits CMTAT 3.3.0 Standard with "Mint with dedicated allowance (`mintFrom`)" ✔ and links [`Rules/doc/technical/RuleMintAllowance.md`](https://github.com/CMTA/Rules/blob/main/doc/technical/RuleMintAllowance.md) by name. The two documents disagree.

**Two caveats worth stating in the fix**, both from `Rules/README.md`:

* `RuleMintAllowance` is an *operation rule* keyed on the caller and **requires the RuleEngine path** — it cannot be bound directly to the token with `setRuleEngine(rule)`.
* The RuleEngine hook enters the inheritance chain at `3_CMTATBaseRuleEngine`, so it is **unreachable from the Light variant** that this very document recommends for stablecoins (Light stops at `0_CMTATBaseCore`). The `Allowlist` variant is the other exception — it branches off at the same level with `ValidationModuleAllowlist`.

**Suggested fix** — set line 330's Standard and Permit cells to "✓ (via `Rules/RuleMintAllowance`, RuleEngine path)" and rewrite line 382 accordingly. Note separately that **Paxos's time-windowed rate limit** (`SupplyControl` + `RateLimit.sol`) still has no CMTAT equivalent — `RuleMintAllowance` is an absolute quota with no time dimension.

## 9. USDT is not ERC-20 compliant

**Location** — line 319.

```
| [ERC-20](https://eips.ethereum.org/EIPS/eip-20) | ✓ | ✓ | ✓ | ✓ | ✓ |
```

**Finding** — `TetherToken.sol` is Solidity 0.4.17 and its `transfer`, `transferFrom` and `approve` declare **no return value**, so the contract does not satisfy the ERC-20 ABI. This is the single best-known integration hazard of USDT — it is why `SafeERC20`-style wrappers exist — and an unqualified ✓ hides it. The functions also carry an `onlyPayloadSize` modifier guarding against the short-address attack.

**Suggested fix** — mark USDT "Partial" with a footnote.

## 10. USDT's `deprecate` is a permanent shutdown

**Location** — line 349.

```
| Deactivation (permanent, irreversible) | — | — | ✓ | ✓ | ✓ |
```

**Finding** — `deprecate(address)` sets `deprecated = true` with no path back; from that point the contract's own logic is bypassed on every ERC-20 entry point. That is closer to CMTAT's `deactivateContract()` than a plain `—` suggests, though the semantics differ (forwarding vs. terminating).

This also interacts with issue 4: footnote ⁴ describes `deprecate`'s purpose while calling it `migrate`, so the document discusses the function on line 375 while marking its effect absent on line 349.

**Suggested fix** — mark USDT "Partial (`deprecate`, forwards rather than terminates)".

## 11. USDC's role model is understated

**Location** — lines 360–361.

```
| Single-owner model | ✓ | ✓ | — | — | — |
| Role-based access control (RBAC) | ✓ (Minter + Blacklister roles) | — | ✓ (5 roles) | ✓ (10+ roles) | ✓ (10+ roles) |
```

**Finding** — USDC has **five** privileged singletons, not two:

| Role | Declared in |
| --- | --- |
| `owner` | `contracts/v1/Ownable.sol` |
| `masterMinter` | `contracts/v1/FiatTokenV1.sol` |
| `pauser` | `contracts/v1/Pausable.sol` |
| `blacklister` | `contracts/v1/Blacklistable.sol` |
| `rescuer` | `contracts/v1.1/Rescuable.sol` |

plus an arbitrary set of minters, each with its own allowance, and the optional off-token `MasterMinter` / `MintController` contract that adds a controller layer above them. Marking USDC ✓ for "Single-owner model" *and* ✓ for RBAC in the same table is also internally inconsistent.

**Suggested fix** — set "Single-owner model" to `—` for USDC and list the five roles. The CMTAT conclusion is unaffected: CMTAT's roles are still finer-grained and grantable to multiple addresses, where USDC's are one-address-each.

## 12. USDC's `symbol` is not fixed at deployment

**Location** — line 335, restated at line 388.

**Finding** — `FiatTokenV2_2.initializeV2_2(address[] accountsToBlacklist, string newSymbol)` assigns `symbol = newSymbol` (line 49 of `FiatTokenV2_2.sol`). It is a one-shot upgrade-time reinitializer rather than an admin setter, so `—` is defensible for the row — but "USDC name and symbol are fixed at deployment" on line 388 is not accurate for `symbol`.

**Suggested fix** — qualify line 388: "`name` is fixed; `symbol` can only be changed by passing through a version upgrade."

## 13. USDC's `rescueERC20` is not mentioned

**Location** — "Features USDC has that CMTAT Light lacks", lines 380–384.

**Finding** — USDC ships `Rescuable.rescueERC20(IERC20 tokenContract, address to, uint256 amount)` behind a dedicated `rescuer` role, for recovering foreign ERC-20 tokens accidentally sent to the token contract. Paxos (`reclaimToken`) and Wyoming (`salvageERC20` / `salvageGas`) ship the same thing.

**Nothing in the CMTAT stack provides it** — not CMTAT, not RuleEngine, not Rules, not SnapshotEngine, not CMTAT-Factory (`grep -rn "rescue|salvage|reclaimToken|sweepToken"` across all five returns nothing). This is a genuine, unlisted gap, and in practice one of the most frequently exercised admin functions on a production token.

**Suggested fix** — add it to the "Features USDC has that CMTAT Light lacks" list, noting that it is missing from every variant and every companion project.

## 14. Scope: only two stablecoins

**Location** — the section heading "Comparison with USDC and USDT".

**Finding** — Informational, not an error. Four other major stablecoins materially change the picture and are not represented:

| Token | What it adds to the comparison |
| --- | --- |
| **Paxos** (USDP/USDG/PYUSD/PAXG) | External `SupplyControl` with **time-windowed rate limits**; diamond-facet architecture; auto-compounding yield; a `TimelockController` shipped with the token |
| **Monerium** (EURe/GBPe/USDe/ISKe) | **Shared external validator** across four tokens — the closest existing analogue to the RuleEngine; signature-gated `burn` and `recover`; no pause at all |
| **Wyoming** (FRNT/wFRNT) | Pluggable **access registry** with Chainalysis sanctions delegation; ERC-4626 yield wrapper; LayerZero OFT incl. a Solana program; `salvage` |
| **CoinVertible** (EURCV/USDCV) | Three-operator model with **2-step role acceptance and 2-step upgrade authorization**; on-chain redemption addresses |

Several of these map onto CMTAT companion contracts that the document never mentions — `RuleSanctionsList` (Chainalysis screening), `RuleConditionalTransferLight` (per-transfer operator approval, CoinVertible's pattern), `RuleChainlinkPoR` (proof-of-reserve-gated minting, which **no** stablecoin here has).

**Suggested fix** — either broaden the section, or retitle it so it does not read as a survey of the stablecoin landscape.

---

## Net effect on the comparison

Correcting the fourteen issues changes the USDC/USDT verdict in specific ways. Most move in CMTAT's favour; two do not.

### Rows where CMTAT gains

| Row | Before | After | Why |
| --- | --- | --- | --- |
| Forced transfer to a third party (l. 345) | USDC ✓, USDT ✓ | **USDC —, USDT —** | Issues 1–2. Neither token can move a holder's balance. `forcedTransfer` (every variant but Light) and `forcedBurn` (Light) have no counterpart in either. |
| Mint to any address (l. 329) | USDT ✓ | **USDT —** | Issue 5. `issue()` credits `balances[owner]` only. USDT is *more* restricted than USDC here, not less. |
| Mint with dedicated allowance (l. 330) | CMTAT — for all variants | **Standard / Permit ✓** via `Rules/RuleMintAllowance` | Issue 8. Light stays `—`, since the rule needs the RuleEngine hook it lacks. |
| Single-owner model (l. 360) | USDC ✓ | **USDC —** | Issue 11. Five privileged singletons, plus an arbitrary minter set and an optional `MasterMinter` controller layer. |

### Rows where CMTAT does not gain

| Row | Correction | Net effect |
| --- | --- | --- |
| Restriction on `transferFrom` spender (l. 351, fn ³) | Issue 3 | **The ✓ survives, the reasoning does not.** USDC has no global third-party switch, but `FiatTokenV1.transferFrom` does carry `notBlacklisted(msg.sender)` — mechanically the same check CMTAT applies to a frozen spender. USDC and CMTAT are **equivalent** on this row rather than USDC being ahead. Footnote ³'s second sentence stands, but as a CMTAT-**only** capability. |
| Upgradeable — UUPS (l. 372) | Issue 7 | **CMTAT loses a ✓.** No UUPS Permit implementation exists; `CMTATUpgradeableUUPS` is on the Standard branch. |
| Features USDC has that CMTAT lacks (l. 380–384) | Issue 13 | **CMTAT loses ground.** `rescueERC20` should be added to the list — it is absent from CMTAT and from all seven companion projects (RuleEngine, Rules, SnapshotEngine, CMTAT-Factory, CMTAT-LayerZero, CMTAT-ACE, CMTAT-CCIP). |

### The Light caveat the document does not state

`stablecoin.md` recommends the **Light** variant for stablecoins, then credits "CMTAT" generally with RuleEngine-backed capabilities in the same tables. Those are not the same thing:

* The RuleEngine hook (`ValidationModuleRuleEngine`) enters the inheritance chain at `3_CMTATBaseRuleEngine`. Light stops at `0_CMTATBaseCore` and therefore has **no `setRuleEngine` function at all** — so none of the 15 rules in `Rules` are reachable from it, including `RuleMintAllowance` (issue 8), `RuleBlacklist`, `RuleSanctionsList` and `RuleChainlinkPoR`. Binding a rule directly with `token.setRuleEngine(rule)` does not help, because that setter is precisely what Light lacks.
* **SnapshotEngine is equally out of reach**: Light has no `setSnapshotEngine`, and the engine's in-token variants (`CMTATStandaloneInternalSnapshot`, `CMTATUpgradeableInternalSnapshot`) derive from `CMTATInternalSnapshotBase`, which imports `CMTATBaseRuleEngine` — the level-3 base, not Light's level-0 one.
* **`CMTAT-Factory` is the only companion project a Light deployment can definitely use** (`CMTAT_LIGHT_TP_FACTORY`, `CMTAT_LIGHT_BEACON_FACTORY`; there is no Light UUPS factory). `CMTAT-LayerZero`'s recommended adapter needs ERC-7802, which also enters at level 5; its fallback ERC-3643 adapter targets the `mint` / `burn` pair Light does have, but that combination is not exercised anywhere in that repository. `CMTAT-ACE` and `CMTAT-CCIP` are also out of reach: the ACE token builds derive from `CMTATBaseCommon`, and CCIP needs the ERC-7802 / `CCIPModule` entry points.

The document's own table at line 352 already marks "External rule engine" as `—` for Light, so the structure is known — but the surrounding prose and the per-feature discussion do not carry the consequence through.

**Suggested fix** — add a short note to the "Light Variant — Feature Set" section stating that Light cannot use RuleEngine, Rules or SnapshotEngine, and that any feature described elsewhere as "available via RuleEngine" requires moving to Standard or Permit.

---

## Not verified

Stated for completeness — these were **not** checked and are not claimed to be wrong:

* **Contract size figures** (Light 11.298 KiB / Standard 22.243 KiB / Permit 23.268 KiB). Not recompiled.
* **Benji and BUIDL function names** (`instantTransfer`, `size`, `disableERC20ThirdPartyTransfer`). Neither token is vendored here; they are reproduced as CMTAT's funds table states them.
* **`Rules` / `RuleEngine` runtime behaviour.** Read from source and documentation, not executed.

## Claims checked and found correct

Recorded so a fix does not disturb them:

* `forcedBurn` exists **only** in Light (`0_CMTATBaseCore.sol`); `forcedTransfer` and `freezePartialTokens` exist in every variant **except** Light (`ERC20EnforcementModule` sits in `0_CMTATBaseCommon`). The variant table is right.
* USDC has no equivalent of `forcedBurn`.
* USDT's `destroyBlackFunds` burns a blacklisted balance and decrements `totalSupply`.
* USDT has a fee mechanism (`basisPointsRate` / `maximumFee`), currently 0.
* USDC implements EIP-2612 and EIP-3009; USDT implements neither.
* USDC does not implement ERC-7802; its cross-chain path is CCTP over the standard `mint` / `burn` behind a privileged minter.
* ERC-3009 is absent from **every** CMTAT variant and from all seven companion projects. CMTA plans it as a dedicated deployment version ([issue #346](https://github.com/CMTA/CMTAT/issues/346)), so `stablecoin.md`'s statement that it is "not implemented in any CMTAT variant" is correct today but worth pairing with the roadmap link.
* `batchTransfer` is gated by `MINTER_ROLE` (`onlyMinter` in `ERC20MintModule`), as the Role Summary states.
* Light's blacklisting sequence (`setAddressFrozen` → `forcedBurn`) and the requirement that the account be frozen first.

---

## See also

* [`README.md`](./README.md) — the full CMTAT ⇄ stablecoin comparison these corrections feed into, with a dedicated column for the Light variant.
* [`vendor-stablecoins/README.md`](./vendor-stablecoins/README.md) — the vendored sources and their main files.
* [`vendor-stablecoins/SUMMARY.md`](./vendor-stablecoins/SUMMARY.md) — stablecoin-to-stablecoin comparison.
