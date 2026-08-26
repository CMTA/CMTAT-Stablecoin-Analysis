# CMTAT-Stablecoin-Analysis — agent guide

> **Note — keep in sync:** `AGENTS.md` and `CLAUDE.md` must always be **identical**. Any edit to one must be applied verbatim to the other.

> **Note — commit messages:** After each group of modifications or each feature added, always provide a **one-line GitHub commit message** (Conventional-Commits style, e.g. `docs: ...`, `fix: ...`, `chore: ...`).
>
> **Never put `!` in a commit message** — not as the breaking-change marker (`feat!: ...`), not anywhere else. In an interactive bash, `!` inside double quotes triggers history expansion, so `git commit -m "feat!: ..."` aborts with `bash: !: unrecognized history modifier`. Signal a breaking change with an uppercase `BREAKING CHANGE:` line in the commit body instead, and keep the subject line free of `!`.

> **Note — no tool names in the changelog:** never name an assistant tool, skill or slash command in `CHANGELOG.md`. The changelog records what changed in *this project*, for readers who have no idea what tooling produced it. A line ending "the `<some-skill>` skill gained the corresponding check" documents the author's toolbox rather than the release, and it rots independently of the repository — the tool can be renamed or deleted, leaving a dangling reference to something the reader could never have seen. Describe the change and its effect; if the tooling matters, record it in the audit or analysis report instead.
>
> This is about **tool identities, not the word "Claude"**: files committed to the repository — `CLAUDE.md`, `AGENTS.md`, `CLAUDE_AUDIT.md`, `CLAUDE_ANALYSIS*.md` — are cited freely, because a reader can open them.

> **Note — do not hard-wrap prose in `CHANGELOG.md`:** one line per bullet or paragraph, and let the editor soft-wrap. Markdown collapses a single newline into a space, so a hard-wrapped bullet renders identically — the cost is invisible in the published changelog and paid entirely in the repository. Changing one word reflows every following line, so a one-word correction arrives as a multi-line diff in which a reviewer cannot see what actually changed; and because the wrap column depends on whoever wrote the entry, the file drifts into a mix of styles that reads as damage. Keep the line structure only where it is semantic: fenced code blocks, tables and blockquotes.

> **Note — long changelog entries get sub-bullets:** past roughly three sentences, a bullet stops being scannable — the defect, its blast radius, the fix, the precedent and the caveat all run together, so a reader looking for any one of them has to parse all five. Lead with one sentence naming *what changed*, then one sub-bullet per distinct claim: impact, fix, behaviour-change warning, cost, migration note. A useful trigger is length — compare against the file's own median bullet and split anything several times longer, since that length almost always means several claims in one paragraph. Sub-bullets follow the same no-hard-wrap rule: one line each.

## What this project is

