#include <gtest/gtest.h>

#include <filesystem>
#include <fstream>
#include <string>

#include "{{PACKAGE_NAME}}/{{PACKAGE_NAME}}.hpp"

// Integration smoke test. Placeholder: replace with tests that cross real
// boundaries (files, network, processes, databases).
TEST(GreetIntegration, RoundTripsThroughAFile) {
  const auto path =
      std::filesystem::temp_directory_path() / "{{PACKAGE_NAME}}_smoke.txt";
  {
    std::ofstream out(path);
    out << {{PACKAGE_NAME}}::greet("file");
  }
  std::ifstream in(path);
  std::string line;
  std::getline(in, line);
  in.close();
  std::filesystem::remove(path);
  EXPECT_EQ(line, "Hello, file!");
}
