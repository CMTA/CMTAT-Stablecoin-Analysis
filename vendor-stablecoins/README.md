# Vendor — reference stablecoin implementations

This directory collects the source of several production stablecoins, used as reference points for the comparison with [CMTAT](https://github.com/CMTA/CMTAT) (see [`SUMMARY.md`](./SUMMARY.md) for the feature-by-feature comparison).

Two kinds of directories live here:

* **Git submodules** — upstream repositories, pinned to a commit (see `../.gitmodules`).
* **Etherscan dumps** — verified source of a deployed implementation, downloaded through Etherscan with the [MetaSuites](https://chromewebstore.google.com/detail/metasuites-builders-swiss/) extension (BlockSec). These are snapshots of a *single* implementation contract, not full repos.

| Directory | Issuer / token(s) | Kind | Pinned at |
| --- | --- | --- | --- |
| [`stablecoin-evm`](#circle--stablecoin-evm) | Circle — USDC, EURC | submodule | `fc85788` (2026-08-12) |
| [`paxos-token-contracts`](#paxos--paxos-token-contracts) | Paxos — USDP, USDG, PYUSD, PAXG | submodule | `674ac10` (v2.1.0+3, 2026-07-29) |
| [`monerium-smart-contracts`](#monerium--monerium-smart-contracts) | Monerium — EURe, GBPe, USDe, ISKe | submodule | `514bee7` (v2.0.0+24, 2025-08-21) |
| [`frontier-stable-token`](#wyoming--frontier-stable-token) | Wyoming Stable Token Commission — FRNT, wFRNT | submodule | `f8aa140` (untagged, 2026-04-30) |
| [`cv_eth_0xf4ccc80c…`](#coinvertible--cv_eth_0xf4ccc80c) | Société Générale FORGE — CoinVertible (EURCV, USDCV) | Etherscan dump | impl. `0xF4ccC80C…` |
| [`usdt_eth_0xdac17f95…`](#tether--usdt_eth_0xdac17f95) | Tether — USDT | Etherscan dump | `0xdac17f95…` |

Etherscan-dump directories are named `<token>_eth_<address>_code`, where the address is the **implementation** contract the verified source was downloaded from — not necessarily the address users interact with. Both were downloaded on 2026-08-26 through Etherscan with the [MetaSuites](https://chromewebstore.google.com/detail/metasuites-builders-swiss/) extension (BlockSec), which named them after the wrong token; they were renamed to match their contents.

---

## Circle — `stablecoin-evm`

Upstream: <https://github.com/circlefin/stablecoin-evm> · License Apache-2.0 · Solidity 0.6.12 Contracts behind **USDC** and **EURC** on EVM chains. Hardhat + Foundry.

The token is a versioned implementation chain behind a legacy admin-upgradeability proxy: `FiatTokenV1 → V1_1 → V2 → V2_1 → V2_2`.

Main files:

| Path | Role |
| --- | --- |
| `contracts/v1/FiatTokenV1.sol` | Core token: ERC-20, `masterMinter`, per-minter allowances, `mint`/`burn`, owner |
| `contracts/v1/FiatTokenProxy.sol` | The deployed entrypoint (transparent `AdminUpgradeabilityProxy`) |
| `contracts/v1/Blacklistable.sol` | `blacklister` role, `blacklist` / `unBlacklist` |
| `contracts/v1/Pausable.sol`, `Ownable.sol` | `pauser` role, ownership |
| `contracts/v1.1/Rescuable.sol` | `rescuer` role — pulls **foreign** ERC-20s stuck on the token contract |
| `contracts/v2/FiatTokenV2.sol` | Adds EIP-2612 `permit` + EIP-3009 (`transferWithAuthorization`) |
| `contracts/v2/FiatTokenV2_1.sol` | Un-blacklists the contract itself, minor fixes |
| `contracts/v2/FiatTokenV2_2.sol` | Blacklist packed into the balance slot (gas), dynamic EIP-712 domain (chain-id safe), `symbol` update |
| `contracts/v2/EIP2612.sol`, `EIP3009.sol`, `EIP712.sol` | Signature-based flows, ERC-1271 aware via `util/SignatureChecker.sol` |
| `contracts/v2/FiatTokenUtil.sol` | Helper to batch several `transferWithAuthorization` in one tx |
| `contracts/v2/NativeFiatTokenV2_2.sol` | Variant where the token doubles as the chain's native coin |
| `contracts/v2/celo/*` | Celo variant (`FiatTokenCeloV2_2`) + fee-currency adapter |
| `contracts/minting/MasterMinter.sol`, `MintController.sol`, `Controller.sol` | Off-token contract that decentralises minter management (controller → minter) |
| `contracts/v2/upgrader/*` | Atomic upgrade helpers (`V2Upgrader`, `V2_1Upgrader`, `V2_2Upgrader`) |
| `doc/tokendesign.md` | **Best entry point** — the design rationale |
| `doc/bridged_USDC_standard.md` | Requirements for third-party bridged USDC |
| `doc/masterminter.md`, `upgrade.md`, `v2.2_upgrade.md`, `celo.md` | Operational docs |

## Paxos — `paxos-token-contracts`

Upstream: <https://github.com/paxosglobal/paxos-token-contracts> · License MIT · Solidity 0.8.28 Contracts behind **USDP**, **USDG** (Global Dollar), **PYUSD** (PayPal USD) and **PAXG** (Paxos Gold).

Two architectures coexist: a plain implementation (`PaxosTokenV2`) for USDP/PYUSD/PAXG, and a diamond-style *facet* architecture (`PaxosTokenClaimableRewards`) for USDG's auto-compounding yield.

Main files:

| Path | Role |
| --- | --- |
| `contracts/PaxosTokenV2.sol` | Shared token core: ERC-20, pause, freeze, batch transfers, permit + EIP-3009 |
| `contracts/PaxosTokenClaimableRewards.sol` | USDG core: rebasing/auto-compounding balances, fallback dispatch to facets |
| `contracts/stablecoins/USDP.sol`, `PYUSD.sol`, `USDG.sol`, `PAXG.sol` | Thin per-token contracts (name/symbol/decimals + `_authorizeUpgrade`) |
| `contracts/SupplyControl.sol` | **Separate contract** owning mint/burn rights; `SUPPLY_CONTROLLER_ROLE` with optional rate limits |
| `contracts/lib/RateLimit.sol` | Sliding-window mint/burn rate limiting |
| `contracts/lib/Roles.sol` | All role constants, with a note on which ones can redirect funds |
| `contracts/facets/TokenAdminFacet.sol` | `pause`, `freeze`/`unfreeze` (+ batch), `wipeFrozenAddress`, `reclaimToken` |
| `contracts/facets/TokenExtensionsFacet.sol` | `permit`, `transferWithAuthorization` (+ batch), `receiveWithAuthorization`, `cancelPermits` |
| `contracts/facets/ClaimableRewardsFacet.sol` | Reward claiming per payout group |
| `contracts/facets/MultiplierMgmtFacet.sol`, `PayoutGroupFacet.sol` | Yield multiplier curves and payout-group registration |
| `contracts/lib/SharesLib.sol`, `MultiplierGrowthLib.sol` | Shares math and period-aligned compounding |
| `contracts/BaseStorage.sol`, `BaseStorageV3.sol`, `ClaimableRewardsStorageV3.sol` | Storage layouts shared by proxy + facets |
| `contracts/lib/EIP2612.sol`, `EIP3009.sol`, `ECRecover.sol` | Signature flows (ERC-1271 supported) |
| `contracts/zeppelin/AdminUpgradeabilityProxy.sol` | Legacy proxy still used by the older tokens |
| `contracts/archive/*` | Superseded implementations (`PaxosTokenV1`, `PAXGImplementation`, `USDGv2`) |
| `timelock-controller/` | Timelock used to gate admin operations |
| `docs/CLAIMABLE_REWARDS_README.md` | Deep-dive on the USDG rewards system |
| `docs/PAXG_V2_UPGRADE.md` | PAXG V1 → V2 migration |
| `audits/` | Halborn, Zellic and Trail of Bits reports (PDF) |

## Monerium — `monerium-smart-contracts`

Upstream: <https://github.com/monerium/smart-contracts> · License Apache-2.0 · Solidity 0.8.x Contracts behind the MiCA-licensed e-money tokens **EURe / GBPe / USDe / ISKe**. Foundry + Hardhat. One shared implementation, four ERC-1967 (UUPS) proxies, one shared blacklist validator.

Main files:

| Path | Role |
| --- | --- |
| `src/Token.sol` | The V2 implementation: `ERC20PermitUpgradeable` + UUPS + mint allowance + system roles, `recover()` |
| `src/SystemRoleUpgradeable.sol` | The 3-tier model: `owner` (2-step ownable) → `admin` → `system` |
| `src/MintAllowanceUpgradeable.sol` | Per-`system`-account mint allowance with a global cap |
| `src/IValidator.sol` | Transfer-hook interface called on every `transfer`/`transferFrom` |
| `src/BlacklistValidatorUpgradeable.sol` | The shipped validator: `ban` / `unban`, shared across the four tokens |
| `src/ControllerToken.sol` | Compatibility shim so the V2 proxy can drive the V1 `TokenFrontend` (`*_withCaller` functions, ERC-677 `transferAndCall`) |
| `src/controllers/{Ethereum,Gnosis,Polygon}ControllerToken.sol` | Per-chain controller variants |
| `src/v2_1_0/*` | V2.1.0 controller implementations |
| `src/BatchMint.sol` | One-shot helper to migrate V1 balances into a V2 token |
| `docs/tokendesign.md` | **Best entry point** — roles, issuing/redeeming, fund recovery |
| `docs/version2.md`, `migrating_V1_to_V2.md`, `permit.md`, `DeploymentPlaybook.md` | Design & ops docs |
| `audits/` | Three Ackee Blockchain reports (v1.1.0, v1.2.1, v2.0.0) |
| `holders-main.csv`, `holders-sepolia.csv` | Holder snapshots used by the V1 → V2 migration |

## Wyoming — `frontier-stable-token`

Upstream: <https://github.com/wyostable/frontier-stable-token> · License AGPL-3.0-or-later · Solidity 0.8.22 The **Wyoming Stable Token (FRNT)** and its yield-bearing wrapper **wFRNT** (<https://stabletoken.wyo.gov/>, Ethereum `0x5e817f2abccb9095585d26c2a3ce234a440574fc`). Built on **Fireblocks' ERC-20F** and wired for cross-chain with **LayerZero OFT** (hub/spoke).

> Note: the Commission announced a migration from LayerZero to **Chainlink CCIP** in August 2026 ([press release](https://www.prnewswire.com/news-releases/wyoming-stable-token-commission-migrates-to-chainlink-ccip-for-enhanced-operational-security-302854502.html)). This snapshot still reflects the LayerZero architecture.

Main files:

| Path | Role |
| --- | --- |
| `contracts/FrontierERC20F.sol` | FRNT / spoke-chain wFRNT — `ERC20F` + `ADAPTER_ROLE`, 6 decimals |
| `contracts/FrontierVault.sol` | Hub-chain ERC-4626 vault issuing the yield-bearing wFRNT |
| `contracts/FrontierOFTAdapter.sol` | Hub adapter for wFRNT — **lock/unlock** (burning would corrupt vault yield math) |
| `contracts/FrontierOFTAdapterMintAndBurn.sol` | Adapter for FRNT and spoke wFRNT — **mint/burn** |
| `contracts/fireblocks/ERC20F.sol` | Fireblocks base: UUPS, `ERC20Permit`, `Multicall`, roles (`UPGRADER`, `PAUSER`, `CONTRACT_ADMIN`, `MINTER`, `BURNER`, `RECOVERY`, `SALVAGE`) |
| `contracts/fireblocks/library/DenyList.sol` | The `FrontierAccessRegistry` implementation — deny-list semantics |
| `contracts/fireblocks/library/AccessRegistrySubscriptionUpgradeable.sol` | Hook that queries the registry before mint/transfer/receive |
| `contracts/fireblocks/library/SalvageUpgradeable.sol` | `salvageERC20` / `salvageGas` |
| `contracts/fireblocks/library/PauseUpgradeable.sol`, `RoleAccessUpgradeable.sol` | Pause + role plumbing |
| `programs/oft/` | The **Solana** (Anchor) OFT program — `send`, `lz_receive`, peer config, fee withdrawal |
| `deployments/` | Deployed addresses per chain (ethereum, arbitrum, base, optimism, polygon, avalanche, hedera, solana + testnets) |
| `layerzero-mainnet.config.ts`, `layerzero-testnet.config.ts`, `consts/` | DVN / enforced-options / multisig wiring |
| `tasks/` | Hardhat tasks driven through Fireblocks custody |

## CoinVertible — `cv_eth_0xf4ccc80c…`

**CoinVertible** (EURCV / USDCV), issued by Société Générale FORGE.

* Product page: <https://www.sgforge.com/product/coinvertible/>
* Implementation: <https://etherscan.io/address/0xF4ccC80C4b831A0d8d1414F2ACa82a3D760Ff05B>
* Proxy (entrypoint / token): <https://etherscan.io/token/0x5422374B27757da72d5265cC745ea906E0446634>

Solidity 0.8.22, UUPS upgradeable, OpenZeppelin 4.x upgradeable vendored alongside.

| Path | Role |
| --- | --- |
| `contracts/smartCoin/SmartCoin.sol` | The token: ERC-20 + `mint`, `burn`, `wipeFrozenAddress`, redemption-address routing, gated `upgradeTo` |
| `contracts/smartCoin/ISmartCoin.sol` | Documented token interface (the transfer semantics are described here) |
| `contracts/smartCoin/AccessControlUpgradeable.sol` | The three-operator model: `registrar`, `operations`, `technical` — each role transfer is **2-step** (`accept*Role`) |
| `contracts/smartCoin/IAccessControl.sol` | `freeze` / `unfreeze` (batch), `pause`, `authorizeImplementation`, `add/removeRedemptionAddresses` |
| `contracts/smartCoin/SmartCoinDataLayout.sol`, `AccessControlDataLayout.sol` | Explicit storage layouts |
| `@openzeppelin/contracts-upgradeable/**` | Vendored OZ dependencies as flattened by Etherscan |
| `abi.json` | ABI of the implementation |

Notable design points: a transfer to a registered *redemption address* is silently rerouted to the `registrar` and emits `RedemptionStarted`; upgrades are two-step (`authorizeImplementation` by the registrar/operations, then `upgradeTo` by the `technical` operator); `pause` stops everything except registrar `mint`/`burn`.

## Tether — `usdt_eth_0xdac17f95…`

**USDT**, issued by Tether. Single-file, non-upgradeable, Solidity 0.4.17.

* Address: <https://etherscan.io/address/0xdac17f958d2ee523a2206206994597c13d831ec7>

| Path | Role |
| --- | --- |
| `TetherToken.sol` | The whole token in one file — Solidity **0.4.17**, non-standard ERC-20 (no return values) |
| `abi.json` | ABI |

Notable design points: `SafeMath`, `Ownable`, `Pausable` and `BlackList` inlined; a *fee* mechanism (`basisPointsRate` / `maximumFee`, set via `setParams`, currently 0); `destroyBlackFunds` burns a blacklisted balance; `issue` / `redeem` for supply control (owner only, no separate minter role); and a `deprecate(address)` "upgrade" that forwards every ERC-20 call to a successor contract instead of using a proxy. `onlyPayloadSize` guards against the short-address attack.

---

## See also

* [`SUMMARY.md`](./SUMMARY.md) — feature-by-feature comparison across all of the above, with CMTAT.
* `../cmtat/` — the CMTAT submodules (CMTAT, CMTAT-Confidential, CMTAT-Factory, CMTAT-LayerZero, RuleEngine, Rules, SnapshotEngine).
