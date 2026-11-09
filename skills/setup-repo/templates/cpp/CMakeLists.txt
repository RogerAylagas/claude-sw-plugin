cmake_minimum_required(VERSION 3.25)

project(
  {{PROJECT_NAME}}
  VERSION 0.1.0
  DESCRIPTION "{{DESCRIPTION}}"
  LANGUAGES CXX)

set(CMAKE_CXX_STANDARD {{CXX_STANDARD}})
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

option({{PACKAGE_UPPER}}_WARNINGS_AS_ERRORS "Treat compiler warnings as errors" ON)
option({{PACKAGE_UPPER}}_CLANG_TIDY "Run clang-tidy on the project's sources while building" OFF)

# Warning flags for the project's own targets (dependencies are not affected).
add_library({{PACKAGE_NAME}}_warnings INTERFACE)
if(MSVC)
  target_compile_options(
    {{PACKAGE_NAME}}_warnings INTERFACE /W4 /permissive-
                                        $<$<BOOL:${{{PACKAGE_UPPER}}_WARNINGS_AS_ERRORS}>:/WX>)
else()
  target_compile_options(
    {{PACKAGE_NAME}}_warnings
    INTERFACE -Wall
              -Wextra
              -Wpedantic
              -Wshadow
              -Wconversion
              -Wsign-conversion
              -Wold-style-cast
              -Wnon-virtual-dtor
              -Woverloaded-virtual
              $<$<BOOL:${{{PACKAGE_UPPER}}_WARNINGS_AS_ERRORS}>:-Werror>)
endif()

add_library({{PACKAGE_NAME}} src/{{PACKAGE_NAME}}.cpp)
add_library({{PACKAGE_NAME}}::{{PACKAGE_NAME}} ALIAS {{PACKAGE_NAME}})
target_include_directories({{PACKAGE_NAME}} PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)
target_link_libraries({{PACKAGE_NAME}} PRIVATE {{PACKAGE_NAME}}_warnings)

add_executable({{PACKAGE_NAME}}_cli src/main.cpp)  # sw:if kind=app
set_target_properties({{PACKAGE_NAME}}_cli PROPERTIES OUTPUT_NAME {{PROJECT_NAME}})  # sw:if kind=app
target_link_libraries({{PACKAGE_NAME}}_cli PRIVATE {{PACKAGE_NAME}} {{PACKAGE_NAME}}_warnings)  # sw:if kind=app

if({{PACKAGE_UPPER}}_CLANG_TIDY)
  find_program(CLANG_TIDY_EXE NAMES clang-tidy REQUIRED)
  set_target_properties({{PACKAGE_NAME}} PROPERTIES CXX_CLANG_TIDY "${CLANG_TIDY_EXE}")
endif()

include(CTest)
if(BUILD_TESTING)
  add_subdirectory(tests)
endif()
