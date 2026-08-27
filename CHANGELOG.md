# CHANGELOG

Please follow [https://changelog.md](https://changelog.md) conventions.

This repository publishes documents rather than code, so the version numbers describe the analysis, not a deployable artefact.

## Semantic Version 2.0.0

Given a version number MAJOR.MINOR.PATCH, increment the:

1. MAJOR version when a conclusion changes: a verdict is reversed, a comparison axis is redefined, or the document is restructured such that a reader of the previous version would be misled.
2. MINOR version when a token, a companion project or a comparison section is added, or when pinned sources are moved forward.
3. PATCH version for corrections, clarifications and editorial changes that leave the conclusions intact.

See [https://semver.org](https://semver.org)

## Type of changes

- `Added` for new features.
- `Changed` for changes in existing functionality.
- `Deprecated` for soon-to-be removed features.
- `Removed` for now removed features.
- `Fixed` for any bug fixes.
- `Security` in case of vulnerabilities.

## [0.1.0] - 2026-08-26

First release.

### Added

- `README.md` — a feature-by-feature comparison of the CMTAT standard against seven production stablecoins, across six tables: token standards and signature flows, supply control, compliance and enforcement, access control and governance, upgradeability and lifecycle, and yield, cross-chain and extras.
  - Each table splits CMTAT into three columns — `Light`, `CMTAT` and `Companion` — because a feature's availability depends on which variant is deployed and which companion project is wired alongside it.
  - The stablecoins analysed are Circle (USDC, EURC), Paxos (USDP, USDG, PYUSD, PAXG), Monerium (EURe, GBPe, USDe, ISKe), Wyoming (FRNT, wFRNT), SG-FORGE (CoinVertible), Bridge/Stripe (EURR) and Tether (USDT).
  - A gap analysis separating what the CMTA stack covers outside the token, what it does not provide at all, and what CMTAT has that no stablecoin here does.
- `stablecoin-doc-issue.md` — fourteen documented errors in CMTAT's own `doc/technical/stablecoin.md`, each with the quoted claim, the contradicting source, and a suggested fix.
- `vendor-stablecoins/README.md` — a guide to each vendored stablecoin codebase and the files that matter in it.
- `vendor-stablecoins/SUMMARY.md` — a stablecoin-to-stablecoin comparison that does not centre on CMTAT.
- `CLAUDE.md` and `AGENTS.md` — repository conventions and the evidence rules the analysis follows.
- Seventeen pinned submodules: the CMTAT stack under `cmtat/`, the stablecoin sources under `vendor-stablecoins/`, and Chainlink's ACE policy library under `vendor-chainlink/`.

### Notes on method

- Every claim is read from source pinned in this repository. Upstream documentation is not treated as evidence, and where a document and the code disagree, the code decides and the discrepancy is recorded.
- Claims that could not be verified against the tree are stated as unverified rather than asserted: contract sizes were not recompiled, and Benji and BUIDL are not vendored here.
- The analysis is a snapshot. Six of the seven stablecoins sit behind upgradeable proxies, so the deployed implementation can diverge from the pinned source without any change to this repository.
