## C++

- C++{{CXX_STANDARD}}, built with CMake presets (`CMakePresets.json`): `dev` (Debug), `tidy`
  (clang-tidy), `asan` (sanitizers), `release`. Build output goes to `build/<preset>/`.
- Dependencies come from vcpkg in manifest mode: add them to `vcpkg.json`, then
  `find_package(...)` and `target_link_libraries(...)` in CMake. `VCPKG_ROOT` must point at a
  vcpkg checkout.
- 14-day rule: `builtin-baseline` in `vcpkg.json` is a vcpkg commit at least 14 days old, and
  Dependabot moves it only after its cooldown. Exemption: an `overrides` entry for that one port.
- Public headers in `include/{{PACKAGE_NAME}}/`, sources in `src/`, GoogleTest unit tests in
  `tests/unit/`, integration tests in `tests/integration/` (CTest labels `unit` and
  `integration`).
- Style: clang-format (Google style); clang-tidy with warnings as errors; compiler warnings are
  errors. Prefer RAII, `std::` containers and value semantics; no raw `new`/`delete`.