A **documentation and analysis** repository, not a software project: it compares the [CMTAT](https://github.com/CMTA/CMTAT) token standard against six production stablecoins (Circle USDC/EURC, Paxos USDP/USDG/PYUSD/PAXG, Monerium EURe/GBPe/USDe/ISKe, Wyoming FRNT/wFRNT, SG-FORGE CoinVertible, Tether USDT).

Nothing here is compiled, deployed or tested — the deliverables are Markdown documents, and all Solidity in the tree is upstream reference code pinned as git submodules or captured from Etherscan.

## Key concepts

- **The deliverables are the four Markdown files.** Everything under `cmtat/` and `vendor/` is read-only evidence.
- **Never edit anything inside `cmtat/` or `vendor/`** (except `vendor/README.md` and `vendor/SUMMARY.md`, which are ours). Those trees are submodules and upstream source dumps; a change there is either lost on the next `submodule update` or silently misrepresents the evidence.
- **Every claim must be traced to the pinned source.** Upstream documentation is *not* an acceptable source — CMTAT's own `doc/technical/stablecoin.md` contains 14 verified errors, catalogued in `stablecoin-doc-issue.md`. When a document and the code disagree, the code wins and the discrepancy gets recorded.
- **State non-verification explicitly.** Claims that could not be checked against the tree (contract sizes, tokens not vendored here such as Benji and BUIDL) belong in a "Not verified" section, never asserted inline.
- **The three CMTAT columns.** Comparison tables split CMTAT into `Light` / `CMTAT` / `Companion` because the features are not co-located: `Light` is the stablecoin-oriented variant (`0_CMTATBaseCore`, 11.3 KiB); `CMTAT` is any heavier variant; `Companion` is a separate CMTA project extending the token (RuleEngine, Rules, SnapshotEngine, CMTAT-Factory, CMTAT-LayerZero, CMTAT-ACE, CMTAT-CCIP).
- **Light cannot reach most companions.** `ValidationModuleRuleEngine` enters the inheritance chain at `3_CMTATBaseRuleEngine`; Light stops at level 0, so it has no `setRuleEngine` and therefore no access to RuleEngine, any of the 15 rules, or SnapshotEngine. CMTAT-Factory is the only companion Light can definitely use.
- **`forcedBurn` and `forcedTransfer` never coexist.** `forcedBurn` is defined in `0_CMTATBaseCore` (Light only); `forcedTransfer` and `freezePartialTokens` come from `ERC20EnforcementModule` in `0_CMTATBaseCommon` (every variant *except* Light).
- **Etherscan dumps are named `<token>_eth_<address>_code`,** where the address is the *implementation* contract the source came from, not the proxy users interact with — `cv_eth_0xf4ccc80c…` is CoinVertible's implementation, whose proxy is `0x5422374B…`. The download tool named both directories after the wrong token and they were renamed by hand, so confirm content when re-downloading rather than trusting the generated name.

## File tree

```
README.md                     the main deliverable: CMTAT vs 6 stablecoins, 12 sections, 6 comparison tables
stablecoin-doc-issue.md       14 documented errors in CMTAT's own doc/technical/stablecoin.md, with suggested fixes
vendor/
├── README.md                 per-directory guide to each vendored stablecoin and its main files
├── SUMMARY.md                stablecoin-to-stablecoin comparison (no CMTAT focus)
├── stablecoin-evm/           [submodule] Circle — USDC, EURC (Solidity 0.6.12, transparent proxy)
├── paxos-token-contracts/    [submodule] Paxos — USDP, USDG, PYUSD, PAXG (facets, SupplyControl, rate limits)
├── monerium-smart-contracts/ [submodule] Monerium — EURe/GBPe/USDe/ISKe (UUPS, IValidator hook, no pause)
├── frontier-stable-token/    [submodule] Wyoming — FRNT/wFRNT (Fireblocks ERC-20F, LayerZero OFT, Solana)
├── cv_eth_0xf4ccc80c…_code/    [Etherscan dump] SG-FORGE CoinVertible — EURCV, USDCV (SmartCoin.sol)
└── usdt_eth_0xdac17f95…_code/  [Etherscan dump] Tether USDT (TetherToken.sol, Solidity 0.4.17)
cmtat/
├── CMTAT/                    [submodule] the token standard — deployment variants in contracts/deployment/
├── CMTAT-ACE/                [submodule] Chainlink ACE policy-engine token builds (Lite / Standard)
├── CMTAT-CCIP/               [submodule] Foundry scripts for Chainlink CCIP token pools (no contracts)
├── CMTAT-Confidential/       [submodule] Zama FHE confidential variant
├── CMTAT-Factory/            [submodule] CREATE2 factories (Transparent / UUPS / Beacon, Light and Standard)
├── CMTAT-LayerZero/          [submodule] LayerZero V2 OFT adapters (ERC-7802 and ERC-3643 flavours)
├── RuleEngine/               [submodule] external transfer-restriction controller
├── Rules/                    [submodule] the 15 pluggable rules used by RuleEngine
└── SnapshotEngine/           [submodule] on-chain ERC-20 snapshots
```

## Where the evidence lives

- **CMTAT inheritance chain:** `cmtat/CMTAT/contracts/modules/[0-8]_CMTATBase*.sol` — the digit is the level, and it decides which deployment variant gets which module.
- **CMTAT deployment variants:** `cmtat/CMTAT/contracts/deployment/` — `light/`, `permit/`, `allowlist/`, `snapshot/`, `ERC1363/`, `ERC7551/`, `holderList/`, `debt/`, plus `CMTATStandardStandalone.sol`, `CMTATStandardUpgradeable.sol`, `CMTATUpgradeableUUPS.sol`.
- **The rule catalogue:** `cmtat/Rules/README.md` §"The rules" — 15 rules with their ERC-1404 restriction codes.
- **The ACE policy catalogue:** `cmtat/CMTAT-ACE/README.md` §"Compliance Policies" — note the policies themselves live in the `@chainlink/ace` npm package, which is **not** installed in this tree, so those rows are upstream claims rather than read source.
- **Upstream comparison under review:** `cmtat/CMTAT/doc/technical/stablecoin.md` and the tokenized-fund table at `cmtat/CMTAT/doc/README.md:267`.
- **Version pins:** `git submodule status`, and the table in `README.md` §2.

## Common commands

```bash
git submodule update --init --recursive          # populate cmtat/ and vendor/ (required before any analysis)
git submodule status                             # authoritative version pins for README.md section 2
git -C vendor/<name> log -1 --format='%h %ad'    # date a specific vendored source
```

Verification helpers used while editing the deliverables:

```bash
# per-table column consistency — every Markdown table must have a uniform column count
python3 -c "
rows=open('README.md').read().split('\n'); tbl=[]; start=0; bad=[]
for i,l in enumerate(rows):
    if l.startswith('|'):
        if not tbl: start=i+1
        tbl.append(l.count('|'))
    else:
        if tbl and len(set(tbl))>1: bad.append(start)
        tbl=[]
print(bad if bad else 'tables consistent')"

# no hard-wrapped prose in the agent guides
python3 ~/.claude/skills/check-markdown-linebreaks/check_linebreaks.py CLAUDE.md AGENTS.md
```

## Conventions

- **Symbols are fixed:** ✅ available · ⚠️ partial, indirect or non-standard · ❌ absent · 🏭 companion feature reachable from Light (CMTAT-Factory only). Do not introduce new ones.
- **Column order is fixed** across all six comparison tables: `Feature | Light | CMTAT | Companion | USDC | PAX | MON | FRNT | CV | USDT`. Adding a token means updating all six.
- **Name the contract, not just the project.** A `Companion` cell says `Rules RuleMintAllowance`, not "the Rules library".
- **Cite paths as `file_path:line_number`** when pointing at evidence, so the reference stays clickable and checkable.
- **Markdown prose is never hard-wrapped** — one line per bullet or paragraph, everywhere: `CLAUDE.md`, `AGENTS.md`, `CHANGELOG.md` and all four deliverables (`README.md`, `stablecoin-doc-issue.md`, `vendor/README.md`, `vendor/SUMMARY.md`). A hard wrap always breaks mid-sentence somewhere, and no column width avoids it. Verify with `python3 ~/.claude/skills/check-markdown-linebreaks/check_linebreaks.py --expect=one-line-per-block <files>`; reflow a file with `--unwrap` and commit that on its own, never mixed with substantive edits.
- **Corrections to upstream documentation go in `stablecoin-doc-issue.md`**, one numbered section each, with location, quoted claim, code evidence and a suggested fix — not scattered through `README.md`.
- **No build, test or lint step exists at the root.** If a claim needs compiling to verify, say so and mark it unverified rather than adding tooling to this repository.
