Install:

- A C++{{CXX_STANDARD}} compiler (GCC, Clang or MSVC), [CMake](https://cmake.org) 3.25 or newer,
  and clang-tidy for `just analyze`
- [vcpkg](https://learn.microsoft.com/vcpkg/get_started/get-started): clone it, run its bootstrap
  script, and set the `VCPKG_ROOT` environment variable to the clone
- [uv](https://docs.astral.sh/uv/getting-started/installation/) (runs pre-commit via `uvx`)
- [just](https://just.systems)
