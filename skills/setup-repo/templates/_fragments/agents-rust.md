## Rust

- Toolchain from `rust-toolchain.toml` (stable, with rustfmt and clippy). Add dependencies with
  `cargo add <crate>` (dev-only: `cargo add --dev <crate>`); commit `Cargo.lock`.
- Unit tests live next to the code in `#[cfg(test)] mod tests`; integration tests in `tests/*.rs`.
- Lints: clippy `all` and `pedantic` are warnings, and CI treats warnings as errors; `unsafe` is
  forbidden. Fix lints instead of adding `#[allow(...)]`; if an allow is unavoidable, scope it
  narrowly and explain why.
- Return `Result` for recoverable errors; reserve `panic!`/`unwrap` for bugs and tests.
