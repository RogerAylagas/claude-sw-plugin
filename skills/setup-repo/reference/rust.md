# Rust reference

Last reviewed: 2026-11-09.

| Concern | Default | Alternatives | Notes |
|---|---|---|---|
| Dependency manager | **cargo** | — | No question needed. `Cargo.lock` is committed for libraries and binaries. |
| Toolchain | `rust-toolchain.toml`, channel `stable` + rustfmt, clippy | pinned version (`1.xx.0`) | Pin an exact version when reproducible builds matter more than staying current. |
| Edition | latest, set by `cargo init` | | |
| Formatter | **rustfmt** | — | pre-commit hook runs `cargo fmt --all`. |
| Linter | **clippy**, `all` + `pedantic` as warnings, `-D warnings` in CI | add `nursery`, `cargo` groups | `[lints]` table in Cargo.toml; `unsafe_code = "forbid"`. |
| Tests | `cargo test` | cargo-nextest | Unit: `#[cfg(test)]` modules; integration: `tests/*.rs`. |

## Questions to ask

- Library or binary (`cargo init --lib` / `--bin`).
- Is `unsafe` needed (FFI, performance)? If yes, change `forbid` to `deny` and require a
  `// SAFETY:` comment per block.
- Optional supply-chain checks: `cargo-deny` (licenses, advisories, duplicate versions). Recommend
  for libraries and services; add as a CI step if accepted.

## Retrofit notes

- Existing `Cargo.toml`: add the `[lints]` tables from `templates/_fragments/cargo-lints.toml`
  only after asking; fixing pedantic lints in an existing codebase can be large, so offer to start
  with `all` only.
- Workspaces: put `[workspace.lints]` in the root and `lints.workspace = true` in each member.
