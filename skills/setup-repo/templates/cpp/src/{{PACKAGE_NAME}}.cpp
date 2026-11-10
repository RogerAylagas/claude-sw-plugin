#include "{{PACKAGE_NAME}}/{{PACKAGE_NAME}}.hpp"

#include <string>
#include <string_view>

namespace {{PACKAGE_NAME}} {

std::string greet(std::string_view name) {
  std::string greeting = "Hello, ";
  greeting.append(name);
  greeting.append("!");
  return greeting;
}

}  // namespace {{PACKAGE_NAME}}
