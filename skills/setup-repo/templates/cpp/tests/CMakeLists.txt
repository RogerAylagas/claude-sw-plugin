find_package(GTest CONFIG REQUIRED)
include(GoogleTest)

add_executable(unit_tests unit/test_greet.cpp)
target_link_libraries(unit_tests PRIVATE {{PACKAGE_NAME}}::{{PACKAGE_NAME}} {{PACKAGE_NAME}}_warnings GTest::gtest_main)
gtest_discover_tests(unit_tests PROPERTIES LABELS unit)

add_executable(integration_tests integration/test_smoke.cpp)
target_link_libraries(integration_tests PRIVATE {{PACKAGE_NAME}}::{{PACKAGE_NAME}} {{PACKAGE_NAME}}_warnings GTest::gtest_main)
gtest_discover_tests(integration_tests PROPERTIES LABELS integration)
