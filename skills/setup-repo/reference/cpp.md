# C++ reference

Last reviewed: 2026-11-09.

| Concern | Default | Alternatives (ask) | Notes |
|---|---|---|---|
| Build system | **CMake ≥ 3.25 with `CMakePresets.json`** | Meson, Bazel | Presets: `dev`, `tidy`, `asan`, `release`. |
| Dependency manager | **vcpkg, manifest mode** (`vcpkg.json` + `builtin-baseline`) | Conan 2, CPM/FetchContent | vcpkg integrates through the CMake toolchain file; the baseline pins every port version. For Conan, render with vcpkg and replace the toolchain and CI setup. |
| Standard | C++20 | C++23 | Ask; C++23 needs recent compilers on every target platform. |
| Formatter | **clang-format**, Google style | LLVM, Mozilla, project style | Ask about style only if the team already has one. pre-commit's `mirrors-clang-format` pins the version. |
| Static analysis | **clang-tidy** (bugprone, cert, cppcoreguidelines, modernize, performance, readability, …), warnings as errors | cppcheck | Runs on the project's own targets via the `tidy` preset (needs a configured build). |
| Compiler warnings | `-Wall -Wextra -Wpedantic -Wshadow -Wconversion …` as errors (`/W4 /WX` on MSVC) | | Option `<PROJECT>_WARNINGS_AS_ERRORS`. |
| Tests | **GoogleTest** + CTest (labels `unit`, `integration`) | Catch2, doctest | `gtest_discover_tests` registers each test case. |
| Sanitizers | ASan + UBSan preset and CI job | TSan for threaded code | GCC/Clang only. |

## Questions to ask

- Library or application (application adds an executable target and `src/main.cpp`).
- C++ standard (20 recommended).
- Dependency manager: vcpkg (recommended) or Conan.
- Target platforms: Linux only (CI template), or also Windows/macOS (add matrix entries:
  `windows-latest` with MSVC, `macos-latest` with Apple Clang; the sanitizer job stays on Linux).

## Notes

- `VCPKG_ROOT` must point at a vcpkg clone on developer machines; CI fetches vcpkg at the exact
  `builtin-baseline` commit and caches binary packages.
- Update the baseline (all ports at once) with `vcpkg x-update-baseline`, as its own commit.

## Retrofit notes

- Existing CMake projects: add presets and the warnings interface target; don't restructure their
  targets. Introduce `-Werror` only after the existing warnings are fixed (ask).
- Existing `.clang-format`: keep it.
